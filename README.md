# Vulnerability management lab with Trivy: CVE, CVSS, EPSS, KEV, image scanning and SBOMs, offline

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-vuln-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-vuln-lab/actions/workflows/check.yml)

A ready-made lab for classrooms, from the [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning), where schools, colleges and universities give every student their own containers and terminal in the browser. It teaches vulnerability management with Trivy, the open-source scanner: students scan container images and project lock files, read CVE identifiers and CVSS vectors, rank findings with EPSS and CISA's Known Exploited Vulnerabilities (KEV) catalogue, write and search SBOMs, record a VEX statement, set patch deadlines and report risk. **It works with no internet at all**: Trivy's vulnerability database and a snapshot of EPSS and KEV are inside the image, so every copy gives the same answers. It is the lab behind the [Vulnerability management](https://mitsurutech.co.uk/resources/university/vulnerability-management) module.

It is one `docker-compose` file, `compose.yaml`, and it runs the same on your own machine as it does on the platform, where every student gets a private copy with no way out to the internet.

## What is in it

Three services.

- `scanner` is Trivy 0.76.2 with everything it needs inside its image (built from `image/`):
  - Trivy's vulnerability database as published on **21 November 2026** (07:02 UTC), pinned by the digest of its OCI artifact, so it is never updated;
  - two nginx images saved as archives, `/targets/web-1.25.3.tar` (Alpine 3.18.6, past its end of life) and `/targets/web-1.31.9.tar` (Alpine 3.24.4), pulled by the digest of their linux/amd64 manifests;
  - two projects, `/targets/shop/requirements.txt` (a Flask app pinned in 2022) and `/targets/reports/gradle.lockfile` (a Java service with Log4j 2.14.1);
  - a frozen snapshot in `/work/snapshot`: **EPSS scores of 20 November 2026** (model v2026.06.15, 410,485 CVEs) and **CISA's KEV catalogue, version 2026.11.20** (1,790 entries), checked against `image/snapshot/SHA256SUMS`.
- `web` is the college's web server, nginx 1.25.3 on Alpine 3.18, the same image as the first archive. It is old on purpose and only the lab can reach it.
- `tools` is Python 3.12, sharing `/work` with the scanner, for reading Trivy's JSON reports beside the snapshot.

What it finds, from that frozen snapshot: 74 findings in the old image (3 critical, 44 CVEs, none in KEV), 12 in the new one, 49 in the shop and 23 in the Java service, two of them in KEV (Log4Shell, CVE-2021-44228, and CVE-2021-45046). **A real scan today would find more**, since new vulnerabilities are published every day; the point of a frozen snapshot is that a class all sees the same thing.

## Using it on the platform

The platform gives every student their own copy of a lab, in the browser, with a terminal beside it.

**To try it:** open the [container page](https://mitsurutech.co.uk/container), find this lab in **Sample labs** and press Start. It needs a free account.

**To set it as work for a class:**

1. In your module, make a task of type **Lab** and choose **In a GitHub repository**.
2. Give `https://github.com/mitsurutech/lab-vuln-lab` with the branch `main`. The compose file is the default, `compose.yaml`. Fork the repository first if you want to change it.
3. Publish. Every student's copy starts from the commit you published, so a later change here does not alter a lab already set.

The help manual's [page for this lab](https://mitsurutech.co.uk/help/lab-vuln-lab) and its [guide to container labs](https://mitsurutech.co.uk/help/labs) cover the rest. The matching basic lesson is **Vulnerability Scanning Basics**. No college account yet? [Your first year is free](https://mitsurutech.co.uk/pricing) for up to 50 students, and [signing up](https://mitsurutech.co.uk/signup) takes an email address.

## Running it on your own machine

You need Docker with the Compose plugin.

```bash
docker compose -f compose.yaml -f local.yaml up -d
docker compose exec scanner trivy image --input /targets/web-1.25.3.tar --severity CRITICAL
docker compose exec scanner trivy fs /targets/reports
```

`local.yaml` publishes the old nginx on `127.0.0.1:8080` only, so keep it there. Remove everything with `docker compose -f compose.yaml -f local.yaml down -v`.

## What does not work in a lab

The lab has no way out to the internet, so Trivy never updates its database and cannot pull an image from a registry: it scans the archives and folders it carries. Nothing is exploited; the old nginx is there to be read, not attacked. Only ever scan what you own or have written permission to test.

## Checking the lab

`test/check.sh` starts the lab the way the platform's runner starts every service (all capabilities dropped, `no-new-privileges`, a process limit, memory limits, and no way out to the internet) and checks every total and snapshot figure the lessons quote. On every push, which is the badge at the top, GitHub builds the scanner from `image/` and runs it.

```bash
test/check.sh                                   # the pinned scanner image
docker build -t scanner image && SCANNER_IMAGE=scanner test/check.sh   # one built from image/
```

The pinned image, `ghcr.io/mitsurutech/lab-images:5ec118000001-vuln-lab-scanner-77d86af1e968`, was built from `image/` at commit `77d86af` by the public [lab-builder](https://github.com/mitsurutech/lab-builder) workflow on GitHub's own machines, for amd64 and arm64.

## Where the data comes from

- Trivy is Apache-2.0, by Aqua Security, run unmodified from its official image `aquasec/trivy:0.76.2`.
- The Trivy database is built by Aqua Security from public advisories (NVD, the Linux distributions, GitHub's advisory database and others), each under its own terms.
- EPSS is published by FIRST, the Forum of Incident Response and Security Teams; see [first.org/epss](https://www.first.org/epss/). The file is copied unchanged.
- The KEV catalogue is published by CISA, the US Cybersecurity and Infrastructure Security Agency; see [cisa.gov/known-exploited-vulnerabilities-catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog). The file is copied unchanged.
- nginx is BSD-2-Clause; Alpine's packages are under their own licences. The images are pulled from Docker Hub when the scanner image is built.

The versions pinned in `requirements.txt` and `gradle.lockfile` are old on purpose, to be scanned. Never install them.

## Licence

The lab itself (the compose file, the scripts and this README) is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). You may share it and adapt it for learning and teaching, if you credit Mitsuru Technologies Ltd, do not use it commercially, and share anything you make from it under the same licence. The full text is in the `LICENSE` file. The third-party software and data listed above keep their own licences.

## About

Made by [Mitsuru Technologies](https://mitsurutech.co.uk) for the [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning): Python, Java, Go, Node, SQL and Linux in the browser for schools and colleges, with container labs, web apps deployed from GitHub, and quizzes that mark themselves. Try code with no account in the [playground](https://mitsurutech.co.uk/playground).

More labs from the same place: [lab-harden-nginx](https://github.com/mitsurutech/lab-harden-nginx), [lab-docker-basics](https://github.com/mitsurutech/lab-docker-basics), [lab-nodegoat-lab](https://github.com/mitsurutech/lab-nodegoat-lab), [lab-vector-lab](https://github.com/mitsurutech/lab-vector-lab).
