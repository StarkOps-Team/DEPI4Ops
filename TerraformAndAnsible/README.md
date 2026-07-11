# E-commerce DevOps Infra: Terraform + Ansible

2 EC2 instances: `controller` (runs Ansible) and `target` (gets Docker + single-node Kubernetes via kubeadm).

## Structure
```
terraform/       AWS infra (VPC default, SG, key pair, 2 EC2 instances)
ansible/          playbook.yml installs docker + kubeadm/kubelet/kubectl on target
```

## Prereqs
- AWS credentials configured (`aws configure` or env vars)
- Terraform >= 1.5
- AWS account with default VPC in the target region

## Steps

1. Deploy infra:
```bash
cd terraform
terraform init
terraform apply
```
This creates both instances, generates an SSH key pair (`ecommerce-devops-key.pem`), writes `ansible/inventory.ini`, and copies the key + playbook + inventory onto the controller automatically.

2. SSH into the controller:
```bash
terraform output ssh_to_controller
# run the printed command
```

3. On the controller, run the playbook:
```bash
cd ~
ansible -i inventory.ini target -m ping
ansible-playbook -i inventory.ini playbook.yml
```

4. Verify on the target (or via ansible ad-hoc from controller):
```bash
ansible target -i inventory.ini -m shell -a "docker ps" -b
ansible target -i inventory.ini -m shell -a "kubectl get nodes" -b -u ubuntu
```

## Notes
- `target_instance_type` defaults to `t3.medium` (2 vCPU/4GB) — kubeadm needs at least 2 vCPU and won't init on `t2.micro`.
- Security group opens SSH/HTTP/HTTPS/6443/30000-32767 to `0.0.0.0/0` by default. Set `allowed_cidr` in `variables.tf` to your own IP before using this for anything beyond a lab/thesis demo.
- Cluster is single-node: kubeadm init + Flannel CNI + control-plane taint removed so pods can schedule.
- To tear everything down: `terraform destroy` from the `terraform/` folder.

## Next steps for your e-commerce microservices
Once the cluster is up, you can push your Docker Compose services into k8s manifests (Deployments/Services) or convert with `kompose`, then `kubectl apply -f` from the controller against the target's kubeconfig.
