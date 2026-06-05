# WorkManager: classes instantiated via reflection
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class * extends androidx.room.RoomDatabase { *; }

# WorkManager Flutter plugin
-keep class be.tramckrijte.workmanager.** { *; }

# Flutter local notifications
-keep class com.dexterous.** { *; }
