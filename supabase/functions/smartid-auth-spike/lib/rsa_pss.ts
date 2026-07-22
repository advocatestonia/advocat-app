// Manual RSASSA-PSS verification (RFC 8017 §8.1.2 / §9.1.2) using BigInt.
// -----------------------------------------------------------------------------
// WHY THIS EXISTS (key spike finding, 2026-07-17, Deno 2.7.12):
// Deno's WebCrypto can generate+use RSA keys of any size, but `verify` with a
// key IMPORTED via importKey("spki", …) fails with "public key error: SPKI
// cryptographic key data malformed" for moduli larger than 4096 bits — for
// BOTH RSA-PSS and RSASSA-PKCS1-v1_5. Smart-ID authentication certificates in
// the SK demo environment carry RSA-6144 keys, so WebCrypto alone cannot
// verify Smart-ID ACSP_V2 signatures in a Deno edge function.
//
// This is verification-only (public-key operation: one modexp with e=65537),
// so constant-time concerns that apply to signing/decryption do not arise.
// Cross-validated in tests against WebCrypto on a 2048-bit key and against a
// LIVE SK demo signature on a 6144-bit key.
// -----------------------------------------------------------------------------

import { readTlv, tlvChildren, tlvContent } from "./x509.ts";

// ---------- big-integer helpers ----------

export function bytesToBigInt(bytes: Uint8Array): bigint {
  let n = 0n;
  for (const b of bytes) n = (n << 8n) | BigInt(b);
  return n;
}

export function bigIntToBytes(n: bigint, length: number): Uint8Array {
  const out = new Uint8Array(length);
  for (let i = length - 1; i >= 0; i--) {
    out[i] = Number(n & 0xffn);
    n >>= 8n;
  }
  if (n !== 0n) throw new Error("rsa_pss: integer too large for target length");
  return out;
}

export function modPow(base: bigint, exp: bigint, mod: bigint): bigint {
  let result = 1n;
  base %= mod;
  while (exp > 0n) {
    if (exp & 1n) result = (result * base) % mod;
    base = (base * base) % mod;
    exp >>= 1n;
  }
  return result;
}

// ---------- SPKI → (n, e) ----------

/** Parse modulus + exponent from an rsaEncryption SubjectPublicKeyInfo. */
export function rsaPublicKeyFromSpki(spki: Uint8Array): {
  n: bigint;
  e: bigint;
  modBits: number;
} {
  const root = readTlv(spki, 0);
  const [, bitStringTlv] = tlvChildren(spki, root);
  const bitString = tlvContent(spki, bitStringTlv);
  // first byte of BIT STRING content = unused-bit count (0 here)
  const rsaPubDer = bitString.subarray(1);
  const seq = readTlv(rsaPubDer, 0);
  const [nTlv, eTlv] = tlvChildren(rsaPubDer, seq);
  const stripLeadingZeros = (b: Uint8Array) => {
    let i = 0;
    while (i < b.length - 1 && b[i] === 0) i++;
    return b.subarray(i);
  };
  const nBytes = stripLeadingZeros(tlvContent(rsaPubDer, nTlv));
  const n = bytesToBigInt(nBytes);
  const e = bytesToBigInt(stripLeadingZeros(tlvContent(rsaPubDer, eTlv)));
  return { n, e, modBits: nBytes.length * 8 - Math.clz32(nBytes[0]) + 24 };
}

// ---------- MGF1 + EMSA-PSS-VERIFY ----------

async function digest(hashName: string, data: Uint8Array): Promise<Uint8Array> {
  return new Uint8Array(await crypto.subtle.digest(hashName, data.slice()));
}

async function mgf1(
  hashName: string,
  seed: Uint8Array,
  maskLen: number
): Promise<Uint8Array> {
  const hLen = hashLen(hashName);
  const mask = new Uint8Array(maskLen);
  const counter = new Uint8Array(4);
  let offset = 0;
  for (let i = 0; offset < maskLen; i++) {
    counter[0] = (i >>> 24) & 0xff;
    counter[1] = (i >>> 16) & 0xff;
    counter[2] = (i >>> 8) & 0xff;
    counter[3] = i & 0xff;
    const block = await digest(hashName, concat(seed, counter));
    mask.set(block.subarray(0, Math.min(hLen, maskLen - offset)), offset);
    offset += hLen;
  }
  return mask;
}

function hashLen(hashName: string): number {
  switch (hashName) {
    case "SHA-256":
      return 32;
    case "SHA-384":
      return 48;
    case "SHA-512":
      return 64;
    default:
      throw new Error(`rsa_pss: unsupported hash ${hashName}`);
  }
}

function concat(...parts: Uint8Array[]): Uint8Array {
  const out = new Uint8Array(parts.reduce((s, p) => s + p.length, 0));
  let o = 0;
  for (const p of parts) {
    out.set(p, o);
    o += p.length;
  }
  return out;
}

/** RFC 8017 §9.1.2 EMSA-PSS-VERIFY. Returns true iff EM is consistent with mHash. */
export async function emsaPssVerify(
  mHash: Uint8Array,
  em: Uint8Array,
  emBits: number,
  hashName: string,
  sLen: number
): Promise<boolean> {
  const hLen = hashLen(hashName);
  const emLen = Math.ceil(emBits / 8);
  if (em.length !== emLen) return false;
  if (emLen < hLen + sLen + 2) return false;
  if (em[emLen - 1] !== 0xbc) return false;

  const maskedDb = em.subarray(0, emLen - hLen - 1);
  const h = em.subarray(emLen - hLen - 1, emLen - 1);

  const unusedBits = 8 * emLen - emBits;
  if (unusedBits > 0 && maskedDb[0] >> (8 - unusedBits) !== 0) return false;

  const dbMask = await mgf1(hashName, h, emLen - hLen - 1);
  const db = new Uint8Array(maskedDb.length);
  for (let i = 0; i < db.length; i++) db[i] = maskedDb[i] ^ dbMask[i];
  if (unusedBits > 0) db[0] &= 0xff >> unusedBits;

  const padEnd = emLen - hLen - sLen - 2;
  for (let i = 0; i < padEnd; i++) if (db[i] !== 0) return false;
  if (db[padEnd] !== 0x01) return false;

  const salt = db.subarray(db.length - sLen);
  const mPrime = concat(new Uint8Array(8), mHash, salt);
  const hPrime = await digest(hashName, mPrime);
  if (hPrime.length !== h.length) return false;
  let diff = 0;
  for (let i = 0; i < h.length; i++) diff |= h[i] ^ hPrime[i];
  return diff === 0;
}

/**
 * RSASSA-PSS-VERIFY over `message` with the public key from `spki`.
 * saltLength per Smart-ID spec = octet length of the hash output.
 */
export async function rsaPssVerify(opts: {
  spki: Uint8Array;
  signature: Uint8Array;
  message: Uint8Array;
  hashName: string; // "SHA-256" | "SHA-384" | "SHA-512"
  saltLength: number;
}): Promise<boolean> {
  const { n, e, modBits } = rsaPublicKeyFromSpki(opts.spki);
  const k = Math.ceil(modBits / 8);
  if (opts.signature.length !== k) return false;

  const s = bytesToBigInt(opts.signature);
  if (s >= n) return false;
  const m = modPow(s, e, n);

  const emBits = modBits - 1;
  const emLen = Math.ceil(emBits / 8);
  let em: Uint8Array;
  try {
    em = bigIntToBytes(m, emLen);
  } catch {
    return false;
  }

  const mHash = await digest(opts.hashName, opts.message);
  return await emsaPssVerify(mHash, em, emBits, opts.hashName, opts.saltLength);
}
