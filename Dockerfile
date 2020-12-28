FROM debian:stretch

ENV FLUTTER_VERSION="1.22.5"
ENV ANDROID_VERSION="29"

# image mostly inspired from https://github.com/GoogleCloudPlatform/cloud-builders-community/blob/770e0e9/flutter/Dockerfile
# and https://gitlab.com/gableroux/gitlab_ci_flutter_example/.

LABEL com.gableroux.flutter.name="debian linux image with Flutter and lcov_to_cobertura python script." \
      com.gableroux.flutter.license="MIT" \
      com.gableroux.flutter.vcs-type="git" \
      com.gableroux.flutter.vcs-url="https://github.com/pY4x3g/docker-flutter_lcov_to_cobertura"

WORKDIR /

RUN apt update -y
RUN apt install -y \
  git \
  wget \
  curl \
  unzip \
  lcov \
  lib32stdc++6 \
  libglu1-mesa \
  default-jdk-headless \
  libsqlite3-dev

# Install the Android SDK Dependency.
ENV ANDROID_SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-6200805_latest.zip"
ENV ANDROID_TOOLS_ROOT="/opt/android-sdk-linux"
RUN mkdir -p "${ANDROID_TOOLS_ROOT}"
ENV ANDROID_SDK_ARCHIVE="${ANDROID_TOOLS_ROOT}/archive"
RUN wget -q "${ANDROID_SDK_URL}" -O "${ANDROID_SDK_ARCHIVE}"
RUN unzip -q -d "${ANDROID_TOOLS_ROOT}" "${ANDROID_SDK_ARCHIVE}"
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "--sdk_root=${ANDROID_TOOLS_ROOT}" "build-tools;$ANDROID_VERSION.0.0"
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "--sdk_root=${ANDROID_TOOLS_ROOT}" "platforms;android-$ANDROID_VERSION"
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/tools/bin/sdkmanager" "--sdk_root=${ANDROID_TOOLS_ROOT}" "platform-tools"
RUN rm "${ANDROID_SDK_ARCHIVE}"
ENV PATH="${ANDROID_TOOLS_ROOT}/tools:${PATH}"
ENV PATH="${ANDROID_TOOLS_ROOT}/tools/bin:${PATH}"


# Install Flutter.
ENV FLUTTER_ROOT="/opt/flutter"
RUN git clone --branch $FLUTTER_VERSION --depth=1 https://github.com/flutter/flutter "${FLUTTER_ROOT}"
ENV PATH="${FLUTTER_ROOT}/bin:${PATH}"
ENV ANDROID_HOME="${ANDROID_TOOLS_ROOT}"

# Disable analytics and crash reporting on the builder.
RUN flutter config  --no-analytics

# Accept licenses.
RUN yes "y" | flutter doctor --android-licenses

# Perform a doctor run.
RUN flutter doctor -v

ENV PATH $PATH:/flutter/bin/cache/dart-sdk/bin:/flutter/bin

# Perform an artifact precache so that no extra assets need to be downloaded on demand.
RUN flutter precache



# Install lcov-to-cobertura-xml
RUN apt-get install -y python3 python3-pip
RUN python3 -m pip install setuptools
RUN (cd /usr/bin/ && curl -O https://raw.githubusercontent.com/eriwen/lcov-to-cobertura-xml/master/lcov_cobertura/lcov_cobertura.py)

# Add new user flutter
RUN adduser --disabled-password --gecos "" flutter

# Change rights of androisdk and flutter folders to flutter user
RUN chown flutter:flutter -R ${ANDROID_TOOLS_ROOT}
RUN chown flutter:flutter -R ${FLUTTER_ROOT}

# cp precache from above to flutter user
RUN cp -r /root/.pub-cache/ /home/flutter/.pub-cache/

# Change user and workspace
USER flutter
WORKDIR /home/flutter/
