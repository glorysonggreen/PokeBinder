# AI Usage Disclosure: PokéBinder

**Assistant used:** Claude (Anthropic)

**Rough share of the project that is AI-written:** **about 40%**

Commit links use `https://github.com/glorysonggreen/PokeBinder/commit/<hash>`.

## 1. How I Used AI

### Entry 1: Binder Add / Edit / Delete

**Date / tool:** August 23, 2026, Claude

**What I asked for:** I already had a basic binder screen in commit `1126068` on August 22. I asked Claude to help me fully implement adding, editing, and deleting binders and cards. I also used some of the topics from our 6ADET class repository as reference and explained how I wanted the binder system to work.

**What it gave back:** The implementation of the forms and functions in `binder_form_screen.dart`, `card_form_screen.dart`, and `pokebinder_form_fields.dart`, along with changes to `binders_screen.dart` and `pokemon_card_data.dart`.

**What I kept / changed / why:** I kept the general form structure and reusable fields, but changed parts of the implementation to fit how I wanted binders to work. The binder screen focuses on viewing and organizing cards instead of treating the binder as just another card display. Testing also showed that the sorting behavior needed further changes in `1dab064`. This showed me that generated code still needed to be tested and adjusted.

**Commit:** https://github.com/glorysonggreen/PokeBinder/commit/6d60413

### Entry 2: Login, Signup, and Decks Screens

**Date / tool:** August 28, 2026, Claude

**What I asked for:** I created the initial deck, login, and signup screens myself. I asked Claude to help adjust the deck screens to better fit their purpose and to implement the core logic for logging in and signing up.

**What it gave back:** Adjustments to the deck screens, login and signup logic, a forgot-password screen, and `deck_data.dart`.

**What I kept / changed / why:** I kept the basic structure and made sure the screens matched the existing PokéBinder design and navigation. At first, any input could be used to log in because the application was still being demonstrated without a real backend. After adding the database, I changed this to real authentication. I also removed the Google and Apple sign-in options because they were not needed for the application.

**Commit:** https://github.com/glorysonggreen/PokeBinder/commit/174848e

### Entry 3: Shared Sorting and Filtering

**Date / tool:** August 29, 2026, Claude

**What I asked for:** I needed help applying the sorting and filtering systems consistently across the application. I implemented the sorting options and filter choices myself, then asked Claude to help turn them into reusable controls that could be used across different screens.

**What it gave back:** Claude helped with the shared structure in `lib/widgets/card_sort_controls.dart` and `applyCardSort`, allowing filtering, searching, and sorting to be reused across screens.

**What I kept / changed / why:** I kept the shared approach instead of creating separate sorting systems for each screen. During testing, I found that card numbers needed to be treated as numbers rather than plain text because values such as `2/100` and `10/100` would otherwise be ordered incorrectly. Rarity and condition also needed custom ordering. I changed and tested these parts and continued improving the system in `bc87a15` on September 5.

**Commit:** https://github.com/glorysonggreen/PokeBinder/commit/e208577

### Entry 4: Animations

**Date / tool:** September 27, 2026, Claude

**What I asked for:** Animations were difficult for me, so I first tried implementing them manually. I was not satisfied with the result and asked Claude to improve my implementation and make the animations more consistent across the application.

**What it gave back:** An improved animation system based on my version, including `motion_widgets.dart` and `pokebinder_motion.dart`, with animations applied across most screens.

**What I kept / changed / why:** The current animation system is mainly Claude's improved version based on my earlier implementation. I kept the reusable animation approach and tested it across the application to make sure it worked with the existing screens and did not interfere with normal interaction.

**Commit:** https://github.com/glorysonggreen/PokeBinder/commit/910d829

### Entry 5: Moving the App to a Supabase Backend

**Date / tool:** September 27, 2026, Claude

**What I asked for:** Before Supabase, the application used mock data. I asked Claude how a real Supabase backend could be implemented so the application could read and write actual database records.

**What it gave back:** `supabase/schema.sql`, `supabase_config.dart`, repository classes, model changes for database rows, authentication, and row level security.

**What I kept / changed / why:** I kept the repository approach because it separates database operations from the UI. I adjusted the database structure and generated code to match what was actually needed by PokéBinder. After connecting the backend, I tested the application and found synchronization problems, which led to the next entry.

**Commit:** https://github.com/glorysonggreen/PokeBinder/commit/9e41812

### Entry 6: Fixing Database Syncing

**Date / tool:** September 28 and October 4, 2026, Claude

**What I asked for:** After moving to Supabase, some background database operations were unreliable. The app could update locally while database writes were still running. I asked Claude to make the synchronization more reliable and provide clearer error messages.

**What it gave back:** The first version added `SyncStatus` on September 28. On October 4, I worked with Claude to rewrite it into a write queue with timeouts and more specific error messages. It also included safer deck saving and catalog import tools.

**What I kept / changed / why:** I kept the central synchronization idea. Testing showed that the first version was not enough because multiple database requests could start at nearly the same time and happen in the wrong order. I changed it to use a write queue and added timeouts. I also found that deck saving could delete existing `deck_cards` before new records were successfully inserted, so I changed the process to handle new data more safely before removing old rows. The first error reporting system could also fail to show the same error twice, so I changed how errors were reported and added specific messages for expired sessions, duplicate names, missing records, invalid values, and connection errors.

**Commits:**
https://github.com/glorysonggreen/PokeBinder/commit/40bf957
https://github.com/glorysonggreen/PokeBinder/commit/12c0100

## 2. Where the AI Got It Wrong

### 2.1 Deck Saving Could Remove Existing Cards

**What AI gave me:** The initial deck saving process deleted the existing `deck_cards` before inserting the new cards.

