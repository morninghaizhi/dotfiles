# ~/.zshenv
# すべての zsh セッション(対話・非対話・ログイン・非ログイン問わず)で読まれる
# PATH と環境変数のみを記述する

# ------------------------------------------------------------
# Homebrew (Apple Silicon)
# ------------------------------------------------------------
# PATH, MANPATH, INFOPATH, HOMEBREW_PREFIX などをまとめて設定
eval "$(/opt/homebrew/bin/brew shellenv)"

# ------------------------------------------------------------
# Java
# ------------------------------------------------------------
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH="$JAVA_HOME/bin:$PATH"

# ------------------------------------------------------------
# Flutter / Dart
# ------------------------------------------------------------
export PATH="$PATH:$HOME/work/flutter/bin"
export PATH="$PATH:$HOME/.pub-cache/bin"

# ------------------------------------------------------------
# Android SDK
# ------------------------------------------------------------
export ANDROID_HOME="$HOME/android-sdks"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"

# ------------------------------------------------------------
# Homebrew 配下のコマンド (keg-only な Ruby / curl を優先)
# ------------------------------------------------------------
export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# ------------------------------------------------------------
# ユーザーローカルのコマンド
# ------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"

# ------------------------------------------------------------
# ツール固有の設定 (環境変数)
# ------------------------------------------------------------
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
