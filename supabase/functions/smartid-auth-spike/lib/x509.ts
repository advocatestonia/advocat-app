// Minimal DER / X.509 parser + chain-signature verification (WebCrypto only).
// -----------------------------------------------------------------------------
// Scope: exactly what the Smart-ID spike needs — parse the DER auth certificate
// returned in `cert.value`, expose TBS bytes / SPKI / subject / issuer /
// validity, and verify the certificate's signature against a pinned issuer CA.
// Supported cert-signature algorithms: ECDSA (SHA-256/384/512, P-256/384/521)
// and RSASSA-PKCS1-v1_5 (SHA-256/384/512). SK demo issuing CA "TEST of SK ID
// Solutions EID-Q 2024E" signs end-user certs with ecdsa-with-SHA384 (P-384).
// NOT a general-purpose validator: no extension processing, no revocation,
// no path building beyond one pinned issuer. Documented in the spike doc.
// -----------------------------------------------------------------------------

import { b64Decode } from "./b64.ts";

// ---------- DER primitives ----------

export interface Tlv {
  tag: number;
  /** offset of the tag byte within the buffer */
  start: number;
  /** offset of the first content byte */
  contentStart: number;
  length: number;
  /** offset just past the last content byte */
  end: number;
}

export function readTlv(buf: Uint8Array, offset: number): Tlv {
  if (offset >= buf.length) throw new Error("DER: offset out of bounds");
  const tag = buf[offset];
  let cursor = offset + 1;
  let length = buf[cursor++];
  if (length & 0x80) {
    const numBytes = length & 0x7f;
    if (numBytes === 0 || numBytes > 4)
      throw new Error("DER: unsupported length encoding");
    length = 0;
    for (let i = 0; i < numBytes; i++) length = (length << 8) | buf[cursor++];
  }
  const contentStart = cursor;
  const end = contentStart + length;
  if (end > buf.length) throw new Error("DER: element overruns buffer");
  return { tag, start: offset, contentStart, length, end };
}

export function tlvContent(buf: Uint8Array, t: Tlv): Uint8Array {
  return buf.subarray(t.contentStart, t.end);
}

export function tlvRaw(buf: Uint8Array, t: Tlv): Uint8Array {
  return buf.subarray(t.start, t.end);
}

export function tlvChildren(buf: Uint8Array, t: Tlv): Tlv[] {
  const out: Tlv[] = [];
  let cursor = t.contentStart;
  while (cursor < t.end) {
    const child = readTlv(buf, cursor);
    out.push(child);
    cursor = child.end;
  }
  return out;
}

export function parseOid(content: Uint8Array): string {
  const parts: number[] = [];
  parts.push(Math.floor(content[0] / 40), content[0] % 40);
  let value = 0;
  for (let i = 1; i < content.length; i++) {
    value = value * 128 + (content[i] & 0x7f);
    if ((content[i] & 0x80) === 0) {
      parts.push(value);
      value = 0;
    }
  }
  return parts.join(".");
}

function decodeDirectoryString(buf: Uint8Array, t: Tlv): string {
  // 0x0c UTF8String, 0x13 PrintableString, 0x16 IA5String, 0x14 TeletexString, 0x1e BMPString
  const content = tlvContent(buf, t);
  if (t.tag === 0x1e) {
    let s = "";
    for (let i = 0; i + 1 < content.length; i += 2) {
      s += String.fromCharCode((content[i] << 8) | content[i + 1]);
    }
    return s;
  }
  return new TextDecoder().decode(content);
}

function parseTime(buf: Uint8Array, t: Tlv): Date {
  const s = new TextDecoder().decode(tlvContent(buf, t));
  if (t.tag === 0x17) {
    // UTCTime YYMMDDHHMMSSZ
    const yy = parseInt(s.slice(0, 2), 10);
    const year = yy < 50 ? 2000 + yy : 1900 + yy;
    return new Date(
      Date.UTC(
        year,
        parseInt(s.slice(2, 4), 10) - 1,
        parseInt(s.slice(4, 6), 10),
        parseInt(s.slice(6, 8), 10),
        parseInt(s.slice(8, 10), 10),
        parseInt(s.slice(10, 12), 10)
      )
    );
  }
  // GeneralizedTime YYYYMMDDHHMMSSZ
  return new Date(
    Date.UTC(
      parseInt(s.slice(0, 4), 10),
      parseInt(s.slice(4, 6), 10) - 1,
      parseInt(s.slice(6, 8), 10),
      parseInt(s.slice(8, 10), 10),
      parseInt(s.slice(10, 12), 10),
      parseInt(s.slice(12, 14), 10)
    )
  );
}

