# Project Proposal

---

## App Name: PokéBinder

## The Problem, in One Sentence

People shopping at card shops or browsing online listings may not remember if they already own a card, what condition it is in, or which binder it is stored in, which can lead to duplicate purchases or time spent searching through physical binders.

## Who Is This For?

This app is for me and other Pokémon TCG collectors who keep their cards in physical binders but do not have one place to track their collection. Collectors often rely on memory or check their binders manually. When they are away from home, they may have to guess or skip a purchase because they are unsure whether they already own the card.

## Core Features (MVP)

All of the planned MVP features are now built and connected to Supabase. The hard-coded sample cards are gone. When a user signs in, the app loads their collection from Supabase into in-memory lists (for example `PokemonCardData.library`), the screens read from those lists, and every change is saved back through repository classes (`lib/services/`). A user's collection is stored in their own account and is still there after the app is closed or opened on another device.

The one planned feature I did not keep is the Card Scanner. I built the scanner screen and its demo flow, but on October 4, 2026 I removed it (`scanner_screen.dart`) and replaced it with a searchable card catalog on the **Add** tab. The reasons are in the Risks and "What Changed" sections.

| Feature | Still in the MVP? | Flutter pieces it uses | Status now |
| --- | --- | --- | --- |
| Sign in / Sign up | Yes | Form, TextField, supabase_flutter auth, `AuthService`, auth-state listener, password recovery screen, Sign Out in the More tab | Done. One account per email, "account already exists" message, Forgot Password and Choose a New Password screens, resend-link countdown |
| Manage Collection | Yes | Form (`CardFormScreen`), ListView, GridView for binder pages, showDialog for delete confirmation, multi-select delete, model classes with toJson/fromJson, repositories | Done. Add, edit and delete cards, binders with pages, an Unassigned Cards list, and cleanup of trade list, decks and trainer favorite when a card is deleted |
| Search, Browse & Card Details | Yes | Search and filter controls, sort controls, ListView, GridView, GestureDetector + Transform for the drag-to-tilt 3D card, Navigator.push | Done. Search the user's own binders and cards, search the real card catalog stored in Supabase when adding, and view full card details with a 3D card |
| Card Scanner | No, removed | CustomPaint scan overlay and AnimationController (demo version only) | Removed on Oct 4. Replaced by the catalog picker on the Add tab |
| Wishlist, Trade List & Deck Planner | Yes | TabBar, Form, showDialog, showModalBottomSheet, deck-card join | Done and saved to Supabase |
| Trainer Card & Collection Overview | Yes | Form, profile photo (image_picker and a crop screen), CustomPaint for statistics, favorite pickers | Done. The profile photo is stored in Supabase Storage |
| Supabase Setup | New | Dashboard setup, `supabase/schema.sql`, Row Level Security, Storage bucket, GitHub Actions deploy | Done. The web build deploys to GitHub Pages on every push to `main` |
| Sound, Music & Animations | New | audioplayers, shared_preferences, shared animation widgets | Done. Sound effects, two background themes, a Sound & Music settings screen, and shared animations across screens |

The MVP is complete, so the remaining work is cleanup rather than new features: moving the Supabase settings out of the source code, adding more tests, and recording the demo video.

The earlier plan treated the real scanner as a risk with a 12+ hour estimate. That risk is gone because the feature was cut, not because it was solved.

## Stretch Goals

Where each stretch goal from the last version stands:

1. **Real Scanner Recognition** – **Dropped.** Camera and text recognition were never tested, and the Add tab now covers the same need (getting a real card into the collection quickly) without a camera.
2. **Real Card Catalog** – **Done, in a different way than planned.** The Pokémon TCG data is loaded into Supabase (`card_sets` and `card_catalog`) by an import tool in `tools/`, and the app searches that catalog. The app does not call the Pokémon TCG API directly. The committed seed file contains Base Set and Jungle, and the importer can load every set (about 20,000 cards).
3. **Live Prices** – **Partly done.** Cards get a market price from the TCGplayer prices in the catalog, shown in pesos and adjusted for the card's condition. Prices are not live: they only update when I re-run the import, and the dollar-to-peso rate is a fixed number in `lib/config/pricing.dart`.
4. **Set Completion Tracking** – Not started.
5. **Deck Sharing & Friends List** – Not started.
6. **AI Assistant** – Not started.
7. **Offline Support** – New. Saves currently need a connection and are not retried.

## How My App Saves Data

### Will Different Users See the Same Data?

