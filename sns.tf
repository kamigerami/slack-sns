resource "aws_sns_topic" "sns_lambda_slack" {
  name         = "sns_lambda_slack"
  display_name = "sns_lambda_slack"
}

resource "aws_sns_topic_subscription" "sns_lambda_slack" {
  topic_arn = "${aws_sns_topic.sns_lambda_slack.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.approval_lambda.arn}"
}
