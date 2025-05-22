#!/bin/bash

# === Konfigurasi dasar ===
DOCKER_USERNAME="yatogamiitzy"     # Ganti dengan username Docker Hub kamu
IMAGE_NAME="test"
DOCKER_TAG="latest"
DOCKER_IMAGE="${DOCKER_USERNAME}/${IMAGE_NAME}:${DOCKER_TAG}"
WORKFLOW_DIR=".github/workflows"
WORKFLOW_FILE="${WORKFLOW_DIR}/test-docker-image.yml"

# === Step 1: Buat Dockerfile ===
echo "📦 Membuat Dockerfile..."

cat <<EOF > Dockerfile
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \\
    python3 \\
    python3-pip \\
    nodejs \\
    npm \\
    golang-go \\
    curl \\
    gnupg \\
    postgresql \\
    mongodb \\
    && apt-get clean

# Install mongosh
RUN curl -fsSL https://pgp.mongodb.com/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg \\
    && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list \\
    && apt-get update && apt-get install -y mongodb-mongosh

CMD ["bash"]
EOF

echo "✅ Dockerfile selesai dibuat."

# === Step 2: Build Docker Image ===
echo "🔧 Membuild image Docker..."
docker build -t "$DOCKER_IMAGE" .
echo "✅ Build selesai."

# === Step 3: Push ke Docker Hub ===
echo "🚀 Push image ke Docker Hub..."
docker push "$DOCKER_IMAGE"
echo "✅ Push selesai."

# === Step 4: Siapkan direktori workflow ===
echo "📁 Menyiapkan direktori workflow GitHub..."
mkdir -p "$WORKFLOW_DIR"

# Hapus file/folder jika sebelumnya salah dibuat sebagai direktori
if [ -d "$WORKFLOW_FILE" ]; then
    echo "🧹 Menghapus direktori yang salah: $WORKFLOW_FILE"
    rm -rf "$WORKFLOW_FILE"
fi

# === Step 5: Buat file workflow GitHub Actions ===
echo "⚙️  Membuat file workflow GitHub Actions..."

cat <<EOF > "$WORKFLOW_FILE"
name: Run Custom Docker Image

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  run-custom-image:
    runs-on: ubuntu-latest

    steps:
      - name: Pull Docker image
        run: docker pull $DOCKER_IMAGE

      - name: Run docker container and check tools
        run: |
          docker run --rm $DOCKER_IMAGE bash -c "\
            echo 'Python:' && python3 --version && \
            echo 'Node:' && node --version && \
            echo 'Golang:' && go version && \
            echo 'MongoSH:' && mongosh --version && \
            echo 'PostgreSQL:' && psql --version \
          "
EOF

echo "✅ Workflow GitHub selesai dibuat di: $WORKFLOW_FILE"
