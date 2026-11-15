# Sponsor a Local Bowl

Be the name people see while they decide where lunch is today.

## What you get
- Your banner in the small **Local sponsor** strip at the bottom of the app, for a month.
- Tapping it opens your website, menu, or map.
- Up to **5 sponsors per town** share the strip. The order is random and switches every
  20 seconds, so every sponsor gets a fair share. Nobody is first.

## What it doesn't do
- It doesn't move your soup up the list. The soup list is the same fair daily shuffle for everyone,
  sponsor or not.
- No pop-ups, no sound, no animation, no tracking of the people who see it.

## Your banner: here's your space, have fun with it
| | |
|---|---|
| **Size** | **640 × 100 pixels** (shows at 320 × 50 on phones). It's the standard phone banner size, so Canva and any designer have a template for it. |
| **Safe area** | Keep logo and words at least 16 px from the left and right edges and 8 px from the top and bottom. See `sponsors/template-640x100.png`. |
| **File** | PNG or JPG, under 200 KB. |
| **Words** | Short and big. Your name plus a few words reads best ("Fresh pretzels till 3" beats a paragraph). |
| **Link** | Your website, menu, or Google Maps page. |
| **Keep it local and friendly** | No politics, nothing mean about other businesses, nothing a kid shouldn't see. |

Bring something fun. A drawing, a pun, your dog, this week's special. It's your square
(well, rectangle) of the town.

## Price
*(Starting point to try in Hood River; adjust once we see what works.)*
- **$50 a month** per sponsor, up to 5 sponsors per town.
- Founding sponsors in a new town get their first month free.

## To add a sponsor (for whoever runs the town's bowl)
1. Save their banner in the `sponsors/` folder, e.g. `sponsors/everybodys.png`.
2. In `index.html`, add them to `sponsors` in the `COMMUNITY` block:
   ```js
   sponsors: [
     {name: "Everybody's Brewing", image: "sponsors/everybodys.png", link: "https://..."}
   ]
   ```
3. Commit. At the end of the month, remove or renew.
