variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "table_name" {
  description = "The name of the DynamoDB table"
  type        = string
  default     = "benchmark-items"
}

variable "lambda_configs" {
  description = "Configuration for each lambda function"
  type = map(object({
    filename = string
    runtime  = string
    aot      = bool
    snap     = bool
  }))
  default = {
    dotnet         = { filename = "dotnet.zip",       runtime = "dotnet8",     aot = false, snap = false }
    dotnet-aot     = { filename = "dotnet-aot.zip",   runtime = "dotnet8",     aot = true,  snap = false }
    dotnet-aot-ss  = { filename = "dotnet-aot.zip",   runtime = "dotnet8",     aot = true,  snap = true  }
    node           = { filename = "node.zip",         runtime = "nodejs20.x",  aot = false, snap = false }
    node-ss        = { filename = "node.zip",         runtime = "nodejs20.x",  aot = false, snap = true }
    python         = { filename = "python.zip",       runtime = "python3.12",  aot = false, snap = false }
    python-ss      = { filename = "python.zip",       runtime = "python3.12",  aot = false, snap = true }
  }
}
