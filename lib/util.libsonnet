{
  tankaSpec(name, namespace='default'):: {
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
}
