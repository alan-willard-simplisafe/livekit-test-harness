#!/bin/bash
set -e

echo "Waiting for Toxiproxy to be ready..."
until curl -f http://toxiproxy:8474/version; do
  echo "Toxiproxy not ready yet, waiting..."
  sleep 2
done

echo "Creating Redis proxy..."
curl -X POST http://toxiproxy:8474/proxies \
  -H "Content-Type: application/json" \
  -d '{"name":"redis","listen":"0.0.0.0:26379","upstream":"redis:6379"}'

# echo "Adding bandwidth limit (1MB/s)..."
# curl -X POST http://toxiproxy:8474/proxies/redis/toxics \
#   -H "Content-Type: application/json" \
#   -d '{"type":"bandwidth","attributes":{"rate":1000}}'

echo "Adding latency (100ms)..."
curl -X POST http://toxiproxy:8474/proxies/redis/toxics \
  -H "Content-Type: application/json" \
  -d '{"type":"latency","attributes":{"latency":100}}'

echo "Toxiproxy configuration complete!"
