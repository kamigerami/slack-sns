# Archive a single file

data "archive_file" "approval" {
  type        = "zip"
  source_file = "${path.module}/lambda/approval/approval.py"
  output_path = "${path.module}/.terraform/archive_files/approval.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename         = "${data.archive_file.approval.output_path}"
  function_name    = "approval"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "approval.lambda_handler"
  source_code_hash = "${data.archive_file.approval.output_base64sha256}"
  runtime          = "python3.6"

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "bar",
      SLACK_CHANNEL = "foo"
    }
  }
}

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
