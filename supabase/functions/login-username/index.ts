import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.1";
import { z } from "https://esm.sh/zod@3.23.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const LoginSchema = z.object({
  clinic_code: z.string().length(5),
  username: z.string().min(3),
  password: z.string().min(8),
});

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ ok: false, error: "Not found" }), {
      status: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(
      JSON.stringify({ ok: false, error: "Server misconfigured" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  let payload: z.infer<typeof LoginSchema>;
  try {
    const json = await req.json();
    const parsed = LoginSchema.safeParse(json);
    if (!parsed.success) {
      return new Response(
        JSON.stringify({
          ok: false,
          error: "Validation failed",
          details: parsed.error.flatten(),
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }
    payload = parsed.data;
  } catch {
    return new Response(
      JSON.stringify({ ok: false, error: "Invalid JSON body" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const { data: clinic, error: clinicError } = await adminClient
    .from("clinics")
    .select("clinic_id, clinic_code")
    .eq("clinic_code", payload.clinic_code)
    .single();

  if (clinicError || !clinic) {
    return new Response(
      JSON.stringify({ ok: false, error: "Clinic not found" }),
      {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const { data: userRow, error: userError } = await adminClient
    .from("clinic_users")
    .select("auth_email")
    .eq("clinic_id", clinic.clinic_id)
    .eq("username", payload.username)
    .maybeSingle();

  if (userError) {
    return new Response(
      JSON.stringify({ ok: false, error: userError.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  if (!userRow?.auth_email) {
    return new Response(
      JSON.stringify({ ok: false, error: "Account not found" }),
      {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const { data: authData, error: authError } = await adminClient.auth
    .signInWithPassword({
      email: userRow.auth_email,
      password: payload.password,
    });

  if (authError || !authData.session) {
    return new Response(
      JSON.stringify({
        ok: false,
        error: authError?.message ?? "Invalid credentials",
      }),
      {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  return new Response(
    JSON.stringify({
      ok: true,
      session: authData.session,
      user: authData.user,
    }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
});
