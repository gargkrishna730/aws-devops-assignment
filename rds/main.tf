    # Security Group for RDS
    resource "aws_security_group" "rds_sg" {
      name        = "rds-security-group"
      description = "Allow inbound traffic to RDS instance"
      vpc_id      = "vpc-0ff29527354cab774" # Replace with your VPC ID

      ingress {
        from_port   = 3306 # Default MySQL port (adjust for other engines)
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Be more restrictive in production
      }
    }

    # RDS Instance
    resource "aws_db_instance" "free_tier_db" {
      allocated_storage    = 20
      engine               = "mysql" # Or postgres, mariadb, etc.
      engine_version       = "8.0.42" # Check for free-tier eligible versions
      instance_class       = "db.t4g.micro" # Free-tier eligible instance class
  # db_instance_identifier removed (unsupported argument)
      username             = "admin"
      password             = "12345678" # Replace with a strong password
      parameter_group_name = "default.mysql8.0" # Adjust for your engine
      publicly_accessible  = true # Set to false for production
      skip_final_snapshot  = true
      vpc_security_group_ids = [aws_security_group.rds_sg.id]

      tags = {
        Name = "FreeTierDB"
      }
    }