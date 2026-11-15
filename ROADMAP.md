# Local Bowl roadmap

The test for every idea: **does it keep the app simple and joyful?** Open it, tap the square,
type the soup (or the band), done. Information only. Nothing to argue about.

## Now (this week)
- [ ] Buy **localbowl.com** at Porkbun and point it at the app.
- [ ] New QR codes and signs with the clean address (localbowl.com/gorge), address printed under the code.

## Next: before handing out QR codes widely
**Keep it kind (stop vandalism without adding comments)**
- Soup names and restaurant names pass a blocked-words check in the database, so "their soup sucks" can't post.
- New restaurants come only from real map places; ones typed in by hand wait for approval.
- A quiet "Not a soup?" flag: two flags hide a post until it's checked.
- Once a restaurant posts, its soup is locked for the day (customers can still tap ✓).

**For restaurants: simple sign-in, no passwords**
- A small "Own a restaurant?" link (not a new tab).
- Sign in once with a code sent to your phone or email; stay signed in for weeks.
- Verified once (a code to the restaurant's public phone number, or a quick call), then your
  posts show "Posted by the restaurant" for real.
- Daily reminder by text or email: reply with the soup and it posts.
- Customers never need an account.
- Owner list is private: you (Joe) add a restaurant's email or phone after they say yes. Only you can see it.
- Until automatic reminders are set up, send the morning "what's the soup?" text by hand to pilot restaurants.

**Sponsors**
- Season sponsor line at the top ("Spring on Gorge Bowl is brought to you by ___"), $250 a season. See PITCH.md.

## Later
- **"I want chicken noodle"**: type a soup and see who has it today. If nobody does, gently show what's close ("No chicken noodle today, but here's what's warm right now: tomato bisque, chicken tortilla..."). Results are never paid for.
- **Tonight tab**: music, theater, markets. Anyone posts; the venue's post wins; events disappear after they happen.
- **Seasonal joy**: small seasonal touches beyond color, such as a local wildflower or snowflake drawing that fits each region.
- **More towns**: a community column in the database, one address per town (localbowl.com/teton), each town sees only its own.
- **Sponsors**: turn on the bottom banner when the first business says yes (see SPONSORS.md).

## Not doing, ever
- Ratings, reviews, comments, or stars.
- Paying for a better spot in the list.
- Needing Facebook or Instagram for anything.

## Hosting and security (current setup is fine)
- **GitHub Pages** serves the app: free, fast, secure (https).
- **Supabase** holds restaurants and soups: free tier, public can only read; every write goes
  through guarded functions.
- **Porkbun** holds the domain names.
- Very little data and nothing private, so the real risk is vandalism, not privacy. That's what "Keep it kind" above is for.
