#!/usr/bin/env python3
"""Dựng data/airports.tsv (IATA → múi giờ IANA, mã nước, thành phố) cho bộ máy luật T2 (on-device-extraction.md §4.3).

Nguồn: https://github.com/mwgg/Airports (airports.json, giấy phép MIT, ghi công ở data/README.md).
Múi giờ của nguồn suy theo tọa độ và đôi khi là múi giờ của nước láng giềng (HAN → Asia/Bangkok); nước chỉ có 1 múi giờ trong
zone.tab của tzdata thì lấy múi đó. Nước nhiều múi giữ múi của nguồn; tên cũ (Europe/Kiev) đổi sang tên chuẩn theo dòng `L` của tzdata.zi.

Chạy: python3 -I tool/build_airports.py <airports.json> [/usr/share/zoneinfo] > data/airports.tsv
"""
import collections, json, sys

src = json.load(open(sys.argv[1], encoding="utf-8"))
tzdir = sys.argv[2] if len(sys.argv) > 2 else "/usr/share/zoneinfo"
links = {}
for line in open(f"{tzdir}/tzdata.zi", encoding="utf-8"):
    if line.startswith("L "):
        _, target, name = line.split()
        links[name] = target
zones = collections.defaultdict(list)
for line in open(f"{tzdir}/zone.tab", encoding="utf-8"):
    if line.startswith("#") or not line.strip():
        continue
    cc, _, tz = line.split("\t")[:3]
    zones[cc].append(tz.strip())

rows = {}
for a in src.values():
    code = (a.get("iata") or "").strip().upper()
    if len(code) != 3 or not code.isalpha() or not a.get("tz"):
        continue
    cc = a.get("country") or ""
    tz = zones[cc][0] if len(zones.get(cc, [])) == 1 else links.get(a["tz"], a["tz"])
    city = " ".join((a.get("city") or "").split()).replace("\t", " ")
    # Trùng mã (sân bay đã đóng còn trong dữ liệu): giữ bản có thành phố.
    if code in rows and rows[code][2] and not city:
        continue
    rows[code] = (cc, tz, city)

print("# iata\tcountry\ttz\tcity · nguồn mwgg/Airports (MIT), xem data/README.md · dựng bằng tool/build_airports.py")
for code in sorted(rows):
    cc, tz, city = rows[code]
    print(f"{code}\t{cc}\t{tz}\t{city}")
