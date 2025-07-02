provider "aws" {
  region = var.aws_region
}

resource "aws_dynamodb_table" "benchmark_table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}

resource "aws_lambda_function" "benchmarks" {
  for_each = var.lambda_configs

  function_name = "benchmark-${each.key}"
  role          = aws_iam_role.lambda_exec_role.arn
  handler = (
    each.value.runtime == "python3.12" ? "handler.handler" :
    each.value.runtime == "nodejs20.x" ? "index.handler" :
    "Lambda::Function::FunctionHandler"
  )
  runtime       = each.value.runtime
  filename      = "${path.module}/../lambdas/${each.value.filename}"
  source_code_hash = filebase64sha256("${path.module}/../lambdas/${each.value.filename}")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.benchmark_table.name
    }
  }

  publish = true
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_function_url" "benchmark_urls" {
  for_each           = aws_lambda_function.benchmarks
  function_name      = each.value.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_function_version" "snap_versions" {
  for_each = {
    for k, v in aws_lambda_function.benchmarks :
    k => v if k == "dotnet-aot-ss"
  }

  function_name = each.value.function_name
}

resource "aws_lambda_snap_start" "snap_start" {
  for_each = aws_lambda_function_version.snap_versions

  function_name = each.value.function_name
  qualifier     = "$LATEST"
  apply_on      = "PublishedVersions"
}
