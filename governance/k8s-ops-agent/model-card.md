# Model card: k8s-ops-agent

| Field | Value |
| --- | --- |
| Owner | Platform team |
| Purpose | Diagnose Kubernetes workload problems and propose rollout restarts |
| Tools | MCP server `mcp-k8s-ops`: list_pods, get_events, get_logs (read-only); rollout_restart (write) |
| Permissions | Read pods, logs and events cluster-wide; restart Deployments only where a tenant granted it (team-grid). No access to Secrets or ConfigMaps |
| Human oversight | Every write tool call pauses for human approval; rejection is fed back to the model |
| Limits | Step limit 12 per turn; gateway budget $0.50 and 20 requests/minute for its key |
| Known risks | Wrong diagnosis; indirect prompt injection through logs (tested: blocked by approval and RBAC) |
| Monitoring | Full traces per session (OpenTelemetry and Langfuse); gateway spend per agent key |
