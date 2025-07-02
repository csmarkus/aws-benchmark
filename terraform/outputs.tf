output "lambda_urls" {
  description = "Public URLs for all Lambda functions"
  value = {
    for k, v in aws_lambda_function_url.benchmark_urls :
    k => v.function_url
  }
}
