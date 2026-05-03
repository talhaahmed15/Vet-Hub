import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.1";
import { z } from "https://esm.sh/zod@3.23.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const FileSchema = z.object({
  name: z.string().min(1),
  content_type: z.string().min(1),
  data_base64: z.string().min(1),
});

const ClinicSchema = z.object({
  clinic_code: z.preprocess(
    (value) => (value === null ? undefined : value),
    z.string().length(5).optional(),
  ),
  name: z.string().min(3),
  address: z.string().min(3),
  contact_number: z.string().min(7),
  website: z.string().url().nullable().optional(),
  logo_url: z.string().url().nullable().optional(),
  certificate_url: z.string().url().nullable().optional(),
  tag_line: z.string().min(1).optional(),
  about_clinic: z.string().min(20).optional(),
  services_offered: z.array(z.string()).optional(),
  working_days: z.array(z.string()).optional(),
  opening_time: z.string().optional(),
  closing_time: z.string().optional(),
  is_certified: z.boolean().optional(),
  package_id: z.string().uuid().optional(),
  package_key: z.string().min(1).optional(),
  clinic_status: z.string().min(1).optional(),
  payment_proof_url: z.string().url().nullable().optional(),
  logo_file: FileSchema.optional(),
  certificate_file: FileSchema.optional(),
  payment_proof_file: FileSchema.optional(),
});

const BUCKET_NAME = "Clinic's Data";
const DEFAULT_PACKAGE_KEY = "trial";

