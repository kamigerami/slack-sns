# This function is triggered via API Gateway when a user acts on the Slack interactive message sent by approval_requester.py.

from urllib.parse import parse_qs
import json
import os
import boto3

SLACK_VERIFICATION_TOKEN = os.environ['SLACK_VERIFICATION_TOKEN']

#Triggered by API Gateway
#It kicks off a particular CodePipeline project
def lambda_handler(event, context):
    print(event)
    body = event['body']
    # parse query string
    # load as json
    payload = json.loads(parse_qs(body)['payload'][0])
    token = payload['token']
    callback_id = payload['callback_id']
    value = payload['actions'][0]['value']
    response_url = payload['response_url']
    ts = payload['original_message']['ts']
    SLACK_CHANNEL = payload['channel']['name']
    subject = payload['original_message']['text']
    codepipeline_name = json.loads(value)['codePipelineName']


    # Validate Slack token
    if SLACK_VERIFICATION_TOKEN == token:
        send_to_codepipeline(json.loads(value))

        # This will replace the interactive message with a simple text response.
        # You can implement a more complex message update if you would like.
        return  {
            "isBase64Encoded": "false",
            "statusCode": 200,
            "body": "{\"text\": \"The approval has been processed\"}"
        }
    else:
        return  {
            "isBase64Encoded": "false",
            "statusCode": 403,
            "body": "{\"error\": \"This request does not include a vailid verification token.\"}"
        }


def send_to_codepipeline(action_details):
    codepipeline_status = "Approved" if action_details["approve"] else "Rejected"
    codepipeline_name = action_details["codePipelineName"]
    token = action_details["codePipelineToken"]

    client = boto3.client('codepipeline')
    response_approval = client.put_approval_result(
                            pipelineName=codepipeline_name,
                            stageName='Approval',
                            actionName='ApprovalOrDeny',
                            result={'summary':'','status':codepipeline_status},
                            token=token)
    print(response_approval)


