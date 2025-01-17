#!/bin/bash

# エミュレーターを起動（GUIモード）
#スマホ用エミュ
#emulator -avd test_phone -no-snapshot -no-audio -gpu auto &
#タブレット用エミュ
emulator -avd test_tablet -no-snapshot -no-audio -gpu auto &

# エミュレーターが起動するまで待機
adb wait-for-device

# FlutterのDoctorを実行
flutter doctor

# シェルを保持
exec "$SHELL"
