import os
import boto3


def lambda_handler(event, context):
    event_id = event["id"]

    # Create a Dynamodb client
    dynamodb = boto3.resource('dynamodb')
    table_name = os.environ["TABLE_NAME"]
    table = dynamodb.Table(table_name)

    # Get the current visit count
    response = table.get_item(Key={"id": event_id})
    if "Item" in response:
        return {
            'statusCode': '200',
            'headers': {
                "Access-Control-Allow-Origin": 'origin'
            },
            'body': response["Item"]
        }
    else:
        return {'statusCode': '404', 'body': 'Not found'}
