# ~/.zprofile
# ログインシェル起動時にのみ読まれる (~/.zshenv → /etc/zprofile の後、~/.zshrc の前)
# /etc/zprofile の path_helper が PATH を再構築した後なので、PATH とツールチェーンの場所はここで設定する。
# 未導入の環境でエラーを出さないよう、外部コマンドはすべて存在確認してから使う。

# ------------------------------------------------------------
# Homebrew (Apple Silicon)
# ------------------------------------------------------------
# PATH, MANPATH, INFOPATH, HOMEBREW_PREFIX などをまとめて設定
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# NOTE: Homebrew 版 curl (keg-only, /opt/homebrew/opt/curl/bin) は PATH に入れない。
# macOS キーチェーンを見ないため、社内プロキシのルートCA環境で TLS エラーになる。
# HTTP/3 など新しい機能が必要なときだけ /opt/homebrew/opt/curl/bin/curl をフルパスで呼ぶ。

# ------------------------------------------------------------
# ユーザーローカルのコマンド
# ------------------------------------------------------------
# 自分の権限で動くプロセスなら書き込めるディレクトリなので、
# git / ssh などの偽物が本物より優先されないよう末尾に置く
export PATH="$PATH:$HOME/.local/bin"

# ------------------------------------------------------------
# マシン固有の設定 (git 管理外)
# Android SDK / JDK のパスなど、マシンごとに違う設定はここへ。
# テンプレート: zsh/.zprofile.local.example
# ------------------------------------------------------------
[[ -f ~/.zprofile.local ]] && source ~/.zprofile.local
