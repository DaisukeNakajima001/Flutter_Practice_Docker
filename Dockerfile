# ベースイメージとしてCirrus LabsのFlutter 3.27.1を使用
FROM ghcr.io/cirruslabs/flutter:3.27.1

# 作業ディレクトリ
WORKDIR /app

# 必要パッケージのインストール
RUN apt-get update && apt-get install -y \
    wget gnupg2 unzip libglu1 libstdc++6 libpulse0 libnss3 \
    libx11-6 libxext6 libxi6 libxrender1 libxcursor1 libxdamage1 \
    libxfixes3 libxrandr2 libxss1 libxtst6 libgbm1 \
    qemu-kvm openjdk-11-jdk git sudo \
    libxcb-cursor0 libx11-xcb1 libxcb-xinerama0 libxcb-icccm4 libxcb-image0 \
    libxcb-keysyms1 libxcb-render-util0 libxcb-shape0 libxcb-xfixes0 \
    libqt5core5a libqt5gui5 libqt5network5 libqt5widgets5 \
    libqt5dbus5 libqt5test5 libqt5concurrent5 qt5-gtk-platformtheme \
    libxcb-randr0 libxcb-util1 \
    && rm -rf /var/lib/apt/lists/*

# Google Chromeのインストール
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Android SDK 環境変数を /opt/android-sdk-linux に統一
ENV ANDROID_SDK_ROOT=/opt/android-sdk-linux
# Flutter SDK や emulator/adb 等のパスを追加
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/emulator:${ANDROID_SDK_ROOT}/platform-tools:/sdks/flutter/bin:/usr/local/bin:${PATH}"

# Android commandline-tools のインストール
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/cmdline-tools.zip \
    && unzip /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && rm /tmp/cmdline-tools.zip \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest

# SDKコンポーネントインストール
RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "platforms;android-33" "emulator" "system-images;android-33;google_apis;x86_64"

# flutteruser 作成
RUN useradd -ms /bin/bash flutteruser

# sudo グループに flutteruser を追加
RUN usermod -aG sudo flutteruser

# flutteruser のパスワード設定
RUN echo "flutteruser:flutterUser" | chpasswd

# flutteruser ディレクトリ調整
RUN mkdir -p /home/flutteruser/.android/avd && \
    chown -R flutteruser:flutteruser /home/flutteruser && \
    chmod -R u+rwx /home/flutteruser

# /sdks/flutter の権限修正
RUN chown -R flutteruser:flutteruser /sdks/flutter && chmod -R u+rwx /sdks/flutter || true

# /app /opt/android-sdk-linux の権限修正
RUN chown -R flutteruser:flutteruser /app $ANDROID_SDK_ROOT

# シンボリックリンクを /usr/local/bin に貼る
RUN ln -s /sdks/flutter/bin/flutter /usr/local/bin/flutter && \
    ln -s $ANDROID_SDK_ROOT/emulator/emulator /usr/local/bin/emulator && \
    ln -s $ANDROID_SDK_ROOT/platform-tools/adb /usr/local/bin/adb

# Flutter設定を追加
RUN git config --global --add safe.directory /sdks/flutter && \
    echo "export FLUTTER_GIT_URL=https://github.com/flutter/flutter.git" >> /etc/profile

# entrypoint.sh と start-emulator.sh をコピー
COPY entrypoint.sh /root/entrypoint.sh
COPY start-emulator.sh /home/flutteruser/start-emulator.sh

# スクリプトに実行権限を付与
RUN chmod +x /root/entrypoint.sh && \
    chmod +x /home/flutteruser/start-emulator.sh && \
    chown flutteruser:flutteruser /home/flutteruser/start-emulator.sh

# flutteruser で AVD を作成
USER flutteruser
#スマホ用エミュ
RUN yes | /opt/android-sdk-linux/cmdline-tools/latest/bin/sdkmanager --licenses && \
    echo "no" | /opt/android-sdk-linux/cmdline-tools/latest/bin/avdmanager create avd \
      -n test_phone \
      -k "system-images;android-33;google_apis;x86_64" \
      --device "pixel_4" \
      --force
#タブレット用エミュ
RUN echo "no" | /opt/android-sdk-linux/cmdline-tools/latest/bin/avdmanager create avd \
      -n test_tablet \
      -k "system-images;android-33;google_apis;x86_64" \
      --device "Nexus 10" \
      --force

RUN rm -rf /home/flutteruser/.android/avd/*.avd/*.lock || true

# USER を root に戻す
USER root

# コンテナ起動時は entrypoint.sh を実行
ENTRYPOINT ["/root/entrypoint.sh"]
