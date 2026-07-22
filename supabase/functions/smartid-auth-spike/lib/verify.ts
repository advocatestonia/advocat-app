// Full verification of a completed Smart-ID v3 authentication session:
//   1. ACSP_V2 signature over the reconstructed message (RSASSA-PSS / PKCS1-v1_5)
//   2. certificate validity window + issuer pin + chain signature
//   3. identity extraction from the auth certificate subject
// Spec: rp-api/response_verification.html. Covered by tests/verify_test.ts
// against fixtures captured from live SK demo sessions.

import { b64Decode } from "./b64.ts";
import { buildAcspV2Message } from "./acsp.ts";
import { rsaPssVerify } from "./rsa_pss.ts";
import {
  ParsedCertificate,
  parseCertificate,
  parsePem,
  verifyCertSignature,
} from "./x509.ts";

// ---------- types mirroring the RP API session response ----------

export interface AcspV2Signature {
  value: string; // Base64
  serverRandom: string; // Base64
  userChallenge: string; // Base64URL
  flowType: string;
  signatureAlgorithm: string; // "rsassa-pss" | "shaNNNWithRSAEncryption"
  signatureAlgorithmParameters?: {
    hashAlgorithm?: string; // "SHA-512" etc
    saltLength?: number;
  };
}

export interface SessionStatus {
  state: "RUNNING" | "COMPLETE";
  result?: { endResult: string; documentNumber?: string };
  signatureProtocol?: string;
  signature?: AcspV2Signature;
  cert?: { value: string; certificateLevel: string };
  interactionTypeUsed?: string;
}

export interface SmartIdIdentity {
  /** e.g. "PNOEE-40504040001" */
  etsiIdentifier: string;
  /** e.g. "40504040001" */
  personalCode: string;
  /** ISO 3166-1 alpha-2 from the ETSI identifier, e.g. "EE" */
  country: string;
  givenName: string;
  surname: string;
  documentNumber: string;
}

export interface VerificationResult {
  ok: boolean;
  signatureValid: boolean;
  certChainValid: boolean;
  certInValidityWindow: boolean;
  certificateLevel?: string;
  identity?: SmartIdIdentity;
  error?: string;
}

// ---------- ACSP_V2 signature ----------

const WEBCRYPTO_HASH: Record<string, string> = {
  "SHA-256": "SHA-256",
  "SHA-384": "SHA-384",
  "SHA-512": "SHA-512",
};

/**
 * Verify signature.value over the reconstructed ACSP_V2 message using the
 * public key of the auth certificate.
 *
 * NOTE: rsassa-pss uses the manual RFC 8017 implementation in rsa_pss.ts, NOT
 * WebCrypto — Deno 2.7.12 cannot `verify` with IMPORTED RSA keys larger than
 * 4096 bits ("SPKI cryptographic key data malformed"), and Smart-ID demo auth
 * certs are RSA-6144. See lib/rsa_pss.ts header + docs/SMARTID_SPIKE_2026-07.md.
 */
export async function verifyAcspV2Signature(opts: {
  cert: ParsedCertificate;
  message: string;
  signature: AcspV2Signature;
}): Promise<boolean> {
  const { cert, message, signature } = opts;
  const sigBytes = b64Decode(signature.value);
  const msgBytes = new TextEncoder().encode(message);

  if (signature.signatureAlgorithm === "rsassa-pss") {
    const hashName =
      WEBCRYPTO_HASH[
        signature.signatureAlgorithmParameters?.hashAlgorithm ?? ""
      ];
    if (!hashName) {
      throw new Error(
        `unsupported PSS hash ${signature.signatureAlgorithmParameters?.hashAlgorithm} ` +
          "(SHA3 family is not available in WebCrypto)"
      );
    }
    // saltLength: per spec fixed to the octet length of the hash output.
    const saltLength =
      signature.signatureAlgorithmParameters?.saltLength ??
      parseInt(hashName.split("-")[1], 10) / 8;
    return await rsaPssVerify({
      spki: cert.spki,
      signature: sigBytes,
      message: msgBytes,
      hashName,
      saltLength,
    });
  }

  const pkcs1Match = signature.signatureAlgorithm.match(
    /^sha(256|384|512)WithRSAEncryption$/
  );
  if (pkcs1Match) {
    // Deprecated path; WebCrypto is fine here for keys ≤4096 bits, but will
    // throw for larger imported keys (same Deno limitation as above).
    const key = await crypto.subtle.importKey(
      "spki",
      cert.spki.slice(),
      { name: "RSASSA-PKCS1-v1_5", hash: `SHA-${pkcs1Match[1]}` },
      false,
      ["verify"]
    );
    return await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      key,
      sigBytes.slice(),
      msgBytes
    );
  }

  throw new Error(
    `unsupported signatureAlgorithm ${signature.signatureAlgorithm}`
  );
}

