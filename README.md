# Gorge Bowl

> Some days you just want a good cup of soup. Some days you just need to dance. Here's the place to find out where.
>
> Why this exists and the rules it keeps: [MISSION.md](MISSION.md) · What's next: [ROADMAP.md](ROADMAP.md) · Pitch sheet: [PITCH.md](PITCH.md)

Soups around the Gorge: today's soup at lunch spots from Hood River to The Dalles.

Open `index.html` in a browser, or visit the GitHub Pages link once Pages is turned on.

Shared database: see [`supabase/SETUP.md`](supabase/SETUP.md). Once it's connected, everyone sees the same restaurants and soups. Until then, the app saves on each device only.

What works now:
- **Soup today**: each restaurant's soup and any special, with a Map link, a tag for restaurant vs. customer posts, and a one-tap ✓ to confirm. Customers can fix a customer-posted soup; a restaurant's own post can't be changed by customers. No comments or reviews.
- **Add a restaurant**: search places around the Gorge (free OpenStreetMap search) and tap the right one; it links to Google Maps. If a place isn't found, add it by name and town.
- **Use my location**: picks the restaurant you're standing in from your phone's location.
- **How to tab**: home screen steps for iPhone and Android, how to post and check a soup, and the house rules.
- **Seasonal colors**: fall, winter, spring and summer palettes follow the calendar and blend into the next season over the last three weeks of each.

Not yet:
- The daily text/email reminder is shown but not working yet.
- The events/music tab is parked for later.

## Local Bowl: more communities

Gorge Bowl is the first community of **Local Bowl**. Everything specific to the Gorge
(name, tagline, towns, map area for place search, time zone) lives in the `COMMUNITY`
block at the top of the script in `index.html`. Changing that block is all it takes to
make, say, **North Coast Bowl** or **Teton Valley Bowl**.

Still to do before a second community launches:
- **One database for all communities:** add a `community` column to restaurants so each
  community only sees its own, and let "today" follow each community's time zone
  (the database currently uses Pacific time; Teton Valley is on Mountain time).
- **One address per community**, e.g. `localbowl.app/gorge`, with its own QR code and home screen name.

## How the soup list is ordered (the rule)

Fair and simple, and the same for everyone:
1. Restaurants that posted a soup today come first, in a **random order that reshuffles every day**.
   Nobody picks it: the order comes from the date itself, so it's the same for everyone all day
   and different tomorrow.
2. Restaurants with no soup yet come after, **alphabetically**.

No restaurant can pay for a better spot.

## For developers

**What it is:** one static page (`index.html`: HTML, CSS and plain JavaScript, no build step, no framework)
served by GitHub Pages, with a Supabase (Postgres) database behind it.

**Files**
| Path | What it is |
| --- | --- |
| `index.html` | The whole app. The `COMMUNITY` block at the top of the script holds the town-specific settings and sponsors. |
| `supabase/setup.sql` | Database tables, the `todays_soups` view, read-only access rules, and the three write functions (`add_restaurant`, `post_soup`, `check_soup`). Safe to re-run. |
| `supabase/functions/read-soup-board/` | Optional photo reader (Claude vision). Built but switched off; not deployed. |
| `manifest.webmanifest`, `icons/` | Home screen app setup and icons. |
| `qr/`, `sponsors/` | QR codes, printable sign, sponsor banner template. |
| `MISSION.md`, `ROADMAP.md`, `PITCH.md`, `SPONSORS.md` | Why it exists, what's next, the pitch, sponsor specs. |

**How data flows:** the page calls Supabase's REST API with the public publishable key. The public can only
read; every write goes through a `security definer` function that enforces the rules (length limits, no
duplicate restaurants, a customer can't overwrite the restaurant's post, a check moves by 1). "Today" is
Pacific time. Place search uses Photon (OpenStreetMap), with no key needed.

**Run it locally:** `python3 -m http.server 8000` in this folder, then open http://localhost:8000.
It talks to the live database, so test posts are real (delete them in Supabase's Table Editor).
To work offline, blank out `DB_URL`/`DB_KEY` and the app saves to the browser only.

**Ship a change:** commit and push to `main`; GitHub Pages updates in a minute or two.
Database changes: edit `supabase/setup.sql` and run it in Supabase's SQL Editor.

**Ground rules** (see MISSION.md): no ratings, reviews or comments; nobody pays for position; keep it simple.
Next up is in ROADMAP.md (vandalism guards, restaurant sign-in, multi-town).
