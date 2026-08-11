async function sha256Hex(input) {
  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(hashBuffer)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function verifyTurnstile(token, ip, secret) {
  const response = await fetch(
    "https://challenges.cloudflare.com/turnstile/v0/siteverify",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ secret, response: token, remoteip: ip })
    }
  );
  return await response.json();
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" }
  });
}

function getGenderGroup(value) {
  const map = {
    female_or_woman_aligned: new Set([
      "female","woman","girl","cisgender_woman","cis_woman",
      "transgender_woman","trans_woman","transfeminine","femme",
      "demigirl","demiwoman","librafeminine","paragirl","juxera","girlflux"
    ]),
    male_or_man_aligned: new Set([
      "male","man","boy","cisgender_man","cis_man",
      "transgender_man","trans_man","transmasculine","masc",
      "demiboy","demiman","libramasculine","paraboy","proxvir","boyflux"
    ]),
    nonbinary_or_genderqueer: new Set([
      "nonbinary","non_binary","enby","genderqueer","gender_nonconforming",
      "gender_variant","gender_diverse","gender_expansive","gender_creative",
      "gender_independent","third_gender","other_gender","neither_man_nor_woman",
      "both_man_and_woman","between_man_and_woman"
    ]),
    agender_or_neutral: new Set([
      "agender","genderless","genderfree","gendervoid","voidgender",
      "nullgender","neutrois","neutral_gender","androgyne","androgynous",
      "maverique","aporagender","aliagender","epicene","cassgender",
      "greygender","graygender"
    ]),
    fluid_or_multigender: new Set([
      "genderfluid","genderflux","fluidflux","bigender","trigender",
      "pangender","polygender","multigender","omnigender","ambigender",
      "genderfae","genderfaun","genderflor","genderfruct","genderfrith",
      "genderdoe","genderbuck","demifluid","demiflux","genderfluid_nonbinary"
    ]),
    trans_or_non_cis: new Set([
      "transgender","trans","trans_star","non_cisgender","gender_minority",
      "transsexual","transvestite_identity","crossdresser_identity",
      "questioning_gender","gender_questioning","intergender",
      "intersex_identity","intersex_nonbinary"
    ]),
    cultural_or_community_specific: new Set([
      "two_spirit","hijra","faafafine","faafatama","muxe","travesti",
      "bakla","kathoey","waria","mahu","fakaleiti","akavaine","bissu",
      "calabai","calalai","x_gender","x_jenda","sekhet","sworn_virgin",
      "femminiello","guevedoche"
    ]),
    questioning_or_unsure: new Set(["not_sure","questioning_gender","gender_questioning"]),
    prefer_not_to_say: new Set(["prefer_not_to_say"]),
    self_describe_or_other: new Set([
      "self_describe","prefer_to_self_describe","other_not_listed","queer",
      "queer_gender","pomogender","novigender","autigender","neurogender",
      "xenogender","aesthetigender","kingender","personagender","egogender",
      "charagender","mirrorgender","blurgender","chaosgender","cosmicgender",
      "stargender","solargender","lunargender","cadensgender","colorgender",
      "dreamgender","oneirogender"
    ])
  };
  for (const [group, set] of Object.entries(map)) {
    if (set.has(value)) return group;
  }
  return "self_describe_or_other";
}

function getSexualOrientationGroup(value) {
  const map = {
    heterosexual: new Set(["heterosexual"]),
    same_gender_attraction: new Set(["homosexual","gay","lesbian"]),
    multi_gender_attraction: new Set(["bisexual","pansexual"]),
    asexual_spectrum: new Set(["asexual","demisexual"]),
    queer_or_other: new Set(["queer","other"]),
    questioning_or_unsure: new Set(["questioning"]),
    prefer_not_to_say: new Set(["prefer_not_to_say"])
  };
  for (const [group, set] of Object.entries(map)) {
    if (set.has(value)) return group;
  }
  return "not_answered";
}

const ALLOWED_AGE_GROUP = ["18_20","21_23","24_26","27_or_above","prefer_not_to_say"];
const ALLOWED_EDUCATION_STAGE = [
  "senior_high_grade_3","equivalent_to_senior_high_grade_3",
  "gap_year_or_not_currently_enrolled","college_preparatory_or_foundation",
  "undergraduate_year_1","undergraduate_year_2","undergraduate_year_3",
  "undergraduate_year_4","undergraduate_year_5_or_above","junior_college",
  "postgraduate_master","postgraduate_doctoral","other","prefer_not_to_say"
];
const ALLOWED_RELATIONSHIP_STATUS = [
  "never_dated","dated_before_currently_single","currently_in_relationship",
  "ambiguous_or_unofficial_relationship","not_sure_how_to_define","prefer_not_to_say"
];
const ALLOWED_RELATIONSHIP_WILLINGNESS = [
  "strongly_want","somewhat_want","let_it_be","not_now","clearly_not_want","prefer_not_to_say"
];

