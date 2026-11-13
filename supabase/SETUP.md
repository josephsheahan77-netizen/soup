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
