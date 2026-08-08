// lib/services/profile_service.dart

import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/core/identity/firebase_current_user_identity_port.dart';
import 'package:jyotishasha_app/core/repositories/implementations/firestore_profile_repository.dart';

class ProfileService {
  ProfileService()
    : _currentUserIdentity = FirebaseCurrentUserIdentityPort(),
      _profileRepository = FirestoreProfileRepository();

  final CurrentUserIdentityPort _currentUserIdentity;
  final FirestoreProfileRepository _profileRepository;

  /// Add a new profile.
  Future<String?> addProfile(Map<String, dynamic> data) async {
    final uid = _currentUserIdentity.currentFirebaseUid;
    if (uid == null) return null;
    return _profileRepository.addProfileCompat(firebaseUid: uid, data: data);
  }

  /// Fetch all profiles.
  Future<List<Map<String, dynamic>>> getProfiles() async {
    final uid = _currentUserIdentity.currentFirebaseUid;
    if (uid == null) return [];
    return _profileRepository.getProfilesCompat(uid);
  }

  /// Fetch the active profile.
  Future<Map<String, dynamic>?> getActiveProfile() async {
    final uid = _currentUserIdentity.currentFirebaseUid;
    if (uid == null) return null;
    return _profileRepository.getActiveProfileCompat(uid);
  }

  /// Set the active profile.
  Future<void> setActiveProfile(String profileId) async {
    final uid = _currentUserIdentity.currentFirebaseUid;
    if (uid == null) return;
    await _profileRepository.setActiveProfile(
      firebaseUid: uid,
      profileId: profileId,
    );
  }

  /// Delete a profile.
  Future<bool> deleteProfile(String profileId) async {
    final uid = _currentUserIdentity.currentFirebaseUid;
    if (uid == null) return false;
    return _profileRepository.deleteProfile(
      firebaseUid: uid,
      profileId: profileId,
    );
  }

  /// Update a profile.
  Future<bool> updateProfile(
    String profileId,
    Map<String, dynamic> data,
  ) async {
    final uid = _currentUserIdentity.currentFirebaseUid;
    if (uid == null) return false;
    return _profileRepository.updateProfileCompat(
      firebaseUid: uid,
      profileId: profileId,
      data: data,
    );
  }
}
