# Oracle Stream Analytics 26ai All-in-One Container

IMPORTANT: This image is meant for local development, demos, and sandboxing. It is not tuned for production. This repository is not maintained or supported by Oracle.

This repo builds a docker-compatible Oracle Linux 8 image that packages these components in one `linux/amd64` container:

- Oracle Stream Analytics 26ai from `V1054826-01.zip`
- Apache Kafka 4.1.x in single-node KRaft mode
- Apache Spark 4.0.1 with local master, worker, and history server
- MySQL 8.0 as the OSA metadata store



## What the image does

- Uses `oraclelinux:8` as the base image.
- Installs JDK 21, which OSA 26ai requires.
- Unpacks the local OSA distribution already present in this repo.
- Installs Kafka 4.1.x and Spark 4.0.1.
- Installs MySQL 8.0, initializes the OSA schema, and seeds the default OSA admin account.
- Starts MySQL, Kafka, Spark, and OSA in a single container entrypoint.
- Generates the OSA datasource password at runtime with `osa-secure-tool.sh`, following Oracle's secure-password flow instead of writing `PLAINTEXT:` into `osa-datasource.xml`.
- Generates a self-signed PKCS#12 certificate at startup and enables the documented HTTPS OSA entrypoint by default.
- Leaves the shipped OSA product tree under `/opt/osa` unmodified at image build time and writes mutable runtime config under `/tmp`.

## Files

- `Dockerfile`: the image definition
- `container/entrypoint.sh`: starts and wires together all services
- `V1054826-01.zip`: local OSA installer bundle used during build

## Build the image

This image has been validated on Apple Silicon with Rancher Desktop using the Docker-compatible CLI. Build it as `linux/amd64`:

```bash
docker buildx build --platform linux/amd64 -t ggsa-osa:26ai --load .
```

If Rancher Desktop does not place `docker` on your `PATH`, use its bundled CLI directly:

```bash
~/.rd/bin/docker buildx build --platform linux/amd64 -t ggsa-osa:26ai --load .
```

If you prefer a different tag:

```bash
docker buildx build --platform linux/amd64 -t my-ggsa-stack:latest --load .
```

## Run the container

On Apple Silicon with Rancher Desktop, amd64 startup is slow enough that OSA should be given a longer readiness window. The example below uses host port `19443` for the OSA HTTPS UI and a dedicated `28080-28083` Spark UI port block to avoid collisions with other local Spark services that often use `8080-8082`.

This example keeps everything ephemeral:

```bash
docker run -d \
  --name ggsa-osa \
  --platform linux/amd64 \
  -p 3306:3306 \
  -p 4040-4050:4040-4050 \
  -p 6066:6066 \
  -p 7077:7077 \
  -p 28080:28080 \
  -p 28081:28081 \
  -p 28082:28082 \
  -p 28083:28083 \
  -p 19443:9443 \
  -p 19080:9080 \
  -p 9092:9092 \
  -e MYSQL_ROOT_PASSWORD=oracle \
  -e MYSQL_DATABASE=osa \
  -e MYSQL_USER=osa \
  -e MYSQL_PASSWORD=welcome1 \
  -e OSA_ADMIN_USER=osaadmin \
  -e OSA_ADMIN_PASSWORD=welcome1 \
  -e OSA_PUBLIC_HOST=localhost \
  -e OSA_READY_TIMEOUT=600 \
  ggsa-osa:26ai
```

This example adds persistence:

```bash
docker run -d \
  --name ggsa-osa \
  --platform linux/amd64 \
  -p 3306:3306 \
  -p 4040-4050:4040-4050 \
  -p 6066:6066 \
  -p 7077:7077 \
  -p 28080:28080 \
  -p 28081:28081 \
  -p 28082:28082 \
  -p 28083:28083 \
  -p 19443:9443 \
  -p 19080:9080 \
  -p 9092:9092 \
  -v ggsa-mysql:/var/lib/mysql \
  -v ggsa-kafka:/var/lib/kafka/data \
  -v ggsa-spark-events:/var/lib/spark-events \
  -v ggsa-osa-files:/u01/app/osa/deployedpipelines \
  -e MYSQL_ROOT_PASSWORD=oracle \
  -e MYSQL_DATABASE=osa \
  -e MYSQL_USER=osa \
  -e MYSQL_PASSWORD=welcome1 \
  -e OSA_ADMIN_USER=osaadmin \
  -e OSA_ADMIN_PASSWORD=welcome1 \
  -e OSA_PUBLIC_HOST=localhost \
  -e OSA_READY_TIMEOUT=600 \
  ggsa-osa:26ai
```

If you prefer Podman, use the same flags with `podman` in place of `docker`.

## Default access points

- OSA UI: `https://localhost:19443/osa/index.html` when using the Rancher Desktop example above
- OSA HTTP fallback: `http://localhost:19080/osa/index.html` only if you explicitly set `OSA_ENABLE_SSL=false`
- OSA login: `osaadmin` / `welcome1` unless you override `OSA_ADMIN_PASSWORD`
- Kafka bootstrap server: `localhost:9092`
- Spark master endpoint: `spark://localhost:7077`
- Spark REST submission endpoint: `http://localhost:6066/v1/submissions/create`
- Spark master UI: `http://localhost:28080`
- Spark worker UIs: `http://localhost:28081` and `http://localhost:28082` for the default two-worker setup
- Spark application detail UI: `http://localhost:4040` for the first running app, then `4041`, `4042`, and so on if additional app UIs are opened
- Spark history server: `http://localhost:28083`
- MySQL: `localhost:3306`, database `osa`

