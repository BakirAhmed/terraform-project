# Infrastructure AWS scalable avec Terraform

## Architecture
- VPC avec 4 subnets (2 publics, 2 privés)
- ALB + Auto Scaling Group (1 à 3 instances)
- Bastion host + NAT Gateway
- S3 backup avec IAM Role

## Déploiement
```bash
terraform init
terraform plan
terraform apply -auto-approve