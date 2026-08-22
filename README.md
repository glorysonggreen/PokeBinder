# PokeBinder

> A Pokémon TCG collection manager — track your cards, binders, decks, and wishlist in one place.

**Course:** Applications Development and Emerging Technologies (6ADET), Holy Angel University
**Author:** Matthew Green

## What it does

- View a card's full details — artwork, set, rarity, condition, quantity owned, binder and page — with an interactive, drag-to-tilt 3D card.
- Organize cards into binders and pages.
- Track quantity owned and condition per card.
- See an estimated market value per card.
- Add cards manually, and add them to a deck.

## Built with

| | |
| --- | --- |
| Framework | Flutter (Dart) |
| State | `setState` (local, per-screen) |
| Storage | none yet — in-memory / sample data only |
| Other packages | `device_preview` — lets the app be judged at phone size on a desktop browser |

## Running it yourself

```bash
flutter pub get
flutter run -d chrome
```

### Environment variables

This project does not currently call any external service, so `.env` is not
required yet. If that changes (e.g. a card-pricing API), copy `.env.example`
to `.env`, fill in your own values, and never commit the result.

## Privacy and secrets

- This app does not currently store any personal data — collection data is
  local, in-memory sample data only.
- No secrets are compiled into the web build at this stage.
- All sample data (e.g. "Charizard, Base Set") is publicly available card
  information, not personal information.

See `docs/06-security-and-privacy.md` for the full, dated checklist.

## Status and what is next

**Works:** Card Details screen, matching the PokeBinder mockup, with an
interactive 3D card (drag to tilt, tap for a flourish, smooth release).

**Half done / not started:** Binders list, Search, Add Card form, Wishlist and
Trade list, Deck builder, Trainer profile.

**Next:** wire up navigation between screens, replace sample data with real
local storage.

## Licence

MIT, see [LICENSE](LICENSE). Change it if you want different terms.