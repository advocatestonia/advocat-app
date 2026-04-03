import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// Rate limit: 20 req/min per user
const rateLimits = new Map<string, number[]>();

serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
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

  // Forward to Claude
  const body = await req.json();
  body.max_tokens = Math.min(body.max_tokens || 4096, 8192);

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
      "Access-Control-Allow-Origin": "*",
    },
  });
});
