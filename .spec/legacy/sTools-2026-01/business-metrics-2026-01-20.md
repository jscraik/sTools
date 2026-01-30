# Business Value Metrics: sTools Enhancement Suite

**Date:** 2026-01-20
**Purpose:** Define measurable business value for each proposed feature
**Status:** Draft - Pending full user interviews for baseline validation

---

## Executive Summary

Based on user research findings and persona analysis, this document defines measurable business value metrics for the **3 HIGH-priority features** validated by codebase analysis:

1. **Feature 1: Diagnostic Bundles** — Support ticket efficiency
2. **Feature 2: Usage Analytics** — Data-driven quality decisions
3. **Feature 5: Security Scanning** — Vulnerability prevention

**Key Finding:** Features 1, 2, and 5 have strong evidence of user need from commit history analysis. Features 3 and 4 have moderate/weak evidence respectively.

*Evidence:* `/Users/jamiecraik/dev/sTools/.spec/user-research-findings-2026-01-20.md` lines 260-312

---

## Feature 1: Diagnostic Bundles

### Business Problem

**User Pain Point:** Debugging CI failures and validation issues requires multiple rounds of information gathering.

**Evidence:**
- Recent commits show observability focus (90e4c78: log viewer, f6ab23a: structured logging)
- Adversarial review UX finding #2: "Missing loading states for long-running operations"
- Support workflow requires back-and-forth for system info, logs, and config

### Business Value Metrics

#### Primary Metric: Time-to-Resolution (TTR)

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Average support ticket TTR | **TBD** | -30% | Time from ticket open to close |
| Information gathering cycles | **3-5 rounds** | -50% | Number of back-and-forth messages |
| First-contact resolution rate | **<20%** | +50% | Tickets resolved in one response |

**Evidence gap:** Current baseline requires measurement from existing support channels.

#### Secondary Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Bundle adoption rate | 60% of users with issues | % of tickets with attached bundle |
| Bundle export time | <5 seconds | Time from click to ZIP download |
| Bundle size | <10 MB (95th percentile) | Compressed archive size |
| User satisfaction | 4.0/5.0 | Post-ticket survey |

### Success Criteria

**SUCCESS if:**
- Average TTR decreases by 30% within 3 months
- Bundle adoption reaches 60% of users with issues
- Bundle export time consistently <5 seconds
- No privacy/security incidents from bundle content

**FAILURE if:**
- TTR does not improve after 6 months
- Bundle adoption <20% after 3 months
- Users report bundles don't contain needed info

### Data Collection Plan

**Pre-launch (baseline):**
1. Analyze last 50 support tickets for:
   - Time to resolution
   - Information gathering rounds
   - Common questions asked

**Post-launch (measurement):**
1. Track bundle downloads per day
2. Survey users after ticket resolution
3. Analyze ticket content for bundle attachments
4. Measure bundle export success rate

### ROI Calculation

**Assumptions:**
- Average support ticket cost: $50 (engineering time)
- Current tickets per month: 20
- Target reduction: 30% fewer tickets (self-serve debugging)

**Expected savings:**
- 6 tickets × $50 = $300/month savings
- Development cost: ~40 hours
- Breakeven: ~2 months

---

## Feature 2: Usage Analytics

### Business Problem

**User Pain Point:** No visibility into scan patterns, error trends, or skill quality over time.

**Evidence:**
- Recent telemetry/metrics features (1dc6156: metrics export, 4778f8c: error budget tracking)
- Platform maintainer persona: "Need to understand what changed"
- No existing dashboard for scan history

### Business Value Metrics

#### Primary Metric: Data-Driven Decision Rate

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Analytics DAU | **0** | 20% of users | Daily Active Users of dashboard |
| Action rate from insights | **N/A** | 10% | Users who change behavior based on analytics |
| Quality improvement rate | **Unknown** | +15% | Reduction in validation errors over time |

