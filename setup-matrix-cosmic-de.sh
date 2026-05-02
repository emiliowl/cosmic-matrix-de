#!/usr/bin/env bash
# Matrix Cosmic DE visual setup
# Writes: wallpaper, dark mode, matrix-green accent, sharp corners,
#         terminal + monospace font, autotile

set -e

GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
NC='\033[0m'

log()      { echo -e "${BRIGHT_GREEN}[MATRIX]${GREEN} $1${NC}"; }
log_done() { echo -e "${BRIGHT_GREEN}[MATRIX] ✓ $1${NC}"; }
log_warn() { echo -e "${BRIGHT_GREEN}[MATRIX] ⚠ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COSMIC_CFG="$HOME/.config/cosmic"

# ─── Guard ────────────────────────────────────────────────────────────────────
if [ ! -d "$COSMIC_CFG" ]; then
  log_warn "~/.config/cosmic not found — is COSMIC DE installed?"
  read -rp "Continue anyway? [y/N] " _ans
  [[ "$_ans" =~ ^[Yy]$ ]] || exit 1
fi

write_ron() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  # Use printf so heredoc content doesn't get a trailing newline mangled
  printf '%s' "$2" > "$path"
}

# ─── 1. Wallpaper ─────────────────────────────────────────────────────────────
log "Setting up wallpaper..."
WALLPAPER_NAME="matrix-falling-code-3840x2160-15697.jpg"
WALLPAPER_SRC="$SCRIPT_DIR/wallpapers/$WALLPAPER_NAME"
WALLPAPER_DEST="$HOME/Pictures/$WALLPAPER_NAME"

if [ -f "$WALLPAPER_SRC" ]; then
  mkdir -p "$HOME/Pictures"
  cp "$WALLPAPER_SRC" "$WALLPAPER_DEST"
  log_done "Wallpaper copied to $WALLPAPER_DEST"
else
  log_warn "wallpapers/$WALLPAPER_NAME not found in repo — skipping copy."
  log_warn "Place it manually at: $WALLPAPER_DEST"
fi

BG_DIR="$COSMIC_CFG/com.system76.CosmicBackground/v1"
mkdir -p "$BG_DIR"

write_ron "$BG_DIR/all" "(
    output: \"all\",
    source: Path(\"$WALLPAPER_DEST\"),
    filter_by_theme: true,
    rotation_frequency: 300,
    filter_method: Lanczos,
    scaling_mode: Zoom,
    sampling_method: Alphanumeric,
)"
write_ron "$BG_DIR/same-on-all" "true"
log_done "Background config written"

# ─── 2. Dark mode ─────────────────────────────────────────────────────────────
log "Enabling dark mode..."
MODE_DIR="$COSMIC_CFG/com.system76.CosmicTheme.Mode/v1"
mkdir -p "$MODE_DIR"
write_ron "$MODE_DIR/is_dark" "true"
log_done "Dark mode enabled"

# ─── 3. Matrix green accent + sharp corners ───────────────────────────────────
log "Applying matrix green accent..."
BUILDER_DIR="$COSMIC_CFG/com.system76.CosmicTheme.Dark.Builder/v1"
mkdir -p "$BUILDER_DIR"

# Matrix green: roughly #14DD25 in linear light
write_ron "$BUILDER_DIR/accent" "Some((
    red: 0.078516245,
    green: 0.866248,
    blue: 0.14417365,
))"

# Sharp corners — keeps the hacker/terminal aesthetic
write_ron "$BUILDER_DIR/corner_radii" "(
    radius_0: (0.0, 0.0, 0.0, 0.0),
    radius_xs: (2.0, 2.0, 2.0, 2.0),
    radius_s: (8.0, 8.0, 8.0, 8.0),
    radius_m: (8.0, 8.0, 8.0, 8.0),
    radius_l: (8.0, 8.0, 8.0, 8.0),
    radius_xl: (8.0, 8.0, 8.0, 8.0),
)"

write_ron "$BUILDER_DIR/spacing" "(
    space_none: 0,
    space_xxxs: 4,
    space_xxs: 8,
    space_xs: 12,
    space_s: 16,
    space_m: 24,
    space_l: 32,
    space_xl: 48,
    space_xxl: 64,
    space_xxxl: 128,
)"

log_done "Theme builder written (dark green, sharp corners)"

# ─── 4. Cosmic Terminal font ──────────────────────────────────────────────────
log "Configuring Cosmic Terminal font..."
TERM_DIR="$COSMIC_CFG/com.system76.CosmicTerm/v1"
mkdir -p "$TERM_DIR"
write_ron "$TERM_DIR/font_name" "\"MesloLGS NF\""
write_ron "$TERM_DIR/font_size" "13.0"
log_done "Cosmic Terminal: MesloLGS NF 13"

# ─── 5. System monospace font ─────────────────────────────────────────────────
log "Setting system monospace font..."
TK_DIR="$COSMIC_CFG/com.system76.CosmicTk/v1"
mkdir -p "$TK_DIR"
write_ron "$TK_DIR/monospace_font" "(
    family: \"MesloLGS NF\",
    weight: Normal,
    stretch: Normal,
    style: Normal,
)"
log_done "Monospace font: MesloLGS NF"

# ─── 6. Autotile ──────────────────────────────────────────────────────────────
log "Enabling autotile..."
COMP_DIR="$COSMIC_CFG/com.system76.CosmicComp/v1"
mkdir -p "$COMP_DIR"
write_ron "$COMP_DIR/autotile" "true"
write_ron "$COMP_DIR/autotile_behavior" "PerWorkspace"
log_done "Autotile enabled (PerWorkspace)"

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BRIGHT_GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BRIGHT_GREEN}║  Cosmic DE matrix theme applied.                     ║${NC}"
echo -e "${BRIGHT_GREEN}║                                                      ║${NC}"
echo -e "${BRIGHT_GREEN}║  Log out and back in for all changes to take effect. ║${NC}"
echo -e "${BRIGHT_GREEN}╚══════════════════════════════════════════════════════╝${NC}"
