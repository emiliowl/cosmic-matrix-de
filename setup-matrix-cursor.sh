#!/usr/bin/env bash
# Matrix Cursor Setup
# Installs one of two Matrix-green cursor themes:
#   greenglass           — glass/translucent look (bundled in repo)
#   Vimix-green-cursors  — geometric/solid look (built from SVG source)
# Configures GTK3/4, systemd env, COSMIC DE, and X11 default.
set -e

GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
NC='\033[0m'

log()      { echo -e "${BRIGHT_GREEN}[MATRIX]${GREEN} $1${NC}"; }
log_done() { echo -e "${BRIGHT_GREEN}[MATRIX] ✓ $1${NC}"; }
log_warn() { echo -e "${BRIGHT_GREEN}[MATRIX] ⚠ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="$HOME/.icons"

# ─── 1. Theme selection ───────────────────────────────────────────────────────
echo ""
echo -e "${BRIGHT_GREEN}  Choose a cursor theme:${NC}"
echo -e "${GREEN}  1) greenglass          (glass/translucent look — recommended)${NC}"
echo -e "${GREEN}  2) Vimix-green-cursors (geometric/solid look — built from SVG)${NC}"
echo ""
read -rp "$(echo -e "${BRIGHT_GREEN}  Enter choice [1/2, default=1]: ${NC}")" _choice

case "${_choice:-1}" in
  1)
    CURSOR_THEME="greenglass"
    CURSOR_SIZE=24
    ;;
  2)
    CURSOR_THEME="Vimix-green-cursors"
    CURSOR_SIZE=36
    ;;
  *)
    echo "Invalid choice. Run again and enter 1 or 2."
    exit 1
    ;;
esac

log "Selected: $CURSOR_THEME (default size: ${CURSOR_SIZE}px)"

# ─── 2. Install cursor theme ──────────────────────────────────────────────────
INSTALL_DIR="$ICONS_DIR/$CURSOR_THEME"

if [ "$CURSOR_THEME" = "greenglass" ]; then
  # ── greenglass: install from bundled repo files ───────────────────────────
  BUNDLE="$SCRIPT_DIR/cursors/greenglass"
  if [ ! -d "$BUNDLE/cursors" ]; then
    log_warn "cursors/greenglass not found in repo at $BUNDLE"
    exit 1
  fi

  if [ -d "$INSTALL_DIR/cursors" ]; then
    log_done "greenglass already installed at $INSTALL_DIR"
  else
    log "Installing greenglass from repo bundle..."
    mkdir -p "$ICONS_DIR"
    cp -r "$BUNDLE" "$INSTALL_DIR"
    log_done "greenglass installed to $INSTALL_DIR"
  fi

