#!/bin/bash
# Quick diagnostic for Ubuntu Elimu model loading issues
# Run: bash check_device_memory.sh

echo "============================================"
echo "Ubuntu Elimu Device Diagnostic Tool"
echo "============================================"
echo ""

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ No Android device connected"
    echo "Please connect your device via USB and enable USB debugging"
    exit 1
fi

echo "✅ Device connected"
echo ""

# Get device info
echo "📱 Device Information:"
MODEL=$(adb shell getprop ro.product.model | tr -d '\r')
ANDROID=$(adb shell getprop ro.build.version.release | tr -d '\r')
echo "   Model: $MODEL"
echo "   Android: $ANDROID"
echo ""

# Get memory info
echo "💾 Memory Status:"
MEMINFO=$(adb shell "cat /proc/meminfo")
TOTAL=$(echo "$MEMINFO" | grep "MemTotal:" | awk '{print $2}')
AVAILABLE=$(echo "$MEMINFO" | grep "MemAvailable:" | awk '{print $2}')

TOTAL_MB=$((TOTAL / 1024))
AVAILABLE_MB=$((AVAILABLE / 1024))
USED_MB=$((TOTAL_MB - AVAILABLE_MB))
USAGE_PERCENT=$(( (USED_MB * 100) / TOTAL_MB ))

echo "   Total RAM:     ${TOTAL_MB} MB"
echo "   Available RAM: ${AVAILABLE_MB} MB"
echo "   Used RAM:      ${USED_MB} MB (${USAGE_PERCENT}%)"
echo ""

# Determine device tier
if [ $TOTAL_MB -lt 2048 ]; then
    TIER="Very Low-End (<2GB)"
    COLOR="🔴"
    RECOMMENDED_CONTEXT=512
    WARNING="⚠️  Your device has very limited RAM. Model loading may fail."
elif [ $TOTAL_MB -lt 3072 ]; then
    TIER="Low-End (2-3GB)"
    COLOR="🟡"
    RECOMMENDED_CONTEXT=512
    WARNING="⚠️  Limited RAM. Close all other apps before loading models."
elif [ $TOTAL_MB -lt 6144 ]; then
    TIER="Mid-Range (3-6GB)"
    COLOR="🟢"
    RECOMMENDED_CONTEXT=1024
    WARNING=""
else
    TIER="High-End (6GB+)"
    COLOR="🚀"
    RECOMMENDED_CONTEXT=2048
    WARNING=""
fi

echo "📊 Device Tier: $COLOR $TIER"
echo "   Recommended Context Size: $RECOMMENDED_CONTEXT"
if [ -n "$WARNING" ]; then
    echo "   $WARNING"
fi
echo ""

# Check if model loading is feasible
echo "🔍 Model Loading Assessment:"
if [ $AVAILABLE_MB -lt 800 ]; then
    echo "   ❌ INSUFFICIENT MEMORY"
    echo "   Available: ${AVAILABLE_MB}MB, Required: 800MB"
    echo ""
    echo "   📋 ACTION REQUIRED:"
    echo "   1. Close ALL other apps"
    echo "   2. Restart your device"
    echo "   3. Try loading model immediately after reboot"
    echo ""
    echo "   Current memory usage is too high for model loading."
elif [ $AVAILABLE_MB -lt 1000 ]; then
    echo "   ⚠️  BORDERLINE MEMORY"
    echo "   Available: ${AVAILABLE_MB}MB, Required: 800MB"
    echo ""
    echo "   📋 RECOMMENDATION:"
    echo "   - Close other apps to increase available RAM"
    echo "   - Model should load with context=512"
    echo "   - Performance may be slow"
elif [ $AVAILABLE_MB -lt 1500 ]; then
    echo "   ✅ SUFFICIENT MEMORY"
    echo "   Available: ${AVAILABLE_MB}MB (Good)"
    echo ""
    echo "   Model should load successfully with context=${RECOMMENDED_CONTEXT}"
else
    echo "   ✅ EXCELLENT MEMORY"
    echo "   Available: ${AVAILABLE_MB}MB (Very Good)"
    echo ""
    echo "   Model should load quickly with optimal settings"
fi
echo ""

# Check app installation
echo "📦 App Status:"
if adb shell pm list packages | grep -q "com.example.ubuntu_elimu"; then
    echo "   ✅ Ubuntu Elimu is installed"
    
    # Get app version
    VERSION=$(adb shell "dumpsys package com.example.ubuntu_elimu | grep versionName" | cut -d'=' -f2 | tr -d '\r')
    echo "   Version: $VERSION"
    
    # Check if app is running
    if adb shell "ps | grep ubuntu_elimu" > /dev/null 2>&1; then
        echo "   🟢 App is currently running"
    else
        echo "   ⚪ App is not running"
    fi
else
    echo "   ❌ Ubuntu Elimu is NOT installed"
    echo "   Run: adb install -r build/app/outputs/flutter-apk/app-release.apk"
fi
echo ""

# Show top memory consuming apps
echo "🔝 Top Memory Consuming Apps:"
adb shell "dumpsys meminfo | head -20 | tail -10"
echo ""

# Final recommendations
echo "============================================"
echo "💡 RECOMMENDATIONS:"
echo "============================================"

if [ $AVAILABLE_MB -lt 800 ]; then
    echo "1. ❗ URGENT: Free up memory NOW"
    echo "   - Close Chrome, Instagram, Facebook, etc."
    echo "   - Restart device for maximum available RAM"
    echo ""
    echo "2. After reboot, run this script again"
    echo ""
    echo "3. If still < 800MB available:"
    echo "   - Consider using cloud inference (Groq API)"
    echo "   - Or upgrade to a device with more RAM"
else
    echo "1. ✅ Memory is sufficient for model loading"
    echo ""
    echo "2. Recommended settings for your device:"
    echo "   - Context Size: $RECOMMENDED_CONTEXT"
    echo "   - Threads: 2"
    echo "   - Use Q4 quantized models"
    echo ""
    echo "3. For best results:"
    echo "   - Close background apps before loading"
    echo "   - Use WiFi (not mobile data) for downloads"
    echo "   - Allow 10-30 seconds for model loading"
fi

echo ""
echo "============================================"
echo "To monitor model loading in real-time:"
echo "  adb logcat | grep -E 'ubuntu_elimu|💾|✅|❌'"
echo "============================================"
