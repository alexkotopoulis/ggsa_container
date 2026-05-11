export HOST=phoenix254903.dev3sub3phx.databasede3phx.oraclevcn.com 
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
  -p 9443:9443 \
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
  -e OSA_PUBLIC_HOST=$HOST \
  -e OSA_READY_TIMEOUT=600 \
  ggsa-osa:26ai
