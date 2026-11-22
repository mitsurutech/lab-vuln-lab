# Labo de gestion des vulnérabilités avec Trivy : CVE, CVSS, EPSS, KEV, analyse d'images et SBOM, hors ligne

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-vuln-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-vuln-lab/actions/workflows/check.yml)

Un labo prêt à l'emploi pour la classe, issu de la [plateforme d'apprentissage MitsuruTech](https://mitsurutech.co.uk/fr/learning), où les écoles, lycées et universités donnent à chaque étudiant ses propres conteneurs et son terminal dans le navigateur. Il enseigne la gestion des vulnérabilités avec Trivy, le scanner open source : les étudiants analysent des images de conteneurs et les fichiers de verrouillage de projets, lisent des identifiants CVE et des vecteurs CVSS, classent les résultats avec EPSS et le catalogue Known Exploited Vulnerabilities (KEV) de la CISA, produisent et interrogent des SBOM, consignent une déclaration VEX, fixent des délais de correctif et rendent compte du risque. **Il fonctionne sans aucun accès à internet** : la base de vulnérabilités de Trivy et un instantané d'EPSS et du KEV sont dans l'image, donc chaque copie donne les mêmes réponses. C'est le labo du module [Gestion des vulnérabilités](https://mitsurutech.co.uk/fr/resources/university/vulnerability-management).

C'est un seul fichier `docker-compose`, `compose.yaml`, et il fonctionne de la même façon sur votre machine que sur la plateforme, où chaque étudiant reçoit une copie privée sans accès à internet.

## Ce qu'il contient

Trois services.

- `scanner` est Trivy 0.76.2 avec tout ce dont il a besoin dans son image (construite à partir de `image/`) :
  - la base de vulnérabilités de Trivy telle que publiée le **21 novembre 2026** (07:02 UTC), épinglée par le digest de son artefact OCI, donc jamais mise à jour ;
  - deux images nginx enregistrées sous forme d'archives, `/targets/web-1.25.3.tar` (Alpine 3.18.6, en fin de vie) et `/targets/web-1.31.9.tar` (Alpine 3.24.4), récupérées par le digest de leurs manifestes linux/amd64 ;
  - deux projets, `/targets/shop/requirements.txt` (une application Flask épinglée en 2022) et `/targets/reports/gradle.lockfile` (un service Java avec Log4j 2.14.1) ;
  - un instantané figé dans `/work/snapshot` : **les scores EPSS du 20 novembre 2026** (modèle v2026.06.15, 410 485 CVE) et **le catalogue KEV de la CISA, version 2026.11.20** (1 790 entrées), contrôlés par `image/snapshot/SHA256SUMS`.
- `web` est le serveur web de l'établissement, nginx 1.25.3 sur Alpine 3.18, la même image que la première archive. Il est ancien exprès et seul le labo peut l'atteindre.
- `tools` est un Python 3.12 qui partage `/work` avec le scanner, pour lire les rapports JSON de Trivy à côté de l'instantané.

Ce qu'il trouve, à partir de cet instantané figé : 74 résultats dans l'ancienne image (3 critiques, 44 CVE, aucune dans le KEV), 12 dans la nouvelle, 49 dans la boutique et 23 dans le service Java, dont deux dans le KEV (Log4Shell, CVE-2021-44228, et CVE-2021-45046). **Une vraie analyse aujourd'hui en trouverait davantage**, car de nouvelles vulnérabilités sont publiées chaque jour ; l'intérêt d'un instantané figé, c'est que toute la classe voit la même chose.

## Utilisation sur la plateforme

La plateforme donne à chaque étudiant sa propre copie d'un labo, dans le navigateur, avec un terminal à côté.

**Pour l'essayer :** ouvrez la [page des conteneurs](https://mitsurutech.co.uk/fr/container), trouvez ce labo dans **Sample labs** et appuyez sur Start. Un compte gratuit est nécessaire.

**Pour le donner en travail à une classe :**

1. Dans votre module, créez une tâche de type **Lab** et choisissez **In a GitHub repository**.
2. Indiquez `https://github.com/mitsurutech/lab-vuln-lab` avec la branche `main`. Le fichier compose est celui par défaut, `compose.yaml`. Faites d'abord un fork du dépôt si vous voulez le modifier.
3. Publiez. La copie de chaque étudiant part du commit que vous avez publié, donc une modification ultérieure ici ne change pas un labo déjà donné.

La [page de ce labo](https://mitsurutech.co.uk/fr/help/lab-vuln-lab) dans le manuel d'aide et son [guide des labos en conteneur](https://mitsurutech.co.uk/fr/help/labs) expliquent le reste. La leçon de base correspondante s'appelle **Vulnerability Scanning Basics**. Pas encore de compte d'établissement ? [La première année est gratuite](https://mitsurutech.co.uk/fr/pricing) jusqu'à 50 étudiants, et [l'inscription](https://mitsurutech.co.uk/fr/signup) ne demande qu'une adresse e-mail.

## L'exécuter sur votre propre machine

Il vous faut Docker avec le plugin Compose.

```bash
docker compose -f compose.yaml -f local.yaml up -d
docker compose exec scanner trivy image --input /targets/web-1.25.3.tar --severity CRITICAL
docker compose exec scanner trivy fs /targets/reports
```

`local.yaml` ne publie l'ancien nginx que sur `127.0.0.1:8080` : laissez-le là. Supprimez le tout avec `docker compose -f compose.yaml -f local.yaml down -v`.

## Ce qui ne fonctionne pas dans un labo

Le labo n'a aucun accès à internet : Trivy ne met donc jamais sa base à jour et ne peut pas récupérer une image depuis un registre ; il analyse les archives et les dossiers qu'il embarque. Rien n'est exploité ; l'ancien nginx est là pour être examiné, pas attaqué. N'analysez jamais que ce qui vous appartient ou ce que vous avez l'autorisation écrite de tester.

## Vérifier le labo

`test/check.sh` démarre le labo comme le runner de la plateforme démarre chaque service (toutes les capacités retirées, `no-new-privileges`, une limite de processus, des limites de mémoire et aucun accès à internet) et vérifie chaque total et chaque chiffre de l'instantané cités dans les leçons. À chaque push, c'est le badge en haut de la page, GitHub construit le scanner à partir de `image/` et l'exécute.

```bash
test/check.sh                                   # the pinned scanner image
docker build -t scanner image && SCANNER_IMAGE=scanner test/check.sh   # one built from image/
```

L'image épinglée, `ghcr.io/mitsurutech/lab-images:5ec118000001-vuln-lab-scanner-77d86af1e968`, a été construite à partir de `image/` au commit `77d86af` par le workflow public [lab-builder](https://github.com/mitsurutech/lab-builder) sur les machines de GitHub, pour amd64 et arm64.

## D'où viennent les données

- Trivy est sous licence Apache-2.0, par Aqua Security, et tourne sans modification depuis son image officielle `aquasec/trivy:0.76.2`.
- La base de Trivy est construite par Aqua Security à partir d'avis publics (NVD, les distributions Linux, la base d'avis de GitHub et d'autres), chacun sous ses propres conditions.
- EPSS est publié par FIRST, le Forum of Incident Response and Security Teams ; voir [first.org/epss](https://www.first.org/epss/). Le fichier est copié tel quel.
- Le catalogue KEV est publié par la CISA, la Cybersecurity and Infrastructure Security Agency des États-Unis ; voir [cisa.gov/known-exploited-vulnerabilities-catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog). Le fichier est copié tel quel.
- nginx est sous licence BSD-2-Clause ; les paquets d'Alpine sont sous leurs propres licences. Les images sont récupérées depuis Docker Hub lors de la construction de l'image du scanner.

Les versions épinglées dans `requirements.txt` et `gradle.lockfile` sont anciennes exprès, pour être analysées. Ne les installez jamais.

## Licence

Le labo lui-même (le fichier compose, les scripts et ce README) est sous licence [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr). Vous pouvez le partager et l'adapter pour apprendre et enseigner, à condition de créditer Mitsuru Technologies Ltd, de ne pas en faire un usage commercial et de partager ce que vous en tirez sous la même licence. Le texte complet se trouve dans le fichier `LICENSE`. Les logiciels et données tiers listés ci-dessus gardent leurs propres licences.

## À propos

Réalisé par [Mitsuru Technologies](https://mitsurutech.co.uk/fr) pour la [MitsuruTech Learning Platform](https://mitsurutech.co.uk/fr/learning) : Python, Java, Go, Node, SQL et Linux dans le navigateur pour les écoles et les établissements, avec des labos en conteneur, des applications web déployées depuis GitHub et des quiz qui se corrigent tout seuls. Essayez du code sans compte dans le [playground](https://mitsurutech.co.uk/fr/playground).

D'autres labos du même endroit : [lab-harden-nginx](https://github.com/mitsurutech/lab-harden-nginx), [lab-docker-basics](https://github.com/mitsurutech/lab-docker-basics), [lab-nodegoat-lab](https://github.com/mitsurutech/lab-nodegoat-lab), [lab-vector-lab](https://github.com/mitsurutech/lab-vector-lab).
