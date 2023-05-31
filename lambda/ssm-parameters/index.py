import json
import boto3

print('fetching parameters')

ssm_client = boto3.client('ssm')

def get_parameter(name):
    parameter = ssm_client.get_parameter(Name=name)
    return parameter['Parameter']['Value']


def lambda_handler(event, context):
    #print("Received event: " + json.dumps(event, indent=2))
    return get_parameter(event['parameter']) 
    #raise Exception('Something went wrong')