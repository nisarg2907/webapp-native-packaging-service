#!/bin/bash
set -e

echo "Starting build process for ${APP_NAME}"

# Enable debug mode
set -x

# Validate required environment variables
if [[ -z "${APP_NAME}" ]]; then
    echo "Error: APP_NAME is not set"
    exit 1
fi

if [[ -z "${APP_URL}" ]]; then
    echo "Error: APP_URL is not set"
    exit 1
fi

# Copy the native code to project directory with preserved permissions
echo "Copying React Native code to project directory..."
cp -rp /app/native/* /app/project/
cd /app/project

# Debug information for project root
echo "Listing project root directory contents:"
ls -la

# Debug information for android directory
echo "Listing android directory contents:"
ls -la android/

# Fix line endings and verify gradlew
echo "Fixing gradlew line endings and permissions..."
if [ -f "android/gradlew" ]; then
    # Convert CRLF to LF if needed
    sed -i 's/\r$//' android/gradlew
    
    # Make sure it's a Unix executable
    dos2unix android/gradlew || true
    
    # Set proper permissions
    chmod +x android/gradlew
    
    # Create wrapper if needed
    echo "Creating gradlew wrapper script..."
    cat > android/gradlew.tmp << 'EOF'
#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GRADLE_EXEC="$DIR/gradle/wrapper/gradle-wrapper.jar"
if [ ! -f "$GRADLE_EXEC" ]; then
    echo "Gradle wrapper not found. Downloading..."
    mkdir -p "$DIR/gradle/wrapper"
    curl -o "$GRADLE_EXEC" https://downloads.gradle.org/distributions/gradle-wrapper.jar
fi
java -cp "$GRADLE_EXEC" org.gradle.wrapper.GradleWrapperMain "$@"
EOF
    
    mv android/gradlew.tmp android/gradlew
    chmod +x android/gradlew
    
    echo "Verifying gradle wrapper..."
    if [ ! -f "android/gradle/wrapper/gradle-wrapper.jar" ]; then
        echo "Downloading gradle wrapper..."
        mkdir -p android/gradle/wrapper
        curl -o android/gradle/wrapper/gradle-wrapper.jar https://downloads.gradle.org/distributions/gradle-wrapper.jar
    fi
    
    echo "gradlew file details:"
    file android/gradlew
    ls -l android/gradlew
else
    echo "Error: gradlew not found in android directory"
    exit 1
fi

# Install dependencies with error handling
echo "Installing dependencies..."
npm install --verbose || {
    echo "Failed to install dependencies. Error code: $?"
    exit 1
}

# Modify App.tsx with backup
echo "Updating App.tsx with provided URL..."
if [ -f "App.tsx" ]; then
    cp App.tsx App.tsx.backup
    sed -i "s|const BASE_URL = .*;|const BASE_URL = '${APP_URL}';|g" App.tsx || {
        echo "Failed to update App.tsx. Restoring backup..."
        cp App.tsx.backup App.tsx
        exit 1
    }
else
    echo "Error: App.tsx not found"
    exit 1
fi

# Update app configuration
echo "Updating app configuration..."
node << 'EOF' || { echo "Failed to update app.json"; exit 1; }
try {
    const fs = require('fs');
    const config = JSON.parse(process.env.APP_CONFIG || '{}');
    
    if (!fs.existsSync('./app.json')) {
        throw new Error('app.json not found');
    }
    
    const appJson = require('./app.json');
    
    // Backup original configuration
    fs.writeFileSync('./app.json.backup', JSON.stringify(appJson, null, 2));
    
    appJson.name = process.env.APP_NAME;
    appJson.displayName = process.env.APP_NAME;
    
    if (config.bundleId) {
        appJson.android = appJson.android || {};
        appJson.ios = appJson.ios || {};
        appJson.android.package = config.bundleId;
        appJson.ios.bundleIdentifier = config.bundleId;
    }
    
    if (config.version) {
        appJson.version = config.version;
    }
    
    fs.writeFileSync('./app.json', JSON.stringify(appJson, null, 2));
    console.log('Successfully updated app.json');
} catch (error) {
    console.error('Error updating app.json:', error);
    // Restore backup if it exists
    if (fs.existsSync('./app.json.backup')) {
        fs.copyFileSync('./app.json.backup', './app.json');
    }
    process.exit(1);
}
EOF

# Make sure metro.config.js is set up correctly
echo "Checking metro.config.js..."
if [ -f "metro.config.js" ]; then
    echo "metro.config.js exists, continuing..."
else
    echo "Creating default metro.config.js..."
    cat > metro.config.js << 'EOF'
const { getDefaultConfig } = require('@react-native/metro-config');

const config = getDefaultConfig(__dirname);

module.exports = config;
EOF
fi

# Build Android APK
echo "Building Android APK..."
cd android || { echo "Android directory not found"; exit 1; }

echo "Current directory:"
pwd

echo "Contents of current directory:"
ls -la

# Verify gradle wrapper files
echo "Verifying Gradle wrapper files..."
if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "Gradle wrapper JAR missing. Downloading..."
    mkdir -p gradle/wrapper
    curl -L -o gradle/wrapper/gradle-wrapper.jar https://github.com/gradle/gradle/raw/master/gradle/wrapper/gradle-wrapper.jar
fi

if [ ! -f "gradle/wrapper/gradle-wrapper.properties" ]; then
    echo "Creating gradle-wrapper.properties..."
    mkdir -p gradle/wrapper
    cat > gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-7.5.1-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
fi

# Double-check gradlew exists and is executable
if [ ! -f "gradlew" ]; then
    echo "gradlew not found in $(pwd)"
    echo "Listing parent directory contents:"
    ls -la ..
    exit 1
fi

echo "gradlew file properties before final check:"
ls -l gradlew

# Ensure gradlew is executable one final time
chmod +x gradlew

# Verify the file is actually there and executable
if [ ! -x "gradlew" ]; then
    echo "Error: gradlew is still not executable after chmod"
    echo "Current permissions:"
    ls -l gradlew
    exit 1
fi

# Clean android build with full error output
echo "Cleaning Android build..."
./gradlew clean --stacktrace || {
    echo "Failed to clean Android build. Error code: $?"
    echo "Current directory: $(pwd)"
    echo "Directory contents:"
    ls -la
    exit 1
}

# Build with error handling
echo "Building Release APK..."
./gradlew assembleRelease --info --stacktrace || {
    echo "Failed to build Android APK. Error code: $?"
    exit 1
}

# Copy Android build
echo "Copying build artifacts..."
mkdir -p /app/output/android
cp app/build/outputs/apk/release/app-release.apk /app/output/android/ || {
    echo "Failed to copy APK to output directory"
    exit 1
}

echo "Build process completed successfully"