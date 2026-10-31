# Risk assessment: k8s-ops-agent

## EU AI Act classification (to be confirmed with legal)

- **Role:** deployer of a system built on a general-purpose AI model; the model provider carries the GPAI obligations.
- **Use:** operations tooling for an internal IT container platform. It does not manage or operate electricity, gas or heat supply, and it is not a safety component of such infrastructure.
- **Proposed tier:** not high-risk (no Annex III use case); transparency and AI-literacy duties apply to staff using it.
- **What would change this:** any use as a safety component in managing critical infrastructure, including operational technology at plants or grids, would make it a high-risk system, with risk management, logging, human-oversight, accuracy and documentation duties. Application dates for these obligations have been subject to change; check the current timeline.

## Risks and controls

| Risk | Control | Evidence |
| --- | --- | --- |
| Harmful change to the cluster | Human approval for every write tool call | Lab 5 scenario 2 |
| Cross-tenant action via prompt injection | Approval gate, plus RBAC scoped to granted namespaces | Lab 5 scenario 3: approved deliberately, Kubernetes returned 403 |
| Credential leakage into model context | No tool can read Secrets or ConfigMaps | RBAC in `platform/agents/rbac.yaml` |
| Runaway cost or loops | Step limit, gateway budget and rate limit | Lab 5 configuration |
| Unaccountable actions | Traces per session; approver recorded in production (Slack/Teams/ServiceNow) | Lab 6 traces |
