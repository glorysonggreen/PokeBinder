// Builds supabase/seed_catalog.sql from the Pokémon TCG API (pokemontcg.io).
//
//   dart run tools/import_catalog.dart --sets base1,base2
//   dart run tools/import_catalog.dart --sets base1 --out my_seed.sql
//
// EVERY set and card in the API (about 20,000 cards):
//
//   dart run tools/import_catalog.dart --all --split supabase/seed
//       Writes numbered files (seed_001.sql, seed_002.sql, ...) of at most
//       ~1 MB each, so each can be pasted into the SQL editor. Run them in
//       order (the first one also contains all the sets).
//
//   SUPABASE_URL=... SUPABASE_SECRET_KEY=... dart run tools/import_catalog.dart --all --push
//       Uploads straight to your database, no pasting. The secret (service
//       role) key stays on your computer; never put it in the app.
//       (PowerShell: $env:SUPABASE_URL="..."; $env:SUPABASE_SECRET_KEY="...")
//
//   Add --resume to skip sets already uploaded by a previous --push run
//   (progress is kept in tools/.import_progress.json).
//
// Then paste the generated file into the Supabase SQL editor and run it.
// Running it again later refreshes prices (rows are upserted by id).
//
// Uses only Dart's built-in libraries, so there is nothing to install.
// An API key is optional but gives higher rate limits: set the
// POKEMONTCG_API_KEY environment variable.
//
// Find set ids at https://api.pokemontcg.io/v2/sets. The early sets are
// base1 (Base Set), base2 (Jungle) and base3 (Fossil).

import 'dart:convert';
import 'dart:io';

const _api = 'https://api.pokemontcg.io/v2';

/// Wording the app already uses for a set, if it differs from the API's.
const _setNameOverrides = {'base1': 'Base Set'};

const _appTypes = {
  'colorless', 'grass', 'fire', 'water', 'lightning', 'fighting', 'psychic',
  'darkness', 'metal', 'dragon', 'fairy',
};

/// The app groups rarities into fixed tiers (kRarityOptions in the Dart app).
String normalizeRarity(String? raw) {
  final r = (raw ?? '').trim().toLowerCase();
  if (r == 'common') return 'Common';
  if (r == 'uncommon') return 'Uncommon';
  if (r == 'rare' || r == 'rare holo') return 'Rare';
  if (r == 'double rare') return 'Double Rare';
  if (r == 'illustration rare') return 'Illustration Rare';
  if (r == 'special illustration rare') return 'Special Illustration Rare';
  if (r == 'hyper rare' || r == 'rare secret' || r == 'rare rainbow') {
    return 'Hyper Rare';
  }
  if (r.startsWith('promo')) return 'Promo';
  return 'Other/Additional Rarities';
}

String mapSupertype(String? raw) {
  final s = (raw ?? '').toLowerCase();
  if (s.startsWith('trainer')) return 'trainer';
  if (s.startsWith('energy')) return 'energy';
  return 'pokemon';
}

String mapType(Map<String, dynamic> card, String supertype) {
  final types = (card['types'] as List?)?.cast<String>() ?? const [];
  final first = types.isEmpty ? '' : types.first.toLowerCase();
  if (_appTypes.contains(first)) return first;
  if (supertype == 'energy') {
    // Basic energy cards name their type: "Fire Energy".
    final word = (card['name'] as String).split(' ').first.toLowerCase();
    if (_appTypes.contains(word)) return word;
  }
  return 'colorless';
}

String? mapSubtype(Map<String, dynamic> card, String supertype) {
  final subtypes = (card['subtypes'] as List?)?.cast<String>() ?? const [];
  if (supertype == 'energy') {
    return subtypes.contains('Basic') ? 'Basic' : 'Special';
  }
  if (supertype == 'trainer') {
    for (final s in const ['Item', 'Supporter', 'Stadium']) {
      if (subtypes.contains(s)) return s;
    }
    return subtypes.isNotEmpty ? 'Item' : null; // tools, TMs… count as items
  }
  return subtypes.isEmpty ? null : subtypes.first;
}

/// "2025/10/03" -> "2025-10-03"; anything unparseable -> null.
String? toIsoDate(Object? value) {
  if (value is! String) return null;
  final m = RegExp(r'^(\d{4})[/-](\d{2})[/-](\d{2})').firstMatch(value);
  return m == null ? null : '${m[1]}-${m[2]}-${m[3]}';
}

