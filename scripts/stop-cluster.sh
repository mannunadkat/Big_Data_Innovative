#!/bin/bash
set -e
cd "$(dirname "$0")/../config"
docker-compose down
echo "Cluster stopped (volumes preserved)."
