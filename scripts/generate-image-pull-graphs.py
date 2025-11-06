#!/usr/bin/env python3
"""Generate image pull performance graphs from hard-coded benchmark data.
Outputs PNG charts into results/graphs/.

Run:  python scripts/generate-image-pull-graphs.py
Requires: matplotlib
Install (PowerShell):  pip install matplotlib
"""
import os, statistics
import matplotlib.pyplot as plt

# Data (seconds)
standard_large_pulls = [362.724, 258.882, 396.444, 384.221, 406.576, 243.756, 398.140]
premium_large_pulls = [215.747, 226.793, 224.092]
standard_small_pulls = [378.626, 188.58]  # 6m18.626s (10gb) and 3m8.58s (74gb-rand)
warm_pulls = [0.458, 0.401]

LARGE_SIZE_GIB = 8.13
SMALL_SIZE_GIB = 2.87  # approximate compressed size


# Throughput (MiB/s) approximation: (size GiB * 1024) / seconds
def gib_per_sec(size_gib, seconds):
    return (size_gib * 1024) / seconds


standard_large_tp = [gib_per_sec(LARGE_SIZE_GIB, s) for s in standard_large_pulls]
premium_large_tp = [gib_per_sec(LARGE_SIZE_GIB, s) for s in premium_large_pulls]
standard_small_tp = [gib_per_sec(SMALL_SIZE_GIB, s) for s in standard_small_pulls]

out_dir = os.path.join("results", "graphs")
os.makedirs(out_dir, exist_ok=True)

plt.style.use("seaborn-v0_8")

# 1. Distribution of large image cold pull times (Standard vs Premium)
plt.figure(figsize=(10, 5))
plt.boxplot(
    [standard_large_pulls, premium_large_pulls],
    labels=["Standard (n=7)", "Premium (n=3)"],
)
plt.ylabel("Pull Time (seconds)")
plt.title("Cold Pull Time Distribution – Large Image (8.13 GiB)")
plt.grid(axis="y", alpha=0.3)
plt.savefig(os.path.join(out_dir, "large_cold_pull_boxplot.png"), dpi=160)
plt.close()

# 2. Per-run throughput comparison (Large image)
plt.figure(figsize=(10, 5))
plt.plot(
    range(1, len(standard_large_tp) + 1),
    standard_large_tp,
    marker="o",
    label="Standard",
)
plt.plot(
    range(1, len(premium_large_tp) + 1), premium_large_tp, marker="o", label="Premium"
)
plt.axhline(
    statistics.mean(standard_large_tp),
    color="tab:blue",
    linestyle="--",
    alpha=0.5,
    label="Standard Mean",
)
plt.axhline(
    statistics.mean(premium_large_tp),
    color="tab:orange",
    linestyle="--",
    alpha=0.5,
    label="Premium Mean",
)
plt.ylabel("Throughput (MiB/s)")
plt.xlabel("Run #")
plt.title("Image Pull Throughput – Large Image (8.13 GiB)")
plt.legend()
plt.grid(alpha=0.3)
plt.savefig(os.path.join(out_dir, "large_throughput_runs.png"), dpi=160)
plt.close()

# 3. Warm vs Cold (Premium vs Warm) comparative bar
labels = ["Standard Cold (avg)", "Premium Cold (avg)", "Warm Cached (avg)"]
values = [
    statistics.mean(standard_large_pulls),
    statistics.mean(premium_large_pulls),
    statistics.mean(warm_pulls),
]
plt.figure(figsize=(8, 5))
colors = ["#d95f02", "#1b9e77", "#7570b3"]
plt.bar(labels, values, color=colors)
plt.ylabel("Seconds")
plt.title("Cold vs Warm Startup (Pull Duration Component)")
for i, v in enumerate(values):
    plt.text(i, v + 5, f"{v:.1f}s", ha="center")
plt.grid(axis="y", alpha=0.25)
plt.savefig(os.path.join(out_dir, "cold_vs_warm.png"), dpi=160)
plt.close()

# 4. Small images throughput
plt.figure(figsize=(8, 5))
plt.bar(
    ["10gb-ltsc2019", "74gb-rand-ltsc2019"],
    standard_small_tp,
    color=["#66c2a5", "#fc8d62"],
)
plt.ylabel("Throughput (MiB/s)")
plt.title("Throughput – Small Images (Compressed ~2.87 GiB)")
for i, v in enumerate(standard_small_tp):
    plt.text(i, v + 0.5, f"{v:.1f}", ha="center")
plt.grid(axis="y", alpha=0.3)
plt.savefig(os.path.join(out_dir, "small_images_throughput.png"), dpi=160)
plt.close()

# 5. Summary bar chart: average pull times
plt.figure(figsize=(9, 5))
avg_standard = statistics.mean(standard_large_pulls)
avg_premium = statistics.mean(premium_large_pulls)
avg_warm = statistics.mean(warm_pulls)
plt.bar(
    ["Standard Cold", "Premium Cold", "Warm Cached"],
    [avg_standard, avg_premium, avg_warm],
    color=["#e41a1c", "#377eb8", "#4daf4a"],
)
plt.ylabel("Pull Time (seconds)")
plt.title("Average Pull Times – Large Image")
for i, v in enumerate([avg_standard, avg_premium, avg_warm]):
    plt.text(i, v + 5, f"{v:.1f}s", ha="center")
plt.grid(axis="y", alpha=0.25)
plt.savefig(os.path.join(out_dir, "average_pull_times.png"), dpi=160)
plt.close()

print("Graphs generated in", out_dir)
