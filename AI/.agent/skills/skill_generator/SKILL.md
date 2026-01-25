---
name: Skill Generator
description: Use template with LLM to generate a new skill for LLM model
user-invocable: true
auto-invoke: true
version: "1.0.0"
capabilities: ["mcp", "terminal"]
---

# Skill Generator

Read @assets/skill.template.md and use it as template.  

Interactive mode to ask question below one by one.

1. Answer what the skill name is? <skill_name>.  
2. What role will use this skill? <role>.  
3. Descibe this skill. <skill_description>.  
4. Bsaed on given role and skill description, Generate skill details. <detail>.  
5. Based on the skill folder structure save it to ~/.agent/skill/<skill_name_without_space>/SKILL.md.  
If any other reference, it needs to be saved to sub folder accordingly.  
~/.agent/skill/<skill_name_without_space>.  
├─── SKILL.md       # Main.  
├─── scripts/       # Executable scripts (bash, python, node) the agent can run.  
├─── references/    # Static documentation, schemas, or example data for the agent to consult.  
└─── assets/        # Code templates, boilerplate, or binary resources.
