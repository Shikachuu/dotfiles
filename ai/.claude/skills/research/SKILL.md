---
name: research
version: 1.0.0
description: >
  Technical research for libraries, tools, patterns, and approaches.
  Detects the current stack, discovers options via web research,
  evaluates them against a structured rubric, and produces
  comparison briefs. Applies "Design It Twice" — always surface
  radically different options, not variations of the same idea.
category: development
requires:
  skills: []
  bins: []
trigger: >
  Activate when the user asks to evaluate, compare, or choose between
  libraries, packages, dependencies, CLI/dev tools, architectural patterns,
  or technical approaches.
---

# Research

Technical research skill covering libraries, tools, patterns, and approaches. Detects the project's stack, discovers
candidates, evaluates them against a flexible rubric, and produces comparison briefs. Core principle: always generate
radically different options ("Design It Twice"), then compare by contrast.

## Proactive Activation

Activate this skill **without being asked** when you detect the user is about to make a technical decision without
having evaluated alternatives:

- Installing or adding a new dependency (`npm install X`, `go get X`, `pip install X`)
- Proposing a specific library or tool without comparison
- Describing a new capability need where multiple implementation paths exist
- Asking "how do I do X" where the answer depends heavily on which library/approach they use

In these cases, pause before implementing and say: _"Before we go with X, let me quickly check if it's the best fit
here."_ Then run the research workflow. Keep it lightweight for simple decisions — a brief scorecard is enough; save
the full brief for major choices.

## Core Workflow

> Your first idea is unlikely to be the best. Generate multiple radically different options, then compare. The value
> is in the contrast — even if you end up with your first instinct, you'll understand _why_ it's the right choice.
> — _A Philosophy of Software Design_

1. **Clarify the research question** — what capability, what constraints (stack, scale, must-haves vs nice-to-haves)
2. **Detect the stack** — find manifest files (package.json, go.mod, requirements.txt, Cargo.toml, pyproject.toml,
   Gemfile, etc.) to identify ecosystem and existing deps
3. **Explore the codebase** — find existing patterns, dependencies, and constraints that affect integration fit
4. **Generate radically different options** — not variations of the same approach:
   - For broad research: spawn 2-3 parallel sub-agents, each with a different angle (e.g., "best OSS library",
     "roll-your-own", "managed service/SaaS")
   - For focused research: single-threaded but still 2+ genuinely distinct approaches
   - Each option must be fundamentally different, not a minor variation
5. **Gather key data per option**:
   - For libraries: score against the evaluation rubric (see below)
   - For patterns/approaches: docs, real-world usage, trade-offs, gotchas
6. **Compare by contrast** — highlight where options diverge most, not where they're similar
7. **Synthesize** — scorecard table for at-a-glance + deeper prose per option
8. **Recommend** — clear winner with rationale, or explicit "no clear winner" when genuinely equal
9. **Present and persist** — inline summary in conversation + write a research brief file when substantial

## Key Requirements

### Supported Ecosystems

| Manifest file                         | Registry / ecosystem |
| ------------------------------------- | -------------------- |
| `package.json`                        | npm                  |
| `go.mod`                              | pkg.go.dev           |
| `requirements.txt` / `pyproject.toml` | PyPI                 |
| `Cargo.toml`                          | crates.io            |
| `Gemfile`                             | RubyGems             |
| `pom.xml` / `build.gradle`            | Maven Central        |
| `composer.json`                       | Packagist            |

### Evaluation Rubric

Single flexible rubric — skip criteria that don't apply:

