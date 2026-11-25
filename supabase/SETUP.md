# Turning on the shared soup database

Gorge Bowl uses **Supabase** (free plan) so everyone sees the same restaurants and soups.
Until it's set up, the app still works but saves only on each device.

## 1. Create the project (about 5 minutes)
1. Go to **supabase.com** and sign up (GitHub sign-in is easiest).
2. Click **New project**.
   - Name: `gorge-bowl`
   - Database password: click **Generate**, then save it somewhere safe (the app doesn't need it).
   - Region: **West US (Oregon)**
3. Wait a minute or two while it sets up.

## 2. Create the tables
1. In the left sidebar, open **SQL Editor** → **New query**.
2. Paste in everything from [`setup.sql`](setup.sql) and click **Run**. "Success. No rows returned" means it worked.

## 3. Connect the app
1. Open **Project Settings** → **API Keys** (on older projects: **Project Settings** → **API**).
2. Copy the **Project URL** (looks like `https://abcd1234.supabase.co`).
3. Copy the **publishable** key (starts with `sb_publishable_`) or, on older projects, the **anon public** key (starts with `eyJ`).
   - These two are meant to be public: they're built into every visitor's browser. The database rules in `setup.sql` decide what the public can do.
   - **Never** share the `service_role` / secret key.
4. In `index.html`, fill them in near the top of the script:
   ```js
   const DB_URL = "https://abcd1234.supabase.co";
   const DB_KEY = "sb_publishable_...";
   ```
5. Commit. GitHub Pages updates in a minute or two.

## What the public can and can't do
- **Can:** see restaurants and today's soups; add a restaurant; post a soup; tap ✓.
- **Can't:** edit or delete anything directly; post a soup longer than 40 characters; overwrite a soup the restaurant posted that day; add a duplicate restaurant.
- Soups are kept by day (Pacific time); the app shows only today's.

## Housekeeping
- To remove a restaurant or a bad post: Supabase → **Table Editor** → `restaurants` or `soups` → select the row → delete. Deleting a restaurant also deletes its soups.
- Free projects pause after a week with no visits. If that happens, open the project in Supabase and click **Restore**.

# Turning on the photo reader (snap the soup board)

**Currently off, and the photo button is removed from the app.** The function code is kept here; after the steps below, the photo button needs to be added back to the app.

When someone snaps a photo of the soup board, the app sends it to a small function in your
Supabase project. That function asks Claude (Anthropic's AI) to read the board and fills in the
soup for them. Until this is set up, the app still works: people just type the soup.

## 1. Get an Anthropic API key
1. Go to **platform.claude.com** and sign up.
2. Add a little prepaid credit under **Billing** (start with $5).
3. Under **Settings → Limits**, set a **monthly spend limit** (for example $20) so costs can never surprise you.
4. Open **API Keys** → **Create Key**, name it `gorge-bowl`, and copy it (starts with `sk-ant-`).
   Keep it private: it goes only into Supabase, never into the app or GitHub.

## 2. Add the key to Supabase
1. In Supabase, open **Edge Functions** → **Secrets** (sometimes under **Project Settings → Edge Functions**).
2. Add a secret named `ANTHROPIC_API_KEY` with the key as its value. Save.

## 3. Create the function
1. In Supabase, open **Edge Functions** → **Deploy a new function** → **Via Editor**.
2. Name it exactly `read-soup-board`.
3. Replace the sample code with everything in [`functions/read-soup-board/index.ts`](functions/read-soup-board/index.ts) and click **Deploy**.
4. Open the function's **Details** (or settings) and turn **off** "Verify JWT" / "Enforce JWT verification".
   The app's public key isn't the kind that check expects. The function protects itself instead:
   it only answers the Gorge Bowl site, rejects oversized photos, and your spend limit caps costs.

## 4. Try it
Open the app on your phone, tap **Post a soup** → **Snap the soup board**, and take a photo of a board.
In a few seconds the soup should fill in with "Read from the board. Check it, then tap Post."

## Cost
Each photo costs roughly 1 to 2 cents. 50 photos a day is about $15 to $30 a month.

# Restaurant links (verified restaurants)

Each restaurant gets a private link from you. Opening it on their phone makes that phone post as the
restaurant ("Posted by the restaurant", and customers can't overwrite it). Customers just use the app.

## One-time setup
In Supabase: **SQL Editor → New query**, paste everything in [`restaurant-links.sql`](restaurant-links.sql), click **Run**.

## Make a restaurant's link
1. Make sure the restaurant is in the app (add it like anyone would).
2. In Supabase: **SQL Editor → New query**, type this with the restaurant's exact name, and click **Run**:
   ```sql
   select make_restaurant_link('pFriem Family Brewers');
   ```
3. Copy the link it shows and text it to the restaurant. Ask them to open it on the phone they'll post from
   and tap **Remind me every morning**.
4. Lost phone, or staff change? Run the same line again. The old link stops working.

The link is like a key: send it only to the restaurant.

# Multi-day soups

Restaurants posting with their private link can say a soup runs for up to a week ("Same soup for:
3 days"), so they don't have to post every day. Customers always post for today only.

**One-time setup** (after the restaurant links step): in Supabase, **SQL Editor → New query**, paste everything
in [`multi-day-soups.sql`](multi-day-soups.sql), click **Run**.

# New address: soupsandtunes.com

So new restaurant links use **soupsandtunes.com/gorge**: in Supabase, **SQL Editor → New query**, paste
everything in [`new-address.sql`](new-address.sql), click **Run**. Links already sent keep working.

**Setup order for a fresh project:** `setup.sql` → `restaurant-links.sql` → `multi-day-soups.sql` → `new-address.sql`.
Each runs once; running `restaurant-links.sql` again later stops safely without changing anything.

# Multi-day soups for everyone

Lets anyone pick "Same soup for: 2–5 days" when posting, so the soup doesn't reset tonight.
In Supabase: **SQL Editor → New query**, paste everything in [`multi-day-for-everyone.sql`](multi-day-for-everyone.sql), click **Run**.
Until it's run, multi-day picks quietly post for today only.
