#!/bin/bash

# WezTerm Interactive Cheatsheet
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

clear
echo ""
echo -e "${BOLD}🚀 WezTerm Keyboard Shortcuts Cheatsheet${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

while true; do
    echo -e "${CYAN}Select a category:${NC}"
    echo "1) 📑 Tab Management"
    echo "2) 🪟 Pane Management"
    echo "3) 📋 Copy & Paste"
    echo "4) 🔍 Search & Navigation"
    echo "5) 🎨 View & Display"
    echo "6) 💡 Show All"
    echo "7) 🚪 Exit"
    echo ""
    read -p "Enter your choice (1-7): " choice

    case $choice in
        1)
            clear
            echo -e "${BOLD}📑 TAB MANAGEMENT${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${GREEN}Cmd + T${NC}              → New tab"
            echo -e "${GREEN}Cmd + W${NC}              → Close tab/pane"
            echo -e "${GREEN}Cmd + [${NC}              → Previous tab"
            echo -e "${GREEN}Cmd + ]${NC}              → Next tab"
            echo -e "${GREEN}Cmd + Shift + T${NC}      → Show tab navigator"
            echo -e "${GREEN}Cmd + 1-9${NC}            → Go to tab number"
            echo ""
            ;;
        2)
            clear
            echo -e "${BOLD}🪟 PANE MANAGEMENT${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}Creating Panes:${NC}"
            echo -e "${GREEN}Cmd + D${NC}              → Split horizontal"
            echo -e "${GREEN}Cmd + Shift + D${NC}      → Split vertical"
            echo ""
            echo -e "${YELLOW}Navigating Panes:${NC}"
            echo -e "${GREEN}Cmd + Alt + H${NC}        → Move to left pane"
            echo -e "${GREEN}Cmd + Alt + L${NC}        → Move to right pane"
            echo -e "${GREEN}Cmd + Alt + K${NC}        → Move to upper pane"
            echo -e "${GREEN}Cmd + Alt + J${NC}        → Move to lower pane"
            echo ""
            echo -e "${YELLOW}Resizing Panes:${NC}"
            echo -e "${GREEN}Cmd + Shift + H${NC}      → Resize pane left"
            echo -e "${GREEN}Cmd + Shift + L${NC}      → Resize pane right"
            echo -e "${GREEN}Cmd + Shift + K${NC}      → Resize pane up"
            echo -e "${GREEN}Cmd + Shift + J${NC}      → Resize pane down"
            echo ""
            echo -e "${GREEN}Cmd + Shift + Z${NC}      → Toggle pane zoom"
            echo ""
            ;;
        3)
            clear
            echo -e "${BOLD}📋 COPY & PASTE${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${GREEN}Cmd + C${NC}              → Copy"
            echo -e "${GREEN}Cmd + V${NC}              → Paste"
            echo -e "${GREEN}Cmd + Shift + X${NC}      → Enter copy mode"
            echo -e "${GREEN}Cmd + Shift + P${NC}      → Quick select (URLs, paths, hashes)"
            echo ""
            echo -e "${YELLOW}💡 Tip:${NC} Quick select is great for copying file paths, URLs, git hashes!"
            echo ""
            ;;
        4)
            clear
            echo -e "${BOLD}🔍 SEARCH & NAVIGATION${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${GREEN}Cmd + F${NC}              → Search in terminal"
            echo -e "${GREEN}Cmd + K${NC}              → Clear screen"
            echo -e "${GREEN}Ctrl + Click${NC}         → Open hyperlink"
            echo ""
            echo -e "${YELLOW}💡 Tip:${NC} Regular click selects text, Ctrl+Click opens links!"
            echo ""
            ;;
        5)
            clear
            echo -e "${BOLD}🎨 VIEW & DISPLAY${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${GREEN}Cmd + =${NC}              → Increase font size"
            echo -e "${GREEN}Cmd + -${NC}              → Decrease font size"
            echo -e "${GREEN}Cmd + 0${NC}              → Reset font size"
            echo -e "${GREEN}Cmd + Alt + Enter${NC}    → Toggle fullscreen"
            echo ""
            echo -e "${YELLOW}Features enabled:${NC}"
            echo "• Automatic light/dark theme switching"
            echo "• Visual bell (no sound)"
            echo "• 10,000 lines scrollback"
            echo "• Status bar with workspace & directory"
            echo "• Tab bar auto-hides with single tab"
            echo ""
            ;;
        6)
            clear
            echo -e "${BOLD}🚀 ALL WEZTERM SHORTCUTS${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            wezhelp
            echo ""
            ;;
        7)
            clear
            echo -e "${GREEN}Happy terminal hacking! 🚀${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice! Please select 1-7.${NC}"
            echo ""
            ;;
    esac
    
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
    clear
done
