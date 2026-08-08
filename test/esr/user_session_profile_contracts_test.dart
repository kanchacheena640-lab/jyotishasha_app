import 'package:flutter_test/flutter_test.dart';
import 'package:jyotishasha_app/core/models/profile/birth_details.dart';
import 'package:jyotishasha_app/core/models/profile/profile.dart';
import 'package:jyotishasha_app/core/models/profile/profile_settings.dart';
import 'package:jyotishasha_app/core/models/session/authentication_state.dart';
import 'package:jyotishasha_app/core/models/session/session.dart';
import 'package:jyotishasha_app/core/models/session/session_state.dart';
import 'package:jyotishasha_app/core/models/user/user.dart';
import 'package:jyotishasha_app/core/models/user/user_identity.dart';
import 'package:jyotishasha_app/core/models/user/user_preferences.dart';

void main() {
  group('user contracts', () {
    test('parse flat Firestore data and preserve canonical wire keys', () {
      final user = User.fromJson({
        'uid': 'firebase-1',
        'name': 'Asha',
        'email': 'asha@example.com',
        'phone': null,
        'photo': 'photo-url',
        'provider': 'google',
        'activeProfileId': 'profile-1',
        'backend_user_id': '42',
        'fcm_token': 'token',
        'createdAt': '2026-06-28T00:00:00.000Z',
      });

      expect(user.identity?.firebaseUid, 'firebase-1');
      expect(user.identity?.phone, isNull);
      expect(user.preferences?.activeProfileId, 'profile-1');
      expect(user.backendUserId, 42);
      expect(user.toJson(), containsPair('backend_user_id', 42));
      expect(user.toJson(), containsPair('activeProfileId', 'profile-1'));
    });

    test(
      'identity and preferences support value equality and nullable copy',
      () {
        const identity = UserIdentity(email: 'old@example.com');
        const preferences = UserPreferences(language: 'en');

        expect(identity, const UserIdentity(email: 'old@example.com'));
        expect(identity.copyWith(email: null).email, isNull);
        expect(preferences, const UserPreferences(language: 'en'));
        expect(preferences.copyWith(language: 'hi').language, 'hi');
      },
    );
  });

  group('profile contracts', () {
    test('parse aliases and serialize current profile wire names', () {
      final profile = Profile.fromJson({
        'id': 'profile-1',
        'name': 'Asha',
        'date_of_birth': '2000-01-02',
        'time_of_birth': '03:04',
        'placeName': 'Lucknow',
        'latitude': '26.8467',
        'longitude': 80.9462,
        'tz': '+05:30',
        'lang': 'en',
        'is_active': 1,
        'profileComplete': 'true',
        'moonSign': 'Mesha',
        'backendUserID': '7',
        'backendProfileId': 9.0,
      });

      expect(profile.birthDetails?.dateOfBirth, '2000-01-02');
      expect(profile.birthDetails?.latitude, 26.8467);
      expect(profile.settings?.isActive, isTrue);
      expect(profile.settings?.isComplete, isTrue);
      expect(profile.backendUserId, 7);
      expect(profile.backendProfileId, 9);
      expect(profile.toJson(), containsPair('moon_sign', 'Mesha'));
      expect(profile.toJson(), containsPair('backend_profile_id', 9));
    });

    test(
      'nested contracts are immutable values with nullable copy support',
      () {
        const birth = BirthDetails(placeOfBirth: 'Lucknow');
        const settings = ProfileSettings(language: 'en', isActive: false);
        const profile = Profile(
          id: 'profile-1',
          birthDetails: birth,
          settings: settings,
        );

        expect(birth, const BirthDetails(placeOfBirth: 'Lucknow'));
        expect(
          settings,
          const ProfileSettings(language: 'en', isActive: false),
        );
        expect(profile.copyWith(birthDetails: null).birthDetails, isNull);
        expect(profile.copyWith(name: 'Updated').name, 'Updated');
      },
    );
  });

  group('session contracts', () {
    test('parse backend session aliases and nested state', () {
      final session = Session.fromJson({
        'user': {'uid': 'firebase-1', 'backend_user_id': '42'},
        'authentication_state': {
          'authenticated': 1,
          'identity': {'firebase_uid': 'firebase-1'},
        },
        'session_state': {
          'session_status': 'active',
          'isBackendLinked': 'true',
        },
        'user_id': '42',
        'jwt': 'jwt-token',
      });

      expect(session.user?.identity?.firebaseUid, 'firebase-1');
      expect(session.authentication?.isAuthenticated, isTrue);
      expect(session.state?.status, 'active');
      expect(session.state?.isBackendLinked, isTrue);
      expect(session.backendUserId, 42);
      expect(session.backendToken, 'jwt-token');
    });

    test('state contracts support JSON, equality, and copyWith', () {
      const authentication = AuthenticationState(isAuthenticated: true);
      const state = SessionState(status: 'active', isBackendLinked: true);
      const session = Session(
        authentication: authentication,
        state: state,
        backendToken: 'token',
      );

      expect(
        AuthenticationState.fromJson(authentication.toJson()),
        authentication,
      );
      expect(SessionState.fromJson(state.toJson()), state);
      expect(session, session.copyWith());
      expect(session.copyWith(backendToken: null).backendToken, isNull);
    });
  });
}