// Several printings can be priced (normal, holofoil, reverse…). Prefer the
// plain one, since that is the usual copy; fall back to whatever is listed.
const _priceOrder = [
  'normal', 'unlimitedNormal', 'holofoil', 'unlimitedHolofoil',
  'reverseHolofoil', '1stEditionNormal', '1stEditionHolofoil',
];

({num? usd, String? updated}) pickPrice(Map<String, dynamic> card) {
  final tcg = card['tcgplayer'] as Map<String, dynamic>?;
  final prices = tcg?['prices'] as Map<String, dynamic>?;
  if (prices == null) return (usd: null, updated: null);
  for (final key in [..._priceOrder, ...prices.keys]) {
    final market = (prices[key] as Map<String, dynamic>?)?['market'];
    if (market is num) return (usd: market, updated: toIsoDate(tcg!['updatedAt']));
  }
  return (usd: null, updated: null);
}

// ---- SQL building ---------------------------------------------------------

String _q(Object? v) {
  if (v == null || v == '') return 'null';
  return "'${v.toString().replaceAll("'", "''")}'";
}

String _n(Object? v) => v is num && v.isFinite ? v.toString() : 'null';

String setRow(Map<String, dynamic> set) {
  final id = set['id'] as String;
  final name = _setNameOverrides[id] ?? set['name'];
  final images = set['images'] as Map<String, dynamic>?;
  return '(${_q(id)}, ${_q(name)}, ${_q(set['series'] ?? '')}, '
      '${_n(set['printedTotal'])}, ${_n(set['total'])}, '
      '${_q(toIsoDate(set['releaseDate']))}, ${_q(images?['logo'])}, '
      '${_q(images?['symbol'])})';
}

String cardRow(Map<String, dynamic> card) {
  final supertype = mapSupertype(card['supertype'] as String?);
  final price = pickPrice(card);
  final images = card['images'] as Map<String, dynamic>?;
  final set = card['set'] as Map<String, dynamic>;
  return '(${[
    _q(card['id']), _q(set['id']), _q(card['number']), _q(card['name']),
    _q(supertype), _q(mapSubtype(card, supertype)), _q(mapType(card, supertype)),
    _q(normalizeRarity(card['rarity'] as String?)), _q(card['rarity']),
    _q(images?['small']), _q(images?['large']), _n(price.usd), _q(price.updated),
  ].join(', ')})';
}

List<String> _insertStatements(
    String table, List<String> columns, List<String> rows,
    {int batch = 200}) {
  final updates = columns
      .where((c) => c != 'id')
      .map((c) => '$c = excluded.$c')
      .join(', ');
  final out = <String>[];
  for (var i = 0; i < rows.length; i += batch) {
    final end = i + batch > rows.length ? rows.length : i + batch;
    out.add('insert into public.$table (${columns.join(', ')}) values\n'
        '${rows.sublist(i, end).join(',\n')}\n'
        'on conflict (id) do update set $updates;\n');
  }
  return out;
}

String buildSql(List<Map<String, dynamic>> sets, List<Map<String, dynamic>> cards) {
  return [
    '-- Generated by tools/import_catalog.dart — safe to run again (upserts by id).',
    '-- ${sets.length} set(s), ${cards.length} card(s).',
    ..._insertStatements(
      'card_sets',
      ['id', 'name', 'series', 'printed_total', 'total', 'release_date',
        'logo_url', 'symbol_url'],
      sets.map(setRow).toList(),
    ),
    ..._insertStatements(
      'card_catalog',
      ['id', 'set_id', 'number', 'name', 'supertype', 'subtype', 'type',
        'rarity', 'rarity_raw', 'image_small', 'image_large',
        'market_price_usd', 'price_updated_at'],
      cards.map(cardRow).toList(),
    ),
  ].join('\n');
}

// ---- fetching -------------------------------------------------------------

/// A 404 means the id is wrong; retrying can't fix that.
class _NotFound implements Exception {
  final String url;
  const _NotFound(this.url);
  @override
  String toString() => 'Not found: $url\n'
      'Check the set id against https://api.pokemontcg.io/v2/sets '
      '(for example Jungle is base2, not jungle).';
}

