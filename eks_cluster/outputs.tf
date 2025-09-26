output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

# OIDC Provider outputs for IRSA
output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# IRSA Role ARNs

output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI Driver IAM role"
  value = var.enable_irsa && var.enable_ebs_csi_driver_irsa ? (
    var.existing_ebs_csi_role_arn != "" ? var.existing_ebs_csi_role_arn : aws_iam_role.ebs_csi_driver[0].arn
  ) : null
}
