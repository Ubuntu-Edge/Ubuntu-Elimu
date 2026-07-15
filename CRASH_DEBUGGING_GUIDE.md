# Ubuntu Elimu Crash Debugging Guide

## What Was Fixed

Your app was experiencing **10+ silent crashes per week** due to three main architectural issues. Here's what was implemented to fix them:

### 1. ✅ Crash Monitoring System
- **Firebase Crashlytics** integration for cloud-based crash tracking
- **Local CrashLoggerService** for offline crash logging (useful when Firebase is unavailable)
- Device information capture (Android version, device model, memory info)
- Detailed stack traces and context for each crash

### 2. ✅ Memory Management - Document Processing
- **Moved PDF/DOCX extraction to background isolates** (was happening on main thread, causing OOM)
- **Text chunking now runs in separate isolate** (prevents UI freezing)
- Proper cleanup and disposal of large objects after processing
- 30-second timeout protection on file extraction operations

### 3. ✅ Error Boundaries & Timeout Protection
- **runZonedGuarded** error boundary in main.dart catches all unhandled exceptions
- **Stream timeout protection** (5-minute max for AI generation)
- **TimeoutException handling** for long-running operations
- Graceful degradation when operations fail

### 4. ✅ Inference Error Handling
- Model loading failures are caught and logged
- OOM errors on native layer are captured
- Inference errors are logged with device context
- Proper stream error handling prevents silent crashes

---

## How to Access Crash Logs

### Option 1: Firebase Console (Recommended)
When Firebase is properly configured, crashes appear in the Firebase Console:
1. Go to **Console.Firebase.Google.com** → Your Project
2. Navigate to **Crashlytics**
3. Filter by "ubuntu_elimu" package name
4. View crash frequency, stack traces, and affected devices

### Option 2: Local Crash Logs
Crashes are also logged locally in Hive database:

```dart
// Add this code to view crashes in your app (e.g., in Settings screen)
import 'package:ubuntu_elimu/services/crash_logger_service.dart';

// Get all crashes
final crashes = CrashLoggerService.instance.getAllCrashes();
print('Total crashes logged: ${CrashLoggerService.instance.getCrashCount()}');

// Export as JSON for analysis
final json = await CrashLoggerService.instance.exportCrashesAsJson();
print(json);

// Clear logs
await CrashLoggerService.instance.clearCrashes();
```

### Option 3: Logcat (Real-time on Device)
Connect your device and monitor crashes in real-time:

```bash
# Terminal: Android Device Logging
adb logcat *:E | grep -i ubuntu_elimu

# Shows: native crashes, OOM, ANR (Application Not Responding)
# Useful for catching crashes that happen silently in background
```

---

## Understanding the Crash Context

Each crash log includes:

```json
{
  "timestamp": "2024-01-15T10:23:45.123Z",
  "message": "Document processing failed",
  "error": "Out of memory",
  "stackTrace": "... full stack ...",
  "context": {
    "documentName": "large_pdf.pdf",
    "type": "DocType.pdf",
    "modelName": "Llama 3.2",
    "contextSize": 2048
  },
  "deviceInfo": {
    "platform": "Android",
    "version": "14 (API 34)",
    "device": "Samsung SM-A145F",
    "totalMemory": "MemTotal:        3900000 kB",
    "availableMemory": "MemAvailable:    1200000 kB"
  }
}
```

### Key Fields to Check:
- **message**: What operation was happening when it crashed
- **context**: Domain-specific info (which document, which model, etc.)
- **deviceInfo.availableMemory**: Check if OOM before crash
- **deviceInfo.device**: Identify patterns on specific devices

---

## Common Crash Patterns & Solutions

### Pattern 1: OOM During PDF Processing
**Symptom:** Crash when processing large PDFs (>50MB)

**Solution (Already Implemented):**
- Documents now extract in background isolate (not on main thread)
- Isolate automatically cleaned up after completion
- 30s timeout prevents hanging

**To Further Optimize:**
```dart
// Reduce chunk size for very large documents
final chunks = await DocumentProcessingIsolate.chunkTextInIsolate(
  rawText,
  chunkSize: 300,  // Reduced from 500
  overlap: 25,     // Reduced from 50
);
```

