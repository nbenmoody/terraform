# EC2 Kubernetes Cluster
This module contains a VERY simple AWS footprint, setting up a VPC, 3 Public Subnets, a Route Table, a wide-open 
Security Group, and 3 EC2s with a public RSA key already in place. It should be enough to allow for revision and drilling
on how to manually configure a self-maintained Kubernetes Cluster using `kubeadm`.

## Creation

### Prerequisites
These steps assume that you have an AWS account with administrative permissions (AKA, your user has the AdministratorAccess 
policy attached to it, or the equivalent). You should also have the `awscli`, `terraform`, `kubectl`, and `kubeadm` installed locally,
and configured. Here are the links to those things, if you need them. I won't copy their docs here, for brevity.
1. `awscli` 
- [Install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Configure](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
2. `terraform`
- [Install and Configure](https://developer.hashicorp.com/terraform/install)
3. `kubectl`
- [Install](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [Configure and Use](https://kubernetes.io/docs/reference/kubectl/)
4. `kubeadm`
- [Install and Configure](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)

### Infrastructure Creation
If you have all the prerequisites in place, you should be able to run `terraform init` and then `terraform apply` from this module's directory, respond
to the confirmation prompt, and see the resources in AWS after a few minutes. Fair warning: as this is just for getting the
EC2s out there for drilling with kubeadm, this isn't production-grade for sure. It is actually a pretty insecure configuration,
so you'll want to `terraform destroy` it when you are done. This module is meant to be quick, for setup and teardown, on purpose.
This process for creation will also just use your local machine as the "backend" for Terraform's state, which means the "build artifacts" for
this Configuration will end up sitting in this module when you use it. Another strike against production. If you catch my drift: just don't
use this for production. Use it for practice.

1. Replace the public key in the `cluster_node_public_key` file with your own.
2. `terraform init`
3. `terraofmr apply`
4. You should be able to shell into each EC2 now. 

### Kubernetes Configuration
[Reference](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

The certifications for Kubernetes allow you to reference the official Kubernetes documentation, so that's what I'm going to link
out to and use here as well.

### TODO
1. I need to create and Ansible an EC2 with all the CLI stuff above, to use for cluster-creation. During the test, I won't 
be allowed to use my local machine, and I need to practice with the "from-scratch" setup on the `kubeadm` side as well.
