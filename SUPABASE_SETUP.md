# Supabase setup

PokeBinder stores accounts and collection data in Supabase (Auth + Postgres).
This is the one-time setup for a project.

## 1. Create the tables

1. Open your project in the Supabase dashboard > **SQL Editor** > **New query**.
2. Paste the whole of [`supabase/schema.sql`](supabase/schema.sql) and run it.

The script is safe to run again whenever it changes: it only creates what is
missing and replaces the policies and the sign-up trigger. It never drops
tables or data.

## 2. Load the card catalog

The **Add** tab lets people pick a card from a shared card database instead of
typing it in, so the name, set, number, rarity, artwork and price are correct.
`schema.sql` creates the (empty) `card_sets` and `card_catalog` tables; this
step fills them.

1. On your computer, with Node 18 or newer, from the project folder:

   ```
   node tools/import_catalog.mjs --sets base1,jungle
   ```

   Use the sets you want people to choose from (ids are listed at
   <https://api.pokemontcg.io/v2/sets>). The data comes from the Pokémon TCG
   API; artwork is loaded from its image server and prices are TCGplayer market
   prices in US dollars. If the API is slow or rate-limited, set
   `POKEMONTCG_API_KEY` first (a free key from <https://dev.pokemontcg.io>).
2. Open the generated `supabase/seed_catalog.sql`, paste it into the SQL Editor
   and run it. Run the script and the file again whenever you want fresh prices
   or more sets; it updates rows in place.

People can read the catalog but never change it. Prices are converted to pesos
with the fixed rate in `lib/config/pricing.dart` — update it from time to time.

## 3. Point the app at your project

`lib/config/supabase_config.dart` holds the project URL and the **anon /
publishable** key (Project Settings > API). That key is meant to be public;
your data is protected by the Row Level Security policies in `schema.sql`.

Never put the `service_role` / secret key in this app.

## 4. Authentication settings

Dashboard > **Authentication**:

- **Sign In / Providers > Email**: decide whether **Confirm email** is on.
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
screen. Open the link in the same browser that requested it.

## Limits worth knowing

- Supabase returns at most 1,000 rows per request; the app reads in pages so
  larger collections load completely.
- Writes are sent one at a time, in order. If one fails (offline, a rule
  rejects it) a message appears and the change stays on screen but is **not**
  saved on the server. There is no offline queue or automatic retry yet.
