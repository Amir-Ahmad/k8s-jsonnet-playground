local k = import 'k.libsonnet';
local ksutil = import 'ksutil.libsonnet';
local util = import 'util.libsonnet';
local globals = import 'globals.libsonnet';

local deploy = k.apps.v1.deployment;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local service = k.core.v1.service;

util.tankaSpec(name='hello') +
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