export async function onRequestPost(context) {
  const { request, env } = context;

  try {
    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "INVALID_REQUEST_FORMAT" }, 400);
    }

    if (body.consent !== true) {
      return json({ error: "MISSING_CONSENT" }, 400);
    }

    if (body.is_adult !== "yes_18_or_above") {
      return json({ error: "AGE_RESTRICTION" }, 400);
    }

    if (!ALLOWED_AGE_GROUP.includes(body.age_group)) {
      return json({ error: "INVALID_AGE_GROUP" }, 400);
    }
    if (!ALLOWED_EDUCATION_STAGE.includes(body.education_stage)) {
      return json({ error: "INVALID_EDUCATION_STAGE" }, 400);
    }

    // Turnstile disabled — always pass
    const turnstileResult = { success: true };

    const ip =
      request.headers.get("CF-Connecting-IP") ||
      request.headers.get("X-Forwarded-For") ||
      "unknown";

    if (!env.DB) {
      return json({ error: "DATABASE_NOT_BOUND" }, 500);
    }

    const gi = body.gender_identity || "";
    const giSelf = String(body.gender_identity_self_describe || "").trim();
    const so = body.sexual_orientation || "";
    const soSelf = String(body.sexual_orientation_self_describe || "").trim();
    const rs = body.relationship_status || "";
    const rw = body.relationship_willingness || "";

    if (giSelf.length > 80) {
      return json({ error: "GENDER_DESCRIBE_TOO_LONG" }, 400);
    }
    if (soSelf.length > 80) {
      return json({ error: "ORIENTATION_DESCRIBE_TOO_LONG" }, 400);
    }
    if (rs && !ALLOWED_RELATIONSHIP_STATUS.includes(rs)) {
      return json({ error: "INVALID_RELATIONSHIP_STATUS" }, 400);
    }
    if (rw && !ALLOWED_RELATIONSHIP_WILLINGNESS.includes(rw)) {
      return json({ error: "INVALID_RELATIONSHIP_WILLINGNESS" }, 400);
    }

    const createdAt = new Date().toISOString();
    const userAgent = request.headers.get("User-Agent") || "";
    const ipHash = await sha256Hex(ip + "|" + createdAt.slice(0, 10));
    const cfCountry = request.headers.get("CF-IPCountry") || "";

    const giGroup = gi ? getGenderGroup(gi) : "not_answered";
    const soGroup = so ? getSexualOrientationGroup(so) : "not_answered";

    const clamp = (s, max) => (String(s || "").trim().length > max ? String(s).trim().slice(0, max) : String(s || "").trim());

    try {
      await env.DB.prepare(
        `
        INSERT INTO responses (
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
          user_agent,
          ip_hash,
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
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `
      )
        .bind(
          createdAt,
          1,
          body.is_adult,
          body.age_group,
          body.education_stage,
          clamp(body.major_category, 50),
          clamp(body.nationality_background, 50),
          clamp(body.region, 50),
          gi,
          clamp(body.gender_identity_label, 100),
          giGroup,
          giSelf,
          so,
          soGroup,
          soSelf,
          rs || null,
          rw || null,
          clamp(body.love_importance, 50),
          clamp(body.influence_factors, 500),
          clamp(body.love_view, 50),
          clamp(body.partner_factors, 500),
          clamp(body.long_distance_acceptance, 50),
          clamp(body.study_impact, 50),
          clamp(body.relationship_core_values, 50),
          clamp(body.conflict_handling, 50),
          clamp(body.relationship_pressure, 50),
          clamp(body.boundary_awareness, 50),
          clamp(body.help_seeking, 50),
          clamp(body.school_education_need, 50),
          clamp(body.school_support, 50),
          clamp(body.open_problem, 200),
          clamp(body.open_suggestion, 200),
          userAgent,
          ipHash,
          cfCountry,
          1,
          JSON.stringify({
            "Accept-Language": request.headers.get("Accept-Language") || "",
            "Accept": request.headers.get("Accept") || "",
            "Sec-CH-UA": request.headers.get("Sec-CH-UA") || "",
            "Sec-CH-UA-Mobile": request.headers.get("Sec-CH-UA-Mobile") || "",
            "Sec-CH-UA-Platform": request.headers.get("Sec-CH-UA-Platform") || "",
            "CF-Ray": request.headers.get("CF-Ray") || "",
            "Referer": request.headers.get("Referer") || "",
            "User-Agent": userAgent
          }),
          parseInt(body.duration_seconds) || 0,
          clamp(body.device_type, 20),
          parseInt(body.screen_width) || 0,
          parseInt(body.screen_height) || 0,
          parseFloat(body.device_pixel_ratio) || 1,
          parseInt(body.color_depth) || 24,
          clamp(body.timezone, 100),
          clamp(body.languages, 200),
          clamp(body.platform, 50),
          clamp(body.network_type, 20)
        )
        .run();
    } catch (dbErr) {
      return json({ error: "DATABASE_WRITE_FAILED" + dbErr.message }, 500);
    }

    return json({ ok: true });
  } catch (err) {
    return json({ error: "SERVER_INTERNAL_ERROR" + err.message }, 500);
  }
}

export async function onRequestGet() {
  return json({ error: "METHOD_NOT_ALLOWED" }, 405);
}
