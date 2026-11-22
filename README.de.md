# Lab für Schwachstellenmanagement mit Trivy: CVE, CVSS, EPSS, KEV, Image-Scans und SBOMs, offline

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-vuln-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-vuln-lab/actions/workflows/check.yml)

Ein fertiges Lab für den Unterricht von der [MitsuruTech Learning Platform](https://mitsurutech.co.uk/de/learning), auf der Schulen, Colleges und Hochschulen allen Studierenden eigene Container und ein Terminal im Browser geben. Es vermittelt Schwachstellenmanagement mit Trivy, dem Open-Source-Scanner: Die Studierenden scannen Container-Images und Lockfiles von Projekten, lesen CVE-Kennungen und CVSS-Vektoren, priorisieren Befunde mit EPSS und dem Katalog Known Exploited Vulnerabilities (KEV) der CISA, erstellen und durchsuchen SBOMs, halten eine VEX-Erklärung fest, setzen Fristen für Patches und berichten über das Risiko. **Es funktioniert ganz ohne Internet**: Die Schwachstellendatenbank von Trivy und ein Schnappschuss von EPSS und KEV stecken im Image, sodass jede Kopie dieselben Antworten gibt. Es ist das Lab zum Modul [Schwachstellenmanagement](https://mitsurutech.co.uk/de/resources/university/vulnerability-management).

Es ist eine einzige `docker-compose`-Datei, `compose.yaml`, und läuft auf dem eigenen Rechner genauso wie auf der Plattform, wo alle Studierenden eine private Kopie ohne Weg ins Internet bekommen.

## Was darin ist

Drei Dienste.

- `scanner` ist Trivy 0.76.2 mit allem, was es braucht, in seinem Image (gebaut aus `image/`):
  - die Schwachstellendatenbank von Trivy, wie sie am **21. November 2026** (07:02 UTC) veröffentlicht wurde, festgelegt per Digest ihres OCI-Artefakts, also nie aktualisiert;
  - zwei als Archive gespeicherte nginx-Images, `/targets/web-1.25.3.tar` (Alpine 3.18.6, ohne Support) und `/targets/web-1.31.9.tar` (Alpine 3.24.4), geladen per Digest ihrer linux/amd64-Manifeste;
  - zwei Projekte, `/targets/shop/requirements.txt` (eine Flask-App, deren Versionen 2022 festgelegt wurden) und `/targets/reports/gradle.lockfile` (ein Java-Dienst mit Log4j 2.14.1);
  - ein eingefrorener Schnappschuss in `/work/snapshot`: **EPSS-Werte vom 20. November 2026** (Modell v2026.06.15, 410.485 CVEs) und **der KEV-Katalog der CISA, Version 2026.11.20** (1.790 Einträge), geprüft gegen `image/snapshot/SHA256SUMS`.
- `web` ist der Webserver des Colleges, nginx 1.25.3 auf Alpine 3.18, dasselbe Image wie das erste Archiv. Er ist absichtlich alt, und nur das Lab erreicht ihn.
- `tools` ist Python 3.12 und teilt `/work` mit dem Scanner, um die JSON-Berichte von Trivy neben dem Schnappschuss zu lesen.

Was es mit diesem eingefrorenen Schnappschuss findet: 74 Befunde im alten Image (3 kritisch, 44 CVEs, keine im KEV), 12 im neuen, 49 im Shop und 23 im Java-Dienst, zwei davon im KEV (Log4Shell, CVE-2021-44228, und CVE-2021-45046). **Ein echter Scan fände heute mehr**, weil jeden Tag neue Schwachstellen veröffentlicht werden; der Sinn eines eingefrorenen Schnappschusses ist, dass eine ganze Klasse dasselbe sieht.

## Verwendung auf der Plattform

Die Plattform gibt allen Studierenden eine eigene Kopie eines Labs im Browser, mit einem Terminal daneben.

**Zum Ausprobieren:** Öffnen Sie die [Container-Seite](https://mitsurutech.co.uk/de/container), suchen Sie dieses Lab unter **Sample labs** und drücken Sie Start. Dafür ist ein kostenloses Konto nötig.

**Als Aufgabe für eine Klasse:**

1. Legen Sie in Ihrem Modul eine Aufgabe vom Typ **Lab** an und wählen Sie **In a GitHub repository**.
2. Geben Sie `https://github.com/mitsurutech/lab-vuln-lab` mit dem Branch `main` an. Die Compose-Datei ist die Vorgabe, `compose.yaml`. Forken Sie das Repository zuerst, wenn Sie es ändern möchten.
3. Veröffentlichen Sie. Jede Kopie startet von dem Commit, den Sie veröffentlicht haben, sodass eine spätere Änderung hier ein bereits gestelltes Lab nicht verändert.

Die [Seite zu diesem Lab](https://mitsurutech.co.uk/de/help/lab-vuln-lab) im Hilfehandbuch und sein [Leitfaden zu Container-Labs](https://mitsurutech.co.uk/de/help/labs) erklären den Rest. Die passende Grundlagenlektion ist **Vulnerability Scanning Basics**. Noch kein College-Konto? [Das erste Jahr ist kostenlos](https://mitsurutech.co.uk/de/pricing) für bis zu 50 Studierende, und für die [Anmeldung](https://mitsurutech.co.uk/de/signup) genügt eine E-Mail-Adresse.

## Auf dem eigenen Rechner ausführen

Sie brauchen Docker mit dem Compose-Plugin.

```bash
docker compose -f compose.yaml -f local.yaml up -d
docker compose exec scanner trivy image --input /targets/web-1.25.3.tar --severity CRITICAL
docker compose exec scanner trivy fs /targets/reports
```

`local.yaml` veröffentlicht das alte nginx nur auf `127.0.0.1:8080`, und dort sollte es bleiben. Entfernen Sie alles mit `docker compose -f compose.yaml -f local.yaml down -v`.

## Was in einem Lab nicht geht

Das Lab hat keinen Weg ins Internet, deshalb aktualisiert Trivy seine Datenbank nie und kann kein Image aus einer Registry laden: Es scannt die Archive und Ordner, die es mitbringt. Nichts wird ausgenutzt; das alte nginx ist zum Lesen da, nicht zum Angreifen. Scannen Sie nur, was Ihnen gehört oder wofür Sie eine schriftliche Erlaubnis zum Testen haben.

## Das Lab prüfen

`test/check.sh` startet das Lab so, wie der Runner der Plattform jeden Dienst startet (alle Capabilities entzogen, `no-new-privileges`, ein Prozesslimit, Speicherlimits und kein Weg ins Internet), und prüft jede Summe und jede Zahl aus dem Schnappschuss, die die Lektionen zitieren. Bei jedem Push, das ist das Abzeichen oben, baut GitHub den Scanner aus `image/` und führt ihn aus.

```bash
test/check.sh                                   # the pinned scanner image
docker build -t scanner image && SCANNER_IMAGE=scanner test/check.sh   # one built from image/
```

Das festgelegte Image, `ghcr.io/mitsurutech/lab-images:5ec118000001-vuln-lab-scanner-77d86af1e968`, wurde aus `image/` im Commit `77d86af` vom öffentlichen Workflow [lab-builder](https://github.com/mitsurutech/lab-builder) auf den eigenen Maschinen von GitHub gebaut, für amd64 und arm64.

## Woher die Daten kommen

- Trivy steht unter Apache-2.0, stammt von Aqua Security und läuft unverändert aus seinem offiziellen Image `aquasec/trivy:0.76.2`.
- Die Trivy-Datenbank wird von Aqua Security aus öffentlichen Sicherheitshinweisen gebaut (NVD, die Linux-Distributionen, die Advisory-Datenbank von GitHub und andere), jeweils unter eigenen Bedingungen.
- EPSS wird von FIRST veröffentlicht, dem Forum of Incident Response and Security Teams; siehe [first.org/epss](https://www.first.org/epss/). Die Datei ist unverändert kopiert.
- Der KEV-Katalog wird von der CISA veröffentlicht, der US-amerikanischen Cybersecurity and Infrastructure Security Agency; siehe [cisa.gov/known-exploited-vulnerabilities-catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog). Die Datei ist unverändert kopiert.
- nginx steht unter BSD-2-Clause; die Pakete von Alpine stehen unter ihren eigenen Lizenzen. Die Images werden beim Bau des Scanner-Images von Docker Hub geladen.

Die in `requirements.txt` und `gradle.lockfile` festgelegten Versionen sind absichtlich alt, um gescannt zu werden. Installieren Sie sie niemals.

## Lizenz

Das Lab selbst (die Compose-Datei, die Skripte und diese README) steht unter der Lizenz [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.de). Sie dürfen es zum Lernen und Lehren teilen und bearbeiten, wenn Sie Mitsuru Technologies Ltd nennen, es nicht kommerziell nutzen und alles, was Sie daraus machen, unter derselben Lizenz weitergeben. Der vollständige Text steht in der Datei `LICENSE`. Die oben genannte Software und die Daten Dritter behalten ihre eigenen Lizenzen.

## Über uns

Erstellt von [Mitsuru Technologies](https://mitsurutech.co.uk/de) für die [MitsuruTech Learning Platform](https://mitsurutech.co.uk/de/learning): Python, Java, Go, Node, SQL und Linux im Browser für Schulen und Colleges, mit Container-Labs, aus GitHub bereitgestellten Web-Apps und Quizzen, die sich selbst bewerten. Probieren Sie Code ohne Konto im [Playground](https://mitsurutech.co.uk/de/playground) aus.

Weitere Labs aus demselben Haus: [lab-harden-nginx](https://github.com/mitsurutech/lab-harden-nginx), [lab-docker-basics](https://github.com/mitsurutech/lab-docker-basics), [lab-nodegoat-lab](https://github.com/mitsurutech/lab-nodegoat-lab), [lab-vector-lab](https://github.com/mitsurutech/lab-vector-lab).
