# PRD

## Overview

Bootstrap Ralph for the sTools repo so agent loops can run with accurate build/test/lint
commands and a minimal, safe initial task set. Scope is configuration-only for Ralph;
no product code changes are required. The output should help establish a clean starting
point for future feature work by validating the repo’s quality gates and recording the
results in Ralph’s iteration logs.

## Tasks

- [ ] Confirm repo commands and quality gates in `.ralph/AGENTS.md` (build/test/lint/CLI smoke)
- [ ] Run a baseline Ralph iteration using the updated configuration
- [ ] Record any blockers or follow-up tasks discovered during the run
