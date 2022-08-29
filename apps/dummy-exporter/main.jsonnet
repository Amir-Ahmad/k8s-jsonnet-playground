local globals = import 'globals.libsonnet';
local k = import 'k.libsonnet';
local ksutil = import 'ksutil.libsonnet';
local util = import 'util.libsonnet';

local deploy = k.apps.v1.deployment;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local service = k.core.v1.service;

util.tankaSpec(name='dummy-exporter', namespace='default') +
{
  _config+:: {
    name: 'dummy-exporter',
    image: 'kobtea/dummy_exporter',
    containerPort: 9510,
  },

  data: {
    deploy:
      deploy.new(name=$._config.name, containers=[
        container.new(name=$._config.name, image=$._config.image)
        + container.withPorts(containerPort.newNamed($._config.containerPort, 'metrics')),
      ]),
    service:
      ksutil.serviceFor(self.deploy),
    # to do: replace with https://github.com/jsonnet-libs/prometheus-operator-libsonnet
    serviceMonitor: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'dummy-exporter',
        namespace: 'default',
      },
      spec: {
        endpoints: [
          {
            interval: '30s',
            path: '/metrics',
          },
        ],
        namespaceSelector: {
          matchNames: [
            'default',
          ],
        },
        selector: {
          matchLabels: {
            name: 'dummy-exporter',
          },
        },
      },
    },
  },
}
