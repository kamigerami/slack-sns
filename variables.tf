variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-east-1"
}

variable "slack_channel" {
  description = "The Slack #channel to post the sns to"
  default = "aws-codecommit"
}
