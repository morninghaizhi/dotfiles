# ~/.zprofile
# ログインシェル起動時にのみ読まれる (~/.zshenv → /etc/zprofile → ~/.zprofile → ~/.zshrc の順)

# /etc/zprofile の path_helper がシステムのパス (/usr/bin など) を先頭に並べ替えるので、
# ~/.zshenv で組んだ並びを先頭に戻す (重複は .zshenv の typeset -U で取り除かれる)
path=("${_zshenv_path[@]}" "${path[@]}")
unset _zshenv_path
