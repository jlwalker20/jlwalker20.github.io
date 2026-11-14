# walkerwagoner.com/gaming

Tabletop companion apps plus the shared Firefight campaign tracker.

```
gaming/
  index.html            hub page linking every app
  malediction/          Malediction companion            (works offline)
  oak-and-iron/         Oak & Iron companion             (works offline)
  oak-and-iron-solo/    Oak & Iron solo                  (works offline)
  firefight/            Firefight companion, v3.5 rules  (works offline)
  firefight-solo/       Firefight solo, co-op, horde     (works offline)
  campaign/             Firefight campaigns              (online, shared through Supabase)
  config.js             Supabase URL and anon key for the campaign app
  supabase/schema.sql   database setup for campaigns, run once
  sw.js, manifest.webmanifest, icons/, vendor/   offline support, install icon, Supabase library
```

## 1. Put the folder on the site

GitHub Pages serves the site, so pick whichever matches how walkerwagoner.com is set up:

- **The domain points at one site repo** (the repo whose Pages settings show `walkerwagoner.com`):
  copy this whole `gaming` folder into the root of that repo, commit and push.
  It appears at `https://walkerwagoner.com/gaming/`.
- **Separate repos per app** (like `plant-collection`): make a new repo named exactly `gaming`,
  put the *contents* of this folder at its root, push, then in the repo go to
  Settings -> Pages -> Build and deployment -> Deploy from a branch -> `main` / `(root)`.
  Because your account's Pages domain is walkerwagoner.com, a repo named `gaming`
  shows up at `https://walkerwagoner.com/gaming/`.

Every link inside is relative, so the folder works at any address.

## 2. Set up the campaign database (once)

You can use the same Supabase project as the plant app. These tables all start with `gaming_`
and don't touch anything else.

1. Supabase dashboard -> SQL Editor -> New query. Paste all of `supabase/schema.sql` and press Run.
2. Project Settings -> API. Copy the **Project URL** and the **anon public** key into `config.js`:

   ```js
   window.GAMING_CONFIG = {
     supabaseUrl: "https://xxxxxxxx.supabase.co",
     supabaseAnonKey: "eyJhbGciOi..."
   };
   ```
3. Commit and push `config.js`.

The anon key is designed to be public. Visitors can only read campaigns; every change runs through
database functions that check the campaign's password, and the passwords are stored only as bcrypt
hashes in a table nobody can read. Up to 20 new campaigns can be created per hour, site-wide.

## How campaigns work

- `walkerwagoner.com/gaming/campaign/` lists every campaign and has the form to start a new one:
  a name, a page address and a password.
- Each campaign lives at its own address, e.g. `.../campaign/?c=ashfall-front`.
  Anyone with the link can follow it, live.
- **Unlock to edit** asks for the password once per device and remembers it there. **Lock** forgets it.
- The campaign settings can change the password or delete the campaign (password needed).
- Passwords can't be recovered. If everyone forgets one, reset it in the Supabase SQL Editor:
  `update gaming_secrets set pass_hash = extensions.crypt('new-password', extensions.gen_salt('bf', 10)) where slug = 'ashfall-front';`

## Offline and installing

The first visit to the hub caches every app. After that the companions open with no connection, and
each device keeps its own saved games. On Android, Chrome offers "Install" (or use the button on the hub);
on iPhone, use Share -> Add to Home Screen.

Updates: push changed files as usual. Devices load the cached copy straight away and pick up the new
version in the background, so changes show on the *second* visit. To force everyone onto a new version
at once, change `CACHE = "gaming-v1"` in `sw.js` to `"gaming-v2"` (and so on).

## Differences from the claude.ai versions

- Oak & Iron Solo and Firefight Solo can't call Claude from a normal website, so the photo-reading AI
  is unavailable here: Oak & Iron Solo's enemy follows its standing orders, and Firefight Solo uses OPR's
  decision tree. The claude.ai copies keep the photo option.
- Campaigns are stored in your Supabase project instead of claude.ai, so campaigns made in the
  claude.ai copy don't carry over.
