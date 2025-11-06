# AKS Windows Image Pull Performance – Executive Summary

## Overview

Recent benchmarking of Windows container image pulls on AKS across Azure Container Registry (ACR) tiers shows substantial gains moving from Standard to Premium. Large image cold start (pull + start) latency drops from ~7m17s to ~4m13s (−42%), and network/decompression throughput increases from ~24.8 MiB/s to ~37.6 MiB/s (+52%). Warm (cached) startups remain ~4s regardless of tier, emphasizing the value of pre-warming.

## Key Metrics

| Scenario | Cold Pull Time | End-to-End (Scheduled→Started) | Throughput (MiB/s) |
|----------|----------------|--------------------------------|--------------------|
| Large Image (8.13 GiB) – ACR Standard | 350 s (5m50s) avg | 437 s (7m17s) avg | 24.8 avg (20.5–34.2 range) |
| Large Image (8.13 GiB) – ACR Premium | 226 s (3m46s) avg | 253 s (4m13s) avg | 37.6 avg (36.9–38.8 range) |
| Small Images (~2.87 GiB) – Standard | 189–379 s (pull) | 215–429 s | 7.8–15.7 |
| Warm (cached) – Either tier | <0.5 s pull | 4 s | N/A (local cache) |

## Premium vs Standard Delta (Large Image)

- Pull Time: 350 s → 226 s (−124 s / −35.6%)
- Scheduled→Started: 437 s → 253 s (−184 s / −42.0%)
- Throughput: 24.8 → 37.6 MiB/s (+51.6%)

## Root Causes

1. Large layer download + Windows container layer extraction dominates cold startup.
2. ACR Standard exhibits variable throughput; Premium gives consistent higher bandwidth.
3. Inflated size (e.g., 2.87 GiB compressed → 9.91 GB inflated) amplifies disk extraction cost.
4. Lack of pre-warm on new nodes causes repeated cold pulls.

## Recommended Actions (Priority)

1. Upgrade registry to **ACR Premium** (immediate latency & consistency gains).
2. Deploy **Windows HostProcess pre-warm DaemonSet** for critical images.
3. **Slim large images** (remove ISO/static payloads; mount externally or download at runtime).
4. Add **CI layer diff reporting** + size budgets (<5 GiB target compressed for large images).
5. Migrate to **Windows Server 2022 base** where compatible.
6. Instrument & alert: scheduled→started and pulling→pulled durations into dashboard; track improvements.

## KPI Targets

| KPI | Baseline (Standard) | Target | Status |
|-----|---------------------|--------|--------|
| Cold pull (large) | 350 s | <240 s | Achieved (226 s) |
| Cold scheduled→started | 437 s | <270 s | In progress (253 s) |
| Warm start | 4 s | ≤5 s | Stable |
| Pull throughput | 24.8 MiB/s | >35 MiB/s | Achieved |
| Image compressed size | 8.13 GiB | <5 GiB | Pending |
| Cache hit rate | Unknown | >90% | Pending instrumentation |

## Business Impact

- Faster horizontal scale-out & recovery (node churn less disruptive).
- Higher deployment agility for large Windows workloads.
- Improved developer iteration speed when testing large image revisions.

## Risk & Mitigation Snapshot

| Risk | Mitigation |
|------|------------|
| Added ACR Premium cost | Justify via 42% faster startup & SLA adherence |
| Refactor delays | Phase out ISO layers first, incremental slimming |
| Pre-warm resource contention | Throttle pulls; stagger startup; limit image list |
| Digest pin management | Automate updates via pipeline variables |

## Next 30-Day Plan

Week 1: Registry upgrade + deploy pre-warm DaemonSet.  
Week 2: Image audit + remove largest static assets.  
Week 3: Add CI layer diff + dashboard metrics.  
Week 4: Trial 2022 base, validate functional parity.

## Visuals

See generated graphs in `results/graphs/` after running the graph script.

---
Generated: 2025-11-06
