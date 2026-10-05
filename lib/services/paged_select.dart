import 'package:supabase_flutter/supabase_flutter.dart';

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
