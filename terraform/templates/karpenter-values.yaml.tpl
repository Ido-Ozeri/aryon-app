fullnameOverride: karpenter

# Better use the node's IP when custom networking is enabled;
hostNetwork: true

serviceAccount:
  create: true
  name: karpenter
  annotations:
    eks.amazonaws.com/role-arn: ${role_arn}

nodeSelector:
  karpenter.sh/controller: 'true'
dnsPolicy: Default
settings:
  reservedENIs: "1"
  clusterName: ${cluster_name}
  clusterEndpoint: ${cluster_endpoint}
  interruptionQueue: ${queue_name}
webhook:
  enabled: false

controller:
  resources:
    requests:
      cpu: 1
      memory: "1G"
    limits:
      memory: "4G"
