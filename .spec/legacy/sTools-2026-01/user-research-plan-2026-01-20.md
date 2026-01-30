# User Research Plan: sTools Enhancement Validation

**Date:** 2026-01-20
**Purpose:** Validate proposed features (Diagnostic Bundles, Analytics, Enhanced Error Context, Dependency Visualization, Security Scanning) against actual user needs
**Method:** Semi-structured interviews with 5-10 sTools users

---

## User Personas

Based on README and codebase analysis:

### Persona 1: CI/CD Engineer
**Role:** DevOps/SRE maintaining skill pipelines
**Goals:** Fast validation, reliable CI, clear error reporting
**Pain Points:** Debugging CI failures, understanding scan errors, performance issues
**Current Usage:** `skillsctl scan` in CI/CD, SwiftPM plugin for validation

### Persona 2: Skill Developer
**Role:** Developer creating and maintaining AI skills
**Goals:** Quick feedback during development, easy debugging, quality assurance
**Pain Points:** Understanding why validation failed, tracking changes, ensuring cross-platform compatibility
**Current Usage:** Watch mode, local app for validation, fix mode

### Persona 3: Platform Maintainer
**Role:** Managing skill trees across multiple agents (Codex/Claude)
**Goals:** Keep skills synchronized, track drift, manage versions
**Pain Points:** Understanding what changed, finding inconsistencies, manual sync processes
**Current Usage:** Sync-check, index generation, remote catalog

### Persona 4: Security/Compliance Engineer
**Role:** Ensuring skill security and compliance
**Goals:** Detect vulnerabilities, audit skill changes, enforce standards
**Pain Points:** Finding security issues, tracking remediation, proving compliance
**Current Usage:** Validation rules, baselines, ignore files

### Persona 5: Tooling Engineer
**Role:** Building developer tooling on top of sTools
**Goals:** Extensible validation, custom rules, API access
**Pain Points:** Understanding plugin system, creating custom rules, debugging extensions
**Current Usage:** ValidationRule protocol, CLI integration, plugin development

---

## Interview Guide

### Opening Questions (5 min)

1. "Can you walk me through how you currently use sTools in your daily work?"
2. "What's your primary goal when using sTools? What problem are you trying to solve?"
3. "How often do you run scans or use the sTools app?"

### Feature-Specific Questions

#### Feature 1: Diagnostic Bundles

**Context:** Export full context (system info, logs, findings) for debugging support tickets

4. "Think about the last time you encountered a difficult bug or validation issue. What information did you gather? How did you share it with others?"
5. "Have you ever needed to share your scan results or configuration with support or colleagues? How did you do that?"
6. "If you could export a 'debug bundle' with all your scan results, system info, and recent logs, would that be useful? When would you use it?"

**What to validate:**
- Is diagnostic bundle export a real pain point?
- What information should be included?
- How would it be shared (file, ticket, etc.)?

#### Feature 2: Skill Usage Analytics

**Context:** Track scan frequency, error trends, top skills over time

7. "Do you track how often you scan skills or how many validation errors you get over time?"
8. "Would seeing a dashboard with scan history and error trends help you? What questions would you want answered?"
9. "Do you know which skills get scanned most frequently or have the most issues? Would that information be valuable?"

**What to validate:**
- Is analytics a real need?
- What metrics matter most?
- Is a dashboard the right format?

#### Feature 3: Enhanced Error Context

**Context:** Rich error messages with expected/actual values, related files, next steps

10. "Think about the last time you got a validation error. What information was missing from the error message?"
11. "Have you ever been confused by a validation error and didn't know how to fix it?"
12. "Would seeing 'expected vs actual' comparisons or step-by-step fix instructions help? When?"

**What to validate:**
- Are current error messages insufficient?
- What contextual help is needed?
- Would next steps prevent follow-up questions?

#### Feature 4: Dependency Visualization

**Context:** Graph skill relationships, export as GraphViz DOT

13. "Do you understand how your skills reference each other or depend on external skills?"
14. "Have you ever wanted to see a visual map of which skills use or reference other skills?"
15. "Would a dependency graph help you understand impact before making changes? How?"

**What to validate:**
- Is dependency awareness a real problem?
- What visualization format would help?
- Is impact analysis important?

#### Feature 5: Security Scanning

**Context:** Scan scripts for hardcoded secrets, command injection, insecure operations

