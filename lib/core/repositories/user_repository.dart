import '../models/user/user.dart';
import '../models/user/user_identity.dart';

/// Purpose: owns application user records and backend user identity linkage.
///
/// Responsibilities: load and persist users, register backend identity,
/// bootstrap profile identity, and persist messaging-token metadata.
///
/// Excluded responsibilities: authentication state, profile CRUD, transport,
/// persistence SDK calls, and presentation state.
///
/// Future implementation owner: ESR-003 user data repository implementation.
abstract interface class UserRepository {
  Future<User?> getUser(String firebaseUid);

  Future<User> saveUser(User user);

  Future<int?> registerBackendUser(UserIdentity identity);

  Future<Map<String, dynamic>> bootstrapProfile(Map<String, dynamic> profileData);

  Future<void> updateMessagingToken({
    required String firebaseUid,
    required String token,
  });
}
