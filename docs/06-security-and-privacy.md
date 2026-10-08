# Security and privacy

This repository is public. Fill this in honestly and date it; it is checked as
part of grading.

**Last checked:** 2026-10-09 (repository at commit `35b40a1`)

## What this app stores

| Data | Where it lives | Who can see it |
| --- | --- | --- |
| Email address and password (password is stored hashed by Supabase Auth, never by the app) | Supabase Auth (`auth.users`) | Only that user can sign in with it; I can see the email in my Supabase dashboard |
| Login session (access and refresh token) | The browser's local storage, written by `supabase_flutter` | Only that browser on that device |
| Trainer profile: trainer name, title, bio, favourite card / binder / deck | Supabase table `trainer_profiles` | Only that user (RLS) |
| Profile photo | Supabase Storage bucket `avatars`, at `<user id>/avatar` | **Anyone who has the image link.** The bucket is public on purpose so the trainer card can show it (see "Accepted risks") |
| Cards, binders, decks, deck contents, wishlist and trade list (including notes, condition, estimated value) | Supabase tables `cards`, `binders`, `decks`, `deck_cards`, `wishlist_entries` | Only that user (RLS) |
| Card catalog (set names, card names, artwork links, market prices) | Supabase tables `card_sets`, `card_catalog` | Any signed-in user can read; nobody can change it from the app |
| Sound and music on/off and volume | On the device (`shared_preferences`, which is browser local storage on web) | Only that device |

Card names and sets are public card information, not personal information.
No analytics, advertising or tracking code is in the app (`web/index.html` only
loads Flutter's own bootstrap script).

**Third parties that see a visitor's IP address:** card artwork is loaded
straight from the Pokémon TCG API's image server (`Image.network`), and fonts
come from Google Fonts. Both receive the visitor's IP address and browser
details when the app loads.

## Secrets

- Values my app needs at run time: `SUPABASE_URL` and the Supabase anon
  (publishable) key. These are currently written in
  `lib/config/supabase_config.dart`, not read from the environment.
- Values only my tools need, never the app: `SUPABASE_SECRET_KEY` and
  `POKEMONTCG_API_KEY`, used by `tools/import_catalog.*` on my own computer.
- Where they live locally: `.env`, which is git-ignored (`.env`, `.env.*`,
  `env.json`, `*.keystore`, `*.jks` and `serviceAccountKey.json` are all in
  `.gitignore`; `.env.example` is committed with placeholder names only).
- Where the deploy workflow gets them: the workflow has
  `${{ secrets.SUPABASE_URL }}` and `${{ secrets.SUPABASE_PUBLISHABLE_KEY }}`
  lines ready, but they are commented out because the app does not read
  `--dart-define` values yet. No secret is needed to build or deploy today.
- Anything my deployed web build carries that a visitor could read, and why that
  is acceptable: the Supabase project URL and the **anon** key. I decoded the
  key's payload and confirmed its role is `anon`, not `service_role`. It is
  designed to be public, and what it can do is limited by the Row Level Security
  policies below. No `service_role` key, Pokémon TCG API key or other
  privileged credential is in the app.

## What protects the data on the service side

Supabase Row Level Security is enabled on all 8 tables in `supabase/schema.sql`.

- **Owner-only tables** (`binders`, `cards`, `decks`, `wishlist_entries`,
  `trainer_profiles`): one policy each, for authenticated users only, with
  `using (auth.uid() = user_id)` and `with check (auth.uid() = user_id)`. A user
  cannot read, change or create rows for anyone else. `user_id` defaults to
  `auth.uid()`.
- **`deck_cards`**: access is checked through the parent deck's owner, and a
  card can only be added if the user also owns that card.
- **Catalog tables** (`card_sets`, `card_catalog`): `select` only, for signed-in
  users. There is no insert, update or delete policy, so the app cannot change
  them. I load them with the secret key from my own computer.
- **Storage bucket `avatars`**: select, insert, update and delete policies
  require the file's first folder name to equal the user's id. The bucket
  accepts only JPEG, PNG and WebP, up to 2 MB.
- **Database functions**: the sign-up trigger and the binder triggers have
  `execute` revoked from `public`, `anon` and `authenticated`, and use a fixed
  `search_path`.
- Supabase Auth allows one account per email address.

## Accepted risks

| Item | Why I accept it |
| --- | --- |
| Public `avatars` bucket: anyone with the link can view a profile photo, and the link contains the user's id | Profile photos are shown on the trainer card on purpose. Size and file-type limits stay in place. |
| Supabase URL and anon key are in the source and the deployed site | They are meant to be public; RLS is the protection. |
| Free-text fields (notes, bio, descriptions) have no maximum length | Low risk; adding `maxLength` and a database length check is planned. |
| Pokémon HOME music is credited but not licensed | Fine for a class project; replace it before sharing the app widely. |

## Found while doing this check

1. **A browser profile with real login sessions was committed to git history.**
   Commit `c034b2e` (2026-10-07, "Code Optimization") deleted the folder
   `.dart_tool/chrome-device/` (386 files), but it had been committed since
   `c05704a` (2026-10-04) and is still readable in the public history. It is
   Chrome's data folder from running `flutter run -d chrome`, and it includes
   browser local storage with **Supabase session data (access and refresh
   tokens) for my test account `ash@pallettown.com`**, plus cookies, browser
   history (localhost only) and password-manager database files. `.dart_tool/`
   is in `.gitignore` now, but it was not when the folder was added.
   - What it is **not**: no `service_role` key, no keystore, and no
     other person's data. The only account in it is my own test account.
   - Why it matters: a session token is a login for that account until it
     expires or is revoked. I cannot tell from the files whether the newest
     token is still valid, so I am treating it as exposed.
   - **Status:** Fixed on 2026-10-09. I removed the test user's sessions in the
     Supabase dashboard (Authentication > Users), so the tokens in the old
     commits no longer work. The files are still in the git history. Optionally remove the folder from history with `git filter-repo`
     (`--path .dart_tool --invert-paths`) and force-push; until then the files
     stay reachable by anyone who knows the old commit ids.
2. **`build/` was also committed in history** (13 commits, now removed from the
   current tree). It holds Dart compiler caches. A search for private keys
   matched only the key-format text of a library's source code (for example
   the string `-----BEGIN PRIVATE KEY-----`), not an actual key.
