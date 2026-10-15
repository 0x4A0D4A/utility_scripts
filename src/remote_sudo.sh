#!/usr/bin/env bash
# script to run one command as root on a remote host, feeding the sudo password from `pass` over a pipe so it never reaches argv, a file, or the terminal
# primarily intended to give an agent the ability to run some superuser commands on a remote server once, with prior approval, and not without
#
# usage:   remote_sudo.sh <user@host> <pass-entry> '<shell command string>'
# example: remote_sudo.sh admin@server.example.com servers/example 'ufw status verbose'

set +o xtrace +o verbose
umask 077

if [ $# -ne 3 ]; then
  echo "usage: ${0##*/} <user@host> <pass-entry> '<command>'" >&2
  exit 2
fi

host=$1 entry=$2 cmd=$3

# refuse anything that ssh or pass could parse as an option
for v in "$host" "$entry"; do
  case $v in -*|"") echo "${0##*/}: invalid argument '$v'" >&2; exit 2 ;; esac
done

trap 'gpgconf --reload gpg-agent >/dev/null 2>&1' EXIT

# base64 the command so no quoting survives to be mangled by the remote shell
b64=$(printf %s "$cmd" | base64 --wrap=0)

# stdin of ssh is the password line; the command is decoded on the remote side and passed to sudo as its sh -c argument
pass "$entry" 2>/dev/null | head --lines=1 |
  ssh -o RequestTTY=no -o BatchMode=yes -- "$host" \
    "sudo --stdin --prompt='' sh -c \"\$(printf %s $b64 | base64 --decode)\""
rc=${PIPESTATUS[2]}
passrc=${PIPESTATUS[0]}

# 141 is SIGPIPE from head, which is normal for a one-line entry
if [ "$passrc" -ne 0 ] && [ "$passrc" -ne 141 ]; then
  echo "${0##*/}: pass failed (gpg locked?); unlock it and retry" >&2
fi
exit "$rc"
