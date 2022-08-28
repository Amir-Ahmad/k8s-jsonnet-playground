local k = import 'k.libsonnet';
local prometheus = import 'prometheus-ksonnet/prometheus-ksonnet.libsonnet';
local util = import 'util.libsonnet';
local globals = import 'globals.libsonnet';

local ingress = k.networking.v1.ingress;
local ingressTls = k.networking.v1.ingressTLS;
local ingressRule = k.networking.v1.ingressRule;
local ingressBackend = k.networking.v1.ingressBackend;
local httpIngressPath = k.networking.v1.httpIngressPath;

util.tankaSpec(name='prom-grafana', namespace='default') +
{
  _config+:: {
    app_url: 'grafana.' + globals.domainName,
  },

  data: {
    namespace: k.core.v1.namespace.new($.spec.namespace),

    prometheus: prometheus {
      _config+:: {
        cluster_name: globals.clusterName,
        namespace: $.spec.namespace,
        grafana_root_url: 'https://' + $._config.app_url,
      },
    },

    ingress:
      ingress.new('grafana')
      + ingress.spec.withIngressClassName(globals.ingressClass)
      + ingress.spec.withTls(
        ingressTls.withHosts($._config.app_url)
        + ingressTls.withSecretName(globals.tlsSecretName)
      )
      + ingress.spec.withRules(
        ingressRule.withHost($._config.app_url)
        + ingressRule.http.withPaths(
          httpIngressPath.withPath('/')
          + httpIngressPath.withPathType('Prefix')
          + httpIngressPath.backend.service.port.withNumber(3000)
          + httpIngressPath.backend.service.withName('grafana')
        )
      ),
  },
}
