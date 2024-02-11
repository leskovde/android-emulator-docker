FROM --platform=linux/amd64 openjdk:18-jdk-slim

ENV DEBIAN_FRONTEND noninteractive

WORKDIR /
#=============================
# Install Dependenices 
#=============================
SHELL ["/bin/bash", "-c"]   

RUN apt update && apt install -y curl sudo wget unzip bzip2 libdrm-dev libxkbcommon-dev libgbm-dev libasound-dev libnss3 libxcursor1 libpulse-dev libxshmfence-dev xauth xvfb x11vnc fluxbox wmctrl libdbus-glib-1-2 vim

#==============================
# Android SDK ARGS
#==============================
# TODO: Arch needs to be adjusted to x86_64 when built on x86_64
#ARG ARCH="arm64-v8a"
ARG ARCH="x86_64"
ARG TARGET="google_apis_playstore"  
ARG API_LEVEL="34" 
ARG BUILD_TOOLS="34.0.0"
ARG ANDROID_ARCH=${ANDROID_ARCH_DEFAULT}
ARG ANDROID_API_LEVEL="android-${API_LEVEL}"
#system-images;android-34;google_apis_playstore;arm64-v8a
ARG DEVICE_IMAGE_NAME="system-images;${ANDROID_API_LEVEL};${TARGET};${ARCH}"
ARG PLATFORM_VERSION="platforms;${ANDROID_API_LEVEL}"
ARG BUILD_TOOL="build-tools;${BUILD_TOOLS}"
ARG ANDROID_CMD="commandlinetools-linux-11076708_latest.zip"
#ARG ANDROID_SDK_PACKAGES="${EMULATOR_PACKAGE} ${PLATFORM_VERSION} ${BUILD_TOOL} platform-tools"
ARG ANDROID_SDK_PACKAGES="${PLATFORM_VERSION} ${BUILD_TOOL} platform-tools"
#ARG EMULATOR_ZIP_FILE="sdk-repo-linux_aarch64-emulator-11411100.zip"
ARG EMULATOR_ZIP_FILE="sdk-repo-linux-emulator-11434393.zip"
ARG EMULATOR_PACKAGE_FILE="package.xml"

#==============================
# Set JAVA_HOME - SDK
#==============================
ENV ANDROID_SDK_ROOT=/opt/android
ENV PATH "$PATH:$ANDROID_SDK_ROOT/cmdline-tools/tools:$ANDROID_SDK_ROOT/cmdline-tools/tools/bin:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/build-tools/${BUILD_TOOLS}"
ENV DOCKER="true"

#RUN apt-get update -y && \
#    apt-get install qemu -y

#============================================
# Install required Android CMD-line tools
#============================================
RUN wget https://dl.google.com/android/repository/${ANDROID_CMD} -P /tmp && \
              unzip -d $ANDROID_SDK_ROOT /tmp/$ANDROID_CMD && \
              mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/tools && cd $ANDROID_SDK_ROOT/cmdline-tools &&  mv NOTICE.txt source.properties bin lib tools/  && \
              cd $ANDROID_SDK_ROOT/cmdline-tools/tools && ls

COPY ${EMULATOR_ZIP_FILE} ./
RUN unzip ${EMULATOR_ZIP_FILE} -d $ANDROID_SDK_ROOT
COPY ${EMULATOR_PACKAGE_FILE} $ANDROID_SDK_ROOT/emulator/package.xml

#============================================
# Install required package using SDK manager
#============================================
RUN yes Y | sdkmanager --licenses
#RUN yes Y | sdkmanager --verbose --no_https "platforms;android-34" "build-tools;34.0.0" "platform-tools"
RUN yes Y | sdkmanager --verbose --no_https ${ANDROID_SDK_PACKAGES}
#RUN yes Y | sdkmanager --verbose --no_https "system-images;android-34;google_apis_playstore;arm64-v8a"
RUN yes Y | sdkmanager --verbose --no_https ${DEVICE_IMAGE_NAME}

#============================================
# Create required emulator
#============================================
ARG EMULATOR_NAME="nexus"
ARG EMULATOR_DEVICE="Nexus 6"
ENV EMULATOR_NAME=$EMULATOR_NAME
ENV DEVICE_NAME=$EMULATOR_DEVICE
RUN echo "no" | avdmanager --verbose create avd --force --name "${EMULATOR_NAME}" --device "${EMULATOR_DEVICE}" --package "${DEVICE_IMAGE_NAME}"

#====================================
# Install latest nodejs, npm & appium
#====================================
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash && \
    apt-get -qqy install nodejs && \
    npm install -g npm && \
    npm i -g appium --unsafe-perm=true --allow-root && \
    appium driver install uiautomator2 && \
    exit 0 && \
    npm cache clean && \
    apt-get remove --purge -y npm && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -Rf /tmp/* && rm -Rf /var/lib/apt/lists/*


#===================
# Alias
#===================
ENV EMU=./start_emu.sh
ENV EMU_HEADLESS=./start_emu_headless.sh
ENV VNC=./start_vnc.sh
ENV APPIUM=./start_appium.sh


#===================
# Ports
#===================
ENV APPIUM_PORT=4723

#=========================
# Copying Scripts to root
#=========================
COPY . /

RUN chmod a+x start_vnc.sh && \
    chmod a+x start_emu.sh && \
    chmod a+x start_appium.sh && \
    chmod a+x start_emu_headless.sh

#=======================
# framework entry point
#=======================
CMD [ "/bin/bash" ]
