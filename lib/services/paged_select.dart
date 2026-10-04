import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase/PostgREST caps every `select()` at 1,000 rows by default
/// (`max_rows`). A plain `.select()` therefore *silently* returns only the
/// first 1,000 rows of a bigger table — a collector with 1,001 cards would
/// lose the last one on every launch, with no error. This reads a table in
/// pages until it runs out.
///
/// Pagination is only stable when the sort is total, so [thenBy] should be a
/// unique column (usually `id`). Note `order()` defaults to descending in
/// postgrest-dart, hence the explicit `ascending: true`.
Future<List<Map<String, dynamic>>> fetchAllRows(
  String table, {
  required String orderBy,
  String? thenBy,
  int pageSize = 1000,
}) async {
  final client = Supabase.instance.client;
  final all = <Map<String, dynamic>>[];
  var from = 0;
  while (true) {
    var query = client.from(table).select().order(orderBy, ascending: true);
    if (thenBy != null) query = query.order(thenBy, ascending: true);
    final page = await query.range(from, from + pageSize - 1);
    all.addAll(page);
    if (page.length < pageSize) break;
    from += pageSize;
  }
  return all;
}
