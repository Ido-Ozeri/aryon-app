module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = var.eks_public_access_cidrs

  cluster_enabled_log_types              = ["audit", "authenticator", "api"]
  cloudwatch_log_group_retention_in_days = 90

  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {}

  cluster_addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true

      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values = jsonencode({
        env = {
          AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
          ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
          WARM_ENI_TARGET                    = "1"
          ENABLE_PREFIX_DELEGATION           = "true"
        }
      })
    }
  }

  tags = {
    "karpenter.sh/discovery" = local.cluster_name
  }
}

# Allow VPC-internal traffic to NodePorts (required for EKS LoadBalancers);
resource "aws_security_group_rule" "nodes_allow_all_from_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = module.eks.node_security_group_id
  cidr_blocks       = [module.vpc.vpc_cidr_block]
  description       = "Allow traffic inside VPC to reach NodePorts"
}