else
  # ── Vimix-green-cursors: build from SVG source ────────────────────────────
  if [ -d "$INSTALL_DIR/cursors" ]; then
    log_done "Vimix-green-cursors already installed at $INSTALL_DIR"
  else
    log "Building Vimix-green-cursors (Matrix green recolor of Vimix-cursors)..."

    log "Installing build dependencies..."
    sudo apt-get install -y -qq x11-apps librsvg2-bin
    log_done "Build deps ready"

    TMPDIR_BUILD="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR_BUILD"' EXIT

    git clone --depth=1 https://github.com/vinceliuice/Vimix-cursors.git "$TMPDIR_BUILD/src"
    cd "$TMPDIR_BUILD/src"

    # Recolor SVGs to Matrix green
    # Original: #000000 (body), #1a1a1a (shadow), #333333 (stroke), #ffffff (highlight)
    # Matrix:   #00FF41 (body), #00CC33 (shadow), #005f00 (stroke), #ffffff (highlight)
    cp -r src/svg/ src/svg-green/
    find src/svg-green/ -name "*.svg" -exec sed -i \
      -e 's/#000000/#00FF41/g' \
      -e 's/#1a1a1a/#00CC33/g' \
      -e 's/#333333/#005f00/g' \
      {} +
    log_done "SVG colors patched to Matrix green"

    log "Rendering cursor PNGs..."
    SRC="$TMPDIR_BUILD/src/src"
    mkdir -p "$SRC/x1" "$SRC/x1_25" "$SRC/x1_5" "$SRC/x2"
    find "$SRC/svg-green/" -name "*.svg" -type f | while read -r svg; do
      base="$(basename "${svg%.svg}")"
      rsvg-convert -w 32 -h 32 -o "$SRC/x1/${base}.png"    "$svg"
      rsvg-convert -w 40 -h 40 -o "$SRC/x1_25/${base}.png" "$svg"
      rsvg-convert -w 48 -h 48 -o "$SRC/x1_5/${base}.png"  "$svg"
      rsvg-convert -w 64 -h 64 -o "$SRC/x2/${base}.png"    "$svg"
    done
    log_done "PNGs rendered"

    log "Generating X11 cursor files..."
    BUILD_CURSORS="$TMPDIR_BUILD/src/dist-green/cursors"
    mkdir -p "$BUILD_CURSORS"
    cd "$SRC"
    for cur_cfg in config/*.cursor; do
      name="$(basename "${cur_cfg%.*}")"
      xcursorgen "$cur_cfg" "$BUILD_CURSORS/$name"
    done

    while read -r alias_line; do
      from="${alias_line#* }"
      to="${alias_line% *}"
      [ -e "$BUILD_CURSORS/$to" ] || ln -sr "$BUILD_CURSORS/$from" "$BUILD_CURSORS/$to"
    done < cursorList
    log_done "X11 cursor files generated"

    printf '[Icon Theme]\nName=Vimix Green Cursors\n' > "$TMPDIR_BUILD/src/dist-green/index.theme"
    mkdir -p "$ICONS_DIR"
    cp -r "$TMPDIR_BUILD/src/dist-green" "$INSTALL_DIR"
    log_done "Vimix-green-cursors installed to $INSTALL_DIR"
  fi
fi

# ─── 3. Default X11 cursor pointer ───────────────────────────────────────────
log "Setting X11 default cursor..."
mkdir -p "$ICONS_DIR/default"
cat > "$ICONS_DIR/default/index.theme" << EOF
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$CURSOR_THEME
EOF
log_done "~/.icons/default → $CURSOR_THEME"

# ─── 4. GTK 3 ─────────────────────────────────────────────────────────────────
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
log_done "GTK3: $CURSOR_THEME @ ${CURSOR_SIZE}px"

# ─── 5. GTK 4 ─────────────────────────────────────────────────────────────────
log "Configuring GTK4 cursor..."
GTK4="$HOME/.config/gtk-4.0/settings.ini"
mkdir -p "$(dirname "$GTK4")"
[ -f "$GTK4" ] || printf '[Settings]\n' > "$GTK4"

set_ini_key "$GTK4" "gtk-cursor-theme-name" "$CURSOR_THEME"
set_ini_key "$GTK4" "gtk-cursor-theme-size" "$CURSOR_SIZE"
log_done "GTK4: $CURSOR_THEME @ ${CURSOR_SIZE}px"

# ─── 6. Environment ───────────────────────────────────────────────────────────
log "Writing cursor environment..."
mkdir -p "$HOME/.config/environment.d"
cat > "$HOME/.config/environment.d/cursor.conf" << EOF
XCURSOR_THEME=$CURSOR_THEME
XCURSOR_SIZE=$CURSOR_SIZE
EOF
log_done "environment.d/cursor.conf written"

for key_val in "XCURSOR_THEME=$CURSOR_THEME" "XCURSOR_SIZE=$CURSOR_SIZE"; do
  key="${key_val%%=*}"
  if grep -q "^${key}=" /etc/environment 2>/dev/null; then
    sudo sed -i "s|^${key}=.*|${key_val}|" /etc/environment
  else
    echo "$key_val" | sudo tee -a /etc/environment > /dev/null
  fi
done
log_done "/etc/environment updated"

# ─── 7. COSMIC DE ─────────────────────────────────────────────────────────────
log "Configuring COSMIC DE cursor..."
COSMIC_COMP="$HOME/.config/cosmic/com.system76.CosmicComp/v1"
mkdir -p "$COSMIC_COMP"
printf '%s'  "$CURSOR_SIZE"    > "$COSMIC_COMP/cursor_size"
printf '"%s"' "$CURSOR_THEME" > "$COSMIC_COMP/cursor_theme"
log_done "COSMIC cursor_theme=$CURSOR_THEME, cursor_size=${CURSOR_SIZE}px"

# ─── 8. Apply live via gsettings ──────────────────────────────────────────────
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
echo -e "${BRIGHT_GREEN}║  Cursor theme: ${CURSOR_THEME}${NC}"
printf  "${BRIGHT_GREEN}║  Size: ${CURSOR_SIZE}px  (change with: ./setup-matrix-cursor-size.sh)   ║${NC}\n"
echo -e "${BRIGHT_GREEN}║                                                      ║${NC}"
echo -e "${BRIGHT_GREEN}║  Log out and back in for COSMIC DE to pick it up.    ║${NC}"
echo -e "${BRIGHT_GREEN}╚══════════════════════════════════════════════════════╝${NC}"
