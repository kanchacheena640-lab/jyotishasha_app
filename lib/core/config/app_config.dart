// lib/core/config/app_config.dart

/// N6 QA infrastructure — the SINGLE authoritative Jyotishasha backend base
/// URL. Every repository/service/provider that previously hardcoded
/// `https://jyotishasha-backend.onrender.com` now reads it from here
/// instead — one source of truth, not a second competing config system
/// (no `AppConfig`/`Environment`/flavor/`--dart-define` layer existed
/// anywhere in this app before this file; `.env`/flutter_dotenv is
/// confirmed dead code elsewhere, see GoogleMapsConfig's own docstring).
///
/// [String.fromEnvironment] is resolved at COMPILE time, from a
/// `--dart-define=BACKEND_URL=...` flag passed to `flutter run`/`build`.
/// A normal build/run with NO such flag gets exactly [defaultValue] --
/// the real, unchanged production backend -- so every existing build
/// pipeline, CI job, and release artifact behaves identically to before
/// this file existed. There is no debug-mode auto-detection and no
/// automatic localhost selection: pointing at a local backend is always
/// an explicit, deliberate opt-in.
///
/// This class does not change, wrap, or validate any endpoint path,
/// request body, auth header, or timeout -- every call site still owns
/// its own path/method/headers exactly as before; only the domain the
/// path is built on top of now comes from here.
class AppConfig {
  const AppConfig._();

  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://jyotishasha-backend.onrender.com',
  );
}
