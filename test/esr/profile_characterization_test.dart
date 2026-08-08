import 'package:flutter_test/flutter_test.dart';

import '../helpers/source_characterization.dart';

void main() {
  group('profile ownership characterization', () {
    test('empty, single, active, and other profile decisions stay fixed', () {
      final source = normalizeWhitespace(
        readProjectSource('lib/core/state/profile_provider.dart'),
      );

      expect(source, contains('if (list.length == 1)'));
      expect(source, contains('if (only["isActive"] != true)'));
      expect(source, contains('await _service.setActiveProfile(only["id"]);'));
      expect(source, contains('return loadProfiles();'));
      expect(
        source,
        contains(
          'if (list.isEmpty) { activeProfile = null; otherProfiles = []; '
          'activeProfileId = null;',
        ),
      );
      expect(source, contains('(p) => p["isActive"] == true'));
      expect(source, contains('activeProfileId = activeProfile?["id"];'));
      expect(
        source,
        contains(
          'otherProfiles = list.where((p) => p["isActive"] != true).toList();',
        ),
      );
    });

    test('backend identifier aliases normalize to snake case', () {
      final source = readProjectSource('lib/core/state/profile_provider.dart');

      expectMarkersInOrder(source, const [
        'activeProfile!["backend_user_id"] ??',
        'activeProfile!["backendUserId"] ??',
        'activeProfile!["backendUserID"]',
        'activeProfile!["backend_user_id"] = buid;',
        'activeProfile!["backend_profile_id"] ??',
        'activeProfile!["backendProfileId"] ??',
        'activeProfile!["backendProfileID"]',
        'activeProfile!["backend_profile_id"] = bpid;',
      ]);
    });

    test('first and selected profile activation update root ownership', () {
      final repository = normalizeWhitespace(
        readProjectSource(
          'lib/core/repositories/implementations/'
          'firestore_profile_repository.dart',
        ),
      );

      expect(repository, contains("data['isActive'] = existing.docs.isEmpty;"));
      expect(repository, contains("{'activeProfileId': document.id}"));
      expectMarkersInOrder(repository, const [
        "await profile.reference.update({'isActive': false});",
        "await profiles.doc(profileId).update({'isActive': true});",
        "await _users.doc(firebaseUid).update({'activeProfileId': profileId});",
      ]);
    });

    test('deleting active profile clears root id and mutations reload', () {
      final service = normalizeWhitespace(
        readProjectSource(
          'lib/core/repositories/implementations/'
          'firestore_profile_repository.dart',
        ),
      );
      final provider = normalizeWhitespace(
        readProjectSource('lib/core/state/profile_provider.dart'),
      );

      expectMarkersInOrder(service, const [
        'await _profiles(firebaseUid).doc(profileId).delete();',
        "if (snapshot.data()?['activeProfileId'] == profileId)",
        "await user.update({'activeProfileId': null});",
      ]);
      expect('await loadProfiles();'.allMatches(provider), hasLength(6));
    });

    test('profile service uses approved post-migration boundaries', () {
      final source = readProjectSource('lib/services/profile_service.dart');

      expect(source, contains('CurrentUserIdentityPort'));
      expect(source, contains('FirestoreProfileRepository'));
      expect(source, contains('_profileRepository = FirestoreProfileRepository()'));
      expect(source, contains('return _profileRepository.addProfileCompat('));
      expect(source, contains('return _profileRepository.getProfilesCompat(uid);'));
      expect(source, contains('return _profileRepository.getActiveProfileCompat(uid);'));
      expect(source, contains('await _profileRepository.setActiveProfile('));
      expect(source, contains('return _profileRepository.deleteProfile('));
      expect(source, contains('return _profileRepository.updateProfileCompat('));
      expect(source, isNot(contains('ProfileRepositoryAdapter')));
      expect(source, contains('ProfileService()'));
      expect(source, isNot(contains('ProfileService({')));
      expect(source, isNot(contains('FirebaseAuth')));
      expect(source, isNot(contains('FirebaseFirestore')));
    });
  });
}
