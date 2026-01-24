---
name: Story Generator
description: given a scene and use the archetype to generate a instagram story and 3-5 images
---

# Story Generator

1. Load archetype/*, background/* folder
2. Given a scene from input
3. Based on the scene, enrich scene with details, like interaction, background, related items, and so on.
    ex: it should have performance stage if it's a concert scene.
4. Generate 3-5 images based the prompt
5. Store prompt into YYYYMMDD-<scene_name>.md
6. Store images into YYYYMMDD-<scene_name>.<img_id>.png
