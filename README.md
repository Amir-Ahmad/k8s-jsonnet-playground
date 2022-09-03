# k8s-jsonnet-playground

Local kubernetes cluster with [kind](https://github.com/kubernetes-sigs/kind) and [ingress-nginx](https://github.com/kubernetes/ingress-nginx) that I'm using to play around with jsonnet.

## Dependencies:
- [kind](https://github.com/kubernetes-sigs/kind) to create the containerised cluster/s
- [mkcert](https://github.com/FiloSottile/mkcert) to generate self signed certificates
- [Just](https://github.com/casey/just) as a task runner
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [kubecfg](https://github.com/kubecfg/kubecfg) for outputting yaml from the jsonnet
- [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler) for vendoring jsonnet libraries

## Get started

This requires a wildcard domain name that points to 127.0.0.1. This is so we don't need to edit our /etc/hosts file.

By default it uses vcap.me (owned by CloudFoundry), but this can be overridden (see local_domain_name in the Justfile). 

```
# Create cert for <local_domain_name> and *.<local_domain_name>
just create-cert

# Create cluster
just create-cluster
```

## Install apps

Install Jsonnet libraries to vendor/
```
jb install
```

Install a hello app (https://vcap.me/hello)
```
just kcfg update apps/hello/main.jsonnet
```

Install kube-prometheus stack (https://grafana.vcap.me)
```
# Do a server side apply to install kubeprometheus
# Run twice - command will fail the first time due to CRDs not being created yet
just kcfg-sapply apps/kube-prometheus/main.jsonnet
```

Deploy a dummy exporter for prometheus:
```
just kcfg update apps/dummy-exporter/main.jsonnet
```

## Tips

You can pass through kubecfg commands with `just kcfg`, and kubectl ones with `just k`
