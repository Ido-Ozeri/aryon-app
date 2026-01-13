module "system_nodegroup" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 20.0"

  name            = "system"
  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.cluster_version
  subnet_ids      = module.vpc.private_subnets
  ami_type        = "AL2023_x86_64_STANDARD"
  disk_size       = 20

  instance_types = ["m6a.large"]

  min_size     = 1
  max_size     = 10
  desired_size = 2

  labels = {
    "karpenter.sh/controller" = "true"
  }
  cluster_service_cidr = module.eks.cluster_service_cidr
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  depends_on = [kubectl_manifest.eni_config]
}
