#!/usr/bin/env python3
import csv
import os
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = os.path.join(ROOT, "output", "charts")
if not os.path.isdir(OUT):
    os.makedirs(OUT)
MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
WRITTEN = []

def rows(rel):
    path = os.path.join(ROOT, rel)
    if not os.path.isfile(path):
        sys.exit("Missing input: " + rel)
    with open(path) as fh:
        data = list(csv.DictReader(fh))
    if not data:
        sys.exit("Empty input: " + rel)
    return data

def save(fig, name):
    fig.tight_layout()
    fig.savefig(os.path.join(OUT, name), dpi=150)
    plt.close(fig)
    WRITTEN.append(name)
    print("wrote " + name)

def hbar(labels, values, title, xlabel, name, fmt="%.1f"):
    fig, ax = plt.subplots(figsize=(9, 0.4 * len(labels) + 1.8))
    pos = list(range(len(labels)))
    ax.barh(pos, values)
    ax.set_yticks(pos)
    ax.set_yticklabels(labels)
    ax.invert_yaxis()
    ax.set_xlabel(xlabel)
    ax.set_title(title)
    for i, v in enumerate(values):
        ax.text(v, i, " " + (fmt % v), va="center", fontsize=8)
    save(fig, name)

def vbar(labels, values, title, ylabel, name, fmt="%.1f"):
    fig, ax = plt.subplots(figsize=(9, 5))
    pos = list(range(len(labels)))
    ax.bar(pos, values)
    ax.set_xticks(pos)
    ax.set_xticklabels(labels)
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    for i, v in enumerate(values):
        ax.text(i, v, fmt % v, ha="center", va="bottom", fontsize=8)
    save(fig, name)

# 1 airline delay share
d = sorted(rows("output/airline_airport/airline_delay_summary.csv"), key=lambda r: -float(r["delay_pct"]))
hbar([(r["carrier_name"] or r["carrier"])[:24] for r in d], [float(r["delay_pct"]) for r in d],
     "Operated flights arriving 15+ min late, by airline", "% of operated flights", "01_airline_delay_pct.png")
# 2 airports
d = rows("output/airline_airport/airport_origin_delays.csv")[:15]
hbar([r["airport"] for r in d], [float(r["dep_delay_pct"]) for r in d],
     "Origin airports with the highest departure-delay share (top 15)", "% of operated departures 15+ min late", "02_airport_dep_delay_pct.png")
# 3 month
d = sorted(rows("output/time_analysis/delay_by_month.csv"), key=lambda r: int(r["month_num"]))
vbar([MONTHS[int(r["month_num"]) - 1] for r in d], [float(r["delay_pct"]) for r in d],
     "Delay share by month", "% of operated flights 15+ min late", "03_delay_by_month.png")
# 4 day of week
d = sorted(rows("output/time_analysis/delay_by_day_of_week.csv"), key=lambda r: int(r["day_num"]))
vbar([r["day_name"] for r in d], [float(r["delay_pct"]) for r in d],
     "Delay share by day of week", "% of operated flights 15+ min late", "04_delay_by_day_of_week.png")
# 5 hour of day
d = sorted(rows("output/time_analysis/delay_by_dep_hour.csv"), key=lambda r: int(r["dep_hour"]))
fig, ax = plt.subplots(figsize=(9, 5))
ax.plot([int(r["dep_hour"]) for r in d], [float(r["delay_pct"]) for r in d], marker="o")
ax.set_xlabel("Scheduled departure hour")
ax.set_ylabel("% of operated flights 15+ min late")
ax.set_title("Delay share by scheduled departure hour")
ax.set_xticks(list(range(0, 24, 2)))
ax.grid(True, alpha=0.3)
save(fig, "05_delay_by_dep_hour.png")
# 6 cancellation reasons
d = rows("output/cancellation_analysis/cancellation_by_reason.csv")
vbar([r["reason"] + "\n" + r["pct_of_cancellations"] + "%" for r in d], [float(r["cancelled_flights"]) for r in d],
     "Cancelled flights by reason", "Cancelled flights", "06_cancellation_reasons.png", "%.0f")
# 7 weather share by month
d = sorted(rows("output/weather_analysis/weather_by_month.csv"), key=lambda r: int(r["month_num"]))
vbar([MONTHS[int(r["month_num"]) - 1] for r in d], [float(r["weather_share_pct"]) for r in d],
     "Weather share of reported delay minutes, by month", "% of reported cause minutes", "07_weather_share_by_month.png")
