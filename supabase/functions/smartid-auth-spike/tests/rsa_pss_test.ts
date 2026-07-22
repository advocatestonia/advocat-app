// Tests for the manual RFC 8017 RSASSA-PSS verifier (lib/rsa_pss.ts).
// Includes cross-validation against WebCrypto (2048-bit, where WebCrypto still
// works) and the documented Deno >4096-bit import limitation that forced the
// manual implementation in the first place.

import {
  bigIntToBytes,
  bytesToBigInt,
  modPow,
  rsaPssVerify,
  rsaPublicKeyFromSpki,
} from "../lib/rsa_pss.ts";
import { b64Decode } from "../lib/b64.ts";
import { parseCertificate } from "../lib/x509.ts";
import { assert, assertEquals, loadFixture } from "./testutil.ts";

Deno.test("bigint helpers round-trip", () => {
  const bytes = new Uint8Array([0x01, 0x02, 0xff, 0x00, 0x80]);
  const n = bytesToBigInt(bytes);
  assertEquals(n, 0x0102ff0080n);
  assertEquals(Array.from(bigIntToBytes(n, 5)), Array.from(bytes));
});

Deno.test("modPow basic vectors", () => {
  assertEquals(modPow(4n, 13n, 497n), 445n); // classic RFC example
  assertEquals(modPow(2n, 10n, 1000n), 24n);
  assertEquals(modPow(7n, 0n, 13n), 1n);
});

Deno.test(
  "manual PSS cross-validates against WebCrypto sign (2048-bit)",
  async () => {
    const kp = await crypto.subtle.generateKey(
      {
        name: "RSA-PSS",
        modulusLength: 2048,
        publicExponent: new Uint8Array([1, 0, 1]),
        hash: "SHA-512",
      },
      true,
      ["sign", "verify"]
    );
    const message = new TextEncoder().encode("smart-id spike cross-validation");
    const sig = new Uint8Array(
      await crypto.subtle.sign(
        { name: "RSA-PSS", saltLength: 64 },
        kp.privateKey,
        message
      )
    );
    const spki = new Uint8Array(
      await crypto.subtle.exportKey("spki", kp.publicKey)
    );

    assert(
      await rsaPssVerify({
        spki,
        signature: sig,
        message,
        hashName: "SHA-512",
        saltLength: 64,
      }),
      "manual verifier must accept a WebCrypto-produced signature"
    );

    const tampered = message.slice();
    tampered[0] ^= 0xff;
    assert(
      !(await rsaPssVerify({
        spki,
        signature: sig,
        message: tampered,
        hashName: "SHA-512",
        saltLength: 64,
      })),
      "manual verifier must reject a tampered message"
    );

    const badSig = sig.slice();
    badSig[10] ^= 0x01;
    assert(
      !(await rsaPssVerify({
        spki,
        signature: badSig,
        message,
        hashName: "SHA-512",
        saltLength: 64,
      })),
      "manual verifier must reject a corrupted signature"
    );
  }
);

Deno.test("parses RSA-6144 public key from the live Smart-ID cert", () => {
  const fx = loadFixture("live_notification.json");
  const cert = parseCertificate(b64Decode(fx.session.cert!.value));
  const { e, modBits } = rsaPublicKeyFromSpki(cert.spki);
  assertEquals(modBits, 6144);
  assertEquals(e, 65537n);
});

Deno.test(
  "DOCUMENTED DENO LIMITATION: WebCrypto verify fails for imported RSA-6144 (why rsa_pss.ts exists)",
  async () => {
    const fx = loadFixture("live_notification.json");
    const cert = parseCertificate(b64Decode(fx.session.cert!.value));
    const key = await crypto.subtle.importKey(
      "spki",
      cert.spki.slice(),
      { name: "RSA-PSS", hash: "SHA-512" },
      false,
      ["verify"]
    );
    let threw = false;
    try {
      await crypto.subtle.verify(
        { name: "RSA-PSS", saltLength: 64 },
        key,
        b64Decode(fx.session.signature!.value).slice(),
        new TextEncoder().encode("x")
      );
    } catch {
      threw = true;
    }
    // If this test ever FAILS (i.e. stops throwing), Deno fixed the >4096-bit
    // import bug and lib/rsa_pss.ts can be retired in favour of WebCrypto.
    assert(
      threw,
      "Deno WebCrypto now verifies imported RSA-6144 keys — revisit rsa_pss.ts"
    );
  }
);
