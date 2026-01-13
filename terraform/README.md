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

- I'm using an asymmetric subnet layout, as public subnets typically do not require as many IP addresses as private subnets; allocating them equally is often a waste of IP space. This division uses about 80% of the total addresses in the `/19` range which leaves room for future growth. However, hardcoding the main CIDR block and the corresponding subnets is less than ideal. In previous roles, I wrote a 'CIDR-MANAGER' webserver in Python that allocates unique blocks and also calculates the subnets' layout to use the entire block in an optimal way; the reason we're assigning unique CIDR blocks to each VPC is to prevent CIDR overlap if peering is ever required.

- The VPC has a secondary CIDR block attached (`100.64.0.0/16`); by using this CGNAT address space, we're providing plenty of addresses (`~65k`) to be used by pods in the cluster. IP exhaustion is a challenge I've been continuously dealing with, especially when working with dynamic workloads using ArgoEvents and ArgoWorkflows. This approach mitigates that risk.

### EKS Addons

- Since "EKS Custom Networking" requires the `ENIConfig` resources to be deployed BEFORE any nodegroups are created - and since the EKS module does not have built-in support for creating these resources - I passed an empty dictionary to the `eks_managed_node_groups` argument, and instead created them separately, which lets me control their dependencies. Same goes for the EKS Addons. I'm only installing the `vpc-cni` in the EKS module.

### Karpenter

- I'm using `karpenter` since it's the best open-source autoscaler out there (IMO). It's configured specifically to support "EKS Custom Networking". Please note that I'm not installing the `EC2NodeClass` and `NodePool` resources, as they're out of the scope of this project.
