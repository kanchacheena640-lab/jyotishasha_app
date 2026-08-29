// lib/core/constants/google_maps_config.dart

/// Google Maps / Places API key -- CLIENT-PUBLISHABLE by Google's own
/// design, not a server secret. Google's own documented model for this
/// key type is restriction via the Google Cloud Console (Android app
/// restriction: package name + release signing certificate SHA-1
/// fingerprint), never secrecy inside the client -- a Maps/Places key
/// embedded in an app is expected to be recoverable, exactly like this
/// one already was (hardcoded in modules/services/location_service.dart,
/// the app's one real, live Maps/Places integration, since before this
/// remediation).
///
/// Flutter Secret Exposure Remediation: this is now the SINGLE source
/// of truth for that same key -- previously duplicated as a private
/// constant in LocationService AND (separately, and non-functionally --
/// see below) referenced via flutter_dotenv from two dead, unreferenced
/// widgets. Consolidating avoids three copies of the same client key
/// silently drifting apart on a future rotation.
///
/// NOT sourced from flutter_dotenv/.env: `.env` was never actually
/// loaded anywhere in this app (`dotenv.load()` exists nowhere but a
/// commented-out line in main.dart), so `GetAnyoneHoroscopeCard`'s and
/// `PlaceAutocompleteField`'s own `dotenv.env['GOOGLE_MAPS_API_KEY']!`
/// / `dotenv.env['GOOGLE_PLACES_KEY']` reads were already permanently
/// null/throwing dead code, in both currently-unreferenced widgets --
/// confirmed neither is instantiated anywhere else in this codebase.
/// This constant simply gives all three call sites the one real,
/// already-working value LocationService has always actually used.
class GoogleMapsConfig {
  const GoogleMapsConfig._();

  static const String apiKey = 'AIzaSyBxt6et6THD47K936GIXWJ8o-TP65RayOc';
}
