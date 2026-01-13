locals {
  azs            = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr       = "10.0.0.0/19"
  secondary_cidr = "100.64.0.0/16"

  # 2048 addresses each;
  private_subnets = [
    "10.0.0.0/21",
    "10.0.8.0/21",
    "10.0.16.0/21",
  ]

  # 128 addresses each;
  public_subnets = [
    "10.0.24.0/25",
    "10.0.24.128/25",
    "10.0.25.0/25",
  ]

  intra_subnets = [
    "100.64.0.0/18",
    "100.64.64.0/18",
    "100.64.128.0/18",
  ]

  cluster_name    = "${var.name}-${var.environment}"
  cluster_version = "1.33"
}
