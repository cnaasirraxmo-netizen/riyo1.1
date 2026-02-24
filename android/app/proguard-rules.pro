# Google Cast SDK ProGuard rules
-keep class com.google.android.gms.cast.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.felnanuke.google_cast.** { *; }
-keep class com.riyo.app.** { *; }

# jUPnP / media_cast_dlna rules
-dontwarn org.osgi.**
-dontwarn org.jupnp.**
-keep class org.jupnp.** { *; }
