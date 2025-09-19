#!/bin/bash

# Install script for Claude Code agents and commands
# Clones repositories and sets up symlinks

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing Claude Code agents and commands...${NC}"
echo

# Clone repositories
echo -e "${YELLOW}Cloning repositories...${NC}"

if [ ! -d "awesome-claude-code-subagents" ]; then
    echo "Cloning awesome-claude-code-subagents..."
    gh repo clone VoltAgent/awesome-claude-code-subagents awesome-claude-code-subagents
else
    echo "awesome-claude-code-subagents already exists, pulling latest..."
    cd awesome-claude-code-subagents && git pull && cd ..
fi

if [ ! -d "wshobson-agents" ]; then
    echo "Cloning wshobson-agents..."
    gh repo clone wshobson/agents wshobson-agents
else
    echo "wshobson-agents already exists, pulling latest..."
    cd wshobson-agents && git pull && cd ..
fi

if [ ! -d "wshobson-commands" ]; then
    echo "Cloning wshobson-commands..."
    gh repo clone wshobson/commands wshobson-commands
else
    echo "wshobson-commands already exists, pulling latest..."
    cd wshobson-commands && git pull && cd ..
fi

echo
echo -e "${YELLOW}Setting up symlinks...${NC}"

# Run setup scripts
echo "Setting up dallasLabs agents..."
./setup_agents.sh

echo "Setting up wshobson agents..."
./setup_wshobson_agents_symlinks.sh

echo "Setting up wshobson commands..."
./setup_wshobson_commands_symlinks.sh

echo "Setting up awesome Claude Code subagents..."
./setup_awesome_agents_symlinks.sh

echo
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}All agents and commands are now available in ~/.claude/${NC}"
