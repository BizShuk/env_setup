#!/bin/bash

AI_DIR="${HOME}/projects/env_setup/AI"

ln -sf "${AI_DIR}"/.agent ~/
ln -sf ~/.gemini "${AI_DIR}"/
mkdir -p ~/.gemini/antigravity


# Gemini
ln -sf ~/.agent/GEMINI.md ~/.gemini/GEMINI.md
ln -sf ~/.agent/settings.json ~/.gemini/settings.json
ln -sf ~/.agent/skills ~/.gemini/skills
ln -sf ~/.agent/rules ~/.gemini/rules
ln -sf ~/.gemini/extensions ~/.agent/extensions/gemini_extensions


# Antigravity

ln -sf ~/.agent/workflows ~/.gemini/antigravity/global_workflows
ln -sf ~/.agent/skills ~/.gemini/antigravity/global_skills
ln -sf ~/.agent/skills ~/.gemini/antigravity/skills
ln -sf ~/.agent/rules ~/.gemini/antigravity/rules
ln -sf ~/.agent/mcp/mcp.json ~/.gemini/antigravity/mcp_config.json


ln -sf ~/.gemini/extensions ~/.agent/extensions/gemini_extensions