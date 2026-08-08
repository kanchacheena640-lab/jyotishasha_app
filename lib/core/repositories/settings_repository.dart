/// Purpose: owns persisted application settings.
///
/// Responsibilities: read and write the application language preference while
/// preserving the current nullable/default behavior at the caller boundary.
///
/// Excluded responsibilities: localization rendering, profile preferences,
/// SharedPreferences access, Provider state, and UI notifications.
///
/// Future implementation owner: ESR-003 settings repository implementation.
abstract interface class SettingsRepository {
  Future<String?> getLanguage();

  Future<void> setLanguage(String language);
}
