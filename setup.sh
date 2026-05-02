#!/usr/bin/env bash
# Matrix Setup — full environment setup orchestrator
#
# Usage:
#   ./setup.sh                  run everything
#   ./setup.sh --cosmic-only    skip terminal setup, apply Cosmic DE config only
#   ./setup.sh --terminal-only  skip Cosmic DE config
#   ./setup.sh --skip-cosmic    apply terminal + colors, skip Cosmic DE
#   ./setup.sh --skip-terminal  skip zsh/p10k install
#   ./setup.sh --skip-colors    skip terminal color profiles
#   ./setup.sh --skip-cursor    skip cursor theme setup

set -e

GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()      { echo -e "${BRIGHT_GREEN}[MATRIX]${GREEN} $1${NC}"; }
log_done() { echo -e "${BRIGHT_GREEN}[MATRIX] ✓ $1${NC}"; }

echo ""
echo -e "${BRIGHT_GREEN}  ╔╦╗╦ ╦╔═╗  ╔╦╗╔═╗╔╦╗╦═╗╦═╗ ╦${NC}"
echo -e "${BRIGHT_GREEN}   ║ ╠═╣║╣   ║║║╠═╣ ║ ╠╦╝║╠╩╗╠╩╗${NC}"
echo -e "${BRIGHT_GREEN}   ╩ ╩ ╩╚═╝  ╩ ╩╩ ╩ ╩ ╩╚═╩╩ ╩╩ ╩${NC}"
echo -e "${BRIGHT_GREEN}  Full environment setup — $(date '+%Y-%m-%d')${NC}"
echo ""

SKIP_TERMINAL=0
SKIP_COLORS=0
SKIP_COSMIC=0
SKIP_CURSOR=0

for arg in "$@"; do
  case $arg in
    --skip-terminal)  SKIP_TERMINAL=1 ;;
    --skip-colors)    SKIP_COLORS=1 ;;
    --skip-cosmic)    SKIP_COSMIC=1 ;;
    --skip-cursor)    SKIP_CURSOR=1 ;;
    --cosmic-only)    SKIP_TERMINAL=1; SKIP_COLORS=1 ;;
    --terminal-only)  SKIP_COSMIC=1; SKIP_CURSOR=1 ;;
    -h|--help)
      sed -n '3,10p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg  (run with --help for usage)"
      exit 1
      ;;
  esac
done

# ─── Step 1: zsh + Oh My Zsh + Powerlevel10k ──────────────────────────────────
if [ "$SKIP_TERMINAL" = 0 ]; then
  log "Step 1/4 — Terminal (zsh, Oh My Zsh, p10k, fonts)..."
  bash "$SCRIPT_DIR/setup-matrix-terminal.sh"
  log_done "Terminal setup complete"
else
  log "Step 1/4 — Skipping terminal setup"
fi

# ─── Step 2: Terminal color profiles ──────────────────────────────────────────
if [ "$SKIP_COLORS" = 0 ]; then
  log "Step 2/4 — Terminal color profiles (GNOME Terminal, Tilix, Cosmic Term)..."
  bash "$SCRIPT_DIR/setup-matrix-terminal-colors.sh"
  log_done "Terminal colors applied"
else
  log "Step 2/4 — Skipping terminal colors"
fi

# ─── Step 3: Cosmic DE visual config ──────────────────────────────────────────
if [ "$SKIP_COSMIC" = 0 ]; then
  log "Step 3/4 — Cosmic DE (wallpaper, theme, fonts, autotile)..."
  bash "$SCRIPT_DIR/setup-matrix-cosmic-de.sh"
  log_done "Cosmic DE setup complete"
else
  log "Step 3/4 — Skipping Cosmic DE setup"
fi

# ─── Step 4: Cursor theme ─────────────────────────────────────────────────────
if [ "$SKIP_CURSOR" = 0 ]; then
  log "Step 4/4 — Cursor (Vimix-green-cursors)..."
  bash "$SCRIPT_DIR/setup-matrix-cursor.sh"
  log_done "Cursor setup complete"
else
  log "Step 4/4 — Skipping cursor setup"
fi

echo ""
echo -e "${BRIGHT_GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BRIGHT_GREEN}║  All done. The Matrix has you.                       ║${NC}"
echo -e "${BRIGHT_GREEN}║                                                      ║${NC}"
echo -e "${BRIGHT_GREEN}║  Next steps:                                         ║${NC}"
echo -e "${BRIGHT_GREEN}║  1. Log out and back in (or reboot)                  ║${NC}"
echo -e "${BRIGHT_GREEN}║  2. Run: exec zsh                                    ║${NC}"
echo -e "${BRIGHT_GREEN}║  3. Run: p10k configure  (first run)                 ║${NC}"
echo -e "${BRIGHT_GREEN}╚══════════════════════════════════════════════════════╝${NC}"