// ---------- X.509 ----------

export const OID_NAMES: Record<string, string> = {
  "2.5.4.3": "CN",
  "2.5.4.4": "surname",
  "2.5.4.5": "serialNumber",
  "2.5.4.6": "C",
  "2.5.4.10": "O",
  "2.5.4.42": "givenName",
  "2.5.4.97": "organizationIdentifier",
};

export interface ParsedCertificate {
  /** raw DER of the whole certificate */
  der: Uint8Array;
  /** raw DER of tbsCertificate (the signed bytes) */
  tbs: Uint8Array;
  /** dotted signature algorithm OID (outer AlgorithmIdentifier) */
  signatureAlgorithmOid: string;
  /** signature bits (BIT STRING content, unused-bits byte stripped) */
  signature: Uint8Array;
  /** raw DER of SubjectPublicKeyInfo — importable via WebCrypto "spki" */
  spki: Uint8Array;
  subject: Record<string, string>;
  issuer: Record<string, string>;
  /** normalized single-line DN strings for pin matching */
  subjectDn: string;
  issuerDn: string;
  notBefore: Date;
  notAfter: Date;
}

function parseName(buf: Uint8Array, nameTlv: Tlv): Record<string, string> {
  const out: Record<string, string> = {};
  for (const rdn of tlvChildren(buf, nameTlv)) {
    for (const atv of tlvChildren(buf, rdn)) {
      const [oidTlv, valTlv] = tlvChildren(buf, atv);
      const oid = parseOid(tlvContent(buf, oidTlv));
      out[OID_NAMES[oid] ?? oid] = decodeDirectoryString(buf, valTlv);
    }
  }
  return out;
}

function dnString(attrs: Record<string, string>): string {
  return Object.entries(attrs)
    .map(([k, v]) => `${k}=${v}`)
    .sort()
    .join(",");
}

export function parseCertificate(der: Uint8Array): ParsedCertificate {
  const root = readTlv(der, 0);
  const [tbsTlv, sigAlgTlv, sigValTlv] = tlvChildren(der, root);

  // signatureAlgorithm
  const sigAlgChildren = tlvChildren(der, sigAlgTlv);
  const signatureAlgorithmOid = parseOid(tlvContent(der, sigAlgChildren[0]));

  // signatureValue — BIT STRING; first content byte = number of unused bits
  const sigBits = tlvContent(der, sigValTlv);
  const signature = sigBits.subarray(1);

  // tbsCertificate fields
  const tbsChildren = tlvChildren(der, tbsTlv);
  let idx = 0;
  if (tbsChildren[0].tag === 0xa0) idx = 1; // [0] EXPLICIT version
  // serialNumber = tbsChildren[idx]; inner sig alg = idx+1
  const issuerTlv = tbsChildren[idx + 2];
  const validityTlv = tbsChildren[idx + 3];
  const subjectTlv = tbsChildren[idx + 4];
  const spkiTlv = tbsChildren[idx + 5];

  const [notBeforeTlv, notAfterTlv] = tlvChildren(der, validityTlv);
  const subject = parseName(der, subjectTlv);
  const issuer = parseName(der, issuerTlv);

  return {
    der,
    tbs: tlvRaw(der, tbsTlv),
    signatureAlgorithmOid,
    signature,
    spki: tlvRaw(der, spkiTlv),
    subject,
    issuer,
    subjectDn: dnString(subject),
    issuerDn: dnString(issuer),
    notBefore: parseTime(der, notBeforeTlv),
    notAfter: parseTime(der, notAfterTlv),
  };
}

