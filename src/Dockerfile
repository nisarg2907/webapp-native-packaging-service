# FROM node:18

# # Install system dependencies
# RUN apt-get update && apt-get install -y \
#     git \
#     wget \
#     unzip \
#     openjdk-17-jdk \
#     && rm -rf /var/lib/apt/lists/*

# # Create app directory and scripts
# WORKDIR /app
# RUN mkdir -p /app/scripts /app/project /app/native

# # Copy your native code into the container
# COPY src/native/ /app/native/

# # Copy build script
# COPY src/scripts/build-app.sh /app/scripts/
# RUN chmod +x /app/scripts/*.sh

# # Install Android SDK
# ENV ANDROID_HOME /opt/android-sdk
# RUN mkdir -p ${ANDROID_HOME} && cd ${ANDROID_HOME} \
#     && wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip \
#     && unzip commandlinetools-linux-*_latest.zip \
#     && rm commandlinetools-linux-*_latest.zip \
#     && mkdir cmdline-tools/latest \
#     && mv cmdline-tools/* cmdline-tools/latest/ || true

# # Set up Android SDK
# ENV PATH ${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools
# RUN yes | sdkmanager --licenses \
#     && sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# # Install React Native CLI globally
# RUN npm install -g react-native-cli

# # Set environment variables
# ENV PATH=${PATH}:${ANDROID_HOME}/platform-tools

# CMD ["/bin/bash"]


FROM node:18

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    unzip \
    curl \
    dos2unix \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Create app directory and scripts
WORKDIR /app
RUN mkdir -p /app/scripts /app/project /app/native

# Copy your native code into the container
COPY src/native/ /app/native/

# Copy build script
COPY src/scripts/build-app.sh /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Install Android SDK
ENV ANDROID_HOME /opt/android-sdk
RUN mkdir -p ${ANDROID_HOME} && cd ${ANDROID_HOME} \
    && wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip \
    && unzip commandlinetools-linux-*_latest.zip \
    && rm commandlinetools-linux-*_latest.zip \
    && mkdir -p cmdline-tools/latest \
    && mv cmdline-tools/* cmdline-tools/latest/ || true

# Set up Android SDK
ENV PATH ${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools
RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Install React Native CLI globally
RUN npm install -g react-native-cli

# Set environment variables
ENV PATH=${PATH}:${ANDROID_HOME}/platform-tools

# Pre-download Gradle wrapper
RUN mkdir -p /root/.gradle/wrapper/dists && \
    cd /root/.gradle/wrapper/dists && \
    wget https://services.gradle.org/distributions/gradle-7.5.1-bin.zip

CMD ["/bin/bash"]