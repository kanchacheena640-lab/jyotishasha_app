import 'package:jyotishasha_app/core/repositories/implementations/firebase_user_repository.dart';
import 'package:jyotishasha_app/core/repositories/user_repository.dart';

class UserBootstrapService {
  UserBootstrapService({
    UserRepository? userRepository,
  }) : _userRepository = userRepository ?? FirebaseUserRepository();

  final UserRepository _userRepository;

  Future<Map<String, dynamic>> syncProfile(
    Map<String, dynamic> profileData,
  ) {
    return _userRepository.bootstrapProfile(profileData);
  }
}
