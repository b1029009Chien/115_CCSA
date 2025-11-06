#!/usr/bin/env bash
set -euo pipefail

# build-images.sh
# Build and push Docker images for the application

usage() {
  cat <<EOF
Usage: $0 [--push]

--push    Push images to Docker Hub after building (requires login)

Build backend and frontend Docker images.
EOF
}

PUSH=0
if [[ ${1:-} == "--push" ]]; then
  PUSH=1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/content/backend"
FRONTEND_DIR="$ROOT_DIR/content/frontend"

# Docker Hub username (change this to your username)
DOCKER_USERNAME="${DOCKER_USERNAME:-chien314832001}"

echo "Building images..."
echo "Docker Hub username: $DOCKER_USERNAME"
echo ""

# Build backend
echo "Building backend image..."
cd "$BACKEND_DIR"
docker build -t "${DOCKER_USERNAME}/hw5_api:latest" .
echo "✓ Backend image built: ${DOCKER_USERNAME}/hw5_api:latest"

# Build frontend
echo ""
echo "Building frontend image..."
cd "$FRONTEND_DIR"
docker build -t "${DOCKER_USERNAME}/hw5_web:latest" .
echo "✓ Frontend image built: ${DOCKER_USERNAME}/hw5_web:latest"

if [[ $PUSH -eq 1 ]]; then
  echo ""
  echo "Pushing images to Docker Hub..."
  
  # Check if logged in
  if ! docker info | grep -q "Username"; then
    echo "Not logged in to Docker Hub. Please run: docker login"
    exit 1
  fi
  
  # Push backend
  echo "Pushing backend image..."
  docker push "${DOCKER_USERNAME}/hw5_api:latest"
  echo "✓ Backend image pushed"
  
  # Push frontend
  echo "Pushing frontend image..."
  docker push "${DOCKER_USERNAME}/hw5_web:latest"
  echo "✓ Frontend image pushed"
  
  echo ""
  echo "All images pushed successfully!"
else
  echo ""
  echo "Images built successfully!"
  echo "To push images to Docker Hub, run: $0 --push"
fi

echo ""
echo "Images:"
echo "  - ${DOCKER_USERNAME}/hw5_api:latest"
echo "  - ${DOCKER_USERNAME}/hw5_web:latest"
