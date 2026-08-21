import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../../services/backend_auth_service.dart';
import '../../models/user/user.dart';
import '../../models/user/user_identity.dart';
import '../user_repository.dart';

final class FirebaseUserRepository implements UserRepository {
  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';

  FirebaseUserRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<User?> getUser(String firebaseUid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(firebaseUid)
        .get();
    final data = snapshot.data();
    return snapshot.exists && data != null ? User.fromJson(data) : null;
  }

  @override
  Future<User> saveUser(User user) async {
    final firebaseUid = user.identity?.firebaseUid;
    if (firebaseUid == null || firebaseUid.isEmpty) {
      throw ArgumentError.value(firebaseUid, 'firebaseUid');
    }
    await _firestore
        .collection('users')
        .doc(firebaseUid)
        .set(user.toJson(), SetOptions(merge: true));
    return user;
  }

  @override
  Future<int?> registerBackendUser(UserIdentity identity) {
    final firebaseUid = identity.firebaseUid;
    if (firebaseUid == null || firebaseUid.isEmpty) {
      throw ArgumentError.value(firebaseUid, 'firebaseUid');
    }
    return BackendAuthService.registerFirebaseUser(
      firebaseUid: firebaseUid,
      email: identity.email,
      phone: identity.phone,
      name: identity.name,
    );
  }

  @override
  Future<Map<String, dynamic>> bootstrapProfile(
    Map<String, dynamic> profileData,
  ) async {
    final url = Uri.parse('$_baseUrl/api/user/bootstrap');
    // Release-gate fix (P0): bounds a previously-unbounded request so a
    // stalled backend can no longer hang this await forever. A timeout
    // throws TimeoutException, which propagates to the caller exactly
    // like the existing "Bootstrap failed" Exception below already does
    // -- no new code path, no contract change.
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(profileData),
        )
        .timeout(const Duration(seconds: 12));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception('Bootstrap failed: ${data["error"]}');
    }

    return Map<String, dynamic>.from(data as Map);
  }

  @override
  Future<void> updateMessagingToken({
    required String firebaseUid,
    required String token,
  }) {
    return _firestore.collection('users').doc(firebaseUid).update({
      'fcm_token': token,
      'fcm_updated_at': FieldValue.serverTimestamp(),
    });
  }

}
