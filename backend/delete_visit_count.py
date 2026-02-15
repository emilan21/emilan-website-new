import os
import boto3


def lambda_handler(event, context):
    event_id = event["id"]

    # Create a Dynamodb client
    dynamodb = boto3.resource('dynamodb')
    table_name = os.environ["TABLE_NAME"]
    table = dynamodb.Table(table_name)

    # Get the current visit count if it exist
    response = table.get_item(Key={"id": event_id})
    if "Item" in response:
        del_response = table.delete_item(Key={"id": event_id})
        return {
            "statusCode": del_response['ResponseMetadata']['HTTPStatusCode'],
            'body': 'Record ' + str(event_id) + ' deleted'
        }
    else:
        return {'statusCode': '404', 'body': 'Not found'}
