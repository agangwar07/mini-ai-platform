"""MCP server exposing a small, audited set of Kubernetes operations as tools.

Permissions are NOT enforced here. They come from the pod's service account
and Kubernetes RBAC, so a confused or manipulated model can't exceed them.
"""
import json
from datetime import datetime, timezone

from kubernetes import client, config
from kubernetes.client.exceptions import ApiException
from mcp.server.fastmcp import FastMCP

config.load_incluster_config()          # authenticate as this pod's service account
core = client.CoreV1Api()
apps = client.AppsV1Api()

mcp = FastMCP("k8s-ops", host="0.0.0.0", port=8000, stateless_http=True, json_response=True)


def _denied(e: ApiException) -> str:
    return f"DENIED by Kubernetes ({e.status} {e.reason}). The server's service account is not allowed to do this."


@mcp.tool()
def list_pods(namespace: str) -> str:
    """List pods in a namespace with phase, readiness, restart count, waiting reason and owning workload."""
    try:
        pods = core.list_namespaced_pod(namespace).items
    except ApiException as e:
        return _denied(e)
    out = []
    for p in pods:
        statuses = p.status.container_statuses or []
        waiting = next((s.state.waiting.reason for s in statuses if s.state and s.state.waiting), None)
        out.append({
            "name": p.metadata.name,
            "phase": p.status.phase,
            "ready": bool(statuses) and all(s.ready for s in statuses),
            "restarts": sum(s.restart_count for s in statuses),
            "waiting_reason": waiting,
            "owner": p.metadata.owner_references[0].name if p.metadata.owner_references else None,
        })
    return json.dumps(out, indent=1)


@mcp.tool()
def get_events(namespace: str, limit: int = 20) -> str:
    """Most recent events in a namespace, newest first. Warnings usually explain failures."""
    try:
        events = core.list_namespaced_event(namespace).items
    except ApiException as e:
        return _denied(e)
    events.sort(key=lambda e: e.last_timestamp or e.event_time or e.metadata.creation_timestamp, reverse=True)
    return json.dumps([{
        "type": e.type,
        "reason": e.reason,
        "object": f"{e.involved_object.kind}/{e.involved_object.name}",
        "message": e.message,
        "count": e.count,
    } for e in events[:min(limit, 50)]], indent=1)


@mcp.tool()
def get_logs(namespace: str, pod: str, tail_lines: int = 50, previous: bool = False) -> str:
    """Last lines of a pod's logs. Use previous=True to read the last crashed run of a restarting container."""
    try:
        return core.read_namespaced_pod_log(pod, namespace, tail_lines=min(tail_lines, 200), previous=previous) or "(no log output)"
    except ApiException as e:
        return _denied(e) if e.status in (401, 403) else f"Could not read logs ({e.status} {e.reason})"


@mcp.tool()
def rollout_restart(namespace: str, deployment: str) -> str:
    """Rolling-restart a Deployment. This CHANGES the cluster; the agent must get human approval first."""
    patch = {"spec": {"template": {"metadata": {"annotations": {
        "kubectl.kubernetes.io/restartedAt": datetime.now(timezone.utc).isoformat()}}}}}
    try:
        apps.patch_namespaced_deployment(deployment, namespace, patch)
    except ApiException as e:
        return _denied(e)
    return f"Restarted deployment {namespace}/{deployment}"


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
