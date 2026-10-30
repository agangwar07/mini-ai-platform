# Usage: source labs/lab6/agent-env.sh
# Starts the port-forwards the agent needs, issues a fresh agent key, exports env vars, and checks each link.

pf() {  # pf <namespace> <service> <port>
  pkill -f "port-forward svc/$2 " 2>/dev/null
  kubectl -n "$1" port-forward "svc/$2" "$3:$3" > /dev/null 2>&1 &
}
pf gateway litellm 4000
pf agents mcp-k8s-ops 8000
pf observability otel-collector 4318
sleep 4

export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
export MCP_URL=http://localhost:8000/mcp
export GATEWAY_URL=http://localhost:4000/v1

MK=$(kubectl -n gateway get secret litellm-masterkey -o jsonpath='{.data.masterkey}' | base64 -d)
OPS_TEAM=$(curl -s localhost:4000/team/list -H "Authorization: Bearer $MK" | jq -r '.[] | select(.team_alias=="platform-ops-agents") | .team_id' | head -1)
RESP=$(curl -s localhost:4000/key/generate -H "Authorization: Bearer $MK" -H 'Content-Type: application/json' \
  -d "{\"team_id\":\"$OPS_TEAM\",\"key_alias\":\"k8s-ops-agent-$(date +%s)\"}")
export AGENT_KEY=$(echo "$RESP" | jq -r '.key // empty')

export LANGFUSE_PUBLIC_KEY=$(kubectl -n gateway get secret litellm-env -o jsonpath='{.data.LANGFUSE_PUBLIC_KEY}' | base64 -d)
export LANGFUSE_SECRET_KEY=$(kubectl -n gateway get secret litellm-env -o jsonpath='{.data.LANGFUSE_SECRET_KEY}' | base64 -d)
export LANGFUSE_HOST=$(kubectl -n gateway get secret litellm-env -o jsonpath='{.data.LANGFUSE_HOST}' | base64 -d)

echo "gateway   : HTTP $(curl -s -o /dev/null -w '%{http_code}' localhost:4000/health/liveliness)   (want 200)"
echo "collector : HTTP $(curl -s -o /dev/null -w '%{http_code}' -X POST localhost:4318/v1/traces -H 'Content-Type: application/json' -d '{"resourceSpans":[]}')   (want 200)"
echo "mcp       : HTTP $(curl -s -o /dev/null -w '%{http_code}' localhost:8000/mcp)   (any code except 000)"
echo "ops team  : ${OPS_TEAM:-MISSING}"
if [ -n "$AGENT_KEY" ]; then echo "agent key : ${AGENT_KEY:0:8}..."; else echo "agent key : FAILED -> $RESP"; fi
