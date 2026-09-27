import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trainer_profile_data.dart';

/// Loads and saves the signed-in user's one row in `trainer_profiles`.
class TrainerProfileRepository {
  TrainerProfileRepository._();

  static SupabaseQueryBuilder get _table =>
      Supabase.instance.client.from('trainer_profiles');

  /// Returns the user's profile, creating one with [fallbackName] the
  /// first time (e.g. right after sign-up, using the trainer name they
  /// entered on the form).
  static Future<TrainerProfileData> load({required String fallbackName}) async {
    final row = await _table.select().maybeSingle();
    if (row != null) return TrainerProfileData.fromRow(row);

    final profile = TrainerProfileData(name: fallbackName);
    await upsert(profile);
    return profile;
  }

  static Future<void> upsert(TrainerProfileData profile) {
    return _table.upsert(profile.toRow());
  }
}
