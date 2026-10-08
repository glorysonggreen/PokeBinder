# Security Checklist

**Last checked:** October 9, 2026 (repository at commit `d3fab3c`).

## Secrets and credentials

| # | Check | Yes / No / N/A | Evidence |
| - | ----- | -------------- | -------- |
| 1 | No API key, token or password is hardcoded in `lib/`, including in comments and commented out code | No, but low risk | `lib/config/supabase_config.dart` contains the Supabase URL and anon key. The anon key is public and protected by RLS, so it is not a critical secret. No `service_role` key or other private credential was found. |
| 2 | Anything private is in a gitignored config or passed with `--dart-define`, with an example file committed | No | `.env.example` and `.gitignore` are set up (`.env` and `.env.*` are ignored, `.env.example` is kept). But `main.dart` reads the Supabase values directly from `SupabaseConfig`, and the `--dart-define` lines in `deploy-web.yml` are commented out, so the environment based setup is not connected. |
| 3 | No keystore, `key.properties` or signing credential is in the repository | Yes | No `.keystore`, `.jks`, or `key.properties` files were found. `.gitignore` also excludes `*.keystore` and `*.jks`. |
| 4 | Git history is clean: I searched `git log -p` for password, secret, api key and token | Yes, with limitation | I searched the accessible Git history (94 commits). The only matches were placeholder names in comments (for example `# CARD_PRICING_API_KEY=put_your_key_here` in `.env.example`), documentation, and password length checks in the sign-up code. The Supabase anon key appears in history, but it is a public client side key. No `service_role` key or other private credential was found. |
| 5 | Any credential that was ever committed has been rotated | N/A | Only the public Supabase anon key was found. It is meant for client side use and does not need rotation. |

## GitHub Actions

| # | Check | Yes / No / N/A | Evidence |
| - | ----- | -------------- | -------- |
| 6 | No secret value is written literally in any workflow YAML file | Yes | `deploy-web.yml` contains no actual secret values. The Supabase variables are commented out and use `${{ secrets.* }}` when enabled. |
| 7 | Secrets are stored in repository Actions secrets and read with `${{ secrets.NAME }}` | Yes | The workflow is set up to read `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` through `${{ secrets.* }}`. They are commented out for now because the app reads the values from `SupabaseConfig`. |
| 8 | No workflow step echoes, dumps or debug prints a secret, and I opened a recent run's log to confirm | Yes | A recent deployment run was reviewed, and no secret printing commands or visible secret exposure were found. |
| 9 | If I build a signed APK: the keystore is a base64 secret decoded to a file at build time, never printed | N/A | The workflow only builds and deploys the Flutter web app. There is no APK signing step. |
| 10 | Uploaded build artifacts contain no key file, keystore or generated config | Yes | The Pages artifact is `build/web`, the standard Flutter web output. No key or signing files are added. |
| 11 | Third party actions are pinned to a commit SHA, not a moveable tag | No | All four actions in `deploy-web.yml` use version tags: `actions/checkout@v7`, `subosito/flutter-action@v2`, `actions/upload-pages-artifact@v5` and `actions/deploy-pages@v5`. `subosito/flutter-action` is the only one not made by GitHub, so it matters most. |
| 12 | Secret scanning and push protection are enabled on the repository | Yes | Secret scanning and push protection are enabled in the GitHub repository security settings. |

## Backend and security rules

| # | Check | Yes / No / N/A | Evidence |
| - | ----- | -------------- | -------- |
| 13 | Firestore and Storage rules are not left open to anyone; they require an authenticated user | Yes | The project uses Supabase, not Firebase, so Firestore rules do not apply. Supabase Storage has one bucket, `avatars`. Its policies (in `supabase/schema.sql`) require a signed-in user and only allow reading, uploading, replacing and deleting inside the user's own folder. The bucket accepts only JPEG, PNG and WebP files up to 2 MB. The bucket is public, so anyone with an avatar link can view that image (see "Anything I found" below). |
| 14 | Rules restrict a user to their own documents where that makes sense | Yes | Supabase RLS policies check `auth.uid() = user_id`. `deck_cards` checks ownership through the related deck, so users can only manage their own data. The card catalog is shared and read only: signed-in users can read `card_sets` and `card_catalog`, and no policy lets them change those tables. |
| 15 | If Supabase: Row Level Security is on for every table | Yes | RLS is enabled for all eight tables. Six user tables (`binders`, `cards`, `decks`, `deck_cards`, `wishlist_entries`, `trainer_profiles`) have owner policies. The two catalog tables (`card_sets`, `card_catalog`) have read only policies for signed-in users. |
| 16 | Firebase and Google API keys are restricted in the Google Cloud console to the APIs and app they are for | N/A | The project does not use Firebase or Google Cloud API keys. |
| 17 | I opened the app signed out and confirmed I could not read or write data I should not | Yes | The app was tested while signed out, and protected user data was not accessible. Supabase authentication and RLS prevent access to another user's data. |
| 18 | Seed and sample data is invented, not real people's data | Yes | The seed data (`supabase/seed_catalog.sql`) is public Pokémon TCG card data from the Pokémon TCG API and contains no real people's personal information. |