**What was wrong:** If the new insert failed, the existing cards could already have been deleted. This could leave a deck without its previous cards.

**What I did instead:** I changed the process so the new data was handled more safely before removing the old rows. I also added checks for missing cards and invalid quantities.

**Commit:** https://github.com/glorysonggreen/PokeBinder/commit/12c0100

### 2.2 Database Writes Could Run Out of Order

**What AI gave me:** The first version of `SyncStatus` tracked database operations but did not control the order in which they ran.

**What was wrong:** Multiple requests could start at the same time. This created problems when one operation depended on another operation finishing first, such as when a deck needed a card to already exist in the database.

**What I did instead:** I changed the system to use a write queue so database operations are processed in order. I also added a timeout so a request that gets stuck cannot block the queue forever.

**Commits:**
https://github.com/glorysonggreen/PokeBinder/commit/40bf957
https://github.com/glorysonggreen/PokeBinder/commit/12c0100

### 2.3 Repeated Errors Were Not Always Displayed

**What AI gave me:** The first sync system stored the latest error in a `ValueNotifier<String?>`.

**What was wrong:** If the same error happened twice, the value could remain unchanged, so the interface might not react to the second error. The original error messages were also too general to clearly explain what happened.

**What I did instead:** I changed the error reporting so the previous error is cleared before a new one is assigned. I also added more specific messages for database and authentication problems.

**Commit:** https://github.com/glorysonggreen/PokeBinder/commit/12c0100

## 3. Who Wrote What

### 3.1 Binder Organization and Binder Screen

**File:** `lib/screens/binders_screen.dart`

**Commits:**

* https://github.com/glorysonggreen/PokeBinder/commit/1126068
* https://github.com/glorysonggreen/PokeBinder/commit/1dab064
* https://github.com/glorysonggreen/PokeBinder/commit/61026dd

The original design showed the cards of the selected binder at the bottom of the binder screen. I felt this did not make sense because a binder should organize and contain cards. I changed the organization so binders act as actual containers for cards.

I also added the Binders and All Cards tabs, pinned binders, binder limits, the Unsorted binder, and sorting. These were design decisions I made based on how I wanted the application to work. I tested the changes and adjusted the behavior as I developed the feature. The add, edit, and delete forms were implemented by Claude based on my design, so I do not count those forms as code I personally wrote.

### 3.2 Interactive 3D Pokémon Cards

**File:** `lib/widgets/interactive_3d_card.dart`

**Commit:** https://github.com/glorysonggreen/PokeBinder/commit/289d41a

I wanted the Pokémon cards to be more interactive than static images. I was inspired by a friend's similar 3D card effect from an ADET activity. I asked my friend how the effect worked and looked at their example code and research suggestions. I then wrote my own version for PokéBinder and used Claude to explain concepts and help debug the implementation.

My version uses pan gestures, a perspective matrix, a tilt limit, and an eased return. I also made it a reusable widget with a real back face, a tap peek, and adjustable settings. The feature uses `Matrix4` for 3D rotation and perspective to give the card a physical feel. The rotation limits prevent excessive tilting, while an animation controller smoothly returns the card to its normal position. The back image also receives additional rotation to prevent it from appearing mirrored.

### 3.3 Sorting and Filtering

**File:** `lib/widgets/card_sort_controls.dart`

**Commits:**

* https://github.com/glorysonggreen/PokeBinder/commit/e208577
* https://github.com/glorysonggreen/PokeBinder/commit/1dab064
* https://github.com/glorysonggreen/PokeBinder/commit/bc87a15

I implemented the sorting options and filter choices myself. Claude helped me apply the system consistently across the application. The system supports filters for categories and properties such as type, subtype, set, rarity, and condition. It also supports searching by name and sorting by different card values.

One important problem I identified during testing was how card numbers were compared. Card numbers should not be compared as plain text because values such as `2/100` and `10/100` would be ordered incorrectly. I also added custom ordering for rarity and condition. I tested these changes across binders, decks, trade lists, and other card screens.

### AI Written Piece I Understand Best: `SyncStatus`

**File:** `lib/services/sync_status.dart`

**Commits:**

* https://github.com/glorysonggreen/PokeBinder/commit/40bf957
* https://github.com/glorysonggreen/PokeBinder/commit/12c0100

Claude wrote a large part of this feature, especially the first version and the later queue implementation. I understand it well because I tested it, found problems with it, and changed the implementation.

`SyncStatus` tracks background database operations. The final version uses a write queue to process operations in order. The queue uses `Future` chaining so one operation finishes before the next one starts. This is important when one operation depends on another, such as saving a card before a deck can reference it.

The system also uses timeouts so a request cannot block the queue forever. Errors are caught and reported with specific messages. `ValueNotifier` allows the application to react to changes in synchronization and error status. The `flush()` function allows pending writes to finish before actions such as signing out.

## AI Usage Summary

I used Claude throughout the development of PokéBinder as a programming assistant. I mainly used it for feature development, code organization, debugging, database work, and learning Flutter and Dart concepts that I was not fully familiar with. I used AI to create starting points for some features and to understand different approaches, but I did not simply accept the generated code without checking it.

I tested the generated features in the actual application and changed the code when it did not work as expected or did not fit how I wanted PokéBinder to work. The database synchronization work is a good example. Testing showed that database writes could happen in the wrong order, some errors were not displayed properly, and the deck saving process could remove existing data if something failed. I also made important design decisions, such as changing the binder organization and developing the 3D card effect based on a friend's ADET project.

Overall, I used AI as a development assistant rather than letting it build the whole project without my involvement. I was responsible for deciding how the application should work, testing the results, finding problems, changing generated code, and learning how the important parts of PokéBinder work.
