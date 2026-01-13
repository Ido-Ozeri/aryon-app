# Terraform EKS Setup

This Terraform codebase aims to install the required components for an optimized EKS setup.

## Installation

Follow this procedure to install this module:
- Your shell must be authenticated with AWS credentials (use `aws sts get-caller-identity` to verify who you are).
- Your `terraform` binary must be => v1.14. 
- You must obtain your public IP address (for EKS control plane whitelisting), use `curl ifconfig.me` to get it.
Once obtained, specify it in the `terraform.tfvars` file under `eks_public_access_cidrs`.
- Run `terraform init` followed by `terraform apply`.

## Implementation Decisions

This is an opinionated implementation of EKS, based on my own personal experience. I'll try to explain some of the decisions behind the configuration.

### Terraform State Backend

- For simplicity, the Terraform state is saved locally. This is not ideal in a real-world scenario. Ideally, you'd save the state into a S3 bucket and use DynamoDB for state locking.

### Network

- I'm using an assymetric subnet layout, as public subnets typically do not require as many IP addresses as private subnets, this is simply a waste of IP allocations; this division uses about 80% of the total addressses in the `/19` range which leaves room for future growth. However, hardcoding the main CIDR block and the corresponding subnets is less than ideal; with my current employer I wrote a 'CIDR-MANAGER' webserver in python that allocates unique blocks and also calculates the subnets' layout to use the entire block in an optimal way; the reason we're assigning unique CIDR blocks to each VPC is to avoid CIDR overlapping if peering is ever required.

- The VPC has a secondary CIDR block attached (`100.64.0.0/16`); by using this CGNAT address space, we're providing plenty of addresses (`~65k`) to be used by pods in the cluster. IP exhaustion is something I've been consinously dealing with, especially when working with dynamic workloads utilizing ArgoEvents and ArgoWorkflows. This approach reduces this risk.

### EKS Addons

- Since "EKS Custom Networking" requires the `ENIConfig` resources to be deployed BEFORE any nodegroups are created, and since the EKS module does not have built-in support to create aforementioned resources - I had to pass an empty dict to the `eks_managed_node_groups` argument, and instead create them seperately, which let's me control their dependencies. Same goes for the EKS Addons. I'm only installing the `vpc-cni` in the EKS module.

### Karpenter

- I'm using `karpenter` since it's the best open-source autoscaler out there (IMO). It's configured specifically to support "EKS Custom Networking". What I'm not installing in this module is the `EC2NodeClass` and `NodePool` resources, as they're out of the scope of this project.
