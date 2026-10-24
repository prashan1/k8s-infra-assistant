#!/bin/bash
# Runs once as root at first boot (cloud-init). Installs single-node k3s.
set -euxo pipefail

# --write-kubeconfig-mode 644 lets the SSM shell user run kubectl without sudo.
# k3s bundles Traefik (ingress on :80/:443), so no cloud load balancer is needed.
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644" sh -
