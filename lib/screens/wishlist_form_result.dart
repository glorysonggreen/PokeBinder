import '../models/wishlist_entry.dart';

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
