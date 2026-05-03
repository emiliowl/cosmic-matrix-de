#!/usr/bin/env bash
# Matrix Cosmic DE visual setup
# Writes: wallpaper, matrix-green accent, sharp corners, green-tinted bg,
#         frosted panels, terminal + UI fonts, toolkit settings, autotile

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

# ─── 2. Matrix green accent + sharp corners ───────────────────────────────────
log "Applying matrix green accent and theme builder settings..."
BUILDER_DIR="$COSMIC_CFG/com.system76.CosmicTheme.Dark.Builder/v1"
mkdir -p "$BUILDER_DIR"

# Matrix green: #00FF41 in linear light
write_ron "$BUILDER_DIR/accent" "Some((
    red: 0.0,
    green: 1.0,
    blue: 0.254902,
))"

# Fully sharp corners — keeps the hacker/terminal aesthetic
write_ron "$BUILDER_DIR/corner_radii" "(
    radius_0: (0.0, 0.0, 0.0, 0.0),
    radius_xs: (0.0, 0.0, 0.0, 0.0),
    radius_s: (0.0, 0.0, 0.0, 0.0),
    radius_m: (0.0, 0.0, 0.0, 0.0),
    radius_l: (0.0, 0.0, 0.0, 0.0),
    radius_xl: (0.0, 0.0, 0.0, 0.0),
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

# Near-black background with a green tint
write_ron "$BUILDER_DIR/bg_color" "Some((
    red: 0.0,
    green: 0.0274,
    blue: 0.0,
    alpha: 1.0,
))"

# Green-tinted neutrals (panels, sidebars, etc.)
write_ron "$BUILDER_DIR/neutral_tint" "Some((
    red: 0.0,
    green: 0.56,
    blue: 0.067,
))"

write_ron "$BUILDER_DIR/is_frosted" "true"
write_ron "$BUILDER_DIR/gaps" "(0, 4)"
write_ron "$BUILDER_DIR/active_hint" "2"

log_done "Theme builder written (accent #00FF41, fully sharp, green-tinted bg)"

# ─── 3. Cosmic Terminal ───────────────────────────────────────────────────────
log "Configuring Cosmic Terminal..."
TERM_DIR="$COSMIC_CFG/com.system76.CosmicTerm/v1"
mkdir -p "$TERM_DIR"
write_ron "$TERM_DIR/font_name" "\"JetBrainsMono Nerd Font Mono\""
write_ron "$TERM_DIR/font_size" "16"
write_ron "$TERM_DIR/app_theme" "Dark"
write_ron "$TERM_DIR/syntax_theme_dark" "\"COSMIC Dark\""
write_ron "$TERM_DIR/opacity" "80"
write_ron "$TERM_DIR/show_headerbar" "true"
log_done "Cosmic Terminal: JetBrainsMono Nerd Font Mono 16, dark, 80% opacity"

# ─── 4. System fonts + toolkit settings ──────────────────────────────────────
log "Setting system fonts and toolkit settings..."
TK_DIR="$COSMIC_CFG/com.system76.CosmicTk/v1"
mkdir -p "$TK_DIR"
write_ron "$TK_DIR/monospace_font" "(
    family: \"JetBrainsMono Nerd Font\",
    weight: Normal,
    stretch: Normal,
    style: Normal,
)"
write_ron "$TK_DIR/interface_font" "(
    family: \"JetBrainsMonoNL Nerd Font\",
    weight: Normal,
    stretch: Normal,
    style: Normal,
)"
write_ron "$TK_DIR/icon_theme" "\"Cosmic\""
write_ron "$TK_DIR/apply_theme_global" "true"
write_ron "$TK_DIR/interface_density" "Standard"
write_ron "$TK_DIR/header_size" "Standard"
log_done "Fonts: JetBrainsMono Nerd Font (mono), JetBrainsMonoNL Nerd Font (UI)"

# ─── 5. Autotile ──────────────────────────────────────────────────────────────
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
