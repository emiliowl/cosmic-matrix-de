#!/usr/bin/env bash
# Matrix Cursor Setup: Vimix-green-cursors (size 48)
# Installs from source and configures GTK3, GTK4, systemd env, and COSMIC DE
set -e

GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
NC='\033[0m'

log()      { echo -e "${BRIGHT_GREEN}[MATRIX]${GREEN} $1${NC}"; }
log_done() { echo -e "${BRIGHT_GREEN}[MATRIX] ✓ $1${NC}"; }
log_warn() { echo -e "${BRIGHT_GREEN}[MATRIX] ⚠ $1${NC}"; }

CURSOR_THEME="Vimix-green-cursors"
CURSOR_SIZE=48
ICONS_DIR="$HOME/.local/share/icons"
INSTALL_DIR="$ICONS_DIR/$CURSOR_THEME"

# ─── 1. Install cursor theme ──────────────────────────────────────────────────
log "Checking for $CURSOR_THEME..."

if [ -d "$INSTALL_DIR/cursors" ]; then
  log_done "$CURSOR_THEME already installed at $INSTALL_DIR"
else
  log "Installing $CURSOR_THEME from vinceliuice/Vimix-cursors..."

  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT

  git clone --depth=1 https://github.com/vinceliuice/Vimix-cursors.git "$TMPDIR/Vimix-cursors"

  if [ -d "$TMPDIR/Vimix-cursors/dist/$CURSOR_THEME" ]; then
    mkdir -p "$ICONS_DIR"
    cp -r "$TMPDIR/Vimix-cursors/dist/$CURSOR_THEME" "$INSTALL_DIR"
    log_done "$CURSOR_THEME installed to $INSTALL_DIR"
  else
    log_warn "dist/$CURSOR_THEME not found in repo — trying install.sh..."
    cd "$TMPDIR/Vimix-cursors"
    bash install.sh -d "$ICONS_DIR"
    log_done "Vimix cursors installed via install.sh"
  fi
fi

# ─── 2. GTK 3 ─────────────────────────────────────────────────────────────────
log "Configuring GTK3 cursor..."
GTK3="$HOME/.config/gtk-3.0/settings.ini"
mkdir -p "$(dirname "$GTK3")"

if [ ! -f "$GTK3" ]; then
  printf '[Settings]\n' > "$GTK3"
fi

set_ini_key() {
  local file="$1" key="$2" val="$3"
  if grep -q "^${key}" "$file" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${val}|" "$file"
  else
    echo "${key}=${val}" >> "$file"
  fi
}

set_ini_key "$GTK3" "gtk-cursor-theme-name" "$CURSOR_THEME"
set_ini_key "$GTK3" "gtk-cursor-theme-size" "$CURSOR_SIZE"
log_done "GTK3: $CURSOR_THEME @ $CURSOR_SIZE"

# ─── 3. GTK 4 ─────────────────────────────────────────────────────────────────
log "Configuring GTK4 cursor..."
GTK4="$HOME/.config/gtk-4.0/settings.ini"
mkdir -p "$(dirname "$GTK4")"

if [ ! -f "$GTK4" ]; then
  printf '[Settings]\n' > "$GTK4"
fi

set_ini_key "$GTK4" "gtk-cursor-theme-name" "$CURSOR_THEME"
set_ini_key "$GTK4" "gtk-cursor-theme-size" "$CURSOR_SIZE"
log_done "GTK4: $CURSOR_THEME @ $CURSOR_SIZE"

# ─── 4. Systemd user environment ──────────────────────────────────────────────
log "Writing systemd user environment (environment.d)..."
ENV_DIR="$HOME/.config/environment.d"
mkdir -p "$ENV_DIR"
cat > "$ENV_DIR/cursor.conf" << EOF
XCURSOR_THEME=$CURSOR_THEME
XCURSOR_SIZE=$CURSOR_SIZE
EOF
log_done "environment.d/cursor.conf written"

# ─── 5. COSMIC DE ─────────────────────────────────────────────────────────────
log "Configuring COSMIC DE cursor size..."
COSMIC_COMP="$HOME/.config/cosmic/com.system76.CosmicComp/v1"
mkdir -p "$COSMIC_COMP"
printf '%s' "$CURSOR_SIZE" > "$COSMIC_COMP/cursor_size"
log_done "COSMIC cursor_size set to $CURSOR_SIZE"

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BRIGHT_GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BRIGHT_GREEN}║  Vimix green cursor installed and configured.        ║${NC}"
echo -e "${BRIGHT_GREEN}║                                                      ║${NC}"
echo -e "${BRIGHT_GREEN}║  Log out and back in for the cursor to take effect.  ║${NC}"
echo -e "${BRIGHT_GREEN}╚══════════════════════════════════════════════════════╝${NC}"
