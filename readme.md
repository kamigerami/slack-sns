```
# in progress 

# pre-req

# create slack app

# set aws ssm parameter store values for
SLACK_VERIFICATION_TOKEN
SLACK_WEBHOOK_URL 

#channel you want to post to
SLACK_CHANNEL 

# setup terraform aws provider credentials

# run terraform

terraform init
terraform plan
terraform apply

# use output from api gateway endpoint to update
# your slack app message_actions url

# create a codepipeline manual approval step
# subscribe to sns that terraform created

# run pipeline and watch the notification in slack

```
