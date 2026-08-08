import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/profile/profile.dart';
import '../profile_repository.dart';

final class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Profile>> getProfiles(String firebaseUid) async {
    final snapshot = await _profiles(
      firebaseUid,
    ).orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map(
          (document) =>
              Profile.fromJson({'id': document.id, ...document.data()}),
        )
        .toList(growable: false);
  }

  @override
  Future<Profile?> getProfile({
    required String firebaseUid,
    required String profileId,
  }) async {
    final snapshot = await _profiles(firebaseUid).doc(profileId).get();
    final data = snapshot.data();
    return snapshot.exists && data != null
        ? Profile.fromJson({'id': snapshot.id, ...data})
        : null;
  }

  @override
  Future<Profile?> getActiveProfile(String firebaseUid) async {
    final user = await _users.doc(firebaseUid).get();
    final activeId =
        user.data()?['activeProfileId'] ?? user.data()?['active_profile_id'];
    if (activeId == null) return null;
    return getProfile(firebaseUid: firebaseUid, profileId: activeId.toString());
  }

  Future<String> addProfileCompat({
    required String firebaseUid,
    required Map<String, dynamic> data,
  }) async {
    final userRef = _users.doc(firebaseUid);
    final profiles = _profiles(firebaseUid);
    final existing = await profiles.get();
    data['isActive'] = existing.docs.isEmpty;
    _normalizeLegacyBackendProfileId(data);

    final document = await profiles.add(data);

    if (data['isActive'] == true) {
      await userRef.update({'activeProfileId': document.id});
    }

    return document.id;
  }

  Future<List<Map<String, dynamic>>> getProfilesCompat(String firebaseUid) async {
    final snapshot = await _profiles(
      firebaseUid,
    ).orderBy('createdAt', descending: true).get();

    return snapshot.docs
        .map((document) => {'id': document.id, ...document.data()})
        .toList(growable: false);
  }

  Future<Map<String, dynamic>?> getActiveProfileCompat(String firebaseUid) async {
    final userRef = _users.doc(firebaseUid);
    final userDoc = await userRef.get();
    final activeId = userDoc.data()?['activeProfileId'];
    if (activeId == null) return null;

    final profileDoc = await _profiles(firebaseUid).doc(activeId).get();
    final data = profileDoc.data();
    if (!profileDoc.exists || data == null) return null;

    return {'id': activeId, ...data};
  }

  Future<bool> updateProfileCompat({
    required String firebaseUid,
    required String profileId,
    required Map<String, dynamic> data,
  }) async {
    _normalizeLegacyBackendProfileId(data);
    await _profiles(firebaseUid).doc(profileId).update(data);
    return true;
  }

  @override
  Future<Profile> createProfile({
    required String firebaseUid,
    required Profile profile,
  }) async {
    final profiles = _profiles(firebaseUid);
    final existing = await profiles.get();
    final isActive = existing.docs.isEmpty;
    final data = {...profile.toJson(), 'isActive': isActive}..remove('id');
    final document = profile.id == null || profile.id!.isEmpty
        ? await profiles.add(data)
        : profiles.doc(profile.id);
    if (profile.id != null && profile.id!.isNotEmpty) {
      await document.set(data);
    }
    if (isActive) {
      await _users.doc(firebaseUid).update({'activeProfileId': document.id});
    }
    return profile.copyWith(id: document.id);
  }

  @override
  Future<Profile> updateProfile({
    required String firebaseUid,
    required Profile profile,
  }) async {
    final profileId = profile.id;
    if (profileId == null || profileId.isEmpty) {
      throw ArgumentError.value(profileId, 'profile.id');
    }
    final data = profile.toJson()..remove('id');
    await _profiles(firebaseUid).doc(profileId).update(data);
    return profile;
  }

  @override
  Future<bool> deleteProfile({
    required String firebaseUid,
    required String profileId,
  }) async {
    final user = _users.doc(firebaseUid);
    await _profiles(firebaseUid).doc(profileId).delete();
    final snapshot = await user.get();
    if (snapshot.data()?['activeProfileId'] == profileId) {
      await user.update({'activeProfileId': null});
    }
    return true;
  }

  @override
  Future<void> setActiveProfile({
    required String firebaseUid,
    required String profileId,
  }) async {
    final profiles = _profiles(firebaseUid);
    final all = await profiles.get();
    for (final profile in all.docs) {
      await profile.reference.update({'isActive': false});
    }
    await profiles.doc(profileId).update({'isActive': true});
    await _users.doc(firebaseUid).update({'activeProfileId': profileId});
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _profiles(String firebaseUid) =>
      _users.doc(firebaseUid).collection('profiles');

  void _normalizeLegacyBackendProfileId(Map<String, dynamic> data) {
    if (data.containsKey('backendProfileId')) {
      data['backend_profile_id'] = data['backendProfileId'];
      data.remove('backendProfileId');
    }
  }
}