// ---------- certificate validation + identity ----------

export function extractIdentity(
  cert: ParsedCertificate,
  documentNumber: string
): SmartIdIdentity {
  const etsi = cert.subject["serialNumber"] ?? "";
  const m = etsi.match(/^PNO([A-Z]{2})-(.+)$/);
  if (!m) throw new Error(`unexpected subject serialNumber format: ${etsi}`);
  return {
    etsiIdentifier: etsi,
    country: m[1],
    personalCode: m[2],
    givenName: cert.subject["givenName"] ?? "",
    surname: cert.subject["surname"] ?? "",
    documentNumber,
  };
}

export async function validateCertificate(
  certDer: Uint8Array,
  trustedCaPems: string[],
  now = new Date()
): Promise<{
  cert: ParsedCertificate;
  chainValid: boolean;
  inValidityWindow: boolean;
}> {
  const cert = parseCertificate(certDer);
  const inValidityWindow = now >= cert.notBefore && now <= cert.notAfter;

  let chainValid = false;
  for (const pem of trustedCaPems) {
    const ca = parseCertificate(parsePem(pem));
    if (ca.subjectDn !== cert.issuerDn) continue;
    if (await verifyCertSignature(cert, ca)) {
      chainValid = true;
      break;
    }
  }
  return { cert, chainValid, inValidityWindow };
}

// ---------- one-call verification of a COMPLETE/OK session ----------

export async function verifyAuthenticationSession(opts: {
  session: SessionStatus;
  schemeName: string;
  rpChallengeB64: string;
  relyingPartyName: string;
  interactionsB64: string;
  trustedCaPems: string[];
  initialCallbackUrl?: string;
  brokeredRpName?: string;
  now?: Date;
}): Promise<VerificationResult> {
  const { session } = opts;
  const fail = (error: string): VerificationResult => ({
    ok: false,
    signatureValid: false,
    certChainValid: false,
    certInValidityWindow: false,
    error,
  });

  if (session.state !== "COMPLETE") return fail("session not COMPLETE");
  if (session.result?.endResult !== "OK")
    return fail(`endResult=${session.result?.endResult}`);
  if (!session.signature || !session.cert || !session.interactionTypeUsed) {
    return fail("OK session missing signature/cert/interactionTypeUsed");
  }
  if (session.signatureProtocol && session.signatureProtocol !== "ACSP_V2") {
    return fail(`unexpected signatureProtocol=${session.signatureProtocol}`);
  }

  const { cert, chainValid, inValidityWindow } = await validateCertificate(
    b64Decode(session.cert.value),
    opts.trustedCaPems,
    opts.now
  );

  const message = await buildAcspV2Message({
    schemeName: opts.schemeName,
    serverRandom: session.signature.serverRandom,
    rpChallengeB64: opts.rpChallengeB64,
    userChallenge: session.signature.userChallenge,
    relyingPartyName: opts.relyingPartyName,
    brokeredRpName: opts.brokeredRpName ?? "",
    interactionsB64: opts.interactionsB64,
    interactionTypeUsed: session.interactionTypeUsed,
    initialCallbackUrl: opts.initialCallbackUrl ?? "",
    flowType: session.signature.flowType,
  });

  const signatureValid = await verifyAcspV2Signature({
    cert,
    message,
    signature: session.signature,
  });

  const ok = signatureValid && chainValid && inValidityWindow;
  return {
    ok,
    signatureValid,
    certChainValid: chainValid,
    certInValidityWindow: inValidityWindow,
    certificateLevel: session.cert.certificateLevel,
    identity: ok
      ? extractIdentity(cert, session.result.documentNumber ?? "")
      : undefined,
    error: ok ? undefined : "verification failed (see flags)",
  };
}
