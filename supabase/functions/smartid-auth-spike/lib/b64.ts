// Base64 / Base64URL helpers (RFC 4648). Pure, no deps.

export function b64Encode(bytes: Uint8Array): string {
  let bin = "";
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin);
}

export function b64Decode(s: string): Uint8Array {
  const bin = atob(s);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

/** Base64URL without padding — RFC 4648 §5, trailing '=' omitted (SK requirement). */
export function b64UrlEncode(bytes: Uint8Array): string {
  return b64Encode(bytes)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

export function b64UrlDecode(s: string): Uint8Array {
  let t = s.replace(/-/g, "+").replace(/_/g, "/");
  while (t.length % 4 !== 0) t += "=";
  return b64Decode(t);
}

export const utf8 = (s: string): Uint8Array => new TextEncoder().encode(s);
