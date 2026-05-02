#!/usr/bin/env bash
# Matrix Cursor Setup: Vimix-green-cursors (size 48)
# Builds green variant from Vimix-cursors SVG source (recolored to Matrix green)
# and configures GTK3/4, systemd env, COSMIC DE, and X11 default.
set -e

GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
NC='\033[0m'

log()      { echo -e "${BRIGHT_GREEN}[MATRIX]${GREEN} $1${NC}"; }
log_done() { echo -e "${BRIGHT_GREEN}[MATRIX] ✓ $1${NC}"; }
log_warn() { echo -e "${BRIGHT_GREEN}[MATRIX] ⚠ $1${NC}"; }

CURSOR_THEME="Vimix-green-cursors"
CURSOR_SIZE=48
ICONS_DIR="$HOME/.icons"
INSTALL_DIR="$ICONS_DIR/$CURSOR_THEME"

# ─── 1. Install cursor theme ──────────────────────────────────────────────────
log "Checking for $CURSOR_THEME..."

if [ -d "$INSTALL_DIR/cursors" ]; then
  log_done "$CURSOR_THEME already installed at $INSTALL_DIR"
else
  log "Building $CURSOR_THEME (Matrix green recolor of Vimix-cursors)..."

  # Build deps
  log "Installing build dependencies..."
  sudo apt-get install -y -qq x11-apps python3-cairosvg
  log_done "Build deps ready"

  TMPDIR_BUILD="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR_BUILD"' EXIT

  git clone --depth=1 https://github.com/vinceliuice/Vimix-cursors.git "$TMPDIR_BUILD/src"
  cd "$TMPDIR_BUILD/src"

  # Copy SVG source and recolor to Matrix green
  # Original palette: #000000 (body), #1a1a1a (shadow), #333333 (stroke), #ffffff (highlight)
  # Matrix palette:   #00FF41 (body), #00CC33 (shadow), #005f00 (stroke), #ffffff (highlight)
  cp -r src/svg/ src/svg-green/
  find src/svg-green/ -name "*.svg" -exec sed -i \
    -e 's/#000000/#00FF41/g' \
    -e 's/#1a1a1a/#00CC33/g' \
    -e 's/#333333/#005f00/g' \
    {} +
  log_done "SVG colors patched to Matrix green"

  # Generate PNGs at all densities
  log "Rendering cursor PNGs..."
  SRC="$TMPDIR_BUILD/src/src"
  mkdir -p "$SRC/x1" "$SRC/x1_25" "$SRC/x1_5" "$SRC/x2"
  find "$SRC/svg-green/" -name "*.svg" -type f | while read -r svg; do
    base="$(basename "${svg%.svg}")"
    python3 -c "import cairosvg; cairosvg.svg2png(url='$svg', write_to='$SRC/x1/${base}.png',    output_width=32,  output_height=32)"
    python3 -c "import cairosvg; cairosvg.svg2png(url='$svg', write_to='$SRC/x1_25/${base}.png', output_width=40,  output_height=40)"
    python3 -c "import cairosvg; cairosvg.svg2png(url='$svg', write_to='$SRC/x1_5/${base}.png',  output_width=48,  output_height=48)"
    python3 -c "import cairosvg; cairosvg.svg2png(url='$svg', write_to='$SRC/x2/${base}.png',    output_width=64,  output_height=64)"
  done
  log_done "PNGs rendered"

  # Generate X11 cursor files from .cursor configs
  log "Generating X11 cursor files..."
  BUILD_CURSORS="$TMPDIR_BUILD/src/dist-green/cursors"
  mkdir -p "$BUILD_CURSORS"
  cd "$SRC"
  for cur_cfg in config/*.cursor; do
    name="$(basename "${cur_cfg%.*}")"
    xcursorgen "$cur_cfg" "$BUILD_CURSORS/$name"
  done

  # Symlink aliases
  while read -r alias_line; do
    from="${alias_line#* }"
    to="${alias_line% *}"
    [ -e "$BUILD_CURSORS/$to" ] || ln -sr "$BUILD_CURSORS/$from" "$BUILD_CURSORS/$to"
  done < cursorList
  log_done "X11 cursor files generated"

  # Write theme index and install
  printf '[Icon Theme]\nName=Vimix Green Cursors\n' > "$TMPDIR_BUILD/src/dist-green/index.theme"
  mkdir -p "$ICONS_DIR"
  cp -r "$TMPDIR_BUILD/src/dist-green" "$INSTALL_DIR"
  log_done "$CURSOR_THEME installed to $INSTALL_DIR"
fi

# ─── 2. Default X11 cursor pointer ───────────────────────────────────────────
log "Setting X11 default cursor..."
mkdir -p "$ICONS_DIR/default"
cat > "$ICONS_DIR/default/index.theme" << EOF
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$CURSOR_THEME
EOF
log_done "~/.icons/default → $CURSOR_THEME"

# ─── 3. GTK 3 ─────────────────────────────────────────────────────────────────
log "Configuring GTK3 cursor..."
GTK3="$HOME/.config/gtk-3.0/settings.ini"
mkdir -p "$(dirname "$GTK3")"
[ -f "$GTK3" ] || printf '[Settings]\n' > "$GTK3"

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

# ─── 4. GTK 4 ─────────────────────────────────────────────────────────────────
log "Configuring GTK4 cursor..."
GTK4="$HOME/.config/gtk-4.0/settings.ini"
mkdir -p "$(dirname "$GTK4")"
[ -f "$GTK4" ] || printf '[Settings]\n' > "$GTK4"

set_ini_key "$GTK4" "gtk-cursor-theme-name" "$CURSOR_THEME"
set_ini_key "$GTK4" "gtk-cursor-theme-size" "$CURSOR_SIZE"
log_done "GTK4: $CURSOR_THEME @ $CURSOR_SIZE"

# ─── 5. Systemd user environment ──────────────────────────────────────────────
log "Writing systemd user environment..."
mkdir -p "$HOME/.config/environment.d"
cat > "$HOME/.config/environment.d/cursor.conf" << EOF
XCURSOR_THEME=$CURSOR_THEME
XCURSOR_SIZE=$CURSOR_SIZE
EOF
log_done "environment.d/cursor.conf written"

# ─── 6. COSMIC DE ─────────────────────────────────────────────────────────────
log "Configuring COSMIC DE cursor..."
COSMIC_COMP="$HOME/.config/cosmic/com.system76.CosmicComp/v1"
mkdir -p "$COSMIC_COMP"
printf '%s' "$CURSOR_SIZE"    > "$COSMIC_COMP/cursor_size"
printf '"%s"' "$CURSOR_THEME" > "$COSMIC_COMP/cursor_theme"
log_done "COSMIC cursor_theme=$CURSOR_THEME, cursor_size=$CURSOR_SIZE"

# ─── 7. Apply live via gsettings ──────────────────────────────────────────────
log "Applying cursor to current session..."
if command -v gsettings &>/dev/null; then
  gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
  gsettings set org.gnome.desktop.interface cursor-size  "$CURSOR_SIZE"
  log_done "gsettings applied (current session updated)"
else
  log_warn "gsettings not found — cursor will apply after next login"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BRIGHT_GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BRIGHT_GREEN}║  Vimix green cursor installed and configured.        ║${NC}"
echo -e "${BRIGHT_GREEN}║                                                      ║${NC}"
echo -e "${BRIGHT_GREEN}║  Log out and back in for COSMIC DE to pick it up.    ║${NC}"
echo -e "${BRIGHT_GREEN}╚══════════════════════════════════════════════════════╝${NC}"
