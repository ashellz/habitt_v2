# Picked up by the Flutter Gradle plugin for release builds.

# Home screen widgets (docs/home_widgets.md): Glance tells widget types apart by
# class name (GlanceAppWidgetManager maps receiver -> widget class). Without this
# rule R8 merges the four HabittWidget subclasses into one class, so updateAll()
# on one widget drew it into every widget on the home screen.
-keep class com.shellz.habitt.widgets.** extends androidx.glance.appwidget.GlanceAppWidget { <init>(); }
