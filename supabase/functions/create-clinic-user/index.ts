import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.1";
import { z } from "https://esm.sh/zod@3.23.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const RoleSchema = z.enum([
  "owner",
  "admin",
  "vet",
  "receptionist",
  "assistant",
]);

const ClinicUserSchema = z
  .object({
    clinic_code: z.string().length(5),
    full_name: z.string().min(3),
    username: z.string().min(3),
    password: z.string().min(8).optional(),
    role: RoleSchema,
    phone: z.string().min(5),
    auth_email: z.string().email().optional(),
    auth_user_id: z.string().uuid().optional(),
  })
  .refine((data) => data.auth_user_id || data.password, {
    message: "Password or auth_user_id is required",
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

  // service_role key must remain server-only
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  let payload: z.infer<typeof ClinicUserSchema>;
  try {
    const json = await req.json();
    const parsed = ClinicUserSchema.safeParse(json);
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

  const { data: clinic, error: clinicError } = await supabase
    .from("clinics")
    .select("clinic_id, clinic_code, name")
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

  const { data: existingUser, error: existingError } = await supabase
    .from("clinic_users")
    .select("id")
    .eq("clinic_id", clinic.clinic_id)
    .eq("username", payload.username)
    .maybeSingle();

  if (existingError) {
    return new Response(
      JSON.stringify({ ok: false, error: existingError.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  if (existingUser) {
    return new Response(
      JSON.stringify({
        ok: false,
        error: "Username is already registered for this clinic",
      }),
      {
        status: 409,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  let authUserId = payload.auth_user_id;
  let createdAuthUser = false;
  if (authUserId) {
    const { data: authLookup, error: authLookupError } =
      await supabase.auth.admin.getUserById(authUserId);

    if (authLookupError || !authLookup?.user) {
      return new Response(
        JSON.stringify({
          ok: false,
          error: "Auth user not found",
        }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (
      payload.phone &&
      authLookup.user.phone &&
      authLookup.user.phone !== payload.phone
    ) {
      return new Response(
        JSON.stringify({
          ok: false,
          error: "Auth user phone does not match payload",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }
  } else {
    const baseUsername = payload.username.trim().toLowerCase();
    const authEmail =
      payload.auth_email ?? `${baseUsername}@${payload.clinic_code}.vet-hub.local`;
    const { data: authUser, error: authError } = await supabase.auth.admin
      .createUser({
        email: authEmail,
        password: payload.password!,
        email_confirm: true,
      });

    if (authError || !authUser?.user) {
      return new Response(
        JSON.stringify({
          ok: false,
          error: authError?.message ?? "Unable to create auth user",
        }),
        {
          status: 409,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }
    authUserId = authUser.user.id;
    createdAuthUser = true;
  }

  const { data: profile, error: profileError } = await supabase
    .from("clinic_users")
    .insert({
      clinic_id: clinic.clinic_id,
      full_name: payload.full_name,
      username: payload.username,
      phone: payload.phone,
      auth_email: payload.auth_email ??
        `${payload.username.trim().toLowerCase()}@${payload.clinic_code}.vet-hub.local`,
      account_status: "under_review",
      role: payload.role,
      auth_user_id: authUserId,
    })
    .select()
    .single();

  if (profileError) {
    if (createdAuthUser && authUserId) {
      await supabase.auth.admin.deleteUser(authUserId);
    }
    return new Response(
      JSON.stringify({ ok: false, error: profileError.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  return new Response(
    JSON.stringify({
      ok: true,
      user: profile,
    }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
});
