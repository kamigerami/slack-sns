# This function is invoked via SNS when the CodePipeline manual approval action starts.
# It will take the details from this approval notification and sent an interactive message to Slack that allows users to approve or cancel the deployment.

import os
import json
import logging
import urllib.parse

from base64 import b64decode
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

# This is passed as a plain-text environment variable for ease of demonstration.
# Consider encrypting the value with KMS or use an encrypted parameter in Parameter Store for production deployments.
SLACK_WEBHOOK_URL = os.environ['SLACK_WEBHOOK_URL']
SLACK_CHANNEL = os.environ['SLACK_CHANNEL']

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))
    message = event["Records"][0]["Sns"]["Message"]
    subject = event["Records"][0]["Sns"]['Subject']

    data = json.loads(message)
    token = data["approval"]["token"]
    approval_review_link = data["approval"]["approvalReviewLink"]

    codepipeline_name = data["approval"]["pipelineName"]

    slack_message = {
        "channel": SLACK_CHANNEL,
        "text": subject,
        "attachments": [
            {
                "text": "Yes to deploy your build to production :cloud:",
                "callback_id": "approval-from-slack",
                "fallback": "You are unable to promote a build",
                "color": "warning",
                "attachment_type": "default",
                "title": codepipeline_name,
                "title_link": approval_review_link,
                "thumb_url": "https://a0.awsstatic.com/libra-css/images/logos/aws_logo_smile_1200x630.png",
                "actions": [
                    {
                        "name": "deployment",
                        "text": "Yes",
                        "style": "danger",
                        "type": "button",
                        "value": json.dumps({"approve": True, "codePipelineToken": token, "codePipelineName": codepipeline_name}),
                        "confirm": {
                            "title": "Are you sure?",
                            "text": "This will deploy the build to production",
                            "ok_text": "Yes",
                            "dismiss_text": "No"
                        }
                    },
                    {
                        "name": "deployment",
                        "text": "No",
                        "type": "button",
                        "value": json.dumps({"approve": False, "codePipelineToken": token, "codePipelineName": codepipeline_name})
                    }
                ]
            }
        ]
    }

    req = Request(SLACK_WEBHOOK_URL, json.dumps(slack_message).encode('utf-8'))

    response = urlopen(req)
    response.read()

    return None