**No.** Each person who uses PokéBinder has their own private collection. If two people install the app, they do not see each other's cards, binders, decks, wishlist, trade list, or trainer card. This is important to me because PokéBinder is meant to represent a person's actual physical collection. The only shared data is the read-only card catalog, which is public card information. Row Level Security enforces this in the database itself, so it still holds if a screen has a bug.

### How Much Data Will the App Store?

A real user could have around 300 to 1,500 cards in their collection. A user might also add or edit around 20 to 100 cards in a typical week. Aside from cards, a user could have around 5 to 15 binders, about 30 wishlist and trade entries, and several decks.

Based on this, I estimate that PokéBinder could store around **500 to 2,000 records per user**. Supabase returns at most 1,000 rows per request, so the app reads in pages and larger collections still load completely.

### My Choice: Supabase

I chose **Supabase** because it provides PostgreSQL, Supabase Auth, Row Level Security, and file Storage in one platform. It is connected to Flutter with supabase_flutter, and it is now the only place the app stores collection data.

Another reason is that my data is relational. A deck contains multiple cards, a card belongs to a binder and page, and a wishlist or trade entry can point to a card I own. PostgreSQL handles this with separate tables, foreign keys, and cascade rules. For example, deleting a card also removes it from decks and the trade list.

I also wanted PokéBinder to work across devices, so I can check my collection at a card shop and manage it again at home. Cloud storage makes the same account and collection available from any browser.

### The Tradeoff

Using Supabase added work: authentication, Row Level Security, network access, and keeping sensitive keys out of my public repository. A local database would have been simpler and would work without an internet connection.

I still think cloud storage fits PokéBinder better. The cost is that **writes are online-only**. If a save fails (for example, the connection drops or a rule rejects it), the app shows an error message and the change stays on screen but is **not** saved on the server. There is no offline queue and no automatic retry yet.

### What I Save

There are now eight tables, one of which is a join table, plus one storage bucket:

- **trainer_profiles** – stores each user's trainer information
- **binders** – stores the user's binders
- **cards** – stores the cards in the user's collection
- **decks** – stores the user's decks
- **deck_cards** – connects cards to decks and stores their quantities
- **wishlist_entries** – stores wishlist and trade entries
- **card_sets** – shared, read-only list of Pokémon TCG sets
- **card_catalog** – shared, read-only list of real cards with artwork links and market prices
- **avatars** (Storage bucket) – trainer card profile photos, limited to JPEG, PNG and WebP up to 2 MB

Card artwork is no longer bundled with the app. The catalog stores image links, and the app loads the artwork from the Pokémon TCG API's image server. Owned cards and wishlist entries keep a reference to the catalog card (`catalog_id`).

### Have I Tested Supabase Yet?

Yes. PokéBinder runs against a real Supabase project, and the deployed web build uses it. Sign-up, login, password reset, and saving, loading and deleting cards, binders, decks, wishlist entries and trainer profiles all go through Supabase. I also checked that the app cannot read or write protected data while signed out (see `docs/07-security-checklist.md`).

The two test files in `test/` currently cover the sign-in helpers (email checks and error messages) and the audio settings. Saving and loading with Supabase has been tested by hand, not with automated tests.

## One Thing I Want to Add That the Course Did Not Teach

The thing I added is a real Pokémon TCG card catalog using the **Pokémon TCG API**.

Instead of typing in every card by hand, a user can search the catalog on the Add tab, pick a card, and the name, set, number, rarity, artwork and price are filled in correctly. The API data also supplies the TCGplayer market prices that become the estimated value in pesos.

I load the data once into my own Supabase tables with an import tool (`tools/import_catalog.mjs`, with a Dart version, `tools/import_catalog.dart`) rather than calling the API from the app on every screen. This keeps the app fast, keeps the API's rate limits out of the user's way, and means no API key has to be inside the app.

### Does It Run Where I Develop?

Yes. The catalog is read through Supabase, so it works anywhere the app runs, including the web build I develop and deploy with. The importer runs on my own computer with Node 18 or newer, or with Dart. If the API is slow or rate-limited, I use a free API key that stays in my terminal and never in the app.

### Web Fallback and Demo Plan

PokéBinder has no hardware-dependent feature anymore, since the scanner was removed. Everything runs in a normal browser, so there is no camera, GPS or sensor feature to demo on a real device. I will demo the web build in the DevicePreview phone frame.

### Core or Stretch Goal?

The real card catalog started as a stretch goal and is now a working core feature. Cards are added by picking them from the catalog, and the details (quantity, condition, binder, page, notes) can be edited afterward. The app does not yet let a user add a card that is missing from the catalog. If the catalog fails to load, the Add tab shows an error message with a Try Again button.

## How My Project Runs When Someone Else Opens It

### Am I Keeping the DevicePreview Wrapper?

