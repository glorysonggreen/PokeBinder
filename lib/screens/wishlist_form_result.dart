import '../models/wishlist_entry.dart';

/// Result popped by [WishlistFormScreen] and [TradeEntryFormScreen] when the
/// user saves or deletes an entry.
class WishlistFormResult {
  final WishlistEntry? entry;
  final bool deleted;

  const WishlistFormResult.saved(WishlistEntry entry)
      : entry = entry,
        deleted = false;

  const WishlistFormResult.deleted()
      : entry = null,
        deleted = true;
}
