import os
import boto3


def lambda_handler(event, context):
    event_id = event["id"]
    visit_count = 0

    # Create a Dynamodb client
    dynamodb = boto3.resource('dynamodb')
    table_name = os.environ["TABLE_NAME"]
    table = dynamodb.Table(table_name)

    # Get the current visit count if it exist
    response = table.get_item(Key={"id": event_id})
    if "Item" in response:
        visit_count = response["Item"]["count"]

    # Increment the number of visits by 1.
    visit_count += 1

    # Put the new visit count into the table.
    response = table.put_item(Item={"id": event_id, "count": visit_count})

    return {
        "statusCode": response['ResponseMetadata']['HTTPStatusCode'],
        'headers': {
            "Access-Control-Allow-Origin": 'origin'
        },
        'body': str(visit_count)
    }
