# Model card: grid-assistant

| Field | Value |
| --- | --- |
| Owner | Platform team (on behalf of team-grid) |
| Purpose | General assistant for grid-operations staff: explanations, summaries, unit conversions, structured output for internal tools |
| Not for | Real-time control, protection or safety decisions; anything that acts on operational technology |
| Backend | Gemini Flash-Lite via the gateway alias `grid-assistant` (stable/canary deployments) |
| Data | Prompts from internal staff; no customer personal data by policy. Free-tier provider terms allow training on inputs, so production must use a paid tier or cloud endpoint with data-processing terms |
| Evaluation | `platform/evals/golden.jsonl`: domain facts, maths, JSON output, safety refusals, prompt injection, translation. Threshold 90% |
| Known limits | Can be wrong on specialised engineering facts; answers are advisory and must be checked by a qualified person |
| Monitoring | Latency SLO (95% of calls under 5 s), errors and cost per team on the LLM Platform dashboard; traces in Grafana Cloud and Langfuse |
| Change control | Eval-gated canary via `labs/lab7/set-canary.sh`, promotion by pull request |
