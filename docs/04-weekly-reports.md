# Weekly Increment Report

## Week of: September 22, 2026

## What changed this week

1. **Finished the remaining app screens.** All the screens in PokeBinder are now done and match the 19-screen HTML mockup. They are in `lib/screens/`, including `login_screen.dart`, `signup_screen.dart`, `forgot_password_screen.dart`, `home_screen.dart`, `binders_screen.dart`, `decks_screen.dart`, `card_details_screen.dart`, `wishlist_screen.dart`, `stats_screen.dart`, `trainer_card_screen.dart` and `more_screen.dart`. The latest UI commits were the Scanner Rework series (10 commits, `e6bcfe9` to `611f5c5`, Sep 18 to 20) and `5cd184e` Spacing & Font Size Rework (Sep 20).

2. **Started connecting the app to Supabase.** I set up the project and began planning how each screen will read and save data. The screens are not connected yet, so most of the app still uses local or mock data.

3. **Looked for a third-party API for Pokémon card data and prices.** I listed the fields my screens need and checked each option against that list (see below).

## Why

1. I had to finish all the screens first. The backend depends on what data each screen reads and saves, so I needed the screens done before I could design the database.

2. I chose Supabase to handle sign-in, storage and syncing. This way a user's collection is saved online and can be opened on any device, instead of staying on one phone.

3. I need a card data API to get real card information and, if possible, prices. Typing in all the data by hand would take too long.

## What broke or what I got stuck on

1. **It is hard to find a free API that has everything the app needs.** The options I found are either paid, have strict limits on how often I can use them, or are missing important data like prices. I checked each option against the fields my screens need:

   | Screens | Fields needed |
   | --- | --- |
   | Card Details, Binders, Decks | card name, set, card number, rarity, type, artwork |
   | Home, Stats | market price, to show the value of the collection |
   | Sort and filter | type, subtype, set, rarity |

   Card name, set, number, rarity and artwork are essential. Price is useful but the app can work without it. If no free option has all the essential fields, a smaller dataset (for example one or two sets) with some manual entry is enough to finish a working app.

2. **The Supabase connection is not finished.** The screens are not fully connected to it yet, so most of the app still uses local or mock data.

## What is left

1. Finish connecting all screens to Supabase, including sign-in, storage and syncing the collection.
2. Decide on the card data API by finding a suitable free option, or by using a smaller dataset with manual entry.
3. Test the whole app from start to finish once the backend is connected.
4. Do a final cleanup pass after real data works across the app.
5. Design and add the app's logo.
6. Add animations and sound effects throughout the app.

---

## Week of: September 27, 2026

## What changed this week

1. **Added animations across the app** using a shared set of reusable animation widgets (commit `910d829`, Sep 27; 13 files, about 1,060 lines added). The animations are:
   - **Switching tabs:** screens fade between tabs in `app_shell.dart`, and the bottom navigation icons bounce when selected (`app_nav_bar.dart`).
   - **Screen content:** content fades and slides in on Home, Binders, Binder Detail, Decks, Wishlist and Card Details.
   - **Card Details:** the card is "dealt in", and the value counts up.
   - **Counting numbers:** numbers on Stats and Home count up instead of appearing at once.
   - **Binder tiles and buttons:** binder tiles shrink slightly when pressed, and form buttons pop in.
   - **Login and sign-up:** error messages animate in on `login_screen.dart`, `signup_screen.dart`, `forgot_password_screen.dart` and `reset_password_screen.dart`.
   - **Moving between pages:** every page change uses one custom transition (`pokebinder_page_transitions.dart`).

2. **Finished the main Supabase backend** (commit `9e41812`, Sep 27). This includes the database schema (`supabase/schema.sql`), Row Level Security (RLS) rules, the sign-in service (`auth_service.dart`), repository classes for binders, cards, decks, wishlist and trainer profiles, and model updates so each model can be saved to and loaded from database rows.

3. **Moved the app from static and in-memory data to Supabase repositories.** User data is now saved permanently and linked to each account through Supabase Auth and RLS. The screens now read and save through repositories instead of changing lists directly.

4. **Added per-user data security** with Supabase Auth and Row Level Security, so each user can only access their own data.

## Why

1. **Animations.** My first try at animations was done by hand, and it looked different on each screen, so the app felt uneven. I replaced it with one shared set of animation widgets (`motion_widgets.dart`, `pokebinder_motion.dart`). Now every screen reacts the same way to a tap, a page change or a tab switch, and the user can see that something happened.

2. **Supabase.** Before this, the app used mock data stored inside each screen. Any login worked, and nothing was saved after the app closed. With a real backend, a user's collection is saved, belongs to their account, and can be opened on another device.

3. **Repository migration.** Moving every screen to repositories gives the app one path for data. I no longer have to keep a mock version and a real version side by side.

4. **Auth and RLS.** A collection is personal, so the database itself must refuse to show one user's data to another user. RLS enforces this in Postgres, so it still works even if a screen has a bug.

## What broke or what I got stuck on

1. **Card data API.** I did not hit a bug that stopped my work, but choosing the card data API is still a challenge. The free options I found are paid, have strict usage limits, or are missing important data like card prices. Because of this, I am thinking about removing the scanner feature and using manual card entry instead. I will judge each option using these criteria:

   | Criterion | Must have or nice to have | Why |
   | --- | --- | --- |
   | Free, or a free plan big enough for a student project | Must have | I have no budget for a paid plan |
   | Has name, set, number, type and rarity | Must have | Sorting, filtering and Card Details need them |
   | Artwork I can show with credit | Must have | Cards without images look broken |
   | A usage limit I can work within, so I can load the data once | Must have | The app should not call the API on every screen |
   | No secret key stored inside the app | Must have | The app is public, so anyone can copy a key inside it |
   | Includes a market price | Nice to have | Needed for the collection value, but it can be blank at first |

   **Decision rule:** if an option meets every "must have," I will use it. If none does, I will use a smaller dataset (one or two sets) with manual entry, and leave prices blank or enter them by hand. I will keep the scanner only if the chosen data can identify a card by its number or name. If not, I will replace it with manual entry.

2. **Connecting and testing took most of my time.** I replaced the remaining direct data changes in the screens with repository calls. Testing meant checking sign-in, data loading, saving, and each user's own data across several screens.

## What is left

These are listed in the order I will work on them.

**Must work for the app to be usable**

1. Finish and check `login_screen.dart`, `signup_screen.dart` and `forgot_password_screen.dart` with `AuthService`. This comes first because nothing else works without a signed-in user.
2. Add a Sign Out option to `more_screen.dart`.
3. Check the loading states in `app_shell.dart`, so user data and trainer profiles finish loading before the main app is shown.
4. Check that every repository saves correctly (`upsert` and `delete`) and that the screens use them: `binders_screen.dart`, `decks_screen.dart`, `home_screen.dart`, `card_details_screen.dart`, `wishlist_screen.dart`, `trade_list_add_card_screen.dart`, `deck_add_card_screen.dart`, `stats_screen.dart`, `trainer_card_screen.dart` and `trainer_favorite_card_screen.dart`.
5. Choose the card data source using the criteria above, and decide whether to keep the scanner or replace it with manual entry. This decides how cards get into the app.
6. Update `test/widget_test.dart` to cover sign-in and Supabase-backed data.

**Can wait until the app works**

7. Add background music and sound effects throughout the app.
8. Design and add the app's logo.
