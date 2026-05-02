#!/usr/bin/env bash
# Apply Matrix color scheme to GNOME Terminal (also works on Pop!_OS)
# Run AFTER setup-matrix-terminal.sh

GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
NC='\033[0m'

log() { echo -e "${BRIGHT_GREEN}[MATRIX]${GREEN} $1${NC}"; }

# ─── GNOME Terminal (dconf-based) ──────────────────────────────────────────────
if command -v dconf &>/dev/null && command -v gnome-terminal &>/dev/null 2>&1; then
  log "Applying Matrix colors to GNOME Terminal..."

  PROFILE_ID="$(dconf list /org/gnome/terminal/legacy/profiles:/ 2>/dev/null | head -1 | tr -d '/:' || true)"

  if [ -z "$PROFILE_ID" ]; then
    PROFILE_ID="$(uuidgen)"
    dconf write /org/gnome/terminal/legacy/profiles:/default "'$PROFILE_ID'"
    dconf write /org/gnome/terminal/legacy/profiles:/list "['$PROFILE_ID']"
  fi

  BASE="/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID"

  dconf write "$BASE/visible-name"        "'Matrix'"
  dconf write "$BASE/use-theme-colors"    "false"
  dconf write "$BASE/background-color"    "'#0D0D0D'"
  dconf write "$BASE/foreground-color"    "'#00FF41'"
  dconf write "$BASE/cursor-color"        "'#00FF41'"
  dconf write "$BASE/cursor-blink-mode"   "'on'"
  dconf write "$BASE/bold-color"          "'#00FF41'"
  dconf write "$BASE/bold-color-same-as-fg" "false"
  dconf write "$BASE/use-system-font"     "false"
  dconf write "$BASE/font"                "'MesloLGS NF 13'"
  dconf write "$BASE/scrollbar-policy"    "'never'"
  dconf write "$BASE/use-transparent-background" "false"

  # 16-color palette (Matrix green theme)
  # Black  DkRed  DkGreen  DkYellow DkBlue DkMagenta DkCyan  LtGray
  # DkGray BrRed  BrGreen  BrYellow BrBlue BrMagenta BrCyan  White
  PALETTE="['#0D0D0D', '#CC0000', '#00AA00', '#00AA00', '#003B00', '#007700', '#00CC44', '#00FF41', '#003300', '#FF0000', '#00FF41', '#33FF33', '#006600', '#00CC66', '#00FF99', '#CCFFCC']"
  dconf write "$BASE/palette" "$PALETTE"

  log "GNOME Terminal profile 'Matrix' applied."
fi

# ─── Tilix (if installed) ──────────────────────────────────────────────────────
if command -v tilix &>/dev/null; then
  log "Applying Matrix colors to Tilix..."
  TILIX_DIR="$HOME/.config/tilix/schemes"
  mkdir -p "$TILIX_DIR"
  cat > "$TILIX_DIR/matrix.json" << 'JSON'
{
    "background-color": "#0D0D0D",
    "badge-color": "#00FF41",
    "bold-color": "#00FF41",
    "comment": "Matrix color scheme",
    "cursor-background-color": "#00FF41",
    "cursor-foreground-color": "#0D0D0D",
    "foreground-color": "#00FF41",
    "highlight-background-color": "#003B00",
    "highlight-foreground-color": "#00FF41",
    "name": "Matrix",
    "palette": [
        "#0D0D0D",
        "#CC0000",
        "#00AA00",
        "#007700",
        "#003B00",
        "#007700",
        "#00CC44",
        "#00FF41",
        "#003300",
        "#FF0000",
        "#00FF41",
        "#33FF33",
        "#006600",
        "#00CC66",
        "#00FF99",
        "#CCFFCC"
    ],
    "use-badge-color": false,
    "use-bold-color": false,
    "use-cursor-color": true,
    "use-highlight-color": true,
    "use-theme-colors": false
}
JSON
  log "Tilix scheme saved to $TILIX_DIR/matrix.json"
  log "In Tilix: Preferences → Profile → Color → Color scheme → Matrix"
fi

# ─── Cosmic Terminal (Pop!_OS / COSMIC DE native) ─────────────────────────────
# Cosmic Term inherits colors from the system theme.
# Running setup-matrix-cosmic-de.sh applies the dark matrix-green theme system-wide,
# which automatically makes Cosmic Term look correct — no separate color file needed.
COSMIC_TERM_DIR="$HOME/.config/cosmic/com.system76.CosmicTerm/v1"
if [ -d "$(dirname "$COSMIC_TERM_DIR")" ] || command -v cosmic-term &>/dev/null 2>&1; then
  mkdir -p "$COSMIC_TERM_DIR"
  log "Cosmic Terminal detected — applying font..."

  printf '"MesloLGS NF"' > "$COSMIC_TERM_DIR/font_name"
  printf '13.0'           > "$COSMIC_TERM_DIR/font_size"

  log "Cosmic Terminal font: MesloLGS NF 13"
  log "Theme colors (background #0D0D0D, foreground #00FF41) come from setup-matrix-cosmic-de.sh"
fi

echo ""
echo -e "${BRIGHT_GREEN}Matrix color profiles applied.${NC}"
echo -e "${BRIGHT_GREEN}Restart your terminal to see the changes.${NC}"
