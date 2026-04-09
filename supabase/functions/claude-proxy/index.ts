import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// Rate limit: 20 req/min per user
const rateLimits = new Map<string, number[]>();

// Allowed origin for CORS
const ALLOWED_ORIGIN = "https://advocat.ee";

// Allowed Claude models — reject anything else from the client
const ALLOWED_MODELS = new Set([
  "claude-sonnet-4-20250514",
  "claude-haiku-235-20241022",
  "claude-3-5-sonnet-20241022",
  "claude-3-haiku-20240307",
]);

// Hard limits for request body
const MAX_TOKENS_LIMIT = 1000;
const MAX_MESSAGES = 20;

serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "Authorization, Content-Type",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  // Verify JWT
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "No authorization" }), { status: 401 });
  }

  const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_KEY!);
  const token = authHeader.replace("Bearer ", "");
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) {
    return new Response(JSON.stringify({ error: "Invalid token" }), { status: 401 });
  }

  // Rate limiting
  const userId = user.id;
  const now = Date.now();
  const userRequests = rateLimits.get(userId) || [];
  const recentRequests = userRequests.filter(t => now - t < 60000);
  if (recentRequests.length >= 20) {
    return new Response(JSON.stringify({ error: "Rate limit exceeded" }), { status: 429 });
  }
  recentRequests.push(now);
  rateLimits.set(userId, recentRequests);

  // Parse and sanitize request body
  const body = await req.json();

  // Enforce allowed model — default to haiku if not specified or not allowed
  if (!body.model || !ALLOWED_MODELS.has(body.model)) {
    body.model = "claude-3-haiku-20240307";
  }

  // Enforce max_tokens ceiling
  body.max_tokens = Math.min(body.max_tokens || MAX_TOKENS_LIMIT, MAX_TOKENS_LIMIT);

  // Truncate messages array to prevent abuse
  if (Array.isArray(body.messages) && body.messages.length > MAX_MESSAGES) {
    body.messages = body.messages.slice(-MAX_MESSAGES);
  }

  // Strip client-supplied system prompt — the server controls the system prompt
  delete body.system;

  const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": CLAUDE_API_KEY!,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify(body),
  });

  const result = await claudeResponse.json();
  return new Response(JSON.stringify(result), {
    status: claudeResponse.status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
    },
  });
});