**Yes.** The app is wrapped in DevicePreview with `enabled: kIsWeb`, so the web version shows in a phone-sized frame. It does not turn on for native builds.

### Can I Run the Project with `flutter run -d web-server`?

**Yes.** `flutter run -d web-server` works, and so does `flutter run -d chrome` (the one the README documents). A live demo is also deployed at https://glorysonggreen.github.io/PokeBinder/. To run it yourself, run `flutter pub get`, then follow `SUPABASE_SETUP.md` once to create the tables and load the catalog.

The app needs a Supabase project to work, so it no longer falls back to sample data. If it cannot load the user's data, it shows a loading error instead of a blank screen.

### Does Anything That Needs Real Hardware Fall Back to Sample Data Instead of Crashing?

Not applicable. The Card Scanner was the only hardware feature, and it was removed. The profile photo picker uses `image_picker`, which on the web opens a normal file chooser.

## Repository and Security

My project is stored in my public GitHub repository: **glorysonggreen/PokeBinder**

The Supabase URL and anon (publishable) key are written in `lib/config/supabase_config.dart`. This is not what I planned. I planned to keep them in a local `.env` file and pass them in at build time, but the app does not read `--dart-define` values yet, and the matching lines in the deploy workflow are commented out. This is acceptable because the anon key is designed to be public and Row Level Security is what protects the data. I decoded the key and confirmed its role is `anon`. Moving these values to `--dart-define` is still on my list.

Secrets only my tools need, such as the Supabase service_role (secret) key and the Pokémon TCG API key used by the catalog import, go in a local `.env` file that is ignored by Git. They are never in the Flutter app or the repository. `.env.example` contains only placeholder names.

For testing, I use public card information and a test account with a throwaway email. I do not store personal information in the test data.

While doing my security check I found that a Chrome profile folder from `flutter run -d chrome` had been committed to Git history. It contained session tokens for my own test account. I revoked those sessions in Supabase on October 9, 2026. The full list of findings, fixes and accepted risks is in `docs/06-security-and-privacy.md` and `docs/07-security-checklist.md`.

## Data the App Remembers

Every field below comes from `supabase/schema.sql` and my model classes. Changes from the prelim are noted in the change log.

| Thing | Fields | Where it is saved |
| --- | --- | --- |
| Trainer Card | user_id, name, title, bio, favorite_card_id, favorite_binder_id, favorite_deck_id, avatar_url | Supabase table trainer_profiles; photo file in Storage bucket avatars |
| Binder | id, user_id, name, description, page_count, slots_per_page, category, is_pinned, created_at | Supabase table binders |
| Card (owned) | id, user_id, name, set_name, card_number, rarity, type, supertype, subtype, quantity_owned, condition, binder_name, page, estimated_value, notes, image_asset_path, catalog_id, finish, date_added | Supabase table cards |
| Deck | id, user_id, name, format, target_size, description, is_pinned, created_at | Supabase table decks |
| Deck card | deck_id, card_id, quantity | Supabase table deck_cards |
| Wishlist / Trade entry | id, user_id, name, set_name, card_number, rarity, condition, quantity, notes, kind (wishlist or trade), priority, estimated_value, asking_for, source_card_id, image_asset_path, catalog_id, finish, date_added | Supabase table wishlist_entries |
| Card set (shared, read-only) | id, name, series, printed_total, total, release_date, logo_url, symbol_url | Supabase table card_sets |
| Catalog card (shared, read-only) | id, set_id, number, name, supertype, subtype, type, rarity, image_small, image_large, market_price_usd, prices per finish, price_updated_at | Supabase table card_catalog |
| Sound and music settings | music and effects on/off, volumes | On the device (shared_preferences) |

## Screens

1. **Sign In, Sign Up, Forgot Password, Choose a New Password**
2. **Home Dashboard:** Collection Summary (card count, estimated value, binder count), Quick Actions (New Binder, New Deck, Add a New Card), Recently Added, Continue a Binder
3. **Binders:** Binders tab and All Cards tab (each with search), Unassigned Cards, Binder Detail, Create/Edit Binder, Add Card to Binder, Card Details (with 3D card), Add/Edit Card
4. **Add:** Catalog search and picker, then Add/Confirm Card
5. **Deck Planner:** Deck List, Deck Detail, Create/Edit Deck, Add Card to Deck
6. **More Hub:** Trainer Card, Edit Trainer Card, Profile Photo Crop, Choose Favorite Card, Collection Statistics (value by rarity, cards by set, top value cards), Wishlist & Trade List, Wishlist Form, Trade Entry Form, Add Card to Wishlist / Trade List, Sound & Music, Sign Out

