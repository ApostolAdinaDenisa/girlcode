import { createClient } from "npm:@supabase/supabase-js@2";

const allowedOrigins = new Set(
    (Deno.env.get("ALLOWED_ORIGINS") ?? "")
        .split(",")
        .map((origin) => origin.trim())
        .filter(Boolean),
);

function jsonResponse(body: unknown, status: number, origin: string): Response {
    return new Response(JSON.stringify(body), {
        status,
        headers: {
            "Access-Control-Allow-Origin": origin,
            "Access-Control-Allow-Headers": "authorization, apikey, x-client-info, content-type",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Content-Type": "application/json",
            "Vary": "Origin",
        },
    });
}

function getField(form: FormData, name: string): string {
    const value = form.get(name);
    return typeof value === "string" ? value.trim() : "";
}

Deno.serve(async (request) => {
    const origin = request.headers.get("origin") ?? "";
    if (!origin || !allowedOrigins.has(origin)) {
        return new Response("Origin is not allowed.", { status: 403 });
    }

    if (request.method === "OPTIONS") {
        return new Response("ok", {
            headers: {
                "Access-Control-Allow-Origin": origin,
                "Access-Control-Allow-Headers": "authorization, apikey, x-client-info, content-type",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Vary": "Origin",
            },
        });
    }
    if (request.method !== "POST") {
        return jsonResponse({ error: "Method not allowed." }, 405, origin);
    }

    const requestLength = Number(request.headers.get("content-length") ?? "0");
    if (Number.isFinite(requestLength) && requestLength > 9 * 1024 * 1024) {
        return jsonResponse({ error: "Request is too large." }, 413, origin);
    }

    let form: FormData;
    try {
        form = await request.formData();
    } catch {
        return jsonResponse({ error: "Expected multipart form data." }, 400, origin);
    }

    const action = getField(form, "action");
    const captchaToken = getField(form, "captchaToken");
    if (!["post", "comment"].includes(action) || !captchaToken || captchaToken.length > 2048) {
        return jsonResponse({ error: "The submission is invalid." }, 400, origin);
    }

    const turnstileSecret = Deno.env.get("TURNSTILE_SECRET_KEY");
    if (!turnstileSecret) {
        return jsonResponse({ error: "CAPTCHA verification is not configured." }, 503, origin);
    }

    const verificationForm = new FormData();
    verificationForm.set("secret", turnstileSecret);
    verificationForm.set("response", captchaToken);

    let verificationResponse: Response;
    try {
        verificationResponse = await fetch(
            "https://challenges.cloudflare.com/turnstile/v0/siteverify",
            { method: "POST", body: verificationForm },
        );
    } catch (error) {
        console.error("Turnstile verification request failed:", error);
        return jsonResponse({ error: "CAPTCHA verification is temporarily unavailable." }, 503, origin);
    }
    if (!verificationResponse.ok) {
        console.error("Turnstile verification returned HTTP", verificationResponse.status);
        return jsonResponse({ error: "CAPTCHA verification is temporarily unavailable." }, 503, origin);
    }

    let verification: { success?: boolean; hostname?: string };
    try {
        verification = await verificationResponse.json();
    } catch (error) {
        console.error("Turnstile verification response was invalid:", error);
        return jsonResponse({ error: "CAPTCHA verification is temporarily unavailable." }, 503, origin);
    }
    let requestHostname: string;
    try {
        requestHostname = new URL(origin).hostname.toLowerCase();
    } catch {
        return jsonResponse({ error: "The request origin is invalid." }, 400, origin);
    }
    if (
        !verification ||
        verification.success !== true ||
        typeof verification.hostname !== "string" ||
        verification.hostname.toLowerCase() !== requestHostname
    ) {
        return jsonResponse({ error: "CAPTCHA verification failed. Please try again." }, 400, origin);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
        return jsonResponse({ error: "Server database credentials are not configured." }, 503, origin);
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
        auth: { autoRefreshToken: false, persistSession: false },
    });

    if (action === "post") {
        const author = getField(form, "author") || "Anonimă";
        const category = getField(form, "category");
        const title = getField(form, "title");
        const body = getField(form, "body");
        const photo = form.get("photo");

        if (author.length > 60 || title.length < 5 || title.length > 140 || body.length < 1 || body.length > 3000) {
            return jsonResponse({ error: "Textul nu respectă limitele permise." }, 400, origin);
        }
        if (photo !== null && (!(photo instanceof File) || photo.type !== "image/jpeg" || photo.size > 8 * 1024 * 1024)) {
            return jsonResponse({ error: "Fotografia nu este validă." }, 400, origin);
        }

        let photoPath: string | null = null;
        let photoData: ArrayBuffer | null = null;
        if (photo instanceof File) {
            photoData = await photo.arrayBuffer();
            const photoBytes = new Uint8Array(photoData);
            if (photoBytes.length < 3 || photoBytes[0] !== 0xff || photoBytes[1] !== 0xd8 || photoBytes[2] !== 0xff) {
                return jsonResponse({ error: "Fotografia nu este un fișier JPEG valid." }, 400, origin);
            }
            photoPath = `${crypto.randomUUID()}.jpg`;
            const { error: uploadError } = await supabase.storage
                .from("community-photos")
                .upload(photoPath, photoData, {
                    contentType: "image/jpeg",
                    upsert: false,
                });
            if (uploadError) {
                console.error("Community photo upload failed:", uploadError.message);
                return jsonResponse({ error: "Fotografia nu a putut fi încărcată." }, 500, origin);
            }
        }

        const { data, error } = await supabase.rpc("submit_post", {
            p_author: author,
            p_category: category,
            p_title: title,
            p_body: body,
            p_photo_path: photoPath,
        });
        if (error) {
            if (photoPath) {
                const { error: cleanupError } = await supabase.storage
                    .from("community-photos")
                    .remove([photoPath]);
                if (cleanupError) {
                    console.error("Failed to remove photo after rejected post:", cleanupError.message);
                    return jsonResponse({ error: "Postarea a eșuat, iar fotografia temporară nu a putut fi curățată." }, 500, origin);
                }
            }
            return jsonResponse({ error: error.message }, 400, origin);
        }
        return jsonResponse({ id: data }, 200, origin);
    }

    const postId = getField(form, "post_id");
    const author = getField(form, "author") || "Anonimă";
    const body = getField(form, "body");
    if (author.length > 60 || body.length < 1 || body.length > 1000 || form.get("photo") !== null) {
        return jsonResponse({ error: "Comentariul nu respectă limitele permise." }, 400, origin);
    }

    const { data, error } = await supabase.rpc("submit_comment", {
        p_post_id: postId,
        p_author: author,
        p_body: body,
    });
    if (error) return jsonResponse({ error: error.message }, 400, origin);
    return jsonResponse({ id: data }, 200, origin);
});
