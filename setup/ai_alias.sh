#!/bin/bash

AI_DIR="${HOME}/projects/env_setup/AI"

ln -s "${AI_DIR}"/.agent ~/
ln -s "${AI_DIR}"/.gemini ~/



# Gemini
ln -s ~/.agent/GEMINI.md ~/.gemini/GEMINI.md
ln -s ~/.agent/settings.json ~/.gemini/settings.json
ln -s ~/.agent/skills ~/.gemini/skills
ln -s ~/.agent/rules ~/.gemini/rules
ln -s ~/.gemini/extensions ~/.agent/extensions/gemini_extensions


# Antigravity
ln -s ~/.agent/workflows ~/.gemini/antigravityglobal_workflows
ln -s ~/.agent/skills ~/.gemini/antigravity/global_skills
ln -s ~/.agent/skills ~/.gemini/antigravity/skills
ln -s ~/.agent/rules ~/.gemini/antigravity/rules
ln -s ~/.agent/mcp/mcp.json ~/.gemini/antigravity/mcp_config.json


ln -s ~/.gemini/extensions ~/.agent/