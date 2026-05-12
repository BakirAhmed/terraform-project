output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "DNS du Load Balancer"
  value       = aws_lb.test.dns_name
}

output "bastion_public_ip" {
  description = "IP publique du bastion"
  value       = aws_instance.jumper_instance.public_ip
}

output "s3_bucket_name" {
  description = "Nom du bucket S3"
  value       = aws_s3_bucket.ahmed_s3.id
}