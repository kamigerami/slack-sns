# account
resource "aws_api_gateway_account" "slack-sns-message-action-account" {
  cloudwatch_role_arn = "${aws_iam_role.iam_for_lambda.arn}"
}

# api gateway for message_actions
resource "aws_api_gateway_rest_api" "slack-sns-message-action-api" {
  name        = "slack-sns-message-action"
  description = "Slack sns message action response url for yes or no button"
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
  http_method   = "POST"
  authorization = "NONE"
}
# create method settings for api gateway
resource "aws_api_gateway_method_settings" "slack-sns-message-action-method-settings" {
  rest_api_id = "${aws_api_gateway_rest_api.slack-sns-message-action-api.id}"
  stage_name  = "${aws_api_gateway_deployment.slack-sns-message-action-deployment.stage_name}"
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
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.message_action_lambda.arn}/invocations"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  # Transforms the incoming x-www-form-urlencode request to JSON
  request_templates {
    "application/x-www-form-urlencoded" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }
}

# gateway method response 200
resource "aws_api_gateway_method_response" "method-response-200" {
  rest_api_id = "${aws_api_gateway_rest_api.slack-sns-message-action-api.id}"
  resource_id = "${aws_api_gateway_resource.slack-sns-message-action-resource.id}"
  http_method = "${aws_api_gateway_method.slack-sns-message-action-method.http_method}"
  status_code = "200"
  depends_on  = ["aws_api_gateway_integration.slack-sns-message-action-integration"]
}

# gateway method response 400
resource "aws_api_gateway_method_response" "method-response-400" {
  rest_api_id = "${aws_api_gateway_rest_api.slack-sns-message-action-api.id}"
  resource_id = "${aws_api_gateway_resource.slack-sns-message-action-resource.id}"
  http_method = "${aws_api_gateway_method.slack-sns-message-action-method.http_method}"
  status_code = "400"
  depends_on  = ["aws_api_gateway_integration.slack-sns-message-action-integration"]
}

# gateway integration response 200
resource "aws_api_gateway_integration_response" "integration-response-200" {
  rest_api_id = "${aws_api_gateway_rest_api.slack-sns-message-action-api.id}"
  resource_id = "${aws_api_gateway_resource.slack-sns-message-action-resource.id}"
  http_method = "${aws_api_gateway_method.slack-sns-message-action-method.http_method}"
  status_code = "${aws_api_gateway_method_response.method-response-200.status_code}"
  depends_on  = ["aws_api_gateway_integration.slack-sns-message-action-integration"]


  response_templates {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
EOF
  }
}
# gateway integration response 400
resource "aws_api_gateway_integration_response" "integration-response-400" {
  rest_api_id       = "${aws_api_gateway_rest_api.slack-sns-message-action-api.id}"
  resource_id       = "${aws_api_gateway_resource.slack-sns-message-action-resource.id}"
  http_method       = "${aws_api_gateway_method.slack-sns-message-action-method.http_method}"
  status_code       = "${aws_api_gateway_method_response.method-response-400.status_code}"
  selection_pattern = ".+"
  depends_on  = ["aws_api_gateway_integration.slack-sns-message-action-integration"]

  response_templates {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
{
    "text": "Sorry, but there was a problem running your command: $inputRoot.errorMessage"
}
EOF
  }
}

# create deployment for api gateway
resource "aws_api_gateway_deployment" "slack-sns-message-action-deployment" {
  depends_on = ["aws_api_gateway_integration.slack-sns-message-action-integration"]
  rest_api_id = "${aws_api_gateway_rest_api.slack-sns-message-action-api.id}"
  stage_name = "prod"
}

# output for the gateway
output "Add this as your Request URL to SLACK interactive components section" {
  value = "https://${aws_api_gateway_deployment.slack-sns-message-action-deployment.rest_api_id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_deployment.slack-sns-message-action-deployment.stage_name}/${aws_api_gateway_resource.slack-sns-message-action-resource.path_part}"
}