type ClinicPayload = z.infer<typeof ClinicSchema>;

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

  let body: ClinicPayload;
  try {
    const json = await req.json();
    const parsed = ClinicSchema.safeParse(json);
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
    body = parsed.data;
  } catch {
    return new Response(
      JSON.stringify({ ok: false, error: "Invalid JSON body" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  if (body.clinic_code) {
    const { data: existing, error: lookupError } = await supabase
      .from("clinics")
      .select("clinic_id")
      .eq("clinic_code", body.clinic_code)
      .maybeSingle();

    if (lookupError) {
      return new Response(
        JSON.stringify({ ok: false, error: lookupError.message }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (existing) {
      return new Response(
        JSON.stringify({
          ok: false,
          error: "Clinic code already exists",
        }),
        {
          status: 409,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }
  }

  const {
    logo_file,
    certificate_file,
    payment_proof_file,
    package_key,
    package_id,
    ...insertPayload
  } = body;

  const packageLookup = package_id
    ? await supabase
        .from("packages")
        .select()
        .eq("package_id", package_id)
        .eq("is_active", true)
        .maybeSingle()
    : await supabase
        .from("packages")
        .select()
        .eq("package_key", package_key ?? DEFAULT_PACKAGE_KEY)
        .eq("is_active", true)
        .maybeSingle();

  if (packageLookup.error) {
    return new Response(
      JSON.stringify({ ok: false, error: packageLookup.error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const selectedPackage = packageLookup.data;
  if (!selectedPackage) {
    return new Response(
      JSON.stringify({ ok: false, error: "Package not found" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const now = new Date();
  const trialDays = Number(selectedPackage.trial_days ?? 0);
  const isTrial = trialDays > 0;
  const trialEndAt = isTrial
    ? new Date(now.getTime() + trialDays * 24 * 60 * 60 * 1000)
    : null;

  insertPayload.package_id = selectedPackage.package_id;
  insertPayload.package_status = "active";
  insertPayload.clinic_status = insertPayload.clinic_status ?? "pending_review";
  if (trialEndAt) {
    insertPayload.trial_end_at = trialEndAt.toISOString();
  }

  const { data: inserted, error: insertError } = await supabase
    .from("clinics")
    .insert(insertPayload)
    .select()
    .single();

  if (insertError) {
    const isConflict = insertError.code === "23505";
    return new Response(
      JSON.stringify({
        ok: false,
        error: isConflict
          ? "Clinic code already exists"
          : insertError.message,
      }),
      {
        status: isConflict ? 409 : 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  let updated = inserted;
  const clinicCode = inserted.clinic_code ?? inserted.clinic_id;
  const baseFolder = `clinic_${clinicCode}`;

  const updates: Record<string, string> = {};

  if (logo_file) {
    const logoPath = buildStoragePath(
      baseFolder,
      "branding",
      "clinic_logo",
      logo_file.name,
    );
    const uploadError = await uploadFile(
      supabase,
      logoPath,
      logo_file,
    );
    if (uploadError) {
      return new Response(
        JSON.stringify({ ok: false, error: uploadError }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }
    const signed = await supabase.storage
      .from(BUCKET_NAME)
      .createSignedUrl(logoPath, 60 * 60 * 24 * 7);
    if (signed.data?.signedUrl) {
      updates.logo_url = signed.data.signedUrl;
    } else {
      updates.logo_url = supabase.storage
        .from(BUCKET_NAME)
        .getPublicUrl(logoPath).data.publicUrl;
    }
  }

  if (certificate_file) {
    const certPath = buildStoragePath(
      baseFolder,
      "documents",
      "certificate",
      certificate_file.name,
    );
    const uploadError = await uploadFile(
      supabase,
      certPath,
      certificate_file,
    );
    if (uploadError) {
      return new Response(
        JSON.stringify({ ok: false, error: uploadError }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }
    const signed = await supabase.storage
      .from(BUCKET_NAME)
      .createSignedUrl(certPath, 60 * 60 * 24 * 7);
    if (signed.data?.signedUrl) {
      updates.certificate_url = signed.data.signedUrl;
    } else {
      updates.certificate_url = supabase.storage
        .from(BUCKET_NAME)
        .getPublicUrl(certPath).data.publicUrl;
    }
  }

  if (payment_proof_file) {
    const proofPath = buildStoragePath(
      baseFolder,
      "payments",
      "payment_proof",
      payment_proof_file.name,
    );
    const uploadError = await uploadFile(
      supabase,
      proofPath,
      payment_proof_file,
    );
    if (uploadError) {
      return new Response(
        JSON.stringify({ ok: false, error: uploadError }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }
    const signed = await supabase.storage
      .from(BUCKET_NAME)
      .createSignedUrl(proofPath, 60 * 60 * 24 * 7);
    if (signed.data?.signedUrl) {
      updates.payment_proof_url = signed.data.signedUrl;
    } else {
      updates.payment_proof_url = supabase.storage
        .from(BUCKET_NAME)
        .getPublicUrl(proofPath).data.publicUrl;
    }
  }

  if (Object.keys(updates).length > 0) {
    const { data: updatedRow, error: updateError } = await supabase
      .from("clinics")
      .update(updates)
      .eq("clinic_id", inserted.clinic_id)
      .select()
      .single();

    if (updateError) {
      return new Response(
        JSON.stringify({ ok: false, error: updateError.message }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    updated = updatedRow;
  }

  const { error: subscriptionError } = await supabase
    .from("clinic_subscriptions")
    .insert({
      clinic_id: inserted.clinic_id,
      package_id: selectedPackage.package_id,
      status: "active",
      starts_at: now.toISOString(),
      ends_at: trialEndAt ? trialEndAt.toISOString() : null,
      is_trial: isTrial,
    });

  if (subscriptionError) {
    return new Response(
      JSON.stringify({ ok: false, error: subscriptionError.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  return new Response(JSON.stringify({ ok: true, clinic: updated }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});

async function uploadFile(
  supabase: ReturnType<typeof createClient>,
  storagePath: string,
  file: z.infer<typeof FileSchema>,
): Promise<string | null> {
  const bytes = decodeBase64(file.data_base64);
  const { error } = await supabase.storage.from(BUCKET_NAME).upload(
    storagePath,
    bytes,
    { contentType: file.content_type },
  );

  return error ? error.message : null;
}

function decodeBase64(data: string): Uint8Array {
  const binary = atob(data);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

function buildStoragePath(
  baseFolder: string,
  subFolder: string,
  fileLabel: string,
  fileName: string,
): string {
  const extension = fileExtension(fileName);
  const timestamp = Date.now();
  return `${baseFolder}/${subFolder}/${fileLabel}_${timestamp}${extension}`;
}

function fileExtension(fileName: string): string {
  const idx = fileName.lastIndexOf(".");
  return idx >= 0 ? fileName.slice(idx) : "";
}