Future<Map<String, dynamic>> _getJson(String url, {int tries = 8}) async {
  final key = Platform.environment['POKEMONTCG_API_KEY'];
  for (var attempt = 1;; attempt++) {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
    try {
      final req = await client.getUrl(Uri.parse(url));
      if (key != null && key.isNotEmpty) req.headers.set('X-Api-Key', key);
      final res = await req.close().timeout(const Duration(seconds: 90));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode == 404) throw _NotFound(url);
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      return jsonDecode(body) as Map<String, dynamic>;
    } on _NotFound {
      rethrow;
    } catch (e) {
      if (attempt >= tries) throw Exception('$url failed: $e');
      final wait = Duration(milliseconds: 1500 * (attempt > 4 ? 4 : attempt));
      stderr.writeln('  retrying in ${wait.inMilliseconds} ms ($e)');
      await Future<void>.delayed(wait);
    } finally {
      client.close(force: true);
    }
  }
}

Future<Map<String, dynamic>> _fetchSet(String id) async {
  final body = await _getJson('$_api/sets/${Uri.encodeComponent(id)}');
  return body['data'] as Map<String, dynamic>;
}

Future<List<Map<String, dynamic>>> _fetchCards(String setId) async {
  final all = <Map<String, dynamic>>[];
  for (var page = 1;; page++) {
    final q = Uri.encodeQueryComponent('set.id:$setId');
    final body = await _getJson('$_api/cards?q=$q&page=$page&pageSize=250');
    final data = (body['data'] as List).cast<Map<String, dynamic>>();
    all.addAll(data);
    if (all.length >= (body['totalCount'] as num) || data.isEmpty) break;
  }
  return all;
}

Future<List<Map<String, dynamic>>> _fetchAllSets() async {
  final all = <Map<String, dynamic>>[];
  for (var page = 1;; page++) {
    final body =
        await _getJson('$_api/sets?page=$page&pageSize=250&orderBy=releaseDate');
    final data = (body['data'] as List).cast<Map<String, dynamic>>();
    all.addAll(data);
    if (all.length >= (body['totalCount'] as num) || data.isEmpty) break;
  }
  return all;
}

/// Splits statements into pieces of at most [maxBytes] of SQL, keeping each
/// insert statement whole.
List<List<String>> chunkSql(List<String> statements, {int maxBytes = 1000000}) {
  final files = <List<String>>[];
  var current = <String>[];
  var size = 0;
  for (final st in statements) {
    final len = utf8.encode(st).length;
    if (size + len > maxBytes && current.isNotEmpty) {
      files.add(current);
      current = <String>[];
      size = 0;
    }
    current.add(st);
    size += len;
  }
  if (current.isNotEmpty) files.add(current);
  return files;
}

Map<String, dynamic> setJson(Map<String, dynamic> set) {
  final id = set['id'] as String;
  final images = set['images'] as Map<String, dynamic>?;
  return {
    'id': id,
    'name': _setNameOverrides[id] ?? set['name'],
    'series': set['series'] ?? '',
    'printed_total': set['printedTotal'],
    'total': set['total'],
    'release_date': toIsoDate(set['releaseDate']),
    'logo_url': images?['logo'],
    'symbol_url': images?['symbol'],
  };
}

Map<String, dynamic> cardJson(Map<String, dynamic> card) {
  final supertype = mapSupertype(card['supertype'] as String?);
  final price = pickPrice(card);
  final images = card['images'] as Map<String, dynamic>?;
  final set = card['set'] as Map<String, dynamic>;
  return {
    'id': card['id'],
    'set_id': set['id'],
    'number': card['number'],
    'name': card['name'],
    'supertype': supertype,
    'subtype': mapSubtype(card, supertype),
    'type': mapType(card, supertype),
    'rarity': normalizeRarity(card['rarity'] as String?),
    'rarity_raw': card['rarity'],
    'image_small': images?['small'],
    'image_large': images?['large'],
    'market_price_usd': price.usd,
    'price_updated_at': price.updated,
  };
}

