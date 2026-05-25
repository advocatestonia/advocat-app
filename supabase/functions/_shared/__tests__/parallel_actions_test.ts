// parallel_actions_test.ts
// -----------------------------------------------------------------------------
// Deno tests for supabase/functions/_shared/parallel_actions.ts.
//
// Coverage:
//   1. extractProposedActions returns >=2 actions when the synthesis carries
//      a `<proposed_actions>` block with two `<action>` children (the Sulga
//      pattern: Jokela reply + asiakirjapyyntö to poliisi kirjaamo).
//   2. extractProposedActions returns ONE action from the legacy single-
//      draft fallback when no `<proposed_actions>` block is present.
//   3. extractProposedActions returns an empty array when there is neither
//      a block nor a legacy draft.
//   4. extractProposedActions normalises idx to 0..N-1 even when the model
//      emits out-of-order idx attributes.
//   5. serialiseProposedActions ↔ deserialiseProposedActions round-trip
//      preserves every field.
//
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/_shared/__tests__/parallel_actions_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  deserialiseProposedActions,
  extractProposedActions,
  type ProposedAction,
  serialiseProposedActions,
} from "../parallel_actions.ts";

// =============================================================================
// Fixtures
// =============================================================================

const SULGA_SYNTHESIS = `
[Прямой ответ — направление двух действий параллельно]
...

<proposed_actions>
  <action idx="0" kind="email_reply" lang="fi">
    <to>jokela@migri.fi</to>
    <subject>Vastaus 12.5.2026 viestiin</subject>
    <rationale>Soft-return per HOL §122; declines käännytys without admitting wrong identity claim.</rationale>
    <citations>[[ref:fi-hol:122]], [[ref:eu-echr:6.3]]</citations>
    <body>
Hyvä Jokela,

kiitos viestistänne 12.5.2026. ...
    </body>
  </action>
  <action idx="1" kind="email_new" lang="fi">
    <to>kirjaamo.helsinki@poliisi.fi</to>
    <subject>Asiakirjapyyntö (JulkL 14§)</subject>
    <rationale>2vk deadline; requests Eckerö Line + police ticket records that prove käännytys on 5.12.2025.</rationale>
    <citations>[[ref:fi-julkl:14]]</citations>
    <body>
Pyydän julkisuuslain 14§:n nojalla seuraavat asiakirjat:
- ...
    </body>
  </action>
</proposed_actions>
`;

// =============================================================================
// Tests
// =============================================================================

Deno.test("extractProposedActions — 2-action consilium block", () => {
  const actions = extractProposedActions({ synthesis: SULGA_SYNTHESIS });
  assertEquals(actions.length, 2);

  const [first, second] = actions;
  assertEquals(first.idx, 0);
  assertEquals(first.kind, "email_reply");
  assertEquals(first.to_addr, "jokela@migri.fi");
  assertEquals(first.subject, "Vastaus 12.5.2026 viestiin");
  assertEquals(first.language, "fi");
  assertEquals(first.citations, ["[[ref:fi-hol:122]]", "[[ref:eu-echr:6.3]]"]);
  assert(first.rationale.includes("HOL §122"));
  assert(first.body.includes("Hyvä Jokela"));

  assertEquals(second.idx, 1);
  assertEquals(second.kind, "email_new");
  assertEquals(second.to_addr, "kirjaamo.helsinki@poliisi.fi");
  assertEquals(second.subject, "Asiakirjapyyntö (JulkL 14§)");
  assertEquals(second.citations, ["[[ref:fi-julkl:14]]"]);
});

Deno.test("extractProposedActions — legacy single-draft fallback", () => {
  const actions = extractProposedActions({
    synthesis: "[Прямой ответ] No actions block here.",
    legacyDraft: {
      to_addr: "jokela@migri.fi",
      subject: "Re: 12.5.2026",
      body: "Hyvä Jokela, ...",
      language: "fi",
      rationale: "Single-draft fallback path.",
    },
  });
  assertEquals(actions.length, 1);
  assertEquals(actions[0].idx, 0);
  assertEquals(actions[0].kind, "email_reply");
  assertEquals(actions[0].to_addr, "jokela@migri.fi");
  assertEquals(actions[0].subject, "Re: 12.5.2026");
  assertEquals(actions[0].language, "fi");
});

Deno.test("extractProposedActions — empty when no block and no draft", () => {
  const actions = extractProposedActions({ synthesis: "[Plain text only]" });
  assertEquals(actions.length, 0);
});

Deno.test(
  "extractProposedActions — renormalises idx to contiguous 0..N-1",
  () => {
    const synthesis = `
<proposed_actions>
  <action idx="5" kind="email_new" lang="en">
    <to>a@example.com</to>
    <subject>A</subject>
    <body>...</body>
  </action>
  <action idx="2" kind="email_reply" lang="en">
    <to>b@example.com</to>
    <subject>B</subject>
    <body>...</body>
  </action>
</proposed_actions>
`;
    const actions = extractProposedActions({ synthesis });
    assertEquals(actions.length, 2);
    assertEquals(actions[0].idx, 0);
    assertEquals(actions[1].idx, 1);
    // Order is preserved from the source XML — A before B.
    assertEquals(actions[0].to_addr, "a@example.com");
    assertEquals(actions[1].to_addr, "b@example.com");
  },
);

Deno.test(
  "serialise ↔ deserialise round-trips every field",
  () => {
    const input: ProposedAction[] = [
      {
        idx: 0,
        kind: "email_reply",
        to_addr: "jokela@migri.fi",
        cc: ["watch@advocat.ee"],
        subject: "Re: 12.5.2026",
        body: "Hyvä Jokela, ...",
        language: "fi",
        citations: ["[[ref:fi-hol:122]]"],
        rationale: "Soft-return per HOL §122.",
        gate_token: { hmac: "deadbeef" },
      },
      {
        idx: 1,
        kind: "email_new",
        to_addr: "kirjaamo.helsinki@poliisi.fi",
        cc: [],
        subject: "Asiakirjapyyntö",
        body: "Pyydän JulkL 14§:n nojalla ...",
        language: "fi",
        citations: ["[[ref:fi-julkl:14]]"],
        rationale: "2vk deadline.",
        gate_token: null,
      },
    ];
    const wire = serialiseProposedActions(input);
    const out = deserialiseProposedActions(wire);
    assertEquals(out.length, 2);
    for (let i = 0; i < 2; i++) {
      assertEquals(out[i].idx, input[i].idx);
      assertEquals(out[i].kind, input[i].kind);
      assertEquals(out[i].to_addr, input[i].to_addr);
      assertEquals(out[i].cc, input[i].cc);
      assertEquals(out[i].subject, input[i].subject);
      assertEquals(out[i].body, input[i].body);
      assertEquals(out[i].language, input[i].language);
      assertEquals(out[i].citations, input[i].citations);
      assertEquals(out[i].rationale, input[i].rationale);
      assertEquals(out[i].gate_token, input[i].gate_token);
    }
  },
);

Deno.test(
  "deserialiseProposedActions — graceful on garbage input",
  () => {
    assertEquals(deserialiseProposedActions(null), []);
    assertEquals(deserialiseProposedActions(undefined), []);
    assertEquals(deserialiseProposedActions("not an array"), []);
    assertEquals(deserialiseProposedActions([null, 42, "string"]), []);
  },
);