# 8 worst routes
d = rows("output/route_analysis/route_worst_delays.csv")[:10]
hbar([r["route"] for r in d], [float(r["delay_pct"]) for r in d],
     "Routes with the highest delay share (top 10, at least 2000 flights)", "% of operated flights 15+ min late", "08_worst_routes.png")
# 9 threshold sweep on validation
d = rows("output/prediction_results/threshold_sweep_validation.csv")
with open(os.path.join(ROOT, "output", "prediction_results", "chosen_threshold.txt")) as fh:
    chosen = float(fh.read().strip())
xs = [float(r["threshold"]) for r in d]
fig, ax = plt.subplots(figsize=(9, 5))
ax.plot(xs, [float(r["prec"]) for r in d], marker="o", label="Precision")
ax.plot(xs, [float(r["recall"]) for r in d], marker="o", label="Recall")
ax.plot(xs, [float(r["f1"]) for r in d], marker="o", label="F1")
ax.axvline(chosen, linestyle="--", color="gray", label="Chosen threshold " + ("%.2f" % chosen))
ax.set_xlabel("Decision threshold")
ax.set_ylabel("Score")
ax.set_title("Threshold selection on the validation set")
ax.legend()
ax.grid(True, alpha=0.3)
save(fig, "09_threshold_sweep_validation.png")
# 10 confusion matrix on test
m = rows("output/prediction_results/test_metrics.csv")[0]
tp, fp, fn, tn = int(m["tp"]), int(m["fp"]), int(m["fn"]), int(m["tn"])
fig, ax = plt.subplots(figsize=(6, 5))
ax.imshow([[tn, fp], [fn, tp]], cmap="Blues")
ax.set_xticks([0, 1])
ax.set_xticklabels(["Predicted on time", "Predicted delayed"])
ax.set_yticks([0, 1])
ax.set_yticklabels(["Actually on time", "Actually delayed"])
for (i, j), v in {(0, 0): tn, (0, 1): fp, (1, 0): fn, (1, 1): tp}.items():
    ax.text(j, i, "{:,}".format(v), ha="center", va="center", fontsize=11)
ax.set_title("Test-year confusion matrix (threshold " + ("%.2f" % chosen) + ")")
save(fig, "10_confusion_matrix_test.png")
# 11 calibration on test
d = rows("output/prediction_results/calibration_test.csv")
fig, ax = plt.subplots(figsize=(6, 6))
sizes = [max(20.0, 400.0 * float(r["flights"]) / max(float(x["flights"]) for x in d)) for r in d]
ax.scatter([float(r["avg_pred_p"]) for r in d], [float(r["actual_rate"]) for r in d], s=sizes, alpha=0.7)
ax.plot([0, 1], [0, 1], linestyle="--", color="gray", label="Perfect calibration")
ax.set_xlim(0, 1)
ax.set_ylim(0, 1)
ax.set_xlabel("Average predicted probability")
ax.set_ylabel("Actual delay rate")
ax.set_title("Calibration on the test year (point size = flights)")
ax.legend()
ax.grid(True, alpha=0.3)
save(fig, "11_calibration_test.png")
# 12 model vs baselines
fig, axes = plt.subplots(1, 2, figsize=(9, 5))
for ax, labels, vals, ttl in [
    (axes[0], ["Model", "Always on time"], [float(m["accuracy"]), float(m["baseline_accuracy"])], "Accuracy"),
    (axes[1], ["Model", "Always delayed"], [float(m["f1"]), float(m["baseline_f1_always_delayed"])], "F1 (delayed class)")]:
    ax.bar([0, 1], vals)
    ax.set_xticks([0, 1])
    ax.set_xticklabels(labels)
    ax.set_ylim(0, 1)
    ax.set_title(ttl)
    for i, v in enumerate(vals):
        ax.text(i, v, "%.3f" % v, ha="center", va="bottom")
fig.suptitle("Test-year results versus simple baselines")
save(fig, "12_model_vs_baselines.png")
# 13 back-off level usage
d = rows("output/prediction_results/level_usage_test.csv")
order = {"L1": 1, "L2": 2, "L3": 3, "L4": 4, "GLOBAL": 5}
d = sorted(d, key=lambda r: order.get(r["level_used"], 9))
vbar([r["level_used"] for r in d], [float(r["pct_of_test"]) for r in d],
     "Share of test flights scored by each back-off level", "% of test flights", "13_backoff_level_usage.png")

missing = [n for n in WRITTEN if not os.path.isfile(os.path.join(OUT, n)) or os.path.getsize(os.path.join(OUT, n)) < 3000]
if missing or len(WRITTEN) != 13:
    sys.exit("Chart problem: wrote " + str(len(WRITTEN)) + " charts, bad files: " + str(missing))
print("All 13 charts written to output/charts")
