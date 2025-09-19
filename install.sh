#!/bin/bash

# Interactive install script for Claude Code agents and commands
# Prompts user for each component and provides removal options

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to ask yes/no questions
ask_yes_no() {
    local question="$1"
    local response
    while true; do
        echo -e "${BLUE}$question${NC} [y/N]: "
        read -r response
        case $response in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]|"") return 1 ;;
            *) echo -e "${RED}Please answer yes or no.${NC}" ;;
        esac
    done
}

# Function to ask about removal
ask_removal() {
    local component="$1"
    local script="$2"
    if ask_yes_no "Would you like to remove existing $component symlinks first?"; then
        if [ -f "$script" ]; then
            echo -e "${YELLOW}Removing existing $component symlinks...${NC}"
            ./"$script"
        else
            echo -e "${RED}Warning: $script not found${NC}"
        fi
    fi
}

echo -e "${BLUE}Interactive Claude Code Agent Installer${NC}"
echo -e "${BLUE}=====================================${NC}"
echo

# Check for removal scripts and offer removal options
if [ -d ~/.claude/agents ] && [ "$(ls -A ~/.claude/agents 2>/dev/null)" ]; then
    echo -e "${YELLOW}Existing agent installations detected.${NC}"
    echo

    # Check for dLabs agents
    if ls ~/.claude/agents/dLabs-* >/dev/null 2>&1; then
        ask_removal "dLabs agents" "remove_dlabs_agents.sh"
    fi

    # Check for wshobson agents
    if ls ~/.claude/agents/wshobson-* >/dev/null 2>&1; then
        ask_removal "wshobson agents" "remove_wshobson_agents.sh"
    fi

    # Check for awesome agents
    if ls ~/.claude/agents/*-* >/dev/null 2>&1 | grep -v -E "(dLabs-|wshobson-)" >/dev/null 2>&1; then
        ask_removal "awesome-claude-code-subagents" "remove_awesome_agents.sh"
    fi
fi

if [ -d ~/.claude/commands ] && [ "$(ls -A ~/.claude/commands 2>/dev/null)" ]; then
    # Check for wshobson commands
    if [ -d ~/.claude/commands/tools ] || [ -d ~/.claude/commands/workflows ]; then
        ask_removal "wshobson commands" "remove_wshobson_commands.sh"
    fi
fi

echo

# Ask about dLabs agents
if ask_yes_no "Install dLabs agents (local specialized agents)?"; then
    echo -e "${YELLOW}Setting up dLabs agents...${NC}"
    ./setup_agents.sh
    echo
fi

# Ask about awesome-claude-code-subagents
if ask_yes_no "Install awesome-claude-code-subagents (116 industry-standard agents)?"; then
    if [ ! -d "awesome-claude-code-subagents" ]; then
        echo -e "${YELLOW}Cloning awesome-claude-code-subagents...${NC}"
        gh repo clone VoltAgent/awesome-claude-code-subagents awesome-claude-code-subagents
    else
        echo -e "${YELLOW}awesome-claude-code-subagents already exists, pulling latest...${NC}"
        cd awesome-claude-code-subagents && git pull && cd ..
    fi
    echo -e "${YELLOW}Setting up awesome-claude-code-subagents...${NC}"
    ./setup_awesome_agents_symlinks.sh
    echo
fi

# Ask about wshobson agents
if ask_yes_no "Install wshobson agents (82 production-ready agents)?"; then
    if [ ! -d "wshobson-agents" ]; then
        echo -e "${YELLOW}Cloning wshobson-agents...${NC}"
        gh repo clone wshobson/agents wshobson-agents
    else
        echo -e "${YELLOW}wshobson-agents already exists, pulling latest...${NC}"
        cd wshobson-agents && git pull && cd ..
    fi
    echo -e "${YELLOW}Setting up wshobson agents...${NC}"
    ./setup_wshobson_agents_symlinks.sh
    echo
fi

# Ask about wshobson commands
if ask_yes_no "Install wshobson commands (56 workflow tools)?"; then
    if [ ! -d "wshobson-commands" ]; then
        echo -e "${YELLOW}Cloning wshobson-commands...${NC}"
        gh repo clone wshobson/commands wshobson-commands
    else
        echo -e "${YELLOW}wshobson-commands already exists, pulling latest...${NC}"
        cd wshobson-commands && git pull && cd ..
    fi
    echo -e "${YELLOW}Setting up wshobson commands...${NC}"
    ./setup_wshobson_commands_symlinks.sh
    echo
fi

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}Selected agents and commands are now available in ~/.claude/${NC}"
