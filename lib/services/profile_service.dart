// lib/services/profile_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// 🔹 Add New Profile
  Future<String?> addProfile(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final userRef = _db.collection('users').doc(uid);
    final profiles = userRef.collection('profiles');

    // check number of profiles
    final existing = await profiles.get();

    // If no profiles exist, set this as active
    data['isActive'] = existing.docs.isEmpty;

    final doc = await profiles.add(data);

    // If active, also update root user doc
    if (data['isActive'] == true) {
      await userRef.update({'activeProfileId': doc.id});
    }

    return doc.id;
  }

  /// 🔹 Fetch all profiles
  Future<List<Map<String, dynamic>>> getProfiles() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// 🔹 Fetch Active Profile
  Future<Map<String, dynamic>?> getActiveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();

    final activeId = userDoc.data()?['activeProfileId'];
    if (activeId == null) return null;

    final profileDoc = await userRef.collection('profiles').doc(activeId).get();

    if (!profileDoc.exists) return null;

    return {'id': activeId, ...profileDoc.data()!};
  }

  /// 🔹 Set Active Profile
  Future<void> setActiveProfile(String profileId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userRef = _db.collection('users').doc(uid);
    final profiles = userRef.collection('profiles');

    final all = await profiles.get();

    // 1) Set all inactive
    for (final p in all.docs) {
      await profiles.doc(p.id).update({'isActive': false});
    }

    // 2) Set selected active
    await profiles.doc(profileId).update({'isActive': true});

    // 3) Store in root user document
    await userRef.update({'activeProfileId': profileId});
  }

  /// 🔹 Delete Profile
  Future<bool> deleteProfile(String profileId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final userRef = _db.collection('users').doc(uid);
    final profiles = userRef.collection('profiles');

    await profiles.doc(profileId).delete();

    // If active → remove from root
    final userDoc = await userRef.get();
    if (userDoc.data()?['activeProfileId'] == profileId) {
      await userRef.update({'activeProfileId': null});
    }

    return true;
  }

  /// 🔹 UPDATE PROFILE  ⭐ (YAHI MISSING THA)
  Future<bool> updateProfile(
    String profileId,
    Map<String, dynamic> data,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final userRef = _db.collection('users').doc(uid);
    final profiles = userRef.collection('profiles');

    await profiles.doc(profileId).update(data);

    return true;
  }
}
