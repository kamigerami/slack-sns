# This function is triggered via API Gateway when a user acts on the Slack interactive message sent by approval_requester.py.

from urllib.parse import parse_qs
import json
import os
import boto3

SLACK_VERIFICATION_TOKEN = os.environ['SLACK_VERIFICATION_TOKEN']

#Triggered by API Gateway
#It kicks off a particular CodePipeline project
def lambda_handler(event, context):
    #print(event)
    body = event['body']

    # load as json
    payload = json.loads(parse_qs(body)['payload'][0])

    # strings
    token = payload['token']
    callback_id = payload['callback_id']
    value = payload['actions'][0]['value']
    response_url = payload['response_url']
    ts = payload['original_message']['ts']
    SLACK_CHANNEL = payload['channel']['name']
    subject = payload['original_message']['text']
    user_name = payload['user']['name']

    codepipeline_name = json.loads(value)['codePipelineName']


    # Validate Slack token
    if SLACK_VERIFICATION_TOKEN == token:
        send_to_codepipeline(user_name, value)

        # This will replace the interactive message with a simple text response.
        # You can implement a more complex message update if you would like.
        slack_message = {
        "text": "The approval has been processed",
        "attachments": [
            {
                "text": ":white_check_mark: {name} approved".format(name=user_name),
                "callback_id": "approval-from-slack",
                "fallback": "The approval has been processed",
                "color": "good",
                "attachment_type": "default",
                "title": codepipeline_name,
                "thumb_url": "https://a0.awsstatic.com/libra-css/images/logos/aws_logo_smile_1200x630.png",
                    }
                ]
            }

        return  {
            "isBase64Encoded": "false",
            "statusCode": 200,
            "body": json.dumps(slack_message)
        }

    else:
        return  {
            "isBase64Encoded": "false",
            "statusCode": 403,
            "body": "{\"error\": \"This request does not include a vailid verification token.\"}"
        }


def send_to_codepipeline(user_name, value):

    # load as dict
    action_details = json.loads(value)
    # create vars
    codepipeline_name = action_details["codePipelineName"]

    # initiate boto3 client for codepipeline
    client = boto3.client('codepipeline')

    # check if we approved or rejected

    if action_details['approve']:
        codepipeline_status = "Approved"
    else:
        codepipeline_status = "Rejected"

    # get the state of the pipeline
    state = client.get_pipeline_state(name=codepipeline_name)
    # get the stage states of the pipeline
    stage_states = state['stageStates']

    # loop through each index in stages and check for stage thats  'InProgress'
    for index in range(len(stage_states)):
        for index_two in range(len(stage_states[index]['actionStates'])):
          # get token for the stage that is currently in progress
          if 'InProgress' in stage_states[index]['actionStates'][index_two]['latestExecution']['status']:
            # save token, stage_name, action_name
            token = stage_states[index]['actionStates'][index_two]['latestExecution']['token']
            stage_name = stage_states[index]['stageName']
            action_name = stage_states[index]['actionStates'][index_two]['actionName']
            approve_or_deny(client, codepipeline_name, stage_name, action_name, token, user_name, codepipeline_status)
            break



def approve_or_deny(client, codepipeline_name, stage_name, action_name, token, user_name, codepipeline_status):
    client.put_approval_result(
        pipelineName=codepipeline_name,
        stageName=stage_name,
        actionName=action_name,
        result={
            'summary': 'Reviewed by' + user_name,
            'status': codepipeline_status
        },
        token=token
    )
