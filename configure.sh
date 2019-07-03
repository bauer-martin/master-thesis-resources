#!/usr/bin/env bash

DOCKER_IMAGE_NAME=${1:-splconqueror}
DATA_DIR=${2:-data}
RUN_SCRIPT=run-splconqueror.sh

output() {
  printf '\e[34m%s\e[m\n' "$*"
}

die() {
  printf '\e[31m%s\e[m\n' "$*"
  exit 1
}

output "Looking for docker..."
if [ -x "$(command -v docker)" ]; then
  echo "==> Found docker executable."
else
  die "==> Error: docker is not installed."
fi

output "Building docker image for SPL Conqueror..."
docker build -t ${DOCKER_IMAGE_NAME} .
[ $? -eq 0 ] || die "Error: failed to build image."

output "Setting up environment..."
if [ ! -d ${DATA_DIR} ]; then
  mkdir ${DATA_DIR}
fi
cat > ${RUN_SCRIPT} << EOF
#!/usr/bin/env bash

docker run -v $(pwd)/${DATA_DIR}:/home/${DATA_DIR} ${DOCKER_IMAGE_NAME} \$1
EOF
chmod +x ${RUN_SCRIPT}

echo "==> Use './${DATA_DIR}' for file exchange with the docker container."
echo "==> You can run SPL Conqueror via './${RUN_SCRIPT} ${DATA_DIR}/<your_script>'."
