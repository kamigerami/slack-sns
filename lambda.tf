resource "aws_lambda_function" "approval_lambda" {
  filename         = "${data.archive_file.approval.output_path}"
  function_name    = "sns-approval"
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

resource "aws_lambda_function" "message_action_lambda" {
  filename         = "${data.archive_file.message_action.output_path}"
  function_name    = "sns-message_action"
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

# permissions for lambda to access apigw
resource "aws_lambda_permission" "message_action_lambda_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.message_action_lambda.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.accountId.account_id}:${aws_api_gateway_rest_api.slack-sns-message-action-api.id}/*/${aws_api_gateway_method.slack-sns-message-action-method.http_method}${aws_api_gateway_resource.slack-sns-message-action-resource.path}"
}
