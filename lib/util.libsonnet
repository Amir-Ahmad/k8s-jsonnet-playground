local globals = import 'globals.libsonnet';
local k = import 'k.libsonnet';

{
  tankaSpec(name='default', namespace=null):: {
    apiVersion: 'tanka.dev/v1alpha1',
    kind: 'Environment',
    metadata: {
      name: name,
    },
    spec: {
      apiServer: std.extVar('apiServer'),
      namespace: namespace,
    },
  },

  // helper to create an ingress with opinionated defaults
  newIngress(
    name,
    serviceName,
    servicePortName=null,
    servicePortNumber=null,
    namespace='default',
    path='/',
    pathType='Prefix',
    fqdn=null,
  ):: {
    local ingress = k.networking.v1.ingress,
    local ingressTls = k.networking.v1.ingressTLS,
    local ingressRule = k.networking.v1.ingressRule,
    local ingressBackend = k.networking.v1.ingressBackend,
    local httpIngressPath = k.networking.v1.httpIngressPath,

    local fdqn =
      if fqdn == null then
        name + '.' + globals.domainName
      else
        fqdn,

    local httpServicePort =
      if servicePortName != null then
        httpIngressPath.backend.service.port.withName(servicePortName)
      else if servicePortNumber != null then
        httpIngressPath.backend.service.port.withNumber(servicePortNumber)
      else
        error 'ServicePortName or ServicePortNumber must be provided',

    ingress:
      ingress.new(name)
      + ingress.metadata.withNamespace(namespace)
      + ingress.spec.withIngressClassName(globals.ingressClass)
      + ingress.spec.withTls(
        ingressTls.withHosts(fdqn)
        + ingressTls.withSecretName(globals.tlsSecretName)
      )
      + ingress.spec.withRules(
        ingressRule.withHost(fdqn)
        + ingressRule.http.withPaths(
          httpIngressPath.withPath(path)
          + httpIngressPath.withPathType(pathType)
          + httpServicePort
          + httpIngressPath.backend.service.withName(serviceName)
        )
      ),
  },
}
