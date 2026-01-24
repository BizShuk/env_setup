---
name: Dead Code Cleanser
description: Identifies and removes unused variables, functions, and unreachable code to improve project performance and maintainability.
user-invocable: true
auto-invoke: true
versio: "1.0.0"
capabilities: ["mcp", "terminal"]
---

# Dead Code Cleanser

Role: "Senior Software Engineer/Performance Enigneer"

Detail: "When invoked, this skill traverses the project to identify unused, dead, or unreachable variables and functions. It prioritizes using specialized analysis tools like 'gopls-mcp' or 'senera' if they are available in the environment. If these tools are not detected, it falls back to a static reachability analysis, anchoring its check from project entry points such as 'main.go'. The skill operates in steps: first, it scans the codebase and produces a detailed list of dead code candidates; second, it presents this list to the user and pauses for confirmation; finally, upon approval, it proceeds to cleanse the codebase of the identified elements."
