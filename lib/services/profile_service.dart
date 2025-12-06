// lib/services/profile_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// 🔹 Add New Profile (FIXED)
  Future<String?> addProfile(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final userRef = _db.collection('users').doc(uid);
    final profiles = userRef.collection('profiles');

    /// ⭐ AUTO-ACTIVATE FIRST PROFILE
    final existing = await profiles.get();
    data['isActive'] = existing.docs.isEmpty;

    /// ⭐ FIX → Always store backend_profile_id (snake_case)
    if (data.containsKey('backendProfileId')) {
      data['backend_profile_id'] = data['backendProfileId'];
      data.remove('backendProfileId');
    }

    final doc = await profiles.add(data);

    /// ⭐ Update root user doc
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

    // Set all inactive
    for (final p in all.docs) {
      await profiles.doc(p.id).update({'isActive': false});
    }

    // Activate selected
    await profiles.doc(profileId).update({'isActive': true});

    // Store in root document
    await userRef.update({'activeProfileId': profileId});
  }

  /// 🔹 Delete Profile
  Future<bool> deleteProfile(String profileId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final userRef = _db.collection('users').doc(uid);
    final profiles = userRef.collection('profiles');

    await profiles.doc(profileId).delete();

    // Remove active id if deleted
    final userDoc = await userRef.get();
    if (userDoc.data()?['activeProfileId'] == profileId) {
      await userRef.update({'activeProfileId': null});
    }

    return true;
  }

  /// 🔹 UPDATE PROFILE (FIXED)
  Future<bool> updateProfile(
    String profileId,
    Map<String, dynamic> data,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final userRef = _db.collection('users').doc(uid);
    final profiles = userRef.collection('profiles');

    /// ⭐ FIX — convert camelCase → snake_case if needed
    if (data.containsKey('backendProfileId')) {
      data['backend_profile_id'] = data['backendProfileId'];
      data.remove('backendProfileId');
    }

    await profiles.doc(profileId).update(data);

    return true;
  }
}
