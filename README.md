# k8s-tanka-playground

Local kubernetes cluster with [kind](https://github.com/kubernetes-sigs/kind) and [ingress-nginx](https://github.com/kubernetes/ingress-nginx) that I'm using to test tanka and jsonnet.

## Dependencies:
- [kind](https://github.com/kubernetes-sigs/kind) to create the containerised cluster/s
- [mkcert](https://github.com/FiloSottile/mkcert) to generate self signed certificates
- [Just](https://github.com/casey/just) as a task runner
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [tanka](https://github.com/grafana/tanka) and [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler) for installing additional apps

## Get started

This requires a wildcard domain name that points to 127.0.0.1. This is so we don't need to edit our /etc/hosts file.

By default it uses vcap.me (owned by CloudFoundry), but this can be overridden (see local_domain_name in the Justfile). 

```
# Create cert for <local_domain_name> and *.<local_domain_name>
just create-cert

# Create cluster
just create-cluster
```

## Install apps with tanka

Install Jsonnet libraries to vendor/
```
jb install
```

Install a hello app (https://vcap.me/hello)
```
just tk apply apps/hello
```

Install grafana and prometheus (https://grafana.vcap.me)
```
just tk apply apps/prom-grafana
```

## Tips

You can pass through tanka commands with `just tk`, and kubectl ones with `just k`
