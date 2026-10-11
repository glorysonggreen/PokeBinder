# Demo video

**File:** https://drive.google.com/file/d/1Q_aHV3100oNCpvOgyC0P9XeogBDyEmWv/view?usp=drive_link  
**Length:** 37:31  
**Recorded on:** Windows PC, Google Chrome, running the web build of the app

## What it shows

A short list, in order, so a viewer can skip to what they need:

- **Presentation (0:00 to 19:55)**
  - `0:00` **What PokeBinder is** and who it is for: Pokémon card collectors who want their cards, binders, decks and wishlist in one place
  - `0:17` **The problem:** cards scattered across shoeboxes, piles and binders, with no record of copies, condition, binder page or collection value
  - `0:45` **Feature overview:** binders (pinning, card limits, an Unassigned binder), quantity, condition and peso value, search, sort and filter, wishlist, trade list, trainer profile, deck planner, animations, sound and music
  - `1:16` **How the app flows:** login, dashboard, adding cards, binders and card details
  - `2:24` **The part I am proudest of:** the drag-to-tilt 3D card, how it works, and where the idea came from
  - `3:37` **Front end:** Flutter, converting my 19-screen HTML mockup into the final 31-screen app, and the packages used
  - `4:41` **Back end:** Supabase, repository classes, setState, and the sync write queue
  - `5:26` **What Supabase does:** authentication, the profile trigger, row level security, the 8 PostgreSQL tables, and avatar storage
  - `6:20` **Card catalog and prices:** the Pokémon TCG API, TCGplayer prices, the 58 pesos per dollar rate, and condition percentages
  - `7:08` **Security audit** of the public repository, the exposed session tokens I revoked, and the accepted risks
  - `7:51` **The six problems I hit** and how I fixed them: binder layout, UI not matching the mockup, card number sorting, mock data, write order, and the card scanner I had to cut
  - `11:13` **How I used AI:** what I designed myself, what Claude helped with, and my rough 40% estimate
  - `14:56` **Three places the AI got it wrong:** deck saving, write order, and repeated errors
  - `15:53` **The road ahead:** offline support, automatic price refresh, completion tracking, deck sharing and friends list, AI assistant, card scanner, manual add-card form
  - `19:33` **The GitHub repository** and live demo links
- **Live demo (19:55 to 37:31)**
  - `19:55` **Live demo begins**
  - `20:00` **Login screen,** the test account, the six-character minimum password, and the mute sound button
  - `20:35` **Forgot Password flow,** then sign up with name, email, password and confirm password
  - `21:10` **Login errors:** missing email or password, and wrong password
  - `21:27` **Dashboard:** welcome message, card count, collection value, binder count, quick actions, and recently added cards
  - `21:54` **Adding a card:** searching the catalog for Pikachu
  - `22:34` **Search results:** no-results message for a misspelled search, the 200-match limit, show more, and back to top
  - `23:18` **Catalog filters:** newest or oldest, type, card category, card number, rarity, price and set
  - `23:46` **Missing artwork and prices** because of the Pokémon TCG API, mostly the newest sets
  - `25:20` **Add card details:** rotate the 3D card, set condition, quantity and value, and choose a binder or leave it unassigned
  - `26:07` **Adding a card that is already in the binder:** the match message, adding to the quantity, or keeping copies separate for their own value and notes
  - `27:12` **Adding the most expensive Charmander** to a binder, undoing it, and the rare card sound effect
  - `27:50` **Collection screen:** sorting binders by newest, oldest, most cards, highest value or alphabetical
  - `28:05` **All Cards tab:** searching the whole collection with filters, including quantity and condition
  - `28:41` **Unassigned Cards:** a card that is not in any binder
  - `29:14` **Editing a card** to move it into a binder page, and the delete option that removes it from the entire collection
  - `30:22` **Opening the Johto Starters binder,** its cards and pages
  - `30:51` **Card details:** rotating the 3D card, quantity, condition, binder and page, peso value, add to deck, and edit
  - `31:16` **Selecting cards** to remove them from a binder or delete them from the whole collection
  - `31:40` **Creating a new binder** and choosing the slots per page (9, 12 or 15)
  - `32:02` **All Cards search,** finding the Johto Starters
  - `32:13` **Decks:** creating a deck, choosing a format (Standard, Expanded or Casual), adding a description, and searching and filtering decks
  - `33:12` **Deck details:** missing-card count, deck statistics by type, and adding a card you own (Charmander)
  - `34:07` **Trainer card:** uploading and adjusting a profile photo, name, title, favorite card, favorite binder, favorite deck and bio
  - `35:14` **Collection statistics:** value by rarity, cards by set, and top value cards
  - `35:45` **Wishlist and trade list,** including priority and trade eagerness
  - `36:46` **Sound & Music settings:** turn off music, keep sound effects, and adjust volume
  - `37:11` **Signing out** and wrapping up

# Other files

**PPT and Logo:** https://drive.google.com/drive/folders/1N3MWISnXuUYNhWNeilF3HRBtV3JOMwGT?usp=drive_link