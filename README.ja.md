# Trivyで学ぶ脆弱性管理のラボ：CVE、CVSS、EPSS、KEV、イメージスキャン、SBOMをオフラインで

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-vuln-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-vuln-lab/actions/workflows/check.yml)

[MitsuruTechラーニングプラットフォーム](https://mitsurutech.co.uk/ja/learning)の、授業ですぐ使えるラボです。このプラットフォームでは、学校や大学が学生一人ひとりに自分のコンテナとターミナルをブラウザで用意できます。このラボでは、オープンソースのスキャナーTrivyを使って脆弱性管理を学びます。学生は、コンテナイメージとプロジェクトのロックファイルをスキャンし、CVE識別子とCVSSベクトルを読み、EPSSとCISAのKnown Exploited Vulnerabilities（KEV）カタログで発見事項に優先順位をつけ、SBOMを作って検索し、VEXステートメントを記録し、パッチの期限を決め、リスクを報告します。**インターネットがまったくなくても動きます。** Trivyの脆弱性データベースと、EPSSとKEVのスナップショットがイメージの中に入っているので、どのコピーでも同じ答えが出ます。[脆弱性管理](https://mitsurutech.co.uk/ja/resources/university/vulnerability-management)モジュールのためのラボです。

`docker-compose`ファイル1つ、`compose.yaml`だけでできていて、自分のマシンでもプラットフォームでも同じように動きます。プラットフォームでは、学生一人ひとりが、インターネットに出られない自分専用のコピーを使います。

## 中身

3つのサービスがあります。

- `scanner`は、必要なものをすべてイメージの中に持つTrivy 0.76.2です（`image/`からビルドします）。
  - **2026年11月21日**（07:02 UTC）に公開されたTrivyの脆弱性データベース。OCIアーティファクトのダイジェストで固定しているので、更新されることはありません。
  - アーカイブとして保存したnginxのイメージ2つ。`/targets/web-1.25.3.tar`（サポートの終わったAlpine 3.18.6）と`/targets/web-1.31.9.tar`（Alpine 3.24.4）で、linux/amd64のマニフェストのダイジェストで取得しています。
  - 2つのプロジェクト。`/targets/shop/requirements.txt`（2022年に固定したFlaskのアプリ）と`/targets/reports/gradle.lockfile`（Log4j 2.14.1を使うJavaのサービス）です。
  - `/work/snapshot`にある凍結したスナップショット。**2026年11月20日のEPSSスコア**（モデルv2026.06.15、410,485件のCVE）と**CISAのKEVカタログ、バージョン2026.11.20**（1,790件）で、`image/snapshot/SHA256SUMS`と照合しています。
- `web`は学校のWebサーバーで、Alpine 3.18上のnginx 1.25.3です。1つめのアーカイブと同じイメージです。わざと古くしてあり、ラボからしか届きません。
- `tools`はスキャナーと`/work`を共有するPython 3.12で、TrivyのJSONレポートをスナップショットと並べて読むためのものです。

凍結したスナップショットで見つかるもの：古いイメージで74件（重大3件、CVE 44件、KEVに載っているものはなし）、新しいイメージで12件、ショップで49件、Javaのサービスで23件で、そのうち2件がKEVに載っています（Log4ShellことCVE-2021-44228と、CVE-2021-45046）。**今日本物のスキャンをすれば、もっと多く見つかります。** 新しい脆弱性は毎日公開されるからです。凍結したスナップショットの目的は、クラス全員が同じものを見られることです。

## プラットフォームでの使い方

プラットフォームは、すべての学生にラボの専用コピーをブラウザで提供し、横にターミナルを用意します。

**試すには：**[コンテナのページ](https://mitsurutech.co.uk/ja/container)を開き、**Sample labs**でこのラボを探してStartを押します。無料アカウントが必要です。

**クラスの課題にするには：**

1. モジュールで種類が**Lab**のタスクを作り、**In a GitHub repository**を選びます。
2. `https://github.com/mitsurutech/lab-vuln-lab`とブランチ`main`を指定します。composeファイルは既定の`compose.yaml`です。変更したい場合は、先にリポジトリをフォークしてください。
3. 公開します。学生のコピーは公開したコミットから始まるので、あとでここが変わっても、すでに出したラボは変わりません。

ヘルプマニュアルの[このラボのページ](https://mitsurutech.co.uk/ja/help/lab-vuln-lab)と[コンテナラボのガイド](https://mitsurutech.co.uk/ja/help/labs)に、ほかのことが書いてあります。対応する基本レッスンは**Vulnerability Scanning Basics**です。まだ学校のアカウントがありませんか。生徒50人までなら[最初の1年は無料](https://mitsurutech.co.uk/ja/pricing)で、[登録](https://mitsurutech.co.uk/ja/signup)に必要なのはメールアドレスだけです。

## 自分のマシンで動かす

Composeプラグインつきのdockerが必要です。

```bash
docker compose -f compose.yaml -f local.yaml up -d
docker compose exec scanner trivy image --input /targets/web-1.25.3.tar --severity CRITICAL
docker compose exec scanner trivy fs /targets/reports
```

`local.yaml`は古いnginxを`127.0.0.1:8080`にだけ公開するので、そのままにしておいてください。すべて削除するには`docker compose -f compose.yaml -f local.yaml down -v`を実行します。

## ラボでできないこと

ラボはインターネットに出られないので、Trivyはデータベースを更新せず、レジストリからイメージを取得することもできません。スキャンするのは、自分が持っているアーカイブとフォルダーです。何もエクスプロイトしません。古いnginxは読むためにあり、攻撃するためのものではありません。スキャンしてよいのは、自分が所有しているものか、書面でテストの許可を得たものだけです。

## ラボの確認

`test/check.sh`は、プラットフォームのランナーがすべてのサービスを起動するのと同じやり方（ケーパビリティをすべて外し、`no-new-privileges`、プロセス数の上限、メモリの上限、インターネットへの経路なし）でラボを起動し、レッスンに出てくる合計とスナップショットの数値をすべて確かめます。pushのたびに（それが上のバッジです）、GitHubが`image/`からスキャナーをビルドして実行します。

```bash
test/check.sh                                   # the pinned scanner image
docker build -t scanner image && SCANNER_IMAGE=scanner test/check.sh   # one built from image/
```

固定したイメージ`ghcr.io/mitsurutech/lab-images:5ec118000001-vuln-lab-scanner-77d86af1e968`は、コミット`77d86af`の`image/`から、公開の[lab-builder](https://github.com/mitsurutech/lab-builder)ワークフローがGitHub自身のマシンでamd64とarm64向けにビルドしたものです。

## データの出どころ

- TrivyはAqua SecurityのApache-2.0のソフトウェアで、公式イメージ`aquasec/trivy:0.76.2`から変更せずに動かしています。
- Trivyのデータベースは、Aqua Securityが公開アドバイザリー（NVD、Linuxディストリビューション、GitHubのアドバイザリーデータベースなど）から作っており、それぞれに独自の条件があります。
- EPSSはFIRST（Forum of Incident Response and Security Teams）が公開しています。[first.org/epss](https://www.first.org/epss/)を参照してください。ファイルは変更せずにコピーしています。
- KEVカタログは米国のCybersecurity and Infrastructure Security Agency（CISA）が公開しています。[cisa.gov/known-exploited-vulnerabilities-catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)を参照してください。ファイルは変更せずにコピーしています。
- nginxはBSD-2-Clauseで、Alpineのパッケージはそれぞれのライセンスに従います。イメージは、スキャナーのイメージをビルドするときにDocker Hubから取得します。

`requirements.txt`と`gradle.lockfile`で固定しているバージョンは、スキャンするためにわざと古くしてあります。絶対にインストールしないでください。

## ライセンス

ラボそのもの（composeファイル、スクリプト、このREADME）は[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.ja)でライセンスされています。Mitsuru Technologies Ltdのクレジットを表示し、営利目的で使わず、作ったものを同じライセンスで共有するなら、学習と教育のために共有したり改変したりできます。全文は`LICENSE`ファイルにあります。上に挙げた第三者のソフトウェアとデータは、それぞれのライセンスに従います。

## このラボについて

[Mitsuru Technologies](https://mitsurutech.co.uk/ja)が[MitsuruTechラーニングプラットフォーム](https://mitsurutech.co.uk/ja/learning)のために作りました。学校向けに、Python、Java、Go、Node、SQL、Linuxをブラウザで使え、コンテナラボ、GitHubからデプロイするWebアプリ、自動採点のクイズがあります。アカウントなしでも[プレイグラウンド](https://mitsurutech.co.uk/ja/playground)でコードを試せます。

同じところのほかのラボ：[lab-harden-nginx](https://github.com/mitsurutech/lab-harden-nginx)、[lab-docker-basics](https://github.com/mitsurutech/lab-docker-basics)、[lab-nodegoat-lab](https://github.com/mitsurutech/lab-nodegoat-lab)、[lab-vector-lab](https://github.com/mitsurutech/lab-vector-lab)。
