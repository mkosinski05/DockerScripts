#!/bin/bash

export CONTAINER_NAME="rzv2h_ai_sdk_container_slam_2.12.3"
export IMAGE_NAME="rzv2h_ai_sdk_image:slam_2.12.3"
export YOCTO_WORK=$1

echo "Yocto Work directory: $YOCTO_WORK"

# 1. Clean up existing container if it exists
if docker inspect --type container "$CONTAINER_NAME" > /dev/null 2>&1; then
    echo "Container '$CONTAINER_NAME' exists. Removing old instance..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
fi

# 2. Check if image exists, build if it doesn't
if ! docker inspect --type image "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "Image '$IMAGE_NAME' does not exist locally. Building..."
    docker build -t "$IMAGE_NAME" --build-arg SDK="/opt/poky/3.1.31" --build-arg PRODUCT="V2H" .
fi

echo "=== Starting container in the background ==="
# -d runs it in the background (detached)
# 'tail -f /dev/null' keeps the container alive indefinitely so docker exec has an active environment
docker run -d --name "$CONTAINER_NAME" \
  -v "${YOCTO_WORK}:/drp-ai_tvm/yocto" \
  "$IMAGE_NAME" tail -f /dev/null

echo "=== Running first set of commands inside the container ==="
docker exec -it "$CONTAINER_NAME" bash -c "
    echo '--- Inside the container ---'
    pwd
    python3 --version
"

echo "=== Running a task on the HOST ==="
echo "Doing host-side work here..."
# e.g., compilation check, copying files, etc.

echo "=== Running second set of commands inside the container ==="
docker exec -it "$CONTAINER_NAME" bash -c "
    echo '--- Back inside the container ---'
    ls -la /drp-ai_tvm/yocto
"

echo "=== Cleaning up: Stopping and removing the background container ==="
docker rm -f "$CONTAINER_NAME"

echo "Host script finished successfully!"