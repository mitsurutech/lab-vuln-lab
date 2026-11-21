#!/usr/bin/env bash
# What compose.yaml's header and the lessons promise, checked through docker exec, which is how
# the platform's terminal reaches the lab: run by check.sh.
set -euo pipefail
: "${NET:?run through test/check.sh}"
: "${SCANNER:?run through test/check.sh}"
: "${WEB:?run through test/check.sh}"
: "${TOOLS:?run through test/check.sh}"
probe() { docker run --rm --network "$NET" lab-check-probe bash -c "$1"; }
scan() { docker exec "$SCANNER" trivy "$@"; }
# A line the output must hold exactly.
expect() { # expect <output> <line>...
  local out="$1"; shift
  for want in "$@"; do
    echo "$out" | grep -Fxq -- "$want" || { echo "missing '$want' in: $out" >&2; exit 1; }
  done
}

echo "- nothing reaches the internet, and the web server answers on its own network"
probe '
set -eu
curl -fs -o /dev/null http://web/ || { echo "web does not answer" >&2; exit 1; }
if curl -s -m 4 -o /dev/null https://example.com; then echo "the lab reached the internet" >&2; exit 1; fi
'

echo "- Trivy and its frozen database"
out=$(scan --version)
expect "$out" "Version: 0.76.2" "  UpdatedAt: 2026-11-21 07:02:51.626719824 +0000 UTC"

echo "- the old image, as the web server runs it"
expect "$(docker exec "$WEB" cat /etc/alpine-release)" "3.18.6"
expect "$(docker exec "$WEB" grep -A1 -x P:libssl3 /lib/apk/db/installed)" "P:libssl3" "V:3.1.4-r5"

echo "- the totals every lesson quotes"
expect "$(scan image --input /targets/web-1.25.3.tar)" "Total: 74 (UNKNOWN: 0, LOW: 25, MEDIUM: 29, HIGH: 17, CRITICAL: 3)"
expect "$(scan image --input /targets/web-1.25.3.tar --severity CRITICAL)" "Total: 3 (CRITICAL: 3)"
expect "$(scan image --input /targets/web-1.25.3.tar --severity HIGH,CRITICAL)" "Total: 20 (HIGH: 17, CRITICAL: 3)"
expect "$(scan image --input /targets/web-1.31.9.tar)" "Total: 12 (UNKNOWN: 0, LOW: 4, MEDIUM: 7, HIGH: 1, CRITICAL: 0)"
expect "$(scan fs /targets/shop)" "Total: 49 (UNKNOWN: 0, LOW: 7, MEDIUM: 25, HIGH: 16, CRITICAL: 1)"
expect "$(scan fs /targets/reports)" "Total: 23 (UNKNOWN: 0, LOW: 0, MEDIUM: 13, HIGH: 8, CRITICAL: 2)"

echo "- an SBOM written and scanned again"
scan fs /targets/reports --format cyclonedx -o /work/reports/reports.cdx.json
expect "$(scan sbom /work/reports/reports.cdx.json --severity CRITICAL)" "Total: 2 (CRITICAL: 2)"

echo "- the EPSS and KEV snapshot, read from the tools service"
out=$(docker exec "$TOOLS" python3 -c "
import csv, gzip, json
kev = json.load(open('/work/snapshot/kev-2026-11-20.json'))
print('kev', kev['catalogVersion'], kev['count'])
log4j = [v for v in kev['vulnerabilities'] if v['cveID'] == 'CVE-2021-44228'][0]
print('log4shell', log4j['dateAdded'], log4j['dueDate'], log4j['knownRansomwareCampaignUse'])
for row in csv.reader(gzip.open('/work/snapshot/epss-2026-11-20.csv.gz', 'rt')):
    if row[0] in ('CVE-2024-2511', 'CVE-2024-45492', 'CVE-2021-44228'):
        print(*row)
")
expect "$out" "kev 2026.11.20 1790" "log4shell 2021-12-10 2021-12-24 Known" \
  "CVE-2024-2511 0.59304 0.99141" "CVE-2024-45492 0.01393 0.73038" "CVE-2021-44228 0.99999 1.0"