Future<void> _pushRows(String table, List<Map<String, dynamic>> rows,
    {int batch = 500}) async {
  final base = Platform.environment['SUPABASE_URL']?.replaceAll(RegExp(r'/$'), '');
  final key = Platform.environment['SUPABASE_SECRET_KEY'];
  if (base == null || base.isEmpty || key == null || key.isEmpty) {
    stderr.writeln(
        '--push needs SUPABASE_URL and SUPABASE_SECRET_KEY in the environment.');
    exit(1);
  }
  for (var i = 0; i < rows.length; i += batch) {
    final end = i + batch > rows.length ? rows.length : i + batch;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
    try {
      final req = await client
          .postUrl(Uri.parse('$base/rest/v1/$table?on_conflict=id'));
      req.headers
        ..set('apikey', key)
        ..set('Authorization', 'Bearer $key')
        ..set('Content-Type', 'application/json')
        ..set('Prefer', 'resolution=merge-duplicates,return=minimal');
      req.add(utf8.encode(jsonEncode(rows.sublist(i, end))));
      final res = await req.close().timeout(const Duration(seconds: 120));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('$table upload failed: HTTP ${res.statusCode} $body');
      }
    } finally {
      client.close(force: true);
    }
  }
}

Future<void> main(List<String> args) async {
  String? flag(String name) {
    final i = args.indexOf(name);
    return i == -1 || i + 1 >= args.length ? null : args[i + 1];
  }

  final all = args.contains('--all');
  final push = args.contains('--push');
  final resume = args.contains('--resume');
  final splitPrefix = flag('--split');
  var ids = (flag('--sets') ?? '')
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final out = flag('--out') ?? 'supabase/seed_catalog.sql';
  if (ids.isEmpty && !all) {
    stderr.writeln('Usage: dart run tools/import_catalog.dart '
        '(--sets base1,base2 | --all) '
        '[--out file.sql | --split prefix | --push] [--resume]');
    exit(1);
  }

  var sets = <Map<String, dynamic>>[];
  if (all) {
    stderr.writeln('Listing every set…');
    sets = await _fetchAllSets();
    ids = sets.map((s) => s['id'] as String).toList();
    stderr.writeln('  ${ids.length} sets');
  }

  const progressPath = 'tools/.import_progress.json';
  final done = <String>{};
  final progressFile = File(progressPath);
  if (resume && progressFile.existsSync()) {
    done.addAll((jsonDecode(progressFile.readAsStringSync()) as List).cast<String>());
  }

  final cards = <Map<String, dynamic>>[];
  var total = 0;
  for (final id in ids) {
    if (push && done.contains(id)) {
      stderr.writeln('Skipping $id (already pushed)');
      continue;
    }
    stderr.writeln('Fetching $id…');
    final Map<String, dynamic> set;
    if (all) {
      set = sets.firstWhere((s) => s['id'] == id);
    } else {
      set = await _fetchSet(id);
      sets.add(set);
    }
    final setCards = await _fetchCards(id);
    stderr.writeln('  ${setCards.length} cards');
    total += setCards.length;
    if (push) {
      // The set first, so the cards' foreign key is satisfied.
      await _pushRows('card_sets', [setJson(set)]);
      await _pushRows('card_catalog', setCards.map(cardJson).toList());
      done.add(id);
      progressFile.writeAsStringSync(jsonEncode(done.toList()));
    } else {
      cards.addAll(setCards);
    }
  }

  if (push) {
    stderr.writeln('Uploaded $total card(s).');
    return;
  }

  if (splitPrefix != null) {
    final statements = [
      ..._insertStatements(
        'card_sets',
        ['id', 'name', 'series', 'printed_total', 'total', 'release_date',
          'logo_url', 'symbol_url'],
        sets.map(setRow).toList(),
      ),
      ..._insertStatements(
        'card_catalog',
        ['id', 'set_id', 'number', 'name', 'supertype', 'subtype', 'type',
          'rarity', 'rarity_raw', 'image_small', 'image_large',
          'market_price_usd', 'price_updated_at'],
        cards.map(cardRow).toList(),
      ),
    ];
    final files = chunkSql(statements);
    for (var i = 0; i < files.length; i++) {
      final name = '${splitPrefix}_${(i + 1).toString().padLeft(3, '0')}.sql';
      final file = File(name);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
          '-- Part ${i + 1} of ${files.length}. Run the parts in order.\n'
          '${files[i].join('\n')}');
      stderr.writeln('Wrote $name');
    }
    stderr.writeln(
        '${sets.length} set(s), ${cards.length} card(s) in ${files.length} file(s).');
    return;
  }

  final file = File(out);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(buildSql(sets, cards));
  stderr.writeln('Wrote $out');
}