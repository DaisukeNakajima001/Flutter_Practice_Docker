#!/bin/bash
set -e

echo "Configuring /dev/kvm as root..."

# kvm グループ作成（既にあればスルー）
groupadd -r kvm || true

# /dev/kvm の権限設定（存在する場合のみ）
if [ -e /dev/kvm ]; then
    chown root:kvm /dev/kvm || true
    chmod 660 /dev/kvm || true
fi

# flutteruser を kvm グループに追加
usermod -aG kvm flutteruser || true

echo "Switching to flutteruser..."
# flutteruser で start-emulator.sh を実行
exec su flutteruser -c "/home/flutteruser/start-emulator.sh"
