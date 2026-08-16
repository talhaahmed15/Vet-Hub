import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.1";
import { z } from "https://esm.sh/zod@3.23.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, content-type, apikey, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const PayloadSchema = z.object({
  member_id: z.string().uuid(),
  new_password: z.string().min(8),
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ ok: false, error: "Not found" }, 404);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return json({ ok: false, error: "Server misconfigured" }, 500);
  }

  let payload: z.infer<typeof PayloadSchema>;
  try {
    const parsed = PayloadSchema.safeParse(await req.json());
    if (!parsed.success) {
      return json(
        {
          ok: false,
          error: "Validation failed",
          details: parsed.error.flatten(),
        },
        400,
      );
    }
    payload = parsed.data;
  } catch {
    return json({ ok: false, error: "Invalid JSON body" }, 400);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.toLowerCase().startsWith("bearer ")) {
    return json({ ok: false, error: "Missing auth token" }, 401);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const callerJwt = authHeader.slice(7).trim();
  const callerClient = createClient(supabaseUrl, serviceRoleKey, {
    global: { headers: { Authorization: `Bearer ${callerJwt}` } },
    auth: { persistSession: false },
  });
  const { data: callerUser, error: callerErr } =
    await callerClient.auth.getUser();
  if (callerErr || !callerUser?.user) {
    return json({ ok: false, error: "Invalid auth token" }, 401);
  }

  // Look up target member
  const { data: target, error: targetErr } = await supabase
    .from("clinic_users")
    .select("id, clinic_id, auth_user_id")
    .eq("id", payload.member_id)
    .maybeSingle();
  if (targetErr || !target) {
    return json({ ok: false, error: "Member not found" }, 404);
  }
  if (!target.auth_user_id) {
    return json(
      { ok: false, error: "Member has no auth user to reset" },
      400,
    );
  }

  // Caller must be owner/admin in the target's clinic
  const { data: callerMember } = await supabase
    .from("clinic_users")
    .select("role")
    .eq("clinic_id", target.clinic_id)
    .eq("auth_user_id", callerUser.user.id)
    .maybeSingle();
  if (!callerMember) {
    return json(
      { ok: false, error: "Not a member of the target clinic" },
      403,
    );
  }
  const callerRole = (callerMember.role ?? "").toString().toLowerCase();
  if (callerRole !== "owner" && callerRole !== "admin") {
    return json(
      { ok: false, error: "Only owners or admins can reset passwords" },
      403,
    );
  }

  const { error: updateErr } = await supabase.auth.admin.updateUserById(
    target.auth_user_id,
    { password: payload.new_password },
  );
  if (updateErr) {
    return json({ ok: false, error: updateErr.message }, 500);
  }

  return json({ ok: true });
});
