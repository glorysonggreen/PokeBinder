# Supabase setup

PokeBinder stores accounts and collection data in Supabase (Auth + Postgres).
This is the one-time setup for a project.

## 1. Create the tables

1. Open your project in the Supabase dashboard > **SQL Editor** > **New query**.
2. Paste the whole of [`supabase/schema.sql`](supabase/schema.sql) and run it.

The script is safe to run again whenever it changes: it only creates what is
missing and replaces the policies and the sign-up trigger. It never drops
tables or data.

It also creates the public `avatars` storage bucket (with its access rules)
used for trainer card profile pictures. If you set up your project before
profile pictures existed, run the script again to add it.

## 2. Load the card catalog

The **Add** tab lets people pick a card from a shared card database instead of
typing it in, so the name, set, number, rarity, artwork and price are correct.
`schema.sql` creates the (empty) `card_sets` and `card_catalog` tables; this
step fills them.

1. On your computer, with Node 18 or newer, from the project folder:

   ```
   node tools/import_catalog.mjs --sets base1,base2
   ```

   Use the sets you want people to choose from (`base1` is Base Set and `base2` is Jungle; all ids are listed at
   <https://api.pokemontcg.io/v2/sets>). The data comes from the Pokémon TCG
   API; artwork is loaded from its image server and prices are TCGplayer market
   prices in US dollars. If the API is slow or rate-limited, set
   `POKEMONTCG_API_KEY` first (a free key from <https://dev.pokemontcg.io>).
2. Open the generated `supabase/seed_catalog.sql`, paste it into the SQL Editor
   and run it. Run the script and the file again whenever you want fresh prices
   or more sets; it updates rows in place.

   The `supabase/seed_catalog.sql` committed in this repository (Base Set and
   Jungle, prices from Oct 4, 2026) was made by an earlier version of the
   importer and has no per-finish prices. Regenerate it with the command above
   to get them; without them the **Finish** chooser (Holofoil, Reverse Holo and
   so on) on the card form is not shown.

### Loading every card in the API

The API holds about 20,000 cards across 170+ sets. Re-run `supabase/schema.sql`
first (it adds a search index for a catalog that size), then pick one:

- **Upload directly (easiest).** Use the project URL and the **secret /
  service_role** key from Project Settings > API. They stay in your terminal
  only; never put them in the app or commit them.

  ```
  SUPABASE_URL=https://yourproject.supabase.co \
  SUPABASE_SECRET_KEY=... \
  POKEMONTCG_API_KEY=... \
  node tools/import_catalog.mjs --all --push
  ```

  If it stops (rate limit, network), run it again with `--resume`.

  **No Node?** Use the Dart version instead (it comes with Flutter), with the
  same options: `dart run tools/import_catalog.dart --all --push`. In Windows
  PowerShell, set the variables first:

  ```
  $env:SUPABASE_URL="https://yourproject.supabase.co"
  $env:SUPABASE_SECRET_KEY="..."
  $env:POKEMONTCG_API_KEY="..."
  dart run tools/import_catalog.dart --all --push
  ```
- **Paste SQL.** `dart run tools/import_catalog.dart --all --split supabase/seed`
  (or the `node tools/import_catalog.mjs` equivalent)
  writes `seed_001.sql`, `seed_002.sql`, ... of about 1 MB each. Run them in
  the SQL Editor in numeric order.

The full download takes a while without an API key; a free key from
<https://dev.pokemontcg.io> makes it much faster.

People can read the catalog but never change it. Prices are converted to pesos
with the fixed rate in `lib/config/pricing.dart` — update it from time to time.

## 3. Point the app at your project

`lib/config/supabase_config.dart` holds the project URL and the **anon /
publishable** key (Project Settings > API). That key is meant to be public;
your data is protected by the Row Level Security policies in `schema.sql`.

Never put the `service_role` / secret key in this app.

## 4. Authentication settings

Dashboard > **Authentication**:

- **Sign In / Providers > Email**: decide whether **Confirm email** is on. Either way, Supabase Auth allows only one account per email address (case-insensitive), and the app shows an "account already exists" message on a repeat sign-up.
  - On (recommended): sign-up shows "check your email", and the trainer profile
    is created by the database trigger in `schema.sql`.
  - Off: the person is signed in straight after sign-up.
- **URL Configuration**:
  - **Site URL**: your deployed app, e.g. `https://<username>.github.io/PokeBinder/`
  - **Redirect URLs**: add that same URL, plus `http://localhost:8080/` (or the
    port you run `flutter run` on) for local testing.

  The confirmation and password-reset emails link back to the app using these.
  If they are missing, the links go to `localhost` or are rejected.

## 5. Password reset

"Forgot Password" emails a link. Opening it signs the person in with a
temporary recovery session and PokeBinder shows the **Choose a New Password**
screen.

For it to work:

- **Redirect URLs** (section 4) must include the exact address the app is
  served from, including the trailing slash. If it is missing, the link goes
  to the Site URL instead and the reset screen never appears.
- Open the link in the **same browser** that requested it (Supabase uses PKCE,
  which stores a one-time key in that browser).
- Supabase limits reset emails to about one per minute per address. The app
  shows a countdown on the **Resend Link** button.
- The built-in Supabase mailer is rate limited and meant for testing. For real
  users, set up custom SMTP under Authentication > Emails > SMTP Settings.
- Passwords need at least 6 characters (Authentication > Sign In / Providers >
  Email), matching the minimum the app enforces.

## Limits worth knowing

- Supabase returns at most 1,000 rows per request; the app reads in pages so
  larger collections load completely.
- Writes are sent one at a time, in order. If one fails (offline, a rule
  rejects it) a message appears and the change stays on screen but is **not**
  saved on the server. There is no offline queue or automatic retry yet.

## Re-running schema.sql

`supabase/schema.sql` is safe to run again. The last section removes orphaned trade-list rows, adds foreign keys so deleting a card also deletes its trade entries, and adds triggers that keep cards in sync when a binder is renamed or deleted. It also ends with the **Length limits** section, which adds a check constraint for the maximum length of every free-text column (and an upper bound on quantities, page numbers and values) to match the limits in `lib/config/field_limits.dart`. The constraints are added `NOT VALID`, so existing rows are not scanned: new and edited rows are checked, and a row that is already too long must be shortened the next time it is edited. To check old rows as well, run `alter table public.<table> validate constraint <name>;`. Run `schema.sql` once after updating the app.