## Input and app surface

| # | Check | Yes / No / N/A | Evidence |
| - | ----- | -------------- | -------- |
| 19 | Input is validated before it is written, not only styled as valid in the UI | Yes, partially | The forms check input before saving: binder, deck and trade entry names must not be empty (`binder_form_screen.dart`, `deck_form_screen.dart`, `trade_entry_form_screen.dart`), and `card_form_screen.dart` trims the name and checks quantity, value and page numbers. The database also has check rules, such as `quantity > 0` and `estimated_value >= 0`. I found no maximum length on free text fields such as notes and descriptions. |
| 20 | Nothing secret is recoverable from the built app, since a shipped binary can be unpacked | Yes | The only credential in the app is the public Supabase anon key, which is protected by RLS. No `service_role` key or other privileged credential was found. The Pokémon TCG API key, if used, stays on my computer for the catalog import tool and is not in the app. |

## Repository and privacy

| # | Check | Yes / No / N/A | Evidence |
| - | ----- | -------------- | -------- |
| 21 | No student number, personal email, phone number or home address in the repository or in commit messages | No, in commit details | The files and commit messages contain no student number, phone number or home address. But the commit author details on all 94 commits include my full name and my personal Gmail address. |
| 22 | No classmate's personal data in the repository | Yes | No classmate names or personal data were found in the code, assets, or demo data reviewed. |
| 23 | Dependencies come from pub.dev, and `build/` and `.dart_tool/` are gitignored | Yes | `pubspec.yaml` uses pub.dev packages with no Git or local dependencies. `.gitignore` excludes both `build/` and `.dart_tool/`. |
| 24 | Images, fonts and other assets are mine, licensed, or credited | Partly | The sound effects are original, made with my own tools in `tools/audio/`. Chakra Petch is loaded through `google_fonts` under its open license. Card images come from the Pokémon TCG API's image server, and the README credits the API and says Pokémon and card artwork belong to their owners. The title and main menu music (`bgm_title.mp3`, `bgm_main.mp3`) are from Pokémon HOME. They are credited in the README, but I do not have a license for them. |
| 25 | Repository visibility is deliberate, and I checked it after my last push | Yes | The repository is public, and recent GitHub Actions runs are successfully deploying the web app to GitHub Pages. |

## Anything I found and fixed

Nothing here has been fixed in the code yet. Each item has a status and the fix I plan to make.

| Finding | Risk | Status | Fix |
| ------- | ---- | ------ | --- |
| `lib/config/supabase_config.dart` contains the Supabase URL and anon key in the source code. The `.env.example` file and the commented `--dart-define` lines in the workflow are not used. | Low. The anon key is meant to be public and RLS protects the data. | Not fixed | Read the values with `String.fromEnvironment` and pass them with `--dart-define`, using the repository secrets already named in the workflow. |
| The workflow uses version tags instead of commit SHAs for its four actions. | Low. This is a supply chain risk, but it does not expose a secret. | Not fixed | Pin each action to a full commit SHA, starting with `subosito/flutter-action`. |
| My personal Gmail address and full name are in the author details of all 94 commits. | Low to medium. Anyone can see them in the public history. | Not fixed | Set the Git email to the GitHub noreply address, turn on "Keep my email addresses private" and "Block command line pushes that expose my email" in GitHub settings. Old commits would keep the Gmail address unless the history is rewritten. |
| The `avatars` bucket is public, so anyone with an avatar link can view the image. The link contains my user id. | Low. The images are profile pictures that are shown on the trainer card on purpose. | Accepted | Keep it public, and keep the 2 MB size limit and the image-only file types. |
| No maximum length on free text fields. | Low | Not fixed | Add `maxLength` to the text fields and a length check in the database. |
| The Pokémon HOME music is credited but not licensed. | Low for a class project, higher if the app is shared widely. | Accepted for now | Replace it with my own generated music if the app is shared beyond this class. |
