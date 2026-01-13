locals {
  azs            = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr       = "10.0.0.0/19"
  secondary_cidr = "100.64.0.0/16"

  # I'm using an assymetric subnet layout, as public subnets do not
  # need an equal number of IP addresses as private subnets, this is 
  # simply a waste of IP allocations; this division uses about 80% of
  # the total addressses in the /19 range which leaves room for future growth;

  # However, hardcoding the main CIDR block and the corresponding subnets
  # is less than ideal; with my current employer I wrote a 'CIDR-MANAGER' 
  # webserver in python that allocates unique blocks and also calculates 
  # the subnets' layout to use the entire block in an optimal way; the 
  # reason we're assigning unique CIDR blocks to each VPC is to avoid
  # CIDR overlapping if peering is ever required;

  # Using the CGNAT address space (100.64.0.0/16) provides plenty of 
  # addresses to be used by pods in the cluster;

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
