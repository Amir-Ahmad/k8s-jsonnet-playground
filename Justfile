# set shell to bash
set shell := ["bash", "-uc"]

local_domain_name := env_var_or_default('LOCAL_DOMAIN_NAME', 'vcap.me')
cluster_name := env_var_or_default('CLUSTER_NAME', 'dev')
kindconfig := justfile_directory() / "kindconfig.yaml"
kubeconfig := "$HOME/.kube/kindconfig"
context := "kind-" + cluster_name
kubectl := "kubectl --kubeconfig=" + kubeconfig + " --context " + context

# List of tanka commands that need apiServer to be set, separated by |.
tanka_server_commands := "apply|show|diff|prune|delete|status|export|eval"

# Print help
@help:
    just --list

# Create cert
@create-cert:
    mkdir -p certs
    mkcert -install
    mkcert -cert-file certs/server.crt \
    -key-file certs/server.key \
    '*.{{local_domain_name}}' '{{local_domain_name}}' localhost 127.0.0.1

# Create cluster
@create-cluster:
    # create cluster if it doesnt exist
    if ! kind get clusters | grep -q "^{{cluster_name}}$"; then \
        kind create cluster --kubeconfig "{{kubeconfig}}" --config "{{kindconfig}}" --name "{{cluster_name}}"; \
    fi

    # Create secret for certificate
    {{kubectl}} create secret tls localcert --key certs/server.key --cert certs/server.crt \
          --dry-run=client -o yaml | {{kubectl}} apply -f -

    # Deploy ingress-nginx controller
    {{kubectl}} apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

    echo "Waiting for ingress-nginx to be ready"
    {{kubectl}} wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s

# Delete cluster
@delete-cluster:
    kind delete cluster --name "{{cluster_name}}"

# Create a kubie shell with cluster kubeconfig/context
@kb:
    kubie ctx --kubeconfig "{{kubeconfig}}" "{{context}}"

# Pass through kubectl commands
@k *command:
    {{kubectl}} {{command}}

# Pass through tanka commands
# apiServer is grabbed from kubeconfig and passed in as an extVar
@tk *command:
    if [[ $(echo "{{command}}" | awk '{print $1}') == @({{tanka_server_commands}}) ]]; then \
        apiServer=$({{kubectl}} config view \
            -o jsonpath='{.clusters[?(@.name == "{{context}}")].cluster.server}') \
        && KUBECONFIG={{kubeconfig}} tk {{command}} -V apiServer="$apiServer"; \
    else \
        tk {{command}}; \
    fi
