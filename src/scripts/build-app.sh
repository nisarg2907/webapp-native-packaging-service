#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "🚀 Starting build process for ${APP_NAME}"
set -x

# Validate environment variables
if [[ -z "${APP_NAME}" ]]; then
    echo "❌ Error: APP_NAME is not set"
    exit 1
fi

if [[ -z "${APP_URL}" ]]; then
    echo "❌ Error: APP_URL is not set"
    exit 1
fi

echo "✅ App Name: ${APP_NAME}"
echo "✅ App URL: ${APP_URL}"
echo "✅ App Config: ${APP_CONFIG}"

# Prepare project directory
mkdir -p /app/project
cp -rp /app/native/* /app/project/ || {
    echo "❌ Error: Failed to copy React Native code"
    exit 1
}

cd /app/project || exit 1

# Validate Android project
if [[ ! -d "android" ]]; then
    echo "❌ Error: 'android/' directory missing"
    exit 1
fi

if [[ ! -f "android/settings.gradle" ]]; then
    echo "❌ Error: android/settings.gradle missing"
    exit 1
fi

# Fix gradlew permissions
dos2unix android/gradlew
chmod +x android/gradlew

# Install Node dependencies
npm install --legacy-peer-deps --force || {
    echo "❌ Failed to install dependencies"
    exit 1
}

# Configure Android SDK path
echo "sdk.dir=$ANDROID_HOME" > android/local.properties

# Build Android app
cd android || exit 1
rm -rf build .gradle
./gradlew clean assembleRelease --info --stacktrace --refresh-dependencies || {
    echo "❌ Android build failed"
    exit 1
}

# Copy APK to output
mkdir -p /app/output/android
cp app/build/outputs/apk/release/app-release.apk /app/output/android/ || {
    echo "❌ Failed to copy APK"
    exit 1
}

echo "✅ Build successful! APK: /app/output/android/app-release.apk"