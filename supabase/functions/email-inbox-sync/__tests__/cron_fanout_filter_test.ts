// Regression lock for email-inbox-sync cron fan-out filter.
// -----------------------------------------------------------------------------
// The cron tick in index.ts (handleCronTick) MUST filter the user_oauth_tokens
// query to exclude rows with NULL refresh_token, otherwise we fan out work to
// users whose ensureFreshToken() call returns null silently and the tick's
// telemetry (threads_synced / errors) lies about how many users actually had
// sync capability.
//
// Because index.ts builds its own Supabase client at module load and wires the
// real Deno.serve listener, we cannot import it here without side effects.
// Instead, this test grep-asserts the literal filter clause is present in the
// source file. If anyone removes `.not("refresh_token", "is", null)` from the
// cron query, this test fails and forces a conscious decision.
//
// Run with:
//   deno test --allow-read \
//     supabase/functions/email-inbox-sync/__tests__/cron_fanout_filter_test.ts
// -----------------------------------------------------------------------------

import {
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

const INDEX_PATH = new URL("../index.ts", import.meta.url);

Deno.test("cron fan-out query filters out NULL refresh_token rows", async () => {
  const src = await Deno.readTextFile(INDEX_PATH);
  // The filter is: provider=gmail AND refresh_token IS NOT NULL, limit 50.
  // We lock the literal substring so the PostgREST clause cannot be silently
  // dropped or rewritten without breaking this test.
  assertStringIncludes(src, '.not("refresh_token"');
  assertStringIncludes(src, '.eq("provider", "gmail")');
});
