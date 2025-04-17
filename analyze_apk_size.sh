#!/bin/bash

# Make this script executable with: chmod +x analyze_apk_size.sh

# First, build the APK
flutter build apk --release --target-platform android-arm64

# Navigate to build directory
cd build/app/outputs/flutter-apk/

# Check the size of the APK
echo "APK SIZE ANALYSIS"
echo "================="
ls -lh app-release.apk

# If you have bundletool, you can get more detailed info
if command -v bundletool &> /dev/null; then
    echo ""
    echo "DETAILED APK ANALYSIS"
    echo "====================="
    bundletool analyze-apk --apk=app-release.apk
fi

echo ""
echo "OPTIMIZATION RECOMMENDATIONS"
echo "==========================="
echo "1. Check if all dependencies are needed"
echo "2. Make sure debug code and print statements are removed"
echo "3. Use R8/ProGuard for code shrinking"
echo "4. Optimize images and assets"
echo "5. Consider using app bundles instead of APKs" 