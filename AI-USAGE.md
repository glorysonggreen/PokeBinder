# AI Usage Disclosure: PokéBinder

**Assistant used:** Claude (Anthropic)

**Rough share of the project that is AI-written:** about 40% (my own estimate)

**Last updated:** October 9, 2026

This file explains where and how I used Claude while building PokéBinder, a Flutter app for managing Pokémon card collections. It also shows what Claude got wrong, who wrote which parts, and how I tested and changed the AI-generated code. Commit links use `https://github.com/glorysonggreen/PokeBinder/commit/<hash>`.

## Contents

1. [How I Used AI](#1-how-i-used-ai)
2. [Where the AI Got It Wrong](#2-where-the-ai-got-it-wrong)
3. [Who Wrote What](#3-who-wrote-what)
4. [AI Usage Summary](#4-ai-usage-summary)

## 1. How I Used AI

Each entry lists the purpose of the request, what I asked for, what Claude produced, and what I did with the result.

### Entry 1: Binder Add / Edit / Delete

**Date / tool:** August 23, 2026, Claude

**Purpose:** Let users create, change, and remove binders and cards instead of only viewing them.

**What I asked for:** I already had a basic binder screen in commit [`cd11ef7`](https://github.com/glorysonggreen/PokeBinder/commit/cd11ef7) from August 22. I asked Claude to help me fully implement adding, editing, and deleting binders and cards. I explained how I wanted the binder system to work and used topics from our 6ADET class repository as reference.

**What it gave back:** The forms and the logic behind them in `binder_form_screen.dart`, `card_form_screen.dart`, and `pokebinder_form_fields.dart` (reusable input fields). It also changed `binders_screen.dart` and `pokemon_card_data.dart`.

**What I kept / changed / why:** I kept the general form layout and the reusable fields. I changed parts of the code so binders work the way I designed them: the binder screen is for viewing and organizing cards, not just another list of cards. Testing then showed that the sorting needed more changes, which I made in [`fb5dfae`](https://github.com/glorysonggreen/PokeBinder/commit/fb5dfae). This taught me that generated code still has to be tested and adjusted.

**Commit:** [`ae25800`](https://github.com/glorysonggreen/PokeBinder/commit/ae25800)

### Entry 2: Login, Signup, and Decks Screens

**Date / tool:** August 28, 2026, Claude

**Purpose:** Make the deck screens fit their actual use, and make logging in and signing up work.

**What I asked for:** I built the first versions of the deck, login, and signup screens myself. I asked Claude to adjust the deck screens so they better fit their purpose and to write the main logic for logging in and signing up.

**What it gave back:** Changes to the deck screens, the login and signup logic, a forgot-password screen, and `deck_data.dart`.

**What I kept / changed / why:** I kept the basic structure and made sure the screens matched the PokéBinder design and navigation. At first, any input could be used to log in, because the app was still a demo without a real backend. After the database was added (Entry 5), I replaced this with real authentication. I also removed the Google and Apple sign-in options because the app does not need them.

**Commit:** [`209fbc5`](https://github.com/glorysonggreen/PokeBinder/commit/209fbc5)

### Entry 3: Shared Sorting and Filtering

**Date / tool:** August 29, 2026, Claude

**Purpose:** Use one sorting and filtering system on every card screen instead of writing a separate one for each screen.

**What I asked for:** I wrote the sorting options and filter choices myself. I then asked Claude to help me turn them into reusable controls that different screens can share.

**What it gave back:** The shared structure in `lib/widgets/card_sort_controls.dart` and the `applyCardSort` function, which lets filtering, searching, and sorting be reused across screens.

**What I kept / changed / why:** I kept the shared approach. While testing, I found that card numbers and some card properties were sorted incorrectly, so I fixed card number comparison and added custom ordering for rarity and condition (details in Section 3.3). I kept improving the system in [`875861b`](https://github.com/glorysonggreen/PokeBinder/commit/875861b) on September 5.

**Commit:** [`3891dfe`](https://github.com/glorysonggreen/PokeBinder/commit/3891dfe)

### Entry 4: Animations

**Date / tool:** September 27, 2026, Claude

**Purpose:** Give the app smooth, consistent animations on every screen.

**What I asked for:** Animations were hard for me, so I first tried to build them myself. I was not happy with the result, so I asked Claude to improve my version and make the animations consistent across the app.

**What it gave back:** An improved animation system built on my version, including `motion_widgets.dart` and `pokebinder_motion.dart`, with animations applied to most screens.

**What I kept / changed / why:** The current animation system is mainly Claude's improved version of my earlier work. I kept its reusable approach and tested it on the existing screens to make sure it worked and did not get in the way of normal taps and scrolling.

**Commit:** [`d0d650a`](https://github.com/glorysonggreen/PokeBinder/commit/d0d650a)

### Entry 5: Moving the App to a Supabase Backend

**Date / tool:** September 27, 2026, Claude

**Purpose:** Replace sample data stored inside the app with a real database, so the app can save and load real records.

**What I asked for:** Before Supabase, the app used mock data (sample data stored in the app instead of a database). I asked Claude how to connect a real Supabase backend so the app could read and write actual database records.

**What it gave back:** `supabase/schema.sql` (the database tables), `supabase_config.dart`, repository classes (code that keeps database reads and writes separate from the screens), changes to the models so they match database rows, user authentication, and row level security (database rules that control which user can read or change each record).

**What I kept / changed / why:** I kept the repository approach because it keeps database code out of the screens. I changed the database structure and the generated code to match what PokéBinder actually needs. After connecting the backend, my testing found syncing problems, which led to Entry 6.

**Commit:** [`05794d8`](https://github.com/glorysonggreen/PokeBinder/commit/05794d8)

### Entry 6: Fixing Database Syncing

**Date / tool:** September 28 and October 4, 2026, Claude

**Purpose:** Make saving to the database reliable and make error messages clear.

**What I asked for:** After the move to Supabase, some background database operations were unreliable. The app could update on the screen while the database writes were still running. I asked Claude to make syncing more reliable and to give clearer error messages.

**What it gave back:** On September 28, the first version of `SyncStatus`, which tracks background database operations. On October 4, I worked with Claude to rewrite it as a write queue (a line where each database write waits for the one before it), with timeouts and more specific error messages. This update also included safer deck saving and catalog import tools.

**What I kept / changed / why:** I kept the main idea of one central place that tracks syncing. Testing showed the first version was not enough, so I worked with Claude to fix three problems: writes running out of order, deck saving that could delete cards, and repeated errors that were not shown (see Section 2). The final error messages cover expired sessions, duplicate names, missing records, invalid values, and connection errors.

**Commits:**

* [`8794c89`](https://github.com/glorysonggreen/PokeBinder/commit/8794c89)
* [`a00a8dc`](https://github.com/glorysonggreen/PokeBinder/commit/a00a8dc)

### Entry 7: Sound Effect Generator Scripts

**Date / tool:** October 5, 2026, Claude

**Purpose:** Get original sound effects for the app instead of using sounds from the Pokémon games.

**What I asked for:** I decided to create the sound effects with Python code. I asked Claude to help me with the scripts in `tools/audio/` that generate them. The main menu and background music are the one exception (see below).

**What it gave back:** Help with the generator scripts `generate_sfx.py` and `synth_lib.py`, which create the 25 `.wav` files in `assets/audio/sfx/`.

**What I kept / changed / why:** I kept the generator scripts and the audio files Claude provided. The one thing I changed was the main menu music and the background music, which I replaced with music from Pokémon HOME. Those tracks are not AI-generated and are not original to this project; they belong to their original owners.

**Commit:** [`fc25413`](https://github.com/glorysonggreen/PokeBinder/commit/fc25413)

## 2. Where the AI Got It Wrong

These three problems came from Claude's first sync and deck-saving code (Entries 5 and 6). I found each one while testing the app.

### 2.1 Deck Saving Could Remove Existing Cards

**What AI gave me:** The first deck-saving code deleted the existing `deck_cards` before inserting the new ones.

**What was wrong:** If the insert failed, the old cards were already gone, so a deck could end up empty.

**What I did instead:** I worked with Claude to change the process so the new data is handled safely before the old rows are removed. We also added checks for missing cards and invalid quantities.

**Commit:** [`a00a8dc`](https://github.com/glorysonggreen/PokeBinder/commit/a00a8dc)

### 2.2 Database Writes Could Run Out of Order

**What AI gave me:** The first version of `SyncStatus` tracked database operations but did not control the order they ran in.

**What was wrong:** Several requests could start at nearly the same time. This caused problems when one operation needed another to finish first, for example when a deck needed a card to already exist in the database.

**What I did instead:** I worked with Claude to replace it with a write queue, so operations run one at a time in order. We also added a timeout so a stuck request cannot block the queue forever.

**Commits:**

* [`8794c89`](https://github.com/glorysonggreen/PokeBinder/commit/8794c89)
* [`a00a8dc`](https://github.com/glorysonggreen/PokeBinder/commit/a00a8dc)

### 2.3 Repeated Errors Were Not Always Displayed

**What AI gave me:** The first sync code stored the latest error in a `ValueNotifier<String?>` (a Flutter object that tells the screen when its value changes).

**What was wrong:** If the same error happened twice in a row, the value did not change, so the screen might not react to the second error. The error messages were also too general to explain what went wrong.

**What I did instead:** I changed the code to clear the previous error before setting a new one. I also added more specific messages for database and sign-in problems.

**Commit:** [`a00a8dc`](https://github.com/glorysonggreen/PokeBinder/commit/a00a8dc)

## 3. Who Wrote What

### 3.1 Binder Organization and Binder Screen

**File:** `lib/screens/binders_screen.dart`

**Commits:**

* [`cd11ef7`](https://github.com/glorysonggreen/PokeBinder/commit/cd11ef7)
* [`ae25800`](https://github.com/glorysonggreen/PokeBinder/commit/ae25800)
* [`fb5dfae`](https://github.com/glorysonggreen/PokeBinder/commit/fb5dfae)
* [`f8cfae7`](https://github.com/glorysonggreen/PokeBinder/commit/f8cfae7)

The first design showed the cards of the selected binder at the bottom of the screen. I felt this did not make sense, because a binder should organize and contain cards. I changed the design so each binder is a real container for its cards.

I also added the Binders and All Cards tabs, pinned binders, binder limits, the Unsorted binder, and sorting. These were my own design decisions, and I tested and adjusted them as I built the feature. Claude wrote the add, edit, and delete forms based on my design (Entry 1), so I do not count those forms as code I wrote myself.

### 3.2 Interactive 3D Pokémon Cards

**File:** `lib/widgets/interactive_3d_card.dart`

**Commit:** [`712cadb`](https://github.com/glorysonggreen/PokeBinder/commit/712cadb)

I wanted the cards to be more interactive than plain images. I was inspired by a friend's 3D card effect from a 6ADET activity. I asked my friend how the effect worked and looked at their example code and research suggestions. I then wrote my own version for PokéBinder and used Claude to explain concepts and help me debug it.

My version follows the user's finger with pan gestures, applies perspective, limits how far the card can tilt, and eases the card back to rest. I also made it a reusable widget with a real back face, a tap-to-peek action, and adjustable settings. It uses `Matrix4` (the 4x4 matrix Flutter uses for rotation and perspective) to give the card a physical feel. The tilt limit stops the card from rotating too far, and an animation controller moves it smoothly back to normal. The back image gets an extra rotation so it does not appear mirrored.

### 3.3 Sorting and Filtering

**File:** `lib/widgets/card_sort_controls.dart`

**Commits:**

* [`3891dfe`](https://github.com/glorysonggreen/PokeBinder/commit/3891dfe)
* [`fb5dfae`](https://github.com/glorysonggreen/PokeBinder/commit/fb5dfae)
* [`875861b`](https://github.com/glorysonggreen/PokeBinder/commit/875861b)

I wrote the sorting options and filter choices myself. Claude helped me use the system consistently across the app (Entry 3). It supports filters for type, subtype, set, rarity, and condition, searching by name, and sorting by different card values.

The most important problem I found while testing was how card numbers were compared. As plain text, `10/100` would come before `2/100`, so card numbers had to be compared as numbers. I also added custom ordering for rarity and condition, which do not sort correctly in alphabetical order. I tested these changes on the binder, deck, trade list, and other card screens.

### 3.4 Other Screens

**Folder:** `lib/screens/`

Most of the other screens in the app, including the login, signup, and decks screens, were first created by me and then improved by me with help from Claude. I designed the layout and behavior and wrote the first version of each screen. Claude then helped me refine them, fix problems, and connect them to shared systems such as sorting and filtering (Entry 3), animations (Entry 4), and the Supabase backend (Entry 5).

The parts Claude wrote more directly are listed in Section 1: the add, edit, and delete forms (Entry 1), and the deck screen changes, login and signup logic, and forgot-password screen (Entry 2).

### 3.5 AI-Written Piece I Understand Best: `SyncStatus`

**File:** `lib/services/sync_status.dart`

**Commits:**

* [`8794c89`](https://github.com/glorysonggreen/PokeBinder/commit/8794c89)
* [`a00a8dc`](https://github.com/glorysonggreen/PokeBinder/commit/a00a8dc)

Claude wrote a large part of this file, especially the first version and the later write queue (Entry 6). I understand it well because I tested it, found its problems, and worked with Claude to fix them.

`SyncStatus` keeps track of background database work. Its write queue chains operations together so each one finishes before the next one starts. This matters when one operation depends on another, such as saving a card before a deck can use it. Each operation has a timeout so a stuck request cannot block the queue. Errors are caught and reported with specific messages, and a `ValueNotifier` lets the screens react to changes in sync status and errors. The `flush()` function waits for pending writes to finish before actions such as signing out.

## 4. AI Usage Summary

I used Claude throughout the development of PokéBinder as a programming assistant. I mainly used it for building features, organizing code, finding and fixing bugs, setting up the database, and learning Flutter and Dart concepts I did not fully know. I used it to create starting points for some features and to compare different approaches, but I did not accept generated code without checking it.

I also used Claude for documentation. It helped me review the `.md` files in `docs/` and the repository root and update them so they match the current code. It also helped me review and revise this disclosure file.

I tested the generated features in the running app and changed the code when it did not work or did not fit how I wanted PokéBinder to behave. The database syncing work is the clearest example. Testing showed that writes could happen in the wrong order, some errors were not displayed, and deck saving could delete existing data if something failed. I also made key design decisions myself, such as changing the binder organization and building my own version of the 3D card effect, inspired by a friend's 6ADET project.

Overall, I used AI as a development assistant, not as a replacement for my own work. I decided how the app should work, tested the results, found problems, changed the generated code, and learned how the important parts of PokéBinder work.
