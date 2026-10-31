#!/bin/sh
set -eu

KUBECTL_VERSION="${KUBECTL_VERSION:-v1.33.10}"
ORAS_VERSION="${ORAS_VERSION:-1.3.0}"
TRIVY_VERSION="${TRIVY_VERSION:-0.70.0}"
COSIGN_VERSION="${COSIGN_VERSION:-3.0.6}"
VEXCTL_VERSION="${VEXCTL_VERSION:-0.4.1}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Python deps versions
LANGGRAPH_VERSION=${LANGGRAPH_VERSION:-1.1.10}
OPENAI_VERSION=${OPENAI_VERSION:-1.109.1}
LANGCHAINOPENAI_VERSION=${LANGCHAINOPENAI_VERSION:-0.3.33}
LANGCHAINCOMMUNITY_VERSION=${LANGCHAINCOMMUNITY_VERSION:-0.4.2}
LLMGUARD_VERSION=${LLMGUARD_VERSION:-0.3.16}
NEMOGUARDRAILS_VERSION=${NEMOGUARDRAILS_VERSION:-0.21.0}
DATACLASSESJSON_VERSION=${DATACLASSESJSON_VERSION:-0.6.7}
IPYWIDGETS_VERSION=${IPYWIDGETS_VERSION:-8.1.8}

UNAME_S="$(uname -s)"
UNAME_M="$(uname -m)"

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

case "$UNAME_S" in
  Linux)
    OS="linux"
    TRIVY_OS="Linux"
    ;;
  Darwin)
    OS="darwin"
    TRIVY_OS="macOS"
    ;;
  *)
    echo "unsupported OS: $UNAME_S" >&2
    exit 1
    ;;
esac

case "$UNAME_M" in
  x86_64|amd64)
    ARCH="amd64"
    TRIVY_ARCH="64bit"
    ;;
  aarch64|arm64)
    ARCH="arm64"
    TRIVY_ARCH="ARM64"
    ;;
  *)
    echo "unsupported architecture: $UNAME_M" >&2
    exit 1
    ;;
esac

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  run_as_root apt-get update
  run_as_root apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    tar \
    build-essential \
    g++
fi

need_cmd curl
need_cmd tar

run_as_root mkdir -p "$INSTALL_DIR"

download() {
  url="$1"
  out="$2"

  echo "downloading: $url"
  curl -fsSL "$url" -o "$out"
}

install_file() {
  src="$1"
  dst="$2"

  run_as_root install -m 0755 "$src" "$dst"
}

install_kubectl() {
  url="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${OS}/${ARCH}/kubectl"
  out="$TMPDIR/kubectl"

  download "$url" "$out"
  install_file "$out" "$INSTALL_DIR/kubectl"

  echo "installed kubectl ${KUBECTL_VERSION} to ${INSTALL_DIR}/kubectl"
  kubectl version --client=true
}

install_oras() {
  asset="oras_${ORAS_VERSION}_${OS}_${ARCH}.tar.gz"
  url="https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/${asset}"

  download "$url" "$TMPDIR/$asset"
  tar -xzf "$TMPDIR/$asset" -C "$TMPDIR" oras
  install_file "$TMPDIR/oras" "$INSTALL_DIR/oras"

  echo "installed oras v${ORAS_VERSION} to ${INSTALL_DIR}/oras"
  oras version
}

install_trivy() {
  asset="trivy_${TRIVY_VERSION}_${TRIVY_OS}-${TRIVY_ARCH}.tar.gz"
  url="https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/${asset}"

  download "$url" "$TMPDIR/$asset"
  tar -xzf "$TMPDIR/$asset" -C "$TMPDIR" trivy
  install_file "$TMPDIR/trivy" "$INSTALL_DIR/trivy"

  echo "installed trivy v${TRIVY_VERSION} to ${INSTALL_DIR}/trivy"
  trivy --version
}

install_cosign() {
  asset="cosign-${OS}-${ARCH}"
  url="https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/${asset}"

  download "$url" "$TMPDIR/cosign"
  install_file "$TMPDIR/cosign" "$INSTALL_DIR/cosign"

  echo "installed cosign v${COSIGN_VERSION} to ${INSTALL_DIR}/cosign"
  cosign version
}

install_vexctl() {
  asset="vexctl-${OS}-${ARCH}"
  url="https://github.com/openvex/vexctl/releases/download/v${VEXCTL_VERSION}/${asset}"

  download "$url" "$TMPDIR/vexctl"
  install_file "$TMPDIR/vexctl" "$INSTALL_DIR/vexctl"

  echo "installed vexctl v${VEXCTL_VERSION} to ${INSTALL_DIR}/vexctl"
  vexctl version
}

install_python_deps() {
  pip install \
    "langgraph~=${LANGGRAPH_VERSION}" \
    "openai~=${OPENAI_VERSION}" \
    "langchain-openai~=${LANGCHAINOPENAI_VERSION}" \
    "langchain-community~=${LANGCHAINCOMMUNITY_VERSION}" \
    "llm-guard~=${LLMGUARD_VERSION}" \
    "nemoguardrails~=${NEMOGUARDRAILS_VERSION}" \
    "dataclasses-json~=${DATACLASSESJSON_VERSION}" \
    "ipywidgets~=${IPYWIDGETS_VERSION}"
}

download_nlp_models() {
  python -m spacy download en_core_web_sm
  python -m spacy download zh_core_web_sm
}

install_kubectl
install_oras
install_trivy
install_cosign
install_vexctl
install_python_deps
# This requires a lot of resources and makes the pod go slow
# Better to implement it elsewhere
# download_nlp_models
