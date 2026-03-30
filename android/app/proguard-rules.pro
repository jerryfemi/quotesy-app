# Keep Home Widget provider classes used by the Android launcher.
-keep class com.example.quotes.QuotesyHomeWidgetProvider { *; }
-keep class es.antonborri.home_widget.** { *; }

# Keep Flutter entry points and Android components.
-keep class io.flutter.embedding.** { *; }
-dontwarn es.antonborri.home_widget.**
