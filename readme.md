```
# in progress 

# todo
- add chat.update using slackclient
- fix method responses / integrationr responses

# pre-req

# create slack app

# set aws ssm parameter store values for
SLACK_VERIFICATION_TOKEN
SLACK_WEBHOOK_URL 

#channel you want to post to
SLACK_CHANNEL 

# setup terraform aws provider credentials
# update variables.tf with ${aws_region} and ${slack_channel}

# run terraform

terraform init
terraform plan
terraform apply

# use output from api gateway endpoint to update
# your slack app interactive components section Request url

Outputs:

Add this as your Request URL to SLACK interactive components section = https://xxxxxx.execute-api.us-east-1.amazonaws.com/prod/message_action

# create a codepipeline manual approval step
# subscribe to sns that terraform created

# run pipeline and watch the notification in your slack channel

```
