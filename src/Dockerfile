# Use React Native prebuilt image (Latest Version)
FROM reactnativecommunity/react-native-android:latest

# Set working directory
WORKDIR /app

# Copy native code and scripts
COPY src/native/ /app/native/
COPY src/scripts/build-app.sh /app/scripts/

# Ensure script is executable
RUN chmod +x /app/scripts/build-app.sh

# Accept environment variables from DockerService
ARG APP_NAME
ARG APP_URL
ARG APP_CONFIG

ENV APP_NAME=${APP_NAME}
ENV APP_URL=${APP_URL}
ENV APP_CONFIG=${APP_CONFIG}

# Install dependencies
RUN apt-get update && apt-get install -y dos2unix && rm -rf /var/lib/apt/lists/*

# Convert script line endings and fix permissions
RUN dos2unix /app/scripts/build-app.sh

# Run the build script
CMD ["/bin/bash", "/app/scripts/build-app.sh"]
