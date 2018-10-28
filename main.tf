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

# message_action lambda
# archive zip file
data "archive_file" "message_action" {
  type        = "zip"
  source_file = "${path.module}/lambda/message_action/message_action.py"
  output_path = "${path.module}/.terraform/archive_files/message_action.zip"
}
