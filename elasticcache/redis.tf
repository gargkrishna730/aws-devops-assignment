resource "aws_security_group" "redis_sg" {
  name        = "redis-security-group"
  description = "Security group for Redis cluster"

  // Define your security group rules here, e.g., allowing access from specific IP ranges
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // Open to all; customize for your needs
  }
}

resource "aws_elasticache_cluster" "aws-assignment" {
  cluster_id           = "aws-assignment"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  apply_immediately    = true
  port                 = 6379
    // Associate the Redis cluster with the custom security group
  security_group_ids       = [aws_security_group.redis_sg.id]
}