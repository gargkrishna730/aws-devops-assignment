# Launch template for m7i-flex.large nodes
resource "aws_launch_template" "eks_node_group_m7i_flex" {
  name_prefix = "${var.cluster_name}-m7i-flex-nodegroup"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.node_disk_size_m7i_flex
      volume_type = "gp3"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # This enforces IMDSv2
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-m7i-flex-launch-template"
    }
  )
}

# m7i_flex Node Group
resource "aws_eks_node_group" "m7i_flex" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-m7i-flex-nodegroup"
  node_role_arn   = var.existing_node_role_arn != "" ? var.existing_node_role_arn : aws_iam_role.eks_node_role[0].arn
  subnet_ids      = var.node_group_subnet_ids

  ami_type       = "AL2023_x86_64_NEURON"
  instance_types = ["m7i-flex.large"]
  capacity_type  = "ON_DEMAND" # or "SPOT" for cost savings

  launch_template {
    id      = aws_launch_template.eks_node_group_m7i_flex.id
    version = aws_launch_template.eks_node_group_m7i_flex.latest_version
  }

  scaling_config {
    desired_size = var.node_desired_size_m7i_flex
    max_size     = var.node_max_size_m7i_flex
    min_size     = var.node_min_size_m7i_flex
  }

  update_config {
    max_unavailable_percentage = 25
  }

  labels = {
    "node-type"     = "m7i_flex"
    "instance-type" = "m7i.flex"
  }

  tags = merge(
    var.tags,
    {
      "Name"         = "${var.cluster_name}-m7i-flex-nodegroup"
      "InstanceType" = "m7i.flex"
    }
  )

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
  ]
}