export function parsePem(pem: string): Uint8Array {
  const body = pem
    .replace(/-----(BEGIN|END) CERTIFICATE-----/g, "")
    .replace(/\s+/g, "");
  return b64Decode(body);
}

// ---------- chain signature verification ----------

const ECDSA_SIG_OIDS: Record<string, string> = {
  "1.2.840.10045.4.3.2": "SHA-256",
  "1.2.840.10045.4.3.3": "SHA-384",
  "1.2.840.10045.4.3.4": "SHA-512",
};

const RSA_PKCS1_SIG_OIDS: Record<string, string> = {
  "1.2.840.113549.1.1.11": "SHA-256",
  "1.2.840.113549.1.1.12": "SHA-384",
  "1.2.840.113549.1.1.13": "SHA-512",
};

const CURVE_BY_OID: Record<string, { name: string; size: number }> = {
  "1.2.840.10045.3.1.7": { name: "P-256", size: 32 },
  "1.3.132.0.34": { name: "P-384", size: 48 },
  "1.3.132.0.35": { name: "P-521", size: 66 },
};

/** Extract the named-curve OID from an EC SubjectPublicKeyInfo. */
function ecCurveFromSpki(spki: Uint8Array): { name: string; size: number } {
  const root = readTlv(spki, 0);
  const [algTlv] = tlvChildren(spki, root);
  const algChildren = tlvChildren(spki, algTlv);
  if (algChildren.length < 2)
    throw new Error("x509: EC SPKI missing curve parameters");
  const curveOid = parseOid(tlvContent(spki, algChildren[1]));
  const curve = CURVE_BY_OID[curveOid];
  if (!curve) throw new Error(`x509: unsupported EC curve ${curveOid}`);
  return curve;
}

/** Convert DER ECDSA-Sig-Value {r, s} to the raw r||s form WebCrypto expects. */
export function ecdsaDerToRaw(
  derSig: Uint8Array,
  coordSize: number
): Uint8Array {
  const root = readTlv(derSig, 0);
  const [rTlv, sTlv] = tlvChildren(derSig, root);
  const trim = (b: Uint8Array) => {
    let i = 0;
    while (i < b.length - 1 && b[i] === 0) i++;
    return b.subarray(i);
  };
  const r = trim(tlvContent(derSig, rTlv));
  const s = trim(tlvContent(derSig, sTlv));
  if (r.length > coordSize || s.length > coordSize)
    throw new Error("x509: ECDSA component too long");
  const out = new Uint8Array(coordSize * 2);
  out.set(r, coordSize - r.length);
  out.set(s, coordSize * 2 - s.length);
  return out;
}

/**
 * Verify `cert`'s signature using `issuer`'s public key.
 * Returns true when the TBS bytes verify under the certificate's declared
 * signature algorithm.
 */
export async function verifyCertSignature(
  cert: ParsedCertificate,
  issuer: ParsedCertificate
): Promise<boolean> {
  const oid = cert.signatureAlgorithmOid;
  if (ECDSA_SIG_OIDS[oid]) {
    const hash = ECDSA_SIG_OIDS[oid];
    const curve = ecCurveFromSpki(issuer.spki);
    const key = await crypto.subtle.importKey(
      "spki",
      issuer.spki.slice(),
      { name: "ECDSA", namedCurve: curve.name },
      false,
      ["verify"]
    );
    const rawSig = ecdsaDerToRaw(cert.signature, curve.size);
    return await crypto.subtle.verify(
      { name: "ECDSA", hash },
      key,
      rawSig.slice(),
      cert.tbs.slice()
    );
  }
  if (RSA_PKCS1_SIG_OIDS[oid]) {
    const hash = RSA_PKCS1_SIG_OIDS[oid];
    const key = await crypto.subtle.importKey(
      "spki",
      issuer.spki.slice(),
      { name: "RSASSA-PKCS1-v1_5", hash },
      false,
      ["verify"]
    );
    return await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      key,
      cert.signature.slice(),
      cert.tbs.slice()
    );
  }
  throw new Error(`x509: unsupported certificate signature algorithm ${oid}`);
}
