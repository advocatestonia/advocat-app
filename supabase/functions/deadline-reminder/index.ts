import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Find deadlines in next 3 days
    const now = new Date();
    const threeDaysFromNow = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

    const { data: urgentDeadlines } = await supabase
      .from("deadlines")
      .select("*, cases(title, user_id)")
      .gte("due_date", now.toISOString())
      .lte("due_date", threeDaysFromNow.toISOString())
      .eq("status", "pending");

    if (!urgentDeadlines || urgentDeadlines.length === 0) {
      return new Response(JSON.stringify({ message: "No urgent deadlines" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // Group by user
    const byUser: Record<string, any[]> = {};
    for (const d of urgentDeadlines) {
      const userId = d.cases?.user_id || d.user_id;
      if (!userId) continue;
      if (!byUser[userId]) byUser[userId] = [];
      byUser[userId].push(d);
    }

    // For each user, get their email and send notification
    const notifications = [];
    for (const [userId, deadlines] of Object.entries(byUser)) {
      const { data: profile } = await supabase
        .from("profiles")
        .select("email, full_name, preferred_language")
        .eq("id", userId)
        .single();

      if (!profile?.email) continue;

      // For now: save notification to a table (later: send push/email)
      for (const d of deadlines) {
        const daysLeft = Math.ceil(
          (new Date(d.due_date).getTime() - now.getTime()) /
            (1000 * 60 * 60 * 24)
        );
        notifications.push({
          user_id: userId,
          type: "deadline_reminder",
          title: `Deadline in ${daysLeft} days: ${d.title}`,
          body: `Your deadline "${d.title}" for case "${d.cases?.title || "your case"}" is due on ${d.due_date}`,
          read: false,
        });
      }
    }

    // Insert notifications into table
    if (notifications.length > 0) {
      const { error: insertError } = await supabase
        .from("notifications")
        .insert(notifications);

      if (insertError) {
        console.error("Failed to insert notifications:", insertError);
      }
    }

    return new Response(
      JSON.stringify({
        checked: urgentDeadlines.length,
        notifications: notifications.length,
        details: notifications,
      }),
      {
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
