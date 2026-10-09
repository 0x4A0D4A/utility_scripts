#!/usr/bin/env bash
# Wrapper to run the official Claude Code CLI inside a guix shell --container sandbox, since Guix System has no FHS for its release binary to run against natively
set -euo pipefail

# Minimum toolchain Claude Code's own Bash tool needs to function inside
# the container - kept explicit (not derived from the user profile) so it
# doesn't silently break if that profile lacks e.g. bash.
BASE_PKGS="glibc gcc-toolchain ripgrep nss-certs bash coreutils findutils grep sed gawk which file tar gzip curl git openssh less xclip"

# Deliberately NOT merging the user's own installed packages (~/.guix-profile,
# ~/.guix-home/profile) into ALL_PKGS here. Passing a package NAME to `guix
# shell` always re-resolves it against the CURRENT default channel state to
# decide what to build/substitute - it does not just check "is this exact
# thing already in my store" and reuse it. Even a version-pinned "name@version"
# spec re-derives the whole dependency graph, which can drift from what's
# actually already built the moment the channel state moves (e.g. right after
# `guix pull`), silently trading an already-built package for a from-scratch
# rebuild of an unrelated dependency graph (hit in practice: github-cli's Go
# toolchain chain, after a routine `guix pull`). Below, the already-built
# profiles are exposed via PATH instead - see the PATH export before exec.
ALL_PKGS="$BASE_PKGS"

REAL_CLAUDE=$(readlink -f "$HOME/.local/bin/claude" 2>/dev/null || true)

if [ -z "$REAL_CLAUDE" ] || [ ! -x "$REAL_CLAUDE" ]; then
  echo "error: Claude Code binary not found at ~/.local/bin/claude" >&2
  echo "Run: guix shell --container --network --emulate-fhs $BASE_PKGS --share=\$HOME -- bash -c 'curl -fsSL https://claude.ai/install.sh | bash'" >&2
  exit 1
fi

# Share every top-level host path except the ones that would collide with
# what --emulate-fhs/--container construct themselves: /proc,/sys,/dev are
# kernel pseudo-filesystems the container provides on its own; /bin,/sbin,
# /lib,/lib64,/usr are what --emulate-fhs synthesizes from ALL_PKGS (sharing
# the host's - which barely exist on Guix System - collides with that).
# /etc is skipped since it holds host secrets (e.g. /etc/shadow) and no
# sudo is available in the container either - guix system reconfigure and
# other root-level operations deliberately stay out of the sandbox; delete
# /etc from EXCLUDE and add sudo to BASE_PKGS if that's ever asked for.
# /gnu, /var (guix-daemon socket + profiles), and /run (current-system
# profile) are all shared, which is what lets `guix`, `guix home
# reconfigure`, and `guix pull` work from inside the container against the
# live host daemon - see the PATH export below.
EXCLUDE="proc sys dev bin sbin lib lib64 usr etc"
SHARE_ARGS=()
for d in /*; do
  name="${d#/}"
  case " $EXCLUDE " in
    *" $name "*) continue ;;
  esac
  [ -e "$d" ] && SHARE_ARGS+=(--share="$d")
done

# guix shell --container sets its own PATH for the command it runs, so
# already-built tools are exposed by prepending their profiles' bin/sbin
# dirs directly, right before exec'ing claude, rather than passed as
# packages to resolve. This is direct PATH access to what's already built -
# no name/version re-resolution against current channel state, so it can
# never trigger a build or a "which substitute" decision, unlike passing
# names/specs to guix shell (see the ALL_PKGS comment above). Guix binaries
# are self-contained (store-embedded RPATHs), so this works regardless of
# whether the referenced packages were part of --emulate-fhs's own package
# set - that set only needs to cover what BASE_PKGS's FHS emulation itself
# requires (glibc/gcc-toolchain/etc), not every tool made reachable here.
# - ~/.config/guix/current: the user's own `guix pull` profile, first so a
#   bare `guix` is the same one the interactive shell uses. The system guix
#   only knows the channels in /etc/channels.scm (no nonguix), so nonguix
#   packages show up as "unknown package" under it.
# - /run/current-system/profile: the live system profile (still on PATH for
#   its other tools).
# - ~/.guix-profile: ad hoc `guix install`ed packages.
# - ~/.guix-home/profile: declarative packages from home-configuration.scm
#   (including local, non-channel `my-packages` - those are only reachable
#   this way, since a bare `guix shell umpv` can't resolve them by name at
#   all, channel-drift risk or not).
# Any PATH entry for a profile that doesn't exist is silently skipped.
exec guix shell --container --network --emulate-fhs \
  $ALL_PKGS \
  "${SHARE_ARGS[@]}" \
  --preserve='^(TERM|COLORTERM|DISPLAY|XAUTHORITY|SSH_AUTH_SOCK|GPG_TTY|DBUS_SESSION_BUS_ADDRESS|XDG_RUNTIME_DIR|WAYLAND_DISPLAY)$' \
  -- bash -c 'export PATH="$HOME/.config/guix/current/bin:/run/current-system/profile/bin:/run/current-system/profile/sbin:$HOME/.guix-profile/bin:$HOME/.guix-profile/sbin:$HOME/.guix-home/profile/bin:$HOME/.guix-home/profile/sbin:$PATH"; exec "$0" "$@"' "$REAL_CLAUDE" "$@"
