import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");

// O(1) rate limiting: sliding window counter per IP.
// Stores { count, windowStart } instead of an array of timestamps.
const rateLimits = new Map<string, { count: number; windowStart: number }>();

const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX = 10;

const ALLOWED_MODELS = new Set([
  "claude-sonnet-4-20250514",
  "claude-haiku-4-5-20251001",
  "claude-3-5-sonnet-20241022",
  "claude-3-haiku-20240307",
]);

const MAX_TOKENS_LIMIT = 1000;
const MAX_MESSAGES = 20;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, Content-Type, apikey, x-client-info",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" }
    });
  }

  try {
    // O(1) rate limiting by IP — sliding window counter
    const clientIp = req.headers.get("x-forwarded-for") || "unknown";
    const now = Date.now();
    const bucket = rateLimits.get(clientIp);

    if (bucket) {
      if (now - bucket.windowStart < RATE_LIMIT_WINDOW_MS) {
        if (bucket.count >= RATE_LIMIT_MAX) {
          return new Response(JSON.stringify({ error: "Rate limit exceeded. Try again in a minute." }), {
            status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" }
          });
        }
        bucket.count++;
      } else {
        // Window expired — reset
        bucket.count = 1;
        bucket.windowStart = now;
      }
    } else {
      rateLimits.set(clientIp, { count: 1, windowStart: now });
    }

    const body = await req.json();

    // Enforce allowed model
    if (!body.model || !ALLOWED_MODELS.has(body.model)) {
      body.model = "claude-haiku-4-5-20251001";
    }

    // Enforce limits
    body.max_tokens = Math.min(body.max_tokens || MAX_TOKENS_LIMIT, MAX_TOKENS_LIMIT);

    if (Array.isArray(body.messages) && body.messages.length > MAX_MESSAGES) {
      body.messages = body.messages.slice(-MAX_MESSAGES);
    }

    // Limit system prompt size
    if (body.system && typeof body.system === 'string' && body.system.length > 50000) {
      body.system = body.system.slice(0, 50000);
    }

    if (!CLAUDE_API_KEY) {
      return new Response(JSON.stringify({ error: "API key not configured" }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": CLAUDE_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify(body),
    });

    const result = await claudeResponse.json();
    return new Response(JSON.stringify(result), {
      status: claudeResponse.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: "Internal error", details: String(error) }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
