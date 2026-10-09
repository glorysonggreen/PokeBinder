# Security and privacy

This repository is public. This document records what the app stores, how it is
protected, and what I found while checking. The step-by-step checklist with
evidence is in [07-security-checklist.md](07-security-checklist.md).

**Last checked:** October 9, 2026. The counts below (commits, files) were
re-verified against commit `8ff03e9`. The input-length limits described below were added after that commit.

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
- **Length limits**: every free-text column has a `check (char_length(col) <= N)` constraint, and the number columns typed into the app have an upper bound (see [Input limits](#input-limits)).
- **Database functions**: the sign-up trigger and the binder triggers have
  `execute` revoked from `public`, `anon` and `authenticated`, and use a fixed
  `search_path`.
- Supabase Auth allows one account per email address.

## Input limits

Every text box in the app has a maximum length, set in `lib/config/field_limits.dart`. The database repeats the same limits as check constraints at the end of `supabase/schema.sql` (named `<table>_<column>_length_check` and `<table>_<column>_max_check`), so a limit still applies if someone skips the app and calls the Supabase API directly.

| Field | Limit | Where |
| --- | --- | --- |
| Email | 254 characters | Log In, Sign Up, Forgot Password |
| Password and confirmation | 72 characters (the Supabase Auth maximum) | Log In, Sign Up, Choose a New Password |
| Trainer name | 30 characters | Sign Up, Edit Trainer Card |
| Bio | 160 characters, with a counter | Edit Trainer Card |
| Binder name | 40 characters | Create and Edit Binder |
| Binder category | 30 characters | Create and Edit Binder |
| Binder and deck description | 300 characters, with a counter | Create and Edit Binder, Create Deck |
| Deck name | 40 characters | Create Deck |
| Card name, set | 80 characters each | Edit Trade Entry |
| Card number | 20 characters | Edit Trade Entry |
| Notes | 500 characters, with a counter | Edit Card, Add to Collection, Edit Wishlist Card, Edit Trade Entry |
| Looking for in return | 200 characters, with a counter | Edit Trade Entry |
| Search boxes | 80 characters | Every search bar and the set filter in the catalog picker |
| Quantity | 4 digits (9,999) | Edit Trade Entry |
| Page and starting pages | 3 digits (999) | Edit Card, Add to Collection, Create and Edit Binder |
| Estimated value | 9 digits and up to 2 decimals | Edit Card, Add to Collection, Edit Wishlist Card, Edit Trade Entry |

The constraints are added `NOT VALID`: new and edited rows are checked, existing rows are not scanned, so the script can be re-run on a database that already has longer text. A row that is already over a limit has to be shortened the next time it is edited. To check old rows too, run `alter table public.<table> validate constraint <name>;`. The password limit is 72 because Supabase Auth rejects longer passwords. Quantity and value columns have a database bound that is a little looser than the typed digits (for example 99,999 copies against 9,999 typed) because copies can also be added with the **Add** button.

## Accepted risks

| Item | Why I accept it |
| --- | --- |
| Public `avatars` bucket: anyone with the link can view a profile photo, and the link contains the user's id | Profile photos are shown on the trainer card on purpose. Size and file-type limits stay in place. |
| Supabase URL and anon key are in the source and the deployed site | They are meant to be public; RLS is the protection. |
| Pokémon HOME music is credited but not licensed | Fine for a class project; replace it before sharing the app widely. |

## Found while doing this check

1. **A browser profile with real login sessions was committed to git history.**
   Commit `c034b2e` (2026-10-07, "Code Optimization") deleted the folder
   `.dart_tool/chrome-device/` (361 files), but it had been committed since
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
3. **My personal email address and full name are in the author field of all 118
   commits.** Fix going forward: use the GitHub `noreply` address for new
   commits and turn on "Keep my email addresses private" and "Block command line
   pushes that expose my email". Old commits keep it unless history is rewritten.
4. **The `--dart-define` setup is not connected.** `.env.example` and the
   commented workflow lines describe an environment-based config the app does
   not use yet. Acceptable for the anon key; noted so it is not mistaken for
   something it is not.
5. **Third-party GitHub Actions use version tags, not commit SHAs**
   (`subosito/flutter-action@v2` matters most). Planned: pin to SHAs.
6. **Free-text fields had no maximum length.** Fixed on 2026-10-09: see
   [Input limits](#input-limits).

I revoked the exposed test-account sessions (item 1 above and the note at the end). I have not found an exposed secret that could
write to or read other people's data; the exposure in item 1 is limited to my
own test account.

## Checklist

- [x] `.env` (or `env.json`) is in `.gitignore`, and `.env.example` is committed
- [x] `git log -p | grep -i "api_key\|secret\|password\|token"` finds nothing real
- [x] No service account file, keystore or `service_role` key anywhere in the repo
- [x] Security rules or RLS policies written and tested, not left open
- [ ] No real personal data in sample data, screenshots or the video
- [x] No course or university credentials anywhere
- [x] Anyone whose data appears in a test was asked first

**Revoked / rotated:** 2026-10-09. I found session tokens for my test account in
the committed `.dart_tool/chrome-device/` folder and revoked them in Supabase
(Authentication > Users). No other key needed rotating; the only key in the
app is the public anon key.
