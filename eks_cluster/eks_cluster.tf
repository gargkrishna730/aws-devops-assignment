resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.existing_cluster_role_arn != "" ? var.existing_cluster_role_arn : aws_iam_role.eks_cluster_role[0].arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.cluster_subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
  }

  tags = merge(
    var.tags,
    {
      "Name" = var.cluster_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy,
  ]
}

# Add a time delay to ensure nodes are ready
resource "time_sleep" "wait_for_nodes" {
  depends_on = [
    aws_eks_node_group.m7i_flex,
  ]
  create_duration = var.node_readiness_wait_duration
}

# EBS CSI Driver Addon
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "aws-ebs-csi-driver"
  service_account_role_arn = var.enable_irsa && var.enable_ebs_csi_driver_irsa ? (
    var.existing_ebs_csi_role_arn != "" ? var.existing_ebs_csi_role_arn : aws_iam_role.ebs_csi_driver[0].arn
  ) : null

  depends_on = [
    time_sleep.wait_for_nodes
  ]
}

# Metrics Server Addon
resource "aws_eks_addon" "metrics_server" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "metrics-server"

  depends_on = [
    time_sleep.wait_for_nodes
  ]
}

# CoreDNS Addon
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"

  depends_on = [time_sleep.wait_for_nodes]
}

# KubeProxy Addon
resource "aws_eks_addon" "kubeproxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"

  depends_on = [time_sleep.wait_for_nodes]
}

# VPC CNI Addon
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"

  depends_on = [time_sleep.wait_for_nodes]
}

# 
resource "aws_eks_addon" "amazon-cloud-observability" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "amazon-cloudwatch-observability"
}

# Data source to fetch OIDC thumbprint
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# OIDC Identity Provider for IRSA
# This should be created for new clusters to enable IRSA functionality
resource "aws_iam_openid_connect_provider" "cluster" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-eks-irsa"
    }
  )
}