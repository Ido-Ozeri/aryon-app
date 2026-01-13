module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name = module.eks.cluster_name
  enable_irsa  = true

  create_pod_identity_association = false
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = local.cluster_name
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn

  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  # Karpenter v1.7+ offers garbage collection features
  # that require permissions not listed in the build-in module's policy;
  iam_policy_statements = [
    {
      sid    = "KarpenterGC"
      effect = "Allow"
      actions = [
        "iam:ListInstanceProfiles",
      ]
      resources = ["*"]
    }
  ]

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  depends_on = [module.system_nodegroup]
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.8.3"
  wait             = false
  create_namespace = true

  values = [
    templatefile("${path.module}/templates/karpenter-values.yaml.tpl", {
      cluster_name     = module.eks.cluster_name
      cluster_endpoint = module.eks.cluster_endpoint
      queue_name       = module.karpenter.queue_name
      role_arn         = module.karpenter.iam_role_arn
    })
  ]

  depends_on = [module.karpenter]
}
