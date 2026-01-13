module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.name}-${var.environment}"
  cidr = local.vpc_cidr
  azs  = local.azs

  private_subnets       = local.private_subnets
  public_subnets        = local.public_subnets
  secondary_cidr_blocks = [local.secondary_cidr]
  intra_subnets         = local.intra_subnets

  # NAT Gateway - single for cost optimization;
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  map_public_ip_on_launch = false
  enable_dns_hostnames    = true
  enable_dns_support      = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "karpenter.sh/discovery"          = "${local.cluster_name}"
    "kubernetes.io/role/internal-elb" = 1
  }

  intra_subnet_tags = {
    "kubernetes.io/role/cni" = 1
    "Purpose"                = "eks-pods-secondary-cidr"
  }

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}