### Pattern 2: OOM During Model Inference
**Symptom:** Crash during chat generation with large context

**Solution (Already Implemented):**
- Model loading checks available memory first
- 5-minute generation timeout prevents hanging
- Errors are caught and logged

**To Further Optimize:**
```dart
// In OfflineModelProvider, reduce context size on low-memory devices
await OfflineAIService.instance.loadModel(
  modelPath: modelPath,
  model: model,
  contextParams: OfflineContextParams(
    nCtx: 1024,  // Reduced from 2048 for low-RAM devices
    nThreads: 2, // Reduced from 4
  ),
);
```

### Pattern 3: Background Isolate Crash
**Symptom:** App crashes silently in background (not seen by user)

**Solution (Already Implemented):**
- `PlatformDispatcher.instance.onError` catches isolate errors
- `runZonedGuarded` catches async errors

---

## Testing the Crash System

### Test 1: Verify Crash Logging Works
```dart
// In a test button or debug screen
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:ubuntu_elimu/services/crash_logger_service.dart';

// Simulate a crash
try {
  throw Exception('Test crash - can be deleted');
} catch (e, stackTrace) {
  FirebaseCrashlytics.instance.recordError(e, stackTrace);
  CrashLoggerService.instance.logCrash(
    message: 'Test error',
    error: e,
    stackTrace: stackTrace,
  );
}
```

### Test 2: Trigger PDF Processing Stress Test
```dart
// Try uploading a large PDF to verify isolate handling
// Monitor logcat for: "✅ [Isolate] Extracted PDF text"
```

### Test 3: Check Device Memory
```bash
adb shell "cat /proc/meminfo"
# Look for: MemAvailable
# If < 500MB before crash, it's an OOM issue
```

---

## Next Steps for Production

1. **Enable Firebase in google-services.json**
   - Add Firebase project ID to `android/app/google-services.json`
   - Enable Crashlytics in Firebase Console

2. **Monitor the Crash Dashboard**
   - Check daily for new crash patterns
   - Pay attention to "New Issues" tab

3. **Set Up Alerts** (Optional)
   - Firebase: Create alerts for crash rate spikes
   - Create a debug screen to view local crashes in app

4. **Update Model Context Limits**
   - If crashes persist on specific devices, reduce context size
   - Test on low-RAM devices (< 2GB available)

---

## Files Modified

### New Files Created:
- `lib/services/crash_logger_service.dart` - Local crash logging
- `lib/services/document_processing_isolate.dart` - Background PDF/DOCX processing

### Files Updated:
- `lib/main.dart` - Added Firebase init, error boundaries, runZonedGuarded
- `lib/providers/document_provider.dart` - Uses isolates for extraction
- `lib/providers/chat_provider.dart` - Added timeout, error logging
- `lib/services/offline_ai_service.dart` - Added crash reporting
- `pubspec.yaml` - Added firebase_core, firebase_crashlytics, device_info_plus

---

## Debugging Tips

### Tip 1: Check Logcat for Native Crashes
```bash
adb logcat | grep -E "E.*FATAL|E.*SIGSEGV|E.*SIGABRT"
```
These indicate native/JNI crashes from llama_flutter_android

### Tip 2: Monitor Memory in Real-Time
```bash
adb shell "watch -n 1 'cat /proc/meminfo | grep MemAvailable'"
```

### Tip 3: Enable Verbose Logging
All crash-related logs include emojis for easy filtering:
- 🔄 = Processing started
- ✅ = Success
- ❌ = Error
- 💾 = Logged to crash database
- ⏱️ = Timeout
- 🛑 = Stopped by user

Filter: `adb logcat | grep -E "🔄|✅|❌|💾|⏱️|🛑"`

---

## Contact/Support

If crashes persist after these fixes:
1. Check the crash logs with context
2. Verify device has > 1GB free memory before loading models
3. Test with smaller PDFs/documents first
4. Report with logcat output + crash JSON from local logs

**Common Fix:** Most crashes are resolved by:
- Clearing app cache: `adb shell pm clear com.ubuntu.elimu`
- Restarting device
- Reducing model context size
- Processing smaller documents first
