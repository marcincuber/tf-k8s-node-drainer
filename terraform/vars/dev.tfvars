name_prefix = "example-prefix"

subnets = ["subnet-12345"]

tags = {
  Terraform   = "true"
  Service     = "eks"
  Environment = "dev"
}

cluster_name = "test-name"

security_group_ids = ["sg-123355"]

auto_scaling_group_name = "asg-name"
