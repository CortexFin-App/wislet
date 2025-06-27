# Flutter-specific rules.
-dontwarn io.flutter.embedding.**
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.webkit.** { *; }
-keep class io.flutter.embedding.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Rules for local_auth plugin
-keep class androidx.appcompat.app.AppCompatDialogFragment
-keep class androidx.fragment.app.Fragment
-keep class androidx.fragment.app.DialogFragment
-keep class androidx.fragment.app.FragmentActivity

# Rules for Google ML Kit
-keep public class com.google.mlkit.** {*;}
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }

# Rules for Google Play Core library (specific and broad)
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep public class com.google.android.play.core.** { *; }

# General rules for Google Play Services to prevent warnings
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.common.api.** { *; }
-keep class com.google.android.gms.tasks.** { *; }