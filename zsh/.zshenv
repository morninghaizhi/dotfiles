# ~/.zshenv
# すべての zsh セッション(対話・非対話・ログイン・非ログイン問わず)で読まれる。
# PATH 以外の環境変数のみを記述する。
# PATH はここに書かない — /etc/zprofile の path_helper がこの後に PATH を
# 再構築するため、ここで指定した優先順は失われる。PATH は .zprofile で設定する。

# ------------------------------------------------------------
# Homebrew の挙動
# ------------------------------------------------------------
export HOMEBREW_NO_ANALYTICS=1      # 利用統計の送信を停止
export HOMEBREW_NO_AUTO_UPDATE=1    # コマンド毎の自動更新を停止(更新は週次に手動で)
export HOMEBREW_NO_ENV_HINTS=1      # 設定提案のヒントを抑制

# ------------------------------------------------------------
# ツール固有の設定 (環境変数)
# ------------------------------------------------------------
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
