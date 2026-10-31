#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
cd -- "${SCRIPT_DIR}"

: "${REGISTRY:=127.0.0.1:5000}"
: "${MCP_IMAGE:=mcp-run}"
: "${MCP_HARDENED_IMAGE:=mcp-run-hardened}"
: "${MCP_IMAGE_TAG:=latest}"
: "${INSECURE:=true}"

: "${MCP_IMAGE_URI:=${REGISTRY}/${MCP_IMAGE}:${MCP_IMAGE_TAG}}"
: "${MCP_HARDENED_IMAGE_URI:=${REGISTRY}/${MCP_HARDENED_IMAGE}:${MCP_IMAGE_TAG}}"

run_or_warn() {
  if ! "$@"; then
    printf 'Warning: command failed: %s\n' "$*" >&2
  fi
}

run_or_warn kubectl delete --filename manifests/kyverno-policy.yaml --ignore-not-found
run_or_warn kubectl delete --filename manifests/deploy.yaml --ignore-not-found
run_or_warn kubectl delete --filename manifests/garak.yaml --ignore-not-found
run_or_warn kubectl delete --filename manifests/build.yaml --ignore-not-found
run_or_warn kubectl delete --filename manifests/build-hardened.yaml --ignore-not-found

run_or_warn kubectl delete configmap --namespace apps buildkit-context buildkit-context-hardened --ignore-not-found
run_or_warn kubectl delete secret --namespace apps dhi-registry-auth --ignore-not-found

if type cosign >/dev/null 2>&1; then
  run_or_warn cosign clean --force --allow-insecure-registry="${INSECURE}" "${MCP_IMAGE_URI}"
  run_or_warn cosign clean --force --allow-insecure-registry="${INSECURE}" "${MCP_HARDENED_IMAGE_URI}"
fi

if type oras >/dev/null 2>&1; then
  run_or_warn oras manifest delete --force "${MCP_IMAGE_URI}"
  run_or_warn oras manifest delete --force "${MCP_HARDENED_IMAGE_URI}"
fi

rm --recursive --force input output
rm --force sbom.spdx.json vuln-scan.json garak-evaluation.json model_card.md

printf 'Lab 5 reset complete.\n'
