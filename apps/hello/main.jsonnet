local k = import 'k.libsonnet';
local ksutil = import 'ksutil.libsonnet';
local util = import 'util.libsonnet';
local globals = import 'globals.libsonnet';

local deploy = k.apps.v1.deployment;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local service = k.core.v1.service;
local ingress = k.networking.v1.ingress;
local ingressTls = k.networking.v1.ingressTLS;
local ingressRule = k.networking.v1.ingressRule;
local ingressBackend = k.networking.v1.ingressBackend;
local httpIngressPath = k.networking.v1.httpIngressPath;

util.tankaSpec(name='hello', namespace='default') +
{
  _config+:: {
    name: 'hello',
    image: 'nginxdemos/hello',
    containerPort: 80,
  },

  data: {
    deploy:
      deploy.new(name=$._config.name, containers=[
        container.new(name=$._config.name, image=$._config.image)
        + container.withPorts(containerPort.newNamed($._config.containerPort, 'http')),
      ]),
    service:
      ksutil.serviceFor(self.deploy)
      + service.spec.withType('ClusterIP'),
    ingress: util.newIngress(
      name=$._config.name,
      serviceName=$._config.name,
      servicePortNumber=$._config.containerPort,
      fqdn=globals.domainName,
      path='/hello'
    ),
  },
}
