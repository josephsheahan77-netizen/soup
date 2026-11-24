// Gorge Bowl: read a photo of a soup board and return today's soup.
//
// Runs as a Supabase Edge Function. The app sends a photo; this function asks
// Claude (Anthropic's AI) to read the board and sends back the soup name and
// any other soups or specials. The Anthropic API key stays here on the server
// (as the ANTHROPIC_API_KEY secret) and is never sent to people's phones.

import Anthropic from "npm:@anthropic-ai/sdk@1.3.0";
import { betaZodOutputFormat } from "npm:@anthropic-ai/sdk@1.3.0/helpers/beta/zod";
import { z } from "npm:zod@4.6.7";

// Only the Gorge Bowl site (and local testing) may use this function.
const ALLOWED_ORIGINS = [
  "https://soupsandtunes.com",
  "https://www.soupsandtunes.com",
  "https://josephsheahan77-netizen.github.io",
  "http://localhost:8000",
];

const MAX_IMAGE_CHARS = 2_500_000; // ~1.8 MB photo; the app shrinks photos well below this
const MEDIA_TYPES = ["image/jpeg", "image/png", "image/webp"] as const;

const Board = z.object({
  readable: z.boolean().describe(
    "true if the photo shows a menu, chalkboard, whiteboard or sign listing food",
  ),
  soup: z.string().describe(
    "Today's soup as written, in plain title case, at most 40 characters. Empty if none is listed.",
  ),
  other: z.string().describe(
    "Any second soup and other specials, comma separated, at most 60 characters. Empty if none.",
  ),
});

const SYSTEM = `You read photos of restaurant soup boards, chalkboards, whiteboards and specials signs in the Columbia River Gorge.
Report only what is actually written on the board. Never guess or invent a soup.
- "soup": the soup of the day. If there are several, put the first or most prominent one here.
- "other": any additional soups first, then other daily specials, comma separated. Leave out prices, times, and decorations.
- Fix obvious handwriting misspellings (for example "brocoli" to "Broccoli") but keep the restaurant's wording otherwise.
- If the photo isn't a menu or board, or the writing can't be read, set readable to false and leave the text fields empty.`;

const client = new Anthropic(); // reads ANTHROPIC_API_KEY from the function's secrets

function cors(origin: string | null): Record<string, string> {
  const allowed = origin && ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allowed,
    "Access-Control-Allow-Headers": "apikey, authorization, content-type, x-client-info",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

function reply(status: number, body: unknown, origin: string | null): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors(origin), "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  const origin = req.headers.get("Origin");
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors(origin) });
  if (req.method !== "POST") return reply(405, { error: "Use POST." }, origin);
  if (!origin || !ALLOWED_ORIGINS.includes(origin)) {
    return reply(403, { error: "This photo reader only works from the Gorge Bowl app." }, origin);
  }

  let image: string, mediaType: string;
  try {
    const body = await req.json();
    image = String(body.image ?? "");
    mediaType = String(body.media_type ?? "image/jpeg");
  } catch {
    return reply(400, { error: "Send the photo as JSON." }, origin);
  }
  if (!image) return reply(400, { error: "No photo was sent." }, origin);
  if (image.length > MAX_IMAGE_CHARS) return reply(413, { error: "That photo is too large." }, origin);
  if (!(MEDIA_TYPES as readonly string[]).includes(mediaType)) {
    return reply(415, { error: "Send a JPEG, PNG or WebP photo." }, origin);
  }

  try {
    const response = await client.beta.messages.parse({
      model: "claude-opus-5-5",
      max_tokens: 16000,
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      system: SYSTEM,
      output_config: { effort: "low", format: betaZodOutputFormat(Board) },
      messages: [{
        role: "user",
        content: [
          {
            type: "image",
            source: { type: "base64", media_type: mediaType as typeof MEDIA_TYPES[number], data: image },
          },
          { type: "text", text: "What soup does this board list for today?" },
        ],
      }],
    });

    if (response.stop_reason === "refusal") {
      return reply(422, { error: "Couldn't read that photo. Type the soup in instead." }, origin);
    }
    const out = response.parsed_output;
    if (!out) return reply(502, { error: "Couldn't read the board. Type the soup in instead." }, origin);

    return reply(200, {
      readable: out.readable && out.soup.trim().length > 0,
      soup: out.soup.trim().slice(0, 40),
      other: out.other.trim().slice(0, 60),
    }, origin);
  } catch (error) {
    if (error instanceof Anthropic.AuthenticationError) {
      console.error("Anthropic key missing or invalid");
      return reply(500, { error: "The photo reader isn't set up yet." }, origin);
    } else if (error instanceof Anthropic.RateLimitError) {
      return reply(429, { error: "Lots of photos right now. Try again in a minute." }, origin);
    } else if (error instanceof Anthropic.APIError) {
      console.error(`Anthropic API error ${error.status}: ${error.message}`);
      return reply(502, { error: "Couldn't read the board. Type the soup in instead." }, origin);
    }
    console.error(error);
    return reply(500, { error: "Something went wrong reading the photo." }, origin);
  }
});
