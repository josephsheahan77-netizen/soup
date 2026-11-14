# Gorge Bowl

Soups around the Gorge: today's soup at lunch spots from Hood River to The Dalles.

Open `index.html` in a browser, or visit the GitHub Pages link once Pages is turned on.

Shared database: see [`supabase/SETUP.md`](supabase/SETUP.md). Once it's connected, everyone sees the same restaurants and soups. Until then, the app saves on each device only.

What works now:
- **Soup today**: each restaurant's soup and any special, with a Map link, a tag for restaurant vs. customer posts, and a one-tap ✓ to confirm. Customers can fix a customer-posted soup; a restaurant's own post can't be changed by customers. No comments or reviews.
- **Add a restaurant**: search places around the Gorge (free OpenStreetMap search) and tap the right one; it links to Google Maps. If a place isn't found, add it by name and town.
- **Snap the soup board**: the app finds which restaurant you're at from your phone's location and reads the soup off the photo (reading the board is built but switched off for now; see [`supabase/SETUP.md`](supabase/SETUP.md)).
- **Seasonal colors**: fall, winter, spring and summer palettes switch by date.

Not yet:
- The daily text/email reminder is shown but not working yet.
- The events/music tab is parked for later.