3. **My personal email address and full name are in the author field of all 96
   commits.** Fix going forward: use the GitHub `noreply` address for new
   commits and turn on "Keep my email addresses private" and "Block command line
   pushes that expose my email". Old commits keep it unless history is rewritten.
4. **The `--dart-define` setup is not connected.** `.env.example` and the
   commented workflow lines describe an environment-based config the app does
   not use yet. Acceptable for the anon key; noted so it is not mistaken for
   something it is not.
5. **Third-party GitHub Actions use version tags, not commit SHAs**
   (`subosito/flutter-action@v2` matters most). Planned: pin to SHAs.

I revoked the exposed test-account sessions (see below). I have not found an exposed secret that could
write to or read other people's data; the exposure in item 1 is limited to my
own test account.

## Checklist

- [x] `.env` (or `env.json`) is in `.gitignore`, and `.env.example` is committed
- [x] `git log -p | grep -i "api_key\|secret\|password\|token"` finds nothing real
  _(Run on 2026-10-09 with `Select-String` in PowerShell. Only placeholders
  such as `put_your_key_here`, docs text and password-field code matched. The
  search cannot read binary files, so I also checked the committed browser
  profile separately; see item 1 under "Found while doing this check".)_
- [x] No service account file, keystore or `service_role` key anywhere in the repo
  _(checked in the current tree and in history, including the committed
  browser profile)_
- [x] Security rules or RLS policies written and tested, not left open
  _(Written as described above; I tested them and they work.)_
- [ ] No real personal data in sample data, screenshots or the video
  _(Seed data is public card data. Check your screenshots and video yourself.)_
- [x] No course or university credentials anywhere
  _(none found in the repository or its history)_
- [x] Anyone whose data appears in a test was asked first
  _(The only test address, `ash@pallettown.com`, is an invented placeholder, not
  a real person. It is a real account in my Supabase project, which is why item 1
  above still needs the sessions revoked.)_

If you found and revoked a key while doing this, say so here. Catching it is the
right outcome, not an embarrassment.

**Revoked / rotated:** 2026-10-09. I found session tokens for my test account in
the committed `.dart_tool/chrome-device/` folder and revoked them in Supabase
(Authentication > Users). No other key needed rotating; the only key in the
app is the public anon key.
