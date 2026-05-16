#!/usr/bin/env bash
# Matrix Cursor Size: set cursor size to s=32 / m=40 / l=48 / xl=64
# Usage: ./setup-matrix-cursor-size.sh <s|m|l|xl> [--logout]
#   --logout  apply configs then immediately log out so COSMIC picks them up

GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
NC='\033[0m'

log()      { echo -e "${BRIGHT_GREEN}[MATRIX]${GREEN} $1${NC}"; }
log_done() { echo -e "${BRIGHT_GREEN}[MATRIX] ✓ $1${NC}"; }
log_warn() { echo -e "${BRIGHT_GREEN}[MATRIX] ⚠ $1${NC}"; }

LOGOUT=0
SIZE_ARG=""

for arg in "$@"; do
  case "$arg" in
    --logout)  LOGOUT=1 ;;
    s|m|l|xl)  SIZE_ARG="$arg" ;;
    *)
      echo -e "${BRIGHT_GREEN}Usage:${NC} $0 <s|m|l|xl> [--logout]"
      echo -e "  s = 32   m = 40   l = 48   xl = 64"
      echo -e "  --logout  log out immediately after applying"
      exit 1
      ;;
  esac
done

if [ -z "$SIZE_ARG" ]; then
  echo -e "${BRIGHT_GREEN}Usage:${NC} $0 <s|m|l|xl> [--logout]"
  echo -e "  s = 32   m = 40   l = 48   xl = 64"
  exit 1
fi

case "$SIZE_ARG" in
  s)  CURSOR_SIZE=32 ;;
  m)  CURSOR_SIZE=40 ;;
  l)  CURSOR_SIZE=48 ;;
  xl) CURSOR_SIZE=64 ;;
esac

# Detect active theme from COSMIC config, fall back to GTK3
COSMIC_COMP="$HOME/.config/cosmic/com.system76.CosmicComp/v1"
if [ -f "$COSMIC_COMP/cursor_theme" ]; then
  CURSOR_THEME="$(sed 's/"//g' "$COSMIC_COMP/cursor_theme")"
elif grep -q '^gtk-cursor-theme-name=' "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null; then
  CURSOR_THEME="$(grep '^gtk-cursor-theme-name=' "$HOME/.config/gtk-3.0/settings.ini" | cut -d= -f2)"
else
  log_warn "Could not detect active cursor theme — run setup-matrix-cursor.sh first"
  exit 1
fi

log "Setting cursor size to ${CURSOR_SIZE}px ($SIZE_ARG) for theme: $CURSOR_THEME..."

set_ini_key() {
  local file="$1" key="$2" val="$3"
  mkdir -p "$(dirname "$file")"
  [ -f "$file" ] || printf '[Settings]\n' > "$file"
  if grep -q "^${key}=" "$file" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${val}|" "$file"
  else
    echo "${key}=${val}" >> "$file"
  fi
}

set_env_key() {
  local file="$1" key="$2" val="$3"
  mkdir -p "$(dirname "$file")"
  [ -f "$file" ] || touch "$file"
  if grep -q "^${key}=" "$file" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${val}|" "$file"
  else
    echo "${key}=${val}" >> "$file"
  fi
}

# ─── GTK 3 / GTK 4 ────────────────────────────────────────────────────────────
set_ini_key "$HOME/.config/gtk-3.0/settings.ini" "gtk-cursor-theme-size" "$CURSOR_SIZE"
log_done "GTK3 updated"
set_ini_key "$HOME/.config/gtk-4.0/settings.ini" "gtk-cursor-theme-size" "$CURSOR_SIZE"
log_done "GTK4 updated"

# ─── /etc/environment — PAM injects this into ALL processes at login ──────────
# This is what cosmic-session/cosmic-comp actually reads, not environment.d
set_env_key "$HOME/.config/environment.d/cursor.conf" "XCURSOR_SIZE"  "$CURSOR_SIZE"
set_env_key "$HOME/.config/environment.d/cursor.conf" "XCURSOR_THEME" "$CURSOR_THEME"
log_done "environment.d/cursor.conf updated"

if grep -q "^XCURSOR_SIZE=" /etc/environment 2>/dev/null; then
  sudo sed -i "s|^XCURSOR_SIZE=.*|XCURSOR_SIZE=$CURSOR_SIZE|" /etc/environment
