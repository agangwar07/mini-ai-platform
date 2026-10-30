#!/usr/bin/env bash
# Sends three streaming chat requests through the gateway and prints each HTTP status.
for m in local-small local-small gemini-small; do
  code=$(curl -s -N -o /dev/null -w "%{http_code}" localhost:4000/v1/chat/completions \
    -H "Authorization: Bearer $GRID_KEY" -H 'Content-Type: application/json' \
    -d "{\"model\":\"$m\",\"stream\":true,\"stream_options\":{\"include_usage\":true},\"max_tokens\":40,\"messages\":[{\"role\":\"user\",\"content\":\"Name one benefit of wind power.\"}]}")
  echo "$m -> HTTP $code"
done
