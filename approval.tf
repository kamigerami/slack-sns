# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

# get accountID
data "aws_caller_identity" "accountId" {}

# get ssm data  
data "aws_ssm_parameter" "slack_webhook_url" {
  name = "SLACK_WEBHOOK_URL"
}

data "aws_ssm_parameter" "slack_verification_token" {
  name = "SLACK_VERIFICATION_TOKEN"
}

# approval lambda
# archive zip file
data "archive_file" "approval" {
  type        = "zip"
  source_file = "${path.module}/lambda/approval/approval.py"
  output_path = "${path.module}/.terraform/archive_files/approval.zip"
}

resource "aws_lambda_function" "approval_lambda" {
  filename         = "${data.archive_file.approval.output_path}"
  function_name    = "approval"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "approval.lambda_handler"
  source_code_hash = "${data.archive_file.approval.output_base64sha256}"
  runtime          = "python3.6"

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "${data.aws_ssm_parameter.slack_webhook_url.value}"
      SLACK_CHANNEL = "aws-codecommit"
    }
  }
}

# message_action lambda
# archive zip file
data "archive_file" "message_action" {
  type        = "zip"
  source_file = "${path.module}/lambda/message_action/message_action.py"
  output_path = "${path.module}/.terraform/archive_files/message_action.zip"
}

resource "aws_lambda_function" "message_action_lambda" {
  filename         = "${data.archive_file.message_action.output_path}"
  function_name    = "message_action"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "message_action.lambda_handler"
  source_code_hash = "${data.archive_file.message_action.output_base64sha256}"
  runtime          = "python3.6"

  environment {
    variables = {
      SLACK_VERIFICATION_TOKEN = "${data.aws_ssm_parameter.slack_verification_token.value}"
    }
  }
}


# api gateway for message_actions
resource "aws_api_gateway_rest_api" "slack-sns-message-action-api" {
  name        = "slack-sns-message-action"
  description = "Slack sns message action approval button"
}
# create resource for api gateway
resource "aws_api_gateway_resource" "slack-sns-message-action-resource" {
  rest_api_id = "${aws_api_gateway_rest_api.slack-sns-message-action-api.id}"
  parent_id   = "${aws_api_gateway_rest_api.slack-sns-message-action-api.root_resource_id}"
  path_part   = "message_action"
}
# create method for api gateway
resource "aws_api_gateway_method" "slack-sns-message-action-method" {
  rest_api_id   = "${aws_api_gateway_rest_api.slack-sns-message-action-api.id}"
  resource_id   = "${aws_api_gateway_resource.slack-sns-message-action-resource.id}"
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}
# create method settings for api gateway
resource "aws_api_gateway_method_settings" "slack-sns-message-action-method-settings" {
  rest_api_id = "${aws_api_gateway_rest_api.slack-sns-message-action-api.id}"
  stage_name  = "${aws_api_gateway_stage.slack-sns-message-action-stage.stage_name}"
  method_path = "${aws_api_gateway_resource.slack-sns-message-action-resource.path_part}/${aws_api_gateway_method.slack-sns-message-action-method.http_method}"

  settings {
    metrics_enabled = true
    logging_level = "INFO"
  }
}
# create integration for api gateway
resource "aws_api_gateway_integration" "slack-sns-message-action-integration" {
  rest_api_id = "${aws_api_gateway_rest_api.slack-sns-message-action-api.id}"
  resource_id = "${aws_api_gateway_resource.slack-sns-message-action-resource.id}"
  http_method = "${aws_api_gateway_method.slack-sns-message-action-method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.message_action_lambda.arn}/invocations"
}

# create stage for api gateway
resource "aws_api_gateway_stage" "slack-sns-message-action-stage" {
  stage_name = "prod"
  rest_api_id = "${aws_api_gateway_rest_api.slack-sns-message-action-api.id}"
  deployment_id = "${aws_api_gateway_deployment.slack-sns-message-action-deployment.id}"
}

# create deployment for api gateway
resource "aws_api_gateway_deployment" "slack-sns-message-action-deployment" {
  depends_on = ["aws_api_gateway_integration.slack-sns-message-action-integration"]
  rest_api_id = "${aws_api_gateway_rest_api.slack-sns-message-action-api.id}"
  stage_name = "prod"
}

# permissions for lambda to access apigw
resource "aws_lambda_permission" "message_action_lambda_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.message_action_lambda.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.accountId.account_id}:${aws_api_gateway_rest_api.slack-sns-message-action-api.id}/*/${aws_api_gateway_method.slack-sns-message-action-method.http_method}${aws_api_gateway_resource.slack-sns-message-action-resource.path}"
}

# general iam role for lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
