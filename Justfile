# set shell to bash
set shell := ["bash", "-uc"]

local_domain_name := env_var_or_default('LOCAL_DOMAIN_NAME', 'vcap.me')
cluster_name := env_var_or_default('CLUSTER_NAME', 'dev')
kindconfig := justfile_directory() / "kindconfig.yaml"
kubeconfig := "$HOME/.kube/kindconfig"
context := "kind-" + cluster_name
kubectl := "kubectl --kubeconfig=" + kubeconfig + " --context " + context
kubecfg := "kubecfg --kubeconfig=" + kubeconfig + " --context " + context + " -J lib -J vendor"

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
@create-cluster create-ingress="true":
    # create cluster if it doesnt exist
    if ! kind get clusters | grep -q "^{{cluster_name}}$"; then \
        kind create cluster --kubeconfig "{{kubeconfig}}" --config "{{kindconfig}}" --name "{{cluster_name}}"; \
    fi

    if [ "{{create-ingress}}" == "true" ]; then \
        echo "Creating secret for certificate"; \
        {{kubectl}} create secret tls localcert --key certs/server.key --cert certs/server.crt \
            --dry-run=client -o yaml | {{kubectl}} apply -f -; \
        echo "Deploying ingress-nginx controller"; \
        {{kubectl}} apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml; \
        echo "Waiting for ingress-nginx to be ready"; \
        {{kubectl}} wait --namespace ingress-nginx \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/component=controller \
            --timeout=90s; \
    fi

# Delete cluster
@delete-cluster:
    kind delete cluster --name "{{cluster_name}}"

# Create a kubie shell with cluster kubeconfig/context
@kb:
    kubie ctx --kubeconfig "{{kubeconfig}}" "{{context}}"

# Pass through kubectl commands
@k *command:
    {{kubectl}} {{command}}

# Pass through kubecfg commands
@kcfg *command:
    {{kubecfg}} {{command}}

# Server side apply that pipes kubecfg yaml output to kubectl
kcfg-sapply *app:
    {{kubecfg}} show {{app}} | {{kubectl}} apply --server-side -f -
