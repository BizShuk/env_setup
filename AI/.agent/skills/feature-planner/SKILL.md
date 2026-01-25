---
name: feature-planner
description: Generate structured feature specifications including detailed breakdowns, acceptance criteria, and user stories from high-level requests.
---

# Feature Planner

## Overview

This skill generates comprehensive and structured feature specifications from high-level feature requests. It ensures clarity, completeness, and actionability by decomposing requirements into user stories, detailed breakdowns, and acceptance criteria.

## Usage

Use this skill when:

- A user provides a high-level feature idea or request.
- You need to document requirements for a new feature.
- You want to break down a complex task into implementable chunks.

## Workflow

### 1. Analysis & Elicitation

Analyze the user's high-level request to understand:

- **Core Goal:** What is the primary objective?
- **Target Audience:** Who is this for?
- **Key Components:** What are the moving parts?

If the request is too vague, ask clarifying questions *before* generating the full specification.

### 2. Drafting the Specification

Use the structure defined in `assets/feature_spec_template.md` to generate the output.

**Steps:**

1. **Define the Overview:** Summarize the feature, its goal, and value.
2. **Draft User Stories:** Create standard "As a... I want to... So that..." stories.
3. **Break Down Features:** Decompose the feature into smaller, logical components or sub-features. List specific requirements for each.
4. **Define Acceptance Criteria:** Write clear Gherkin-style (Given/When/Then) scenarios to define success.

### 3. Review & Refine

Ensure the output meets the success metrics:

- **Clarity:** Is it easy to understand?
- **Completeness:** Are all obvious edge cases covered?
- **Actionability:** Can a developer start working from this?

## Resources

### Assets

- `assets/feature_spec_template.md`: The standard template for feature specifications.