**Evidence gap:** Current DAU is 0 (feature doesn't exist).

#### Secondary Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Dashboard session time | >2 minutes | Time spent in analytics view |
| Chart export rate | 30% of sessions | PNG/CSV exports per session |
| Time range queries | 50% of sessions | Filters for date ranges |
| Error trend detection | 80% accuracy | Actual vs perceived error spikes |

### Success Criteria

**SUCCESS if:**
- 20% of users engage with analytics dashboard weekly
- 10% of users change behavior based on insights (survey)
- Error trends correlate with actual issues
- Dashboard load time <2 seconds (95th percentile)

**FAILURE if:**
- DAU <5% after 3 months
- Users report dashboard doesn't help decision-making
- Performance SLOs not met (>2s load time)

### Data Collection Plan

**Pre-launch:**
1. Survey users: "What metrics would help you debug?"
2. Audit existing telemetry: What data is available?
3. Define quality metrics: What constitutes "improvement"?

**Post-launch:**
1. Track dashboard views per user
2. Measure chart interaction (hover, zoom, filter)
3. Survey: "Did analytics help you solve a problem this week?"
4. Correlate analytics usage with error reduction

### ROI Calculation

**Intangible benefits:**
- Faster identification of problematic skills
- Data-driven prioritization of validation rules
- Reduced support burden through self-serve troubleshooting

**Quantified benefit:**
- Assume 10% of users (2 per month) find and fix a critical issue 1 day earlier
- Value: 2 days × engineering daily rate = savings
- Development cost: ~60 hours
- Breakeven: ~3 months (conservative)

---

## Feature 5: Security Scanning

### Business Problem

**User Pain Point:** Skills may contain hardcoded secrets, command injection risks, or insecure operations.

**Evidence:**
- Security features added (0c31090: PII scrubbing, a914680: trust store)
- Security/Compliance persona: "Need to detect security issues"
- Commit history shows security concern is real

### Business Value Metrics

#### Primary Metric: Vulnerability Detection Rate

| Metric | Target | Measurement |
|--------|--------|-------------|
| Pre-commit detection | 80% | Vulnerabilities caught before merge |
| False positive rate | <5% | Benign patterns flagged incorrectly |
| Scan adoption | 90% of repos with scripts | Repos with security scans enabled |
| Mean time to remediation | <48 hours | Time from detection to fix |

#### Secondary Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Security issues per scan | 0.1-0.5 per 1000 files | Detection rate (not too high, not too low) |
| User trust in scanner | 4.0/5.0 | Post-scan survey |
| Zero-day vulnerability catch | 1+ per quarter | Critical issues detected |
| Scan performance | <30 seconds | Time for full repo scan |

### Success Criteria

**SUCCESS if:**
- Detect 100% of known vulnerability patterns in test corpus
- False positive rate <5% after pattern tuning
- 80% of users enable scanning after first use
- Zero secrets reach production in 6 months

**FAILURE if:**
- False positive rate >20% (too much noise)
- Users disable scanning after first use
- Known vulnerabilities not detected in testing

### Data Collection Plan

**Pre-launch:**
1. Build vulnerability corpus: Known-bad skill files
2. Define "false positive": What patterns are safe?
3. Measure current secret leak rate (git history audit)

**Post-launch:**
1. Track scan results: true positives vs false positives
2. Survey users after each finding: "Was this helpful?"
3. Monitor security scan enable/disable rate
4. Audit git history for secret commits post-launch

### ROI Calculation

**Cost of single secret leak:**
- Incident response: $5,000
- Credential rotation: $2,000
- Potential breach: $50,000+ (conservative)
- Expected leaks per year: 1-2

**Prevention value:**
- Prevent 1 secret leak = $5,000 savings
- Prevent 1 potential breach = $50,000 savings
- Development cost: ~50 hours
- Breakeven: Prevent 1 secret leak (immediate ROI)

---

## Feature 3: Enhanced Error Context (MEDIUM Priority)

### Business Problem

**User Pain Point:** Validation errors lack sufficient context for quick resolution.

**Evidence:**
- Moderate: FixEngine exists but limited context
- Adversarial UX finding: "Missing expected vs actual"
- Skill developer persona: "Need faster understanding of failures"

### Business Value Metrics

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Follow-up questions per error | **2-3** | -50% | Clarification requests after error |
| Error resolution time | **Unknown** | -40% | Time from error to fix |
| User satisfaction with errors | **3.0/5.0** | 4.0/5.0 | Post-scan survey |

**Evidence gap:** Current resolution time unknown.

---

## Feature 4: Dependency Visualization (LOW Priority)

### Business Problem

**User Pain Point:** Unknown — weak evidence from codebase analysis.

**Evidence:**
- No user requests in git history
- No GitHub issues requesting visualization
- Sync functionality exists but no visualization complaints

### Recommendation

**DO NOT IMPLEMENT** at this time.

**Rationale:**
- No validated user need
- High implementation complexity
- Alternative: Add to analytics dashboard if data shows demand

**Revisit if:**
- User interviews reveal strong demand
- GitHub issues request visualization
- Platform maintainers report pain managing dependencies

---

## Cross-Feature Metrics

### User Engagement

| Metric | Target | Measurement |
|--------|--------|-------------|
| Weekly active users | 60% of install base | Users who run any scan weekly |
| Feature adoption | 40% per feature | Users who try each new feature |
| Churn rate | <5% per month | Users who stop using sTools |

### Developer Experience

| Metric | Target | Measurement |
|--------|--------|-------------|
| Time to first successful scan | <5 minutes | New user onboarding flow |
| CLI help clarity | 4.0/5.0 | Post-onboarding survey |
| Documentation satisfaction | 4.0/5.0 | DevEx survey |

### System Health

| Metric | Target | Measurement |
|--------|--------|-------------|
| Scan success rate | >95% | Scans that complete without errors |
| Cache hit rate | >80% | Unchanged files cached |
| Mean scan time | <30 seconds | All repos, 95th percentile |

---

## Baseline Measurement Plan

Before implementing any features, **measure current baselines:**

### Week 1: User Behavior

1. **Survey active users** (10-20 participants)
   - "How do you currently debug validation issues?"
   - "What information do you gather when filing support tickets?"
   - "How do you track scan performance over time?"

2. **Analyze existing telemetry**
   - Scan frequency distribution
   - Common error patterns
   - Cache performance stats

### Week 2: Support Analysis

1. **Audit recent tickets** (last 50 if available)
   - Time to resolution
   - Information gathering rounds
   - Common questions

2. **Measure current TTR**
   - Open to close time
   - Engineer hours per ticket

### Week 3: Security Assessment

1. **Audit git history** for secrets
   - Scan for leaked credentials
   - Measure frequency of leaks

2. **Build vulnerability corpus**
   - Known-bad skill files
   - Safe patterns (for false positive testing)

---

## Go/No-Go Criteria by Feature

### Feature 1: Diagnostic Bundles

**GO if:**
- Baseline TTR >2 hours (significant room for improvement)
- Users report information gathering takes >2 rounds
- No privacy concerns with bundle content (user interview)

**NO-GO if:**
- TTR already <30 minutes (minimal improvement possible)
- Users don't share results with support
- Privacy team raises concerns

### Feature 2: Usage Analytics

**GO if:**
- Users report wanting "scan history" or "error trends"
- Platform maintainers need drift detection
- No privacy concerns with storing scan metadata

**NO-GO if:**
- Users don't care about historical data
- Analytics viewed as "nice to have" not "need to have"
- Privacy team blocks storing scan results

### Feature 5: Security Scanning

**GO if:**
- Git history shows 1+ secret leaks in past year
- Users express concern about skill security
- False positive rate <10% achievable (prototype test)

**NO-GO if:**
- No secrets in git history (low risk)
- Users disable scanning after first use (prototype feedback)
- False positive rate >20% in prototype

---

## Measurement Tools & Implementation

### Instrumentation Plan

```swift
// Track feature usage
enum AnalyticsEvent {
    case diagnosticBundleGenerated
    case analyticsDashboardViewed
    case securityScanRun
    case enhancedErrorViewed
}

// Log with context
AppLog.shared.info("Feature used", metadata: [
    "event": event,
    "user": hashedUserId,
    "timestamp": Date(),
    "context": metadata
])
```

### Dashboard Configuration

```yaml
# Grafana dashboard configuration (proposed)
panels:
  - title: "Diagnostic Bundle Downloads"
    metric: bundle_downloads_per_day
    target: >10/day

  - title: "Analytics Dashboard DAU"
    metric: unique_users_analytics_dashboard
    target: >20% of total users

  - title: "Security Scan Findings"
    metric: security_findings_per_scan
    target: 0.1-0.5 per 1000 files
```

---

## Conclusion

**Metrics Readiness:**

| Feature | Metrics Defined | Baseline Needed | Go/No-Go Ready |
|---------|----------------|-----------------|----------------|
| Feature 1 (Bundles) | ✅ Complete | ⚠️ Partial (TTR) | ⚠️ Need baseline |
| Feature 2 (Analytics) | ✅ Complete | ✅ Not applicable | ✅ Ready |
| Feature 3 (Error Context) | ⚠️ Partial | ❌ Not defined | ❌ Need baseline |
| Feature 5 (Security) | ✅ Complete | ⚠️ Partial (leak rate) | ⚠️ Need baseline |

**Immediate Actions:**

1. **Conduct user interviews** (Week 1-2) — Validate needs and gather baselines
2. **Audit support channels** (Week 1) — Measure current TTR
3. **Scan git history** (Week 1) — Count secret leaks
4. **Build vulnerability corpus** (Week 2) — Test false positive rate
5. **Define Go/No-Go thresholds** (Week 3) — Set decision criteria

**Evidence:**
- User research findings: `/Users/jamiecraik/dev/sTools/.spec/user-research-findings-2026-01-20.md`
- Performance baseline: `/Users/jamiecraik/dev/sTools/.spec/performance-baseline-2026-01-20.md`

---

*Status:* Metrics defined for HIGH-priority features; baseline measurement pending
*Next:* Conduct user interviews and baseline measurements to validate targets
