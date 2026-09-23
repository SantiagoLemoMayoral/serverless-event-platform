import json
import os

import boto3


eventbridge = boto3.client("events")

EVENT_BUS_NAME = os.environ["EVENT_BUS_NAME"]

ROUTES = {
    "object": "object.created",
    "metadata": "metadata.created",
}


def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")

        event_type = body.get("type")
        data = body.get("data")

        if event_type not in ROUTES:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "type must be 'object' or 'metadata'"
                }),
            }

        if data is None:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "data is required"
                }),
            }

        response = eventbridge.put_events(
            Entries=[
                {
                    "Source": "serverless.api",
                    "DetailType": ROUTES[event_type],
                    "Detail": json.dumps(data),
                    "EventBusName": EVENT_BUS_NAME,
                }
            ]
        )

        if response["FailedEntryCount"] > 0:
            raise RuntimeError("Failed to publish EventBridge event")

        return {
            "statusCode": 202,
            "body": json.dumps({
                "accepted": True,
                "event_type": ROUTES[event_type],
            }),
        }

    except Exception as exc:
        print(f"handler_error={exc}")

        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "internal server error"
            }),
        }