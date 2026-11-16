# Release (R8) keep rules.

# Google Mobile Ads starts WorkManager at launch through androidx.startup.
# WorkManager creates its Room database by reflection
# (WorkDatabase -> WorkDatabase_Impl), so R8 can't see that the generated
# class is used and strips it, crashing every release build on startup with
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
