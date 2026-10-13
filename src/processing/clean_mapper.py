#!/usr/bin/env python3
import sys
import csv
from datetime import datetime

RAW_COLS = ["FL_DATE", "OP_CARRIER", "OP_CARRIER_FL_NUM", "ORIGIN", "DEST",
            "CRS_DEP_TIME", "DEP_TIME", "DEP_DELAY", "TAXI_OUT", "WHEELS_OFF",
            "WHEELS_ON", "TAXI_IN", "CRS_ARR_TIME", "ARR_TIME", "ARR_DELAY",
            "CANCELLED", "CANCELLATION_CODE", "DIVERTED", "CRS_ELAPSED_TIME",
            "ACTUAL_ELAPSED_TIME", "AIR_TIME", "DISTANCE", "CARRIER_DELAY",
            "WEATHER_DELAY", "NAS_DELAY", "SECURITY_DELAY", "LATE_AIRCRAFT_DELAY"]
IDX = dict((name, i) for i, name in enumerate(RAW_COLS))

counts = {}

def bump(name):
    counts[name] = counts.get(name, 0) + 1

def to_float(s):
    s = s.strip()
    if s == "":
        return None
    try:
        return float(s)
    except ValueError:
        return None

def to_int(s, default=0):
    v = to_float(s)
    if v is None:
        return default
    return int(round(v))

for row in csv.reader(sys.stdin):
    bump("ReadRecords")
    if not row:
        bump("DroppedEmpty")
        continue
    if row[0].strip() == "FL_DATE":
        bump("HeaderSkipped")
        continue
    if len(row) < len(RAW_COLS):
        bump("DroppedMalformed")
        continue

    def g(name):
        return row[IDX[name]].strip()

    try:
        d = datetime.strptime(g("FL_DATE"), "%Y-%m-%d")
    except ValueError:
        bump("DroppedBadDate")
        continue

    carrier = g("OP_CARRIER").upper()
    origin = g("ORIGIN").upper()
    dest = g("DEST").upper()
    if (not carrier.isalnum()) or len(origin) != 3 or len(dest) != 3 \
            or (not origin.isalpha()) or (not dest.isalpha()):
        bump("DroppedBadCode")
        continue

    cancelled_f = to_float(g("CANCELLED"))
    crs_dep_f = to_float(g("CRS_DEP_TIME"))
    if cancelled_f is None or crs_dep_f is None:
        bump("DroppedMalformed")
        continue
    cancelled = int(cancelled_f)
    diverted = to_int(g("DIVERTED"))

    if cancelled == 1:
        dep_delay = 0
        arr_delay = 0
        bump("CancelledKept")
    else:
        dep_f = to_float(g("DEP_DELAY"))
        arr_f = to_float(g("ARR_DELAY"))
        if dep_f is None or arr_f is None:
            bump("DroppedMissingDelay")
            continue
        dep_delay = int(round(dep_f))
        arr_delay = int(round(arr_f))

    crs_dep = int(crs_dep_f)
    dep_hour = (crs_dep // 100) % 24
    is_delayed = 1 if (cancelled == 0 and arr_delay >= 15) else 0
    cancel_code = g("CANCELLATION_CODE") or "NONE"

    out = [
        d.strftime("%Y-%m-%d"), str(d.year), str(d.month), str(d.day),
        str(d.isoweekday()), carrier, str(to_int(g("OP_CARRIER_FL_NUM"))),
        origin, dest, str(crs_dep), str(dep_hour), str(dep_delay),
        str(arr_delay), str(cancelled), cancel_code, str(diverted),
        str(to_int(g("DISTANCE"))), str(to_int(g("CARRIER_DELAY"))),
        str(to_int(g("WEATHER_DELAY"))), str(to_int(g("NAS_DELAY"))),
        str(to_int(g("SECURITY_DELAY"))), str(to_int(g("LATE_AIRCRAFT_DELAY"))),
        str(is_delayed),
    ]
    sys.stdout.write(",".join(out) + "\n")
    bump("WrittenRecords")

for name in counts:
    sys.stderr.write("reporter:counter:Cleaning,%s,%d\n" % (name, counts[name]))
