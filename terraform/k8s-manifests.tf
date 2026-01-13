resource "kubectl_manifest" "eni_config" {
  for_each = zipmap(local.azs, module.vpc.intra_subnets)

  yaml_body = yamlencode({
    apiVersion = "crd.k8s.amazonaws.com/v1alpha1"
    kind       = "ENIConfig"
    metadata = {
      name = each.key
    }
    spec = {
      securityGroups = [module.eks.node_security_group_id]
      subnet         = each.value
    }
  })

  depends_on = [module.eks]
}

resource "kubectl_manifest" "default_storage_class" {
  yaml_body = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "gp3-default"
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "true"
      }
    }
    provisioner          = "ebs.csi.aws.com"
    allowVolumeExpansion = true
    reclaimPolicy        = "Delete"
    volumeBindingMode    = "WaitForFirstConsumer"
    parameters = {
      type      = "gp3"
      iops      = "3000"
      encrypted = "true"
    }
  })

  depends_on = [module.eks]
}
