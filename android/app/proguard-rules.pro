#############################################
## FLUTTER + FIREBASE + ADS SAFE PROGUARD  ##
#############################################

# --- Flutter engine keep rules ---
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# --- Firebase ---
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# --- Google Play Services (GMS) ---
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# --- Google Mobile Ads ---
-keep class com.google.ads.** { *; }
-dontwarn com.google.ads.**

#############################################
## PLAY CORE / SPLITINSTALL FIX SECTION    ##
#############################################

# Flutter internally uses Play Core, but NOT full API.
# We keep everything so R8 does not strip and break class refs.

-keep class com.google.android.play.** { *; }
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.tasks.** { *; }

# Ignore missing warnings from Play Core (SplitInstall etc.)
-dontwarn com.google.android.play.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.tasks.**

#############################################
## ANDROIDX / LIFECYCLE
#############################################

-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**

#############################################
## KOTLIN + OKHTTP FIX (common warnings)
#############################################

-dontwarn kotlin.**
-dontwarn okhttp3.**

#############################################
## MISC (your app + other libs safe rules)
#############################################

# Keep your app classes
-keep class com.example.jyotishasha_app.** { *; }

# Prevent stripping of models or JSON-mapped classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Fix reflection-based usages
-keepattributes *Annotation*
-keepattributes InnerClasses
