# Example IRSA (IAM Roles for Service Accounts) configuration
# This file demonstrates how to create an IAM role that can be assumed by Kubernetes service accounts

# Example: IRSA role for EBS CSI Driver
resource "aws_iam_role" "ebs_csi_driver" {
  count = var.enable_irsa && var.enable_ebs_csi_driver_irsa && var.existing_ebs_csi_role_arn == "" ? 1 : 0

  name = "${var.cluster_name}-ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.cluster[0].arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-ebs-csi-driver"
    }
  )
}

# Attach the required policy for EBS CSI Driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count      = var.enable_irsa && var.enable_ebs_csi_driver_irsa && var.existing_ebs_csi_role_arn == "" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver[0].name
}