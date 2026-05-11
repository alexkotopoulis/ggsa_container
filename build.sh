export ARGS=--preserve-env=HTTP_PROXY,HTTPS_PROXY,NO_PROXY,http_proxy,https_proxy,no_proxy # Arge for SUDO to pass on proxy settings
docker build --format docker --http-proxy=true -t ggsa-osa:26ai .

docker volume create ggsa-mysql
docker volume create ggsa-kafka
docker volume create ggsa-spark-events
docker volume create ggsa-osa-files
