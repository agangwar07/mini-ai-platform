# AI governance

Every AI component on the platform has a folder here, reviewed like code.

| Artifact | Purpose |
| --- | --- |
| `model-card.md` | What the component is for, where its data comes from, known limits, owner |
| `risk-assessment.md` | EU AI Act classification with reasoning, risks and controls |
| Eval gate (`platform/evals/`) | Golden set and threshold a model change must pass before it receives traffic |

## Change process

1. Propose the change by pull request (model, prompt, routing or tools).
2. The eval gate runs on sync; below threshold, the change is blocked automatically.
3. Canary at 10% behind the alias; compare latency, errors and cost on the LLM Platform dashboard.
4. Promote by pull request; the gate re-runs against the promoted alias.
5. New self-hosted models need `ai.governance/approved="true"`, applied only after this folder's review.
