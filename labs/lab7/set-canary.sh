#!/usr/bin/env bash
# Usage: labs/lab7/set-canary.sh <candidate-alias|none> <stable-weight> <canary-weight>
# Sets the grid-assistant canary deployment and tells the eval gate which candidate to test.
set -euo pipefail
export CAND="$1" STABLE_W="$2" CANARY_W="$3"
F=apps/litellm.yaml
V='.spec.source.helm.valuesObject'

# Remove any existing canary deployment.
yq -i "del($V.proxy_config.model_list[] | select(.model_info.id == \"grid-assistant-canary\"))" "$F"

# Add the canary: same alias, the candidate's backend settings, its own id and weight.
if [ "$CAND" != "none" ]; then
  yq -i "$V.proxy_config.model_list += [{\"model_name\": \"grid-assistant\",
    \"litellm_params\": ($V.proxy_config.model_list[] | select(.model_name == env(CAND)) | .litellm_params),
    \"model_info\": {\"id\": \"grid-assistant-canary\"}}]" "$F"
  yq -i "($V.proxy_config.model_list[] | select(.model_info.id == \"grid-assistant-canary\") | .litellm_params.weight) = env(CANARY_W)" "$F"
fi

# Stable weight, and the candidate the eval gate must test before this change is applied.
yq -i "($V.proxy_config.model_list[] | select(.model_info.id == \"grid-assistant-stable\") | .litellm_params.weight) = env(STABLE_W)" "$F"
yq -i "($V.extraResources[] | select(.metadata.name == \"gateway-eval-gate\") | .spec.template.spec.containers[0].env[] | select(.name == \"CANDIDATE_MODEL\") | .value) = env(CAND)" "$F"

echo "grid-assistant deployments:"
yq "$V.proxy_config.model_list[] | select(.model_name == \"grid-assistant\") | \"  \" + .model_info.id + \"  \" + .litellm_params.model + \"  weight=\" + (.litellm_params.weight | tostring)" "$F"
echo "eval gate candidate: $(yq "$V.extraResources[0].spec.template.spec.containers[0].env[0].value" "$F")"
