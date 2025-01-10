# ベースイメージとしてCirrus LabsのFlutter 3.27.1を使用
FROM ghcr.io/cirruslabs/flutter:3.27.1

# 作業ディレクトリを設定
WORKDIR /app

# pubspec.yamlとpubspec.lockをコピーして依存関係をキャッシュ
#COPY pubspec.* ./

# Flutterの依存関係を取得
#RUN flutter pub get

# アプリケーションのソースコードをコピー
#COPY . .

# ポートが必要な場合（例: Flutter Web）
# EXPOSE 8080

# デフォルトのコマンドを設定（必要に応じて変更）
# CMD ["flutter", "run"]
