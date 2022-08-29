// https://github.com/prometheus-operator/kube-prometheus/blob/main/example.jsonnet
local globals = import 'globals.libsonnet';
local util = import 'util.libsonnet';
local globals = import 'globals.libsonnet';
local k = import 'k.libsonnet';
local secret = k.core.v1.secret;

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'monitoring',
      },
      grafana+:: {
        config+: {
          sections+: {
            server+: {
              root_url: 'https://grafana' + globals.domainName,
            },
          },
        },
      },
    },
    alertmanager+:: {
      alertmanager+: {
        spec+: {
          externalUrl: 'https://alertmanager' + globals.domainName,
        },
      },
    },
    prometheus+:: {
      prometheus+: {
        spec+: {
          externalUrl: 'https://prometheus' + globals.domainName,
        },
      },
    },
  };

util.tankaSpec(name='kube-prometheus', namespace='default') +
{
    local certcontent = {
        'tls.crt': std.base64(importstr '../../certs/server.crt'),
        'tls.key': std.base64(importstr '../../certs/server.key')
    },

  data:
    { 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
    {
      ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
      for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
    } +
    // { 'setup/pyrra-slo-CustomResourceDefinition': kp.pyrra.crd } +
    // serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
    { 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
    { 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
    { 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
    { ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
    { ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
    { ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
    // { ['pyrra-' + name]: kp.pyrra[name] for name in std.objectFields(kp.pyrra) if name != 'crd' } +
    { ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
    { ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
    { ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
    { ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
    { ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
    {
      // add ingresses
      grafana: util.newIngress(name='grafana', namespace=kp.values.common.namespace, serviceName='grafana', servicePortName='http'),
      prometheus: util.newIngress(name='prometheus', namespace=kp.values.common.namespace, serviceName='prometheus-k8s', servicePortName='web'),
      alert: util.newIngress(name='alertmanager', namespace=kp.values.common.namespace, serviceName='alertmanager-main', servicePortName='web'),
      # create certificate secret in monitoring namespace
      secret: secret.new('localcert', certcontent, type='kubernetes.io/tls')
      + secret.metadata.withNamespace(kp.values.common.namespace)
    }
}
