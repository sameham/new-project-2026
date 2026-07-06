# Room entities and Gson-serialized backup models are accessed reflectively.
-keep class com.elmahdi.travelsuite.data.local.entity.** { *; }
-keep class com.elmahdi.travelsuite.data.backup.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
