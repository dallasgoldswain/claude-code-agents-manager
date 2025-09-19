# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains Claude Code agents and setup scripts for creating a collection of specialized AI agents. The project structure includes:

- `dallasLabs/` - Contains specialized agent definitions (.md files) with YAML frontmatter
- Setup scripts for creating symlinks to make agents available to Claude Code

## Agent Architecture

### Agent Definition Format
Each agent is defined in a markdown file with YAML frontmatter containing:
- `name`: Agent identifier
- `description`: Brief description of the agent's capabilities
- `tools`: List of tools the agent uses

The content includes specialized instructions, checklists, and behavior patterns for the agent.

### Available Agents
- `django-developer.md` - Django 5+ expert with focus on modern Python practices
- `js-ts-tech-lead.md` - JavaScript/TypeScript technical lead
- `data-analysis-expert.md` - Data analysis specialist
- `python-backend-engineer.md` - Python backend development expert
- `debug-specialist.md` - Debugging and troubleshooting specialist

## Setup and Development Commands

### Agent Setup
```bash
# Set up symlinks for basic agents (files in root)
./setup_agents_symlinks.sh

# Set up symlinks for categorized agents (flattened from categories/ folder)
./setup_awesome_agents_symlinks.sh

# Set up command symlinks (from tools/ and workflows/ directories)
./setup_command_symlinks.sh
```

### Usage
- Agents are symlinked to `~/.claude/agents/` for Claude Code access
- Commands are symlinked to `~/.claude/commands/` preserving directory structure
- Run `git pull` in this directory to update all agents

## Development Workflow

1. Create new agent definitions in `dallasLabs/` following the existing format
2. Run appropriate setup script to create symlinks
3. Test agents through Claude Code interface
4. Update agents by editing the source files and pulling updates

## File Management

The setup scripts automatically:
- Skip hidden files, README, LICENSE, and CONTRIBUTING files
- Handle existing symlinks gracefully
- Provide colored output showing success/skip status
- Create necessary destination directories