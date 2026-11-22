# Laboratorio de gestión de vulnerabilidades con Trivy: CVE, CVSS, EPSS, KEV, escaneo de imágenes y SBOM, sin conexión

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-vuln-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-vuln-lab/actions/workflows/check.yml)

Un laboratorio listo para clase, de la [plataforma de aprendizaje MitsuruTech](https://mitsurutech.co.uk/es/learning), donde colegios, institutos y universidades dan a cada estudiante sus propios contenedores y terminal en el navegador. Enseña gestión de vulnerabilidades con Trivy, el escáner de código abierto: los estudiantes escanean imágenes de contenedores y archivos de bloqueo de proyectos, leen identificadores CVE y vectores CVSS, priorizan los hallazgos con EPSS y con el catálogo Known Exploited Vulnerabilities (KEV) de CISA, generan y consultan SBOM, registran una declaración VEX, fijan plazos de parcheo e informan del riesgo. **Funciona sin internet en absoluto**: la base de datos de vulnerabilidades de Trivy y una instantánea de EPSS y KEV están dentro de la imagen, así que cada copia da las mismas respuestas. Es el laboratorio del módulo [Gestión de vulnerabilidades](https://mitsurutech.co.uk/es/resources/university/vulnerability-management).

Es un solo archivo `docker-compose`, `compose.yaml`, y funciona igual en tu ordenador que en la plataforma, donde cada estudiante recibe una copia privada sin salida a internet.

## Qué contiene

Tres servicios.

- `scanner` es Trivy 0.76.2 con todo lo que necesita dentro de su imagen (construida a partir de `image/`):
  - la base de datos de vulnerabilidades de Trivy tal como se publicó el **21 de noviembre de 2026** (07:02 UTC), fijada por el digest de su artefacto OCI, así que nunca se actualiza;
  - dos imágenes de nginx guardadas como archivos, `/targets/web-1.25.3.tar` (Alpine 3.18.6, fuera de soporte) y `/targets/web-1.31.9.tar` (Alpine 3.24.4), descargadas por el digest de sus manifiestos linux/amd64;
  - dos proyectos, `/targets/shop/requirements.txt` (una aplicación Flask fijada en 2022) y `/targets/reports/gradle.lockfile` (un servicio Java con Log4j 2.14.1);
  - una instantánea congelada en `/work/snapshot`: **las puntuaciones EPSS del 20 de noviembre de 2026** (modelo v2026.06.15, 410.485 CVE) y **el catálogo KEV de CISA, versión 2026.11.20** (1.790 entradas), comprobados con `image/snapshot/SHA256SUMS`.
- `web` es el servidor web del centro, nginx 1.25.3 sobre Alpine 3.18, la misma imagen que el primer archivo. Es antiguo a propósito y solo el laboratorio puede llegar a él.
- `tools` es Python 3.12, que comparte `/work` con el escáner, para leer los informes JSON de Trivy junto a la instantánea.

Lo que encuentra, a partir de esa instantánea congelada: 74 hallazgos en la imagen antigua (3 críticos, 44 CVE, ninguno en KEV), 12 en la nueva, 49 en la tienda y 23 en el servicio Java, dos de ellos en KEV (Log4Shell, CVE-2021-44228, y CVE-2021-45046). **Un escaneo real hoy encontraría más**, porque cada día se publican vulnerabilidades nuevas; la gracia de una instantánea congelada es que toda la clase ve lo mismo.

## Uso en la plataforma

La plataforma da a cada estudiante su propia copia de un laboratorio, en el navegador, con una terminal al lado.

**Para probarlo:** abre la [página de contenedores](https://mitsurutech.co.uk/es/container), busca este laboratorio en **Sample labs** y pulsa Start. Necesitas una cuenta gratuita.

**Para ponerlo como tarea a una clase:**

1. En tu módulo, crea una tarea de tipo **Lab** y elige **In a GitHub repository**.
2. Indica `https://github.com/mitsurutech/lab-vuln-lab` con la rama `main`. El archivo compose es el predeterminado, `compose.yaml`. Haz antes un fork del repositorio si quieres cambiarlo.
3. Publica. La copia de cada estudiante parte del commit que publicaste, así que un cambio posterior aquí no altera un laboratorio ya asignado.

La [página de este laboratorio](https://mitsurutech.co.uk/es/help/lab-vuln-lab) en el manual de ayuda y su [guía de laboratorios de contenedores](https://mitsurutech.co.uk/es/help/labs) explican el resto. La lección básica que lo acompaña es **Vulnerability Scanning Basics**. ¿Aún no tienes cuenta de centro? [El primer año es gratis](https://mitsurutech.co.uk/es/pricing) para hasta 50 estudiantes, y para [registrarte](https://mitsurutech.co.uk/es/signup) basta un correo electrónico.

## Ejecutarlo en tu propio ordenador

Necesitas Docker con el plugin Compose.

```bash
docker compose -f compose.yaml -f local.yaml up -d
docker compose exec scanner trivy image --input /targets/web-1.25.3.tar --severity CRITICAL
docker compose exec scanner trivy fs /targets/reports
```

`local.yaml` publica el nginx antiguo solo en `127.0.0.1:8080`, así que déjalo ahí. Elimínalo todo con `docker compose -f compose.yaml -f local.yaml down -v`.

## Qué no funciona en un laboratorio

El laboratorio no tiene salida a internet, así que Trivy nunca actualiza su base de datos y no puede descargar una imagen de un registro: escanea los archivos y carpetas que lleva consigo. No se explota nada; el nginx antiguo está ahí para leerlo, no para atacarlo. Escanea solo lo que sea tuyo o lo que tengas permiso por escrito para probar.

## Comprobar el laboratorio

`test/check.sh` arranca el laboratorio como el runner de la plataforma arranca cada servicio (todas las capacidades eliminadas, `no-new-privileges`, un límite de procesos, límites de memoria y sin salida a internet) y comprueba cada total y cada cifra de la instantánea que citan las lecciones. En cada push, que es la insignia de arriba, GitHub construye el escáner a partir de `image/` y lo ejecuta.

```bash
test/check.sh                                   # the pinned scanner image
docker build -t scanner image && SCANNER_IMAGE=scanner test/check.sh   # one built from image/
```

La imagen fijada, `ghcr.io/mitsurutech/lab-images:5ec118000001-vuln-lab-scanner-77d86af1e968`, se construyó a partir de `image/` en el commit `77d86af` con el workflow público [lab-builder](https://github.com/mitsurutech/lab-builder) en las máquinas de GitHub, para amd64 y arm64.

## De dónde vienen los datos

- Trivy tiene licencia Apache-2.0, es de Aqua Security y se ejecuta sin cambios desde su imagen oficial `aquasec/trivy:0.76.2`.
- La base de datos de Trivy la construye Aqua Security a partir de avisos públicos (NVD, las distribuciones de Linux, la base de avisos de GitHub y otros), cada uno con sus propias condiciones.
- EPSS lo publica FIRST, el Forum of Incident Response and Security Teams; consulta [first.org/epss](https://www.first.org/epss/). El archivo se copia sin cambios.
- El catálogo KEV lo publica CISA, la Cybersecurity and Infrastructure Security Agency de Estados Unidos; consulta [cisa.gov/known-exploited-vulnerabilities-catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog). El archivo se copia sin cambios.
- nginx tiene licencia BSD-2-Clause; los paquetes de Alpine tienen sus propias licencias. Las imágenes se descargan de Docker Hub cuando se construye la imagen del escáner.

Las versiones fijadas en `requirements.txt` y `gradle.lockfile` son antiguas a propósito, para escanearlas. No las instales nunca.

## Licencia

El laboratorio en sí (el archivo compose, los scripts y este README) está bajo la licencia [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es). Puedes compartirlo y adaptarlo para aprender y enseñar, siempre que cites a Mitsuru Technologies Ltd, no lo uses con fines comerciales y compartas lo que crees a partir de él con la misma licencia. El texto completo está en el archivo `LICENSE`. El software y los datos de terceros de la lista anterior mantienen sus propias licencias.

## Acerca de

Creado por [Mitsuru Technologies](https://mitsurutech.co.uk/es) para la [MitsuruTech Learning Platform](https://mitsurutech.co.uk/es/learning): Python, Java, Go, Node, SQL y Linux en el navegador para colegios, institutos y centros de formación, con laboratorios de contenedores, aplicaciones web desplegadas desde GitHub y cuestionarios que se corrigen solos. Prueba código sin cuenta en el [playground](https://mitsurutech.co.uk/es/playground).

Más laboratorios del mismo sitio: [lab-harden-nginx](https://github.com/mitsurutech/lab-harden-nginx), [lab-docker-basics](https://github.com/mitsurutech/lab-docker-basics), [lab-nodegoat-lab](https://github.com/mitsurutech/lab-nodegoat-lab), [lab-vector-lab](https://github.com/mitsurutech/lab-vector-lab).
