/// Looks an enum value up by name, falling back to [fallback] instead of
/// throwing. `Enum.values.byName` throws an [ArgumentError] on an unknown
/// string, and the models parse every row inside `loadAll`, so a single row
/// with an unexpected value (an older app version, a hand-edited row in the
/// Supabase dashboard) used to make the *entire* collection fail to load.
T enumByNameOr<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