else
  echo "XCURSOR_SIZE=$CURSOR_SIZE" | sudo tee -a /etc/environment > /dev/null
fi
if grep -q "^XCURSOR_THEME=" /etc/environment 2>/dev/null; then
  sudo sed -i "s|^XCURSOR_THEME=.*|XCURSOR_THEME=$CURSOR_THEME|" /etc/environment
else
  echo "XCURSOR_THEME=$CURSOR_THEME" | sudo tee -a /etc/environment > /dev/null
fi
log_done "/etc/environment updated (XCURSOR_SIZE=$CURSOR_SIZE XCURSOR_THEME=$CURSOR_THEME)"

# ─── Xresources ───────────────────────────────────────────────────────────────
touch "$HOME/.Xresources"
if grep -q "^Xcursor.size" "$HOME/.Xresources"; then
  sed -i "s|^Xcursor.size:.*|Xcursor.size: $CURSOR_SIZE|" "$HOME/.Xresources"
else
  echo "Xcursor.size: $CURSOR_SIZE" >> "$HOME/.Xresources"
fi
log_done "~/.Xresources updated"

# ─── COSMIC DE ────────────────────────────────────────────────────────────────
mkdir -p "$COSMIC_COMP"
printf '%s' "$CURSOR_SIZE"          > "$COSMIC_COMP/cursor_size"
printf '"%s"' "$CURSOR_THEME"       > "$COSMIC_COMP/cursor_theme"
log_done "COSMIC cursor_size=$CURSOR_SIZE cursor_theme=$CURSOR_THEME"

# ─── Live session ─────────────────────────────────────────────────────────────
command -v gsettings &>/dev/null && \
  gsettings set org.gnome.desktop.interface cursor-size  "$CURSOR_SIZE"  && \
  gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" && \
  log_done "gsettings applied" || log_warn "gsettings failed"

command -v xrdb &>/dev/null && \
  xrdb -merge "$HOME/.Xresources" && \
  log_done "xrdb merged" || true

command -v systemctl &>/dev/null && \
  systemctl --user set-environment XCURSOR_SIZE="$CURSOR_SIZE" XCURSOR_THEME="$CURSOR_THEME" && \
  log_done "systemd user env updated" || true

command -v dbus-update-activation-environment &>/dev/null && \
  dbus-update-activation-environment XCURSOR_SIZE="$CURSOR_SIZE" XCURSOR_THEME="$CURSOR_THEME" && \
  log_done "D-Bus activation env updated" || true

# ─── Verify ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BRIGHT_GREEN}[MATRIX] Verify:${NC}"
echo -e "${GREEN}  COSMIC size  : $(cat "$COSMIC_COMP/cursor_size" 2>/dev/null || echo MISSING)${NC}"
echo -e "${GREEN}  COSMIC theme : $(cat "$COSMIC_COMP/cursor_theme" 2>/dev/null || echo MISSING)${NC}"
echo -e "${GREEN}  gsettings    : $(gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null || echo MISSING)${NC}"
echo -e "${GREEN}  Theme files  : $(ls "$HOME/.icons/$CURSOR_THEME/cursors/" 2>/dev/null | wc -l) cursors${NC}"

echo ""
echo -e "${BRIGHT_GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BRIGHT_GREEN}║  Cursor size → ${CURSOR_SIZE}px ($SIZE_ARG)                               ║${NC}"
echo -e "${BRIGHT_GREEN}║  ✓ GTK / XWayland apps updated NOW                  ║${NC}"
echo -e "${BRIGHT_GREEN}║  ✗ COSMIC Terminal + desktop need session restart    ║${NC}"
echo -e "${BRIGHT_GREEN}╚══════════════════════════════════════════════════════╝${NC}"

# ─── Logout ───────────────────────────────────────────────────────────────────
if [ "$LOGOUT" = 1 ]; then
  log "Logging out..."
  loginctl terminate-user "$USER"
else
  printf "${BRIGHT_GREEN}Log out now to apply everywhere? [y/N]: ${NC}"
  read -r _ans
  case "$_ans" in
    [Yy]) loginctl terminate-user "$USER" ;;
  esac
fi
