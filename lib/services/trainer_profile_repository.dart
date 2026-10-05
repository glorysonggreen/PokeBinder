import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trainer_profile_data.dart';
import 'sync_status.dart';

class TrainerProfileRepository {
  TrainerProfileRepository._();

  static SupabaseQueryBuilder get _table =>
      Supabase.instance.client.from('trainer_profiles');

  static Future<TrainerProfileData> load({required String fallbackName}) async {
    final row = await _table.select().maybeSingle();
    if (row != null) return TrainerProfileData.fromRow(row);

    final profile = TrainerProfileData(name: fallbackName);
    await upsert(profile);
    return profile;
  }

  static Future<void> upsert(TrainerProfileData profile) {
    return SyncStatus.track(
      'save your profile',
      () => _table.upsert(profile.toRow()),
    );
  }

  static const _avatarBucket = 'avatars';

  static String get _avatarPath =>
      '${Supabase.instance.client.auth.currentUser!.id}/avatar';

  static StorageFileApi get _avatars =>
      Supabase.instance.client.storage.from(_avatarBucket);

  static Future<String> uploadAvatar(Uint8List bytes) async {
    await _avatars.uploadBinary(
      _avatarPath,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
    );
    final version = DateTime.now().millisecondsSinceEpoch;
    return '${_avatars.getPublicUrl(_avatarPath)}?v=$version';
  }

  static Future<void> deleteAvatar() async {
    try {
      await _avatars.remove([_avatarPath]);
    } catch (_) {}
  }
}
