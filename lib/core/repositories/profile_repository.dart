import '../models/profile/profile.dart';

/// Purpose: owns persisted profiles and active-profile selection.
///
/// Responsibilities: list, read, create, update, delete, and activate profiles
/// for one user through typed ESR-002 contracts.
///
/// Excluded responsibilities: session ownership, Kundali generation, backend
/// transport details, persistence SDK calls, and presentation state.
///
/// Future implementation owner: ESR-003 profile repository implementation.
abstract interface class ProfileRepository {
  Future<List<Profile>> getProfiles(String firebaseUid);

  Future<Profile?> getProfile({
    required String firebaseUid,
    required String profileId,
  });

  Future<Profile?> getActiveProfile(String firebaseUid);

  Future<Profile> createProfile({
    required String firebaseUid,
    required Profile profile,
  });

  Future<Profile> updateProfile({
    required String firebaseUid,
    required Profile profile,
  });

  Future<bool> deleteProfile({
    required String firebaseUid,
    required String profileId,
  });

  Future<void> setActiveProfile({
    required String firebaseUid,
    required String profileId,
  });
}