The app also opens with a short Poké Ball intro animation.

## Risks, Revised

### The Risk I Named Last Time

The main risk I identified before was reliable card search and scanning.

**Search:** Resolved. Search now runs against the real card catalog in Supabase, with a database index on card names, so it can find cards I have not entered myself.

**Scanning:** Resolved by cutting the feature. Real card recognition was never tested, so I removed the demo scanner and made catalog search the way cards get added.

### The Persistence and Security Risks I Named

**Persistence refactor:** Resolved. The app loads each user's data from Supabase when they sign in (`AppShell` shows a loading state and an error message with a retry if loading fails), and the screens save every change through repository classes (`binder_repository.dart`, `card_repository.dart`, `deck_repository.dart`, `wishlist_repository.dart`, `trainer_profile_repository.dart`, and `catalog_repository.dart` for the catalog). The in-memory lists are kept as a copy of the database, so screens can still read them directly. Data is saved to Supabase and linked to each account.

**Row Level Security:** Policies are written for all eight tables in `schema.sql` (owner-only on user tables, read-only on the catalog) and for the avatars bucket. I checked that protected data is not available while signed out. I also tested with two separate accounts, and each account could only see and change its own data.

### Risks I See Now

**Online-only writes:** A failed save shows a message but is not retried, and nothing is queued offline.

**First step:** Decide whether to add a retry button for failed saves, or only document the limitation clearly.

**Catalog-only adding:** A card can only be added by picking it from the catalog, so a card that is missing from the catalog (or a catalog that has not been loaded) cannot be added.

**First step:** Load more sets with the import tool, and decide whether to add a manual "add a card" form.

**Prices are not live:** Prices only update when I re-run the import, and the peso rate is fixed at 58.

**First step:** Add a visible "prices last updated" note, or keep the current limitation and say so in the demo.

**Secrets configuration:** The Supabase URL and anon key are in source code instead of `--dart-define`, and the GitHub Actions use version tags instead of commit SHAs.

**First step:** Read the Supabase values with `String.fromEnvironment` and use the repository secrets already named in the workflow.

**Thin automated tests:** The tests cover only sign-in helpers and audio settings.

**First step:** Add tests for the models' `toJson` / `fromJson` and for the price calculation in `pricing.dart`.

**Music license:** The title and main music are from Pokémon HOME and are credited but not licensed. This is fine for a class project, but I would replace them before sharing the app widely.

## What Changed, and Why?

| Section | Prelim said | Now says | Why it changed |
| --- | --- | --- | --- |
| Core features | 5 features, all in the MVP, nothing cut | 5 features plus authentication, all built and saved to Supabase. The Card Scanner was removed. | A feature is only "done" when it can save data. The scanner never moved past a simulated demo and the camera plugin was never tested. Catalog search covers the same need. |
| Auth | Not mentioned | Sign In, Sign Up, Forgot Password and Choose a New Password, backed by Supabase Auth, plus Sign Out | Collections are personal, so every user needs a real account. Login used to accept any input. |
| Storage | "Data the app needs to remember" with no storage chosen | Supabase using Postgres, Auth, Row Level Security and Storage | The data is relational and has to work across devices. RLS protects each user's data in the database itself. |
| Data | Card had a "binder name" text field; Deck was "selected cards" | Eight tables, including a deck_cards join table and shared card_sets and card_catalog tables. Cards still store `binder_name` as text, kept in sync by database triggers when a binder is renamed or deleted. Fields such as rarity, priority, finish, catalog_id and estimated value were added. | My actual models needed more information than I first listed. I kept `binder_name` instead of switching to a `binder_id` foreign key, and the triggers keep it consistent. |
| Screens | 5 main screens with a few subscreens | 6 groups, including authentication, the Add tab, Deck Detail, profile photo cropping and Sound & Music | This matches what is actually in `lib/screens/`. |
| Stretch goals | 3 items | The card catalog is done, live prices are partly done (imported, not live), and the scanner was dropped. Set completion, deck sharing and friends, the AI assistant and offline support are not started. | Real card data made the app far more useful, but a live price feed and a scanner would need more time and tools than the project has. |
| Extras | Not mentioned | Sound effects, background music, shared animations, a Poké Ball intro, and a trainer profile photo | These were added to make the app feel finished and consistent across screens. |
| Risks | Search and scanning reliability | Search is solved and scanning was cut. The new risks are online-only saves, adding cards only from the catalog, prices that are not live, secrets configuration, and thin tests. | The persistence and RLS risks were handled by moving to repositories and writing Row Level Security policies. The remaining risks came up while checking security and finishing the app. |
