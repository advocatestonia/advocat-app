// Tiny assert helpers — keeps tests fully offline (no jsr/npm fetch needed).

export function assert(cond: boolean, msg = "assertion failed"): asserts cond {
  if (!cond) throw new Error(msg);
}

export function assertEquals<T>(actual: T, expected: T, msg?: string) {
  const ser = (v: unknown) =>
    JSON.stringify(v, (_k, x) => (typeof x === "bigint" ? `${x}n` : x));
  const a = ser(actual);
  const e = ser(expected);
  if (a !== e)
    throw new Error(
      msg ?? `assertEquals failed:\n  actual:   ${a}\n  expected: ${e}`
    );
}

export interface NotificationFixture {
  request: {
    relyingPartyName: string;
    interactions: string;
    signatureProtocolParameters: { rpChallenge: string };
  };
  interactionsJson: string;
  rpChallenge: string;
  expectedVC?: string;
  schemeName: string;
  init: {
    sessionID: string;
    sessionToken?: string;
    sessionSecret?: string;
    deviceLinkBase?: string;
  };
  unprotectedDeviceLink?: string;
  authCode?: string;
  session: {
    state: "RUNNING" | "COMPLETE";
    result?: { endResult: string; documentNumber?: string };
    signatureProtocol?: string;
    signature?: {
      value: string;
      serverRandom: string;
      userChallenge: string;
      flowType: string;
      signatureAlgorithm: string;
      signatureAlgorithmParameters?: {
        hashAlgorithm?: string;
        saltLength?: number;
      };
    };
    cert?: { value: string; certificateLevel: string };
    interactionTypeUsed?: string;
  };
}

export function loadFixture(name: string): NotificationFixture {
  const url = new URL(`../fixtures/${name}`, import.meta.url);
  return JSON.parse(Deno.readTextFileSync(url)) as NotificationFixture;
}