| Criteria                    | Weight | What to check                                                                | Applies to       |
| --------------------------- | ------ | ---------------------------------------------------------------------------- | ---------------- |
| Maintenance health          | 25%    | Last publish/release date, commit frequency, open issue/PR ratio, bus factor | Libraries, Tools |
| Community & adoption        | 20%    | Downloads/week, GitHub stars, SO presence, used-by count                     | Libraries, Tools |
| API / DX quality            | 20%    | Types (if JS/TS), doc quality, ergonomics, learning curve, CLI UX            | Libraries, Tools |
| Bundle size / footprint     | 15%    | Package size, tree-shakeability, dep count                                   | Libraries        |
| Install & config complexity | 15%    | Setup steps, config surface area, CI integration ease                        | Tools            |
| License                     | 10%    | Compatibility with project license                                           | Libraries, Tools |
| Security                    | 10%    | Known CVEs, audit history, supply chain risk                                 | Libraries, Tools |

When evaluating **libraries**: use Maintenance, Community, API quality, Bundle size, License, Security.
When evaluating **tools**: use Maintenance, Community, DX quality, Install complexity, License, Security.

### Data Sources

- Manifest files — current stack, versions, constraints
- Web research — WebSearch/WebFetch for registry stats, GitHub signals

### Sub-Agent Strategy

| Research type                   | Approach                                      |
| ------------------------------- | --------------------------------------------- |
| Broad ("what auth solution?")   | 2-3 parallel sub-agents with different angles |
| Focused ("which form library?") | Single agent                                  |

When spawning sub-agents, assign each a specific constraint:

- Agent A: "best OSS library for X"
- Agent B: "roll-your-own approach for X"
- Agent C: "managed service or SaaS for X"

## Output Format

**Inline (always):** Short summary with recommendation or "no clear winner."

**For library evaluations — scorecard table:**

```text
| Criteria (weight)   | Library A    | Library B    | Library C    |
|---|---|---|---|
| Maintenance (25%)   | ✅ Active    | ⚠️ Slowing   | ✅ Active    |
| Community (20%)     | ✅ 40k ⭐    | ✅ 28k ⭐    | ⚠️ 3k ⭐    |
| ...                 | ...          | ...          | ...          |
```

**Prose analysis** per option (following the table):

- What it is and its approach
- Strengths / Weaknesses
- Integration fit with codebase
- Gotchas — known issues, migration considerations

**Research brief file** (when substantial):

```markdown
# Research: [Topic]

## Problem Statement

## Constraints

## Options

### Option 1: [Name]

- What it is
- Strengths / Weaknesses
- Integration fit (with current codebase)
- Gotchas

### Option 2: [Name]

- What it is
- Strengths / Weaknesses
- Integration fit (with current codebase)
- Gotchas

## Comparison

| Criteria | Option 1 | Option 2 | ... |
| -------- | -------- | -------- | --- |

[prose analysis]

## Recommendation

## Open Questions
```

## Common Pitfalls

- **Checking only stars** — stars ≠ quality, check maintenance signals
- **Ignoring existing deps** — check what's installed before adding new dependencies
- **License blindness** — flag GPL/AGPL/SSPL in MIT/Apache projects
- **Stale data** — note when data was fetched; flag potentially outdated information
- **Ecosystem mismatch** — don't recommend wrong-runtime libraries
- **Similar options** — enforce radical difference, not variations of the same idea
- **Skipping comparison** — listing without contrasting misses the point
- **Recommending without alternatives** — recommendation is only meaningful in context
- **Researching in a vacuum** — always check codebase integration fit before concluding

## Examples

- "What date library should we use in this project?"
- "Compare tRPC vs REST vs GraphQL for our API layer"
- "Find alternatives to moment.js that are actively maintained"
- "Should we use Zustand or Redux Toolkit for state management?"
- "What ORM options exist for our Go project?"
- "Compare webpack vs vite vs esbuild for our build setup"
- "Which linter should we use — eslint or biome?"
- "Evaluate self-hosted vs managed Postgres for our use case"
- "Is this dependency still actively maintained?"

## Quality Checklist

- [ ] At least 2 genuinely different options presented (Design It Twice)
- [ ] All links and sources verified
- [ ] Codebase context checked for integration fit
- [ ] Trade-offs compared by contrast, not just listed per option
- [ ] Library rubric scores filled in (for library evaluations)
