#!/usr/bin/env bash
# Host-side script to build and execute the Docker-based build and custom URL handler tests.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

echo "Building test Docker image..."
docker build -t thinkmay-client-test -f "${ROOT}/packaging/client/linux/Dockerfile.test" "${ROOT}"

echo "Running test container..."
docker run --rm thinkmay-client-test
