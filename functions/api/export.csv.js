function escapeCsv(value) {
  if (value === null || value === undefined) return "";
  const str = String(value);
  return `"${str.replaceAll('"', '""')}"`;
}

export async function onRequestGet(context) {
  const { request, env } = context;

  const url = new URL(request.url);
  const token = url.searchParams.get("token");

  if (!token || token !== env.EXPORT_TOKEN) {
    return new Response("Unauthorized", { status: 401 });
  }

  const { results } = await env.DB.prepare(
    `
    SELECT
      id,
      created_at,
      consent,
      is_adult,
      age_group,
      education_stage,
      major_category,
      nationality_background,
      region,
      gender_identity,
      gender_identity_label,
      gender_identity_group,
      gender_identity_self_describe,
      sexual_orientation,
      sexual_orientation_group,
      sexual_orientation_self_describe,
      relationship_status,
      relationship_willingness,
      love_importance,
      influence_factors,
      love_view,
      partner_factors,
      long_distance_acceptance,
      study_impact,
      relationship_core_values,
      conflict_handling,
      relationship_pressure,
      boundary_awareness,
      help_seeking,
      school_education_need,
      school_support,
      open_problem,
      open_suggestion,
      cf_country,
      turnstile_success,
      request_headers,
      duration_seconds,
      device_type,
      screen_width,
      screen_height,
      device_pixel_ratio,
      color_depth,
      timezone,
      languages,
      platform,
      network_type
    FROM responses
    ORDER BY id ASC
    `
  ).all();

  const headers = [
    "id",
    "created_at",
    "consent",
    "is_adult",
    "age_group",
    "education_stage",
    "major_category",
    "nationality_background",
    "region",
    "gender_identity",
    "gender_identity_label",
    "gender_identity_group",
    "gender_identity_self_describe",
    "sexual_orientation",
    "sexual_orientation_group",
    "sexual_orientation_self_describe",
    "relationship_status",
    "relationship_willingness",
    "love_importance",
    "influence_factors",
    "love_view",
    "partner_factors",
    "long_distance_acceptance",
    "study_impact",
    "relationship_core_values",
    "conflict_handling",
    "relationship_pressure",
    "boundary_awareness",
    "help_seeking",
    "school_education_need",
    "school_support",
    "open_problem",
    "open_suggestion",
    "cf_country",
    "turnstile_success",
    "request_headers",
    "duration_seconds",
    "device_type",
    "screen_width",
    "screen_height",
    "device_pixel_ratio",
    "color_depth",
    "timezone",
    "languages",
    "platform",
    "network_type"
  ];

  const rows = [
    headers.join(","),
    ...results.map((row) =>
      headers.map((header) => escapeCsv(row[header])).join(",")
    )
  ];

  return new Response("\uFEFF" + rows.join("\n"), {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": "attachment; filename=survey-responses.csv",
      "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
      "Pragma": "no-cache",
      "Expires": "0"
    }
  });
}