## Environment variables

- `MYSQL_ROOT_PASSWORD`: required at runtime, defaults to `oracle`
- `MYSQL_DATABASE`: defaults to `osa`
- `MYSQL_USER`: defaults to `osa`
- `MYSQL_PASSWORD`: required at runtime, defaults to `welcome1`
- `OSA_ADMIN_USER`: defaults to `osaadmin`
- `OSA_ADMIN_PASSWORD`: required at runtime, defaults to `welcome1`
- `OSA_ENABLE_SSL`: defaults to `true`; set to `false` only if you intentionally want the non-documented HTTP fallback
- `OSA_SSL_CERT_PASSWORD`: defaults to the same value as `OSA_ADMIN_PASSWORD`
- `OSA_SSL_FAIL_ON_VALIDATIONS`: defaults to `false` so the generated self-signed demo certificate is accepted at startup
- `OSA_PUBLIC_HOST`: host name written into the OSA UI config, defaults to `localhost`
- `OSA_READY_TIMEOUT`: OSA boot wait in seconds, defaults to `600`
- `OSA_LOAD_SAMPLES`: set to `true` to let OSA load sample content on startup
- `KAFKA_ADVERTISED_LISTENERS`: defaults to `PLAINTEXT://localhost:9092`
- `SPARK_MASTER_REST_ENABLED`: defaults to `true`
- `SPARK_MASTER_REST_PORT`: defaults to `6066`
- `SPARK_MASTER_REST_HOST`: optional override for the Spark REST endpoint host advertised by the master
- `OSA_RUNTIME_DIR`: defaults to `/tmp` and stores generated OSA runtime config outside the shipped product tree
- `SPARK_MASTER_WEBUI_PORT`: defaults to `28080`
- `SPARK_PUBLIC_DNS`: defaults to the same host name as `OSA_PUBLIC_HOST` and is used in Spark master/worker links
- `SPARK_WORKER_WEBUI_PORT`: defaults to `28081`; additional workers increment from that base port
- `SPARK_WORKER_INSTANCES`: defaults to `2` and controls how many Spark workers are started automatically with the container
- `SPARK_WORKER_CORES`: defaults to `8` for each Spark worker started from this image configuration
- `SPARK_WORKER_MEMORY`: defaults to `2g` for each Spark worker started from this image configuration
- `SPARK_WORKER_OPTS`: defaults to Spark executor log rolling settings suitable for container logs
- `SPARK_HISTORY_PORT`: defaults to `28083`

## Notes on the implementation

- The image is intentionally single-container and single-node.
- Kafka runs in KRaft mode, not ZooKeeper mode.
- Spark runs one master, one history server, and the configured standalone workers inside the container.
- Publish worker UI ports if you want Spark master log links to be clickable from the host browser; for the default two-worker setup that means `28081` and `28082`.
- Publish the Spark application UI port range too if you want the direct “Application Detail UI” links from the Spark master to open from the host browser; the default range in this repo is `4040-4050`.
- OSA is wired to MySQL by generating `osa-datasource.xml` at startup.
- OSA runtime config is generated under `/tmp` and passed through Oracle's supported `--extFolder` startup path.
- The datasource password in `osa-datasource.xml` is generated at runtime with `/opt/osa/osa-base/bin/osa-secure-tool.sh`.
- OSA creates or reuses its AES key at `/opt/osa/osa-base/etc/osa_aes.key` for that encrypted datasource password.
- The container generates a self-signed PKCS#12 certificate at startup and writes its encrypted password into `${OSA_RUNTIME_DIR}/ssl.conf`.
- The built image does not edit OSA files under `/opt/osa`; any runtime API-server datasource sync is derived from `osa-datasource.xml` in `OSA_RUNTIME_DIR`.
- The generated self-signed certificate is allowed for local startup by setting `OSA_SERVER_CRT_FAIL_ON_VALIDATIONS=false`.
- The default browser entrypoint is the HTTPS UI under `/osa/index.html` on port `9443`.
- The OSA admin password is synchronized into the seeded MySQL schema on container startup.

## Logs and troubleshooting

Watch the container orchestrator logs:

```bash
docker logs -f ggsa-osa
```

Useful in-container logs:

- OSA app log: `/tmp/logs/osa-api-server.log`
- OSA launcher log: `/opt/osa/osa-base/logs/osa.log`
- OSA runtime overlay dir: `/tmp`
- OSA AES key used by `osa-secure-tool.sh`: `/opt/osa/osa-base/etc/osa_aes.key`
- OSA SSL config: `/tmp/ssl.conf`
- MySQL log: `/var/log/mysql/error.log`
- Spark logs: `/var/log/spark`
- Kafka logs: `/opt/kafka/logs`

Open a shell:

```bash
docker exec -it ggsa-osa bash
```

## Validation status

- Validated on Apple Silicon with Rancher Desktop using `docker buildx build --platform linux/amd64 --load`
- Validated runtime path: `docker run ... -p 19443:9443 -p 28080:28080 -p 28081:28081 -p 28082:28082 -p 28083:28083 -e OSA_PUBLIC_HOST=localhost -e OSA_READY_TIMEOUT=600 ggsa-osa:26ai`
- Confirmed browser entrypoint: `https://localhost:19443/osa/index.html`
