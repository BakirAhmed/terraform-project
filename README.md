# ☁️ Infrastructure AWS scalable avec Terraform


## 📐 Architecture

![Schéma d'architecture AWS](./images/architecture.png)

### Composants déployés

| Service | Rôle |
|---------|------|
| **VPC** | Isolation réseau avec CIDR 192.168.0.0/16 |
| **Subnets publics** | Hébergement du Bastion et de l'ALB |
| **Subnets privés** | Hébergement des instances applicatives (ASG) |
| **Internet Gateway** | Accès Internet pour les ressources publiques |
| **NAT Gateway** | Accès Internet sortant pour les ressources privées |
| **Application Load Balancer** | Répartition de charge HTTP |
| **Auto Scaling Group** | Scaling dynamique (1 à 3 instances) |
| **Bastion Host** | Accès SSH sécurisé aux instances privées |
| **S3 Bucket** | Stockage des sauvegardes |
| **IAM Role** | Gestion des permissions d'accès à S3 |

## 🚀 Déploiement

```bash
terraform init
terraform plan
terraform apply -auto-approve