16. "Do you review skill scripts for security issues (secrets, injection risks)?"
17. "Have you ever accidentally committed a secret or credential to a skill file?"
18. "Would an automated security scanner that flags these issues be useful? Would you want it to run automatically or on-demand?"

**What to validate:**
- Is security scanning a real concern?
- Should it be automatic or opt-in?
- What's the tolerance for false positives?

### Closing Questions (5 min)

19. "Of these 5 features, which would be most valuable to you? Why?"
20. "Is there anything else sTools doesn't currently do that would make your workflow easier?"
21. "What's the biggest pain point in your current sTools workflow?"

---

## Interview Logistics

### Target Participants

- **Total:** 5-10 users
- **Distribution:** Aim for at least 2 users per persona (10 total)
- **Recruitment:** Reach out via:
  - GitHub stars/forkers of sTools
  - Claude/Codex Discord communities
  - Internal team members
  - Local macOS developer meetups

### Session Format

- **Duration:** 30 minutes
- **Format:** Video call or async written interview
- **Compensation:** None (open source project)
- **Recording:** With consent for analysis

### Analysis Plan

For each participant, document:
1. **Current workflow:** How they use sTools today
2. **Pain points:** Frustrations, workarounds, inefficiencies
3. **Feature validation:** Which features resonate, which don't
4. **Prioritization:** Rank features by value
5. **New needs:** Problems not covered by proposed features

### Success Criteria

User research considered successful if:
- [ ] 5+ interviews completed with diverse personas
- [ ] Clear evidence of which features are valued (or not)
- [ ] Business value metrics defined for top features
- [ ] Feature prioritization framework (RICE/MoSCoW) completed
- [ ] Implementation plan adjusted based on findings

---

## Alternative Research Methods

If scheduling interviews is challenging:

### GitHub Issue Analysis

Search for patterns in issues/discussions:
- Requests for debugging help
- Questions about scan failures
- Requests for better error messages
- Feature requests or enhancement proposals

### Support Ticket Analysis

Analyze any support channels:
- What questions are asked repeatedly?
- What issues take longest to resolve?
- What information is usually missing?

### Usage Telemetry Review

Anonymously review existing telemetry:
- Most-used commands
- Common error patterns
- Cache hit rates
- Scan frequency distributions

---

## Interview Document Template

### Participant Profile

- **Participant ID:** (unique identifier)
- **Persona:** CI/CD Engineer | Skill Developer | Platform Maintainer | Security/Compliance | Tooling Engineer | Other
- **Experience with sTools:** (months/years, primary use cases)
- **Team/Company:** (if applicable, otherwise individual)
- **Interview Date:** 2026-01-XX

### Responses

#### Current Workflow
- Goals when using sTools:
- Frequency of use:
- Typical workflow:

#### Feature 1: Diagnostic Bundles
- Pain level with current debugging: (1-5)
- Would diagnostic bundles help?
- What to include in bundle:
- Preferred export format:

#### Feature 2: Usage Analytics
- Current tracking method:
- Would analytics dashboard help?
- Valuable metrics:
- Preferred visualization:

#### Feature 3: Enhanced Error Context
- Confusion level with current errors: (1-5)
- Would enhanced context help?
- Most needed context type:
- Preferred format:

#### Feature 4: Dependency Visualization
- Current dependency understanding: (1-5)
- Would visualization help?
- Use cases for graph:
- Preferred format:

#### Feature 5: Security Scanning
- Current security review process:
- Would automated scanning help?
- Preferred mode (auto/manual):
- False positive tolerance:

#### Overall Prioritization
**Rank features by value (1=highest, 5=lowest):**
1. Feature ___ - Reason:
2. Feature ___ - Reason:
3. Feature ___ - Reason:
4. Feature ___ - Reason:
5. Feature ___ - Reason:

#### Other Needs
- Problems not covered by proposed features:
- Suggestions for other improvements:

---

## Timeline

- **Week 1:** Create interview guide, recruit participants
- **Week 2-3:** Conduct interviews
- **Week 4:** Analyze results, update spec with validated requirements
- **Week 5:** Present findings and recommendations

---

## Evidence Collection

Per adversarial review requirements, all findings will include:
- `Evidence:` line (or `Evidence gap:` if no source exists)
- Citation of file paths/links
- Summary of user quotes and patterns

---

**Status:** Ready to begin user interviews
**Next Steps:** Recruit participants, schedule interviews, begin research
