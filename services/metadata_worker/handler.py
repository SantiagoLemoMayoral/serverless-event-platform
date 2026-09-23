import json
import os
from datetime import datetime, timezone

import boto3


dynamodb = boto3.resource("dynamodb")

table = dynamodb.Table(
    os.environ["TABLE_NAME"]
)


def lambda_handler(event, context):
    failures = []

    for record in event["Records"]:
        message_id = record["messageId"]

        try:
            eventbridge_event = json.loads(record["body"])

            detail = eventbridge_event["detail"]

            item_id = detail.get("id", message_id)

            table.put_item(
                Item={
                    "id": item_id,
                    "payload": detail,
                    "received_at": datetime.now(
                        timezone.utc
                    ).isoformat(),
                }
            )

            print(
                json.dumps({
                    "status": "stored",
                    "message_id": message_id,
                    "id": item_id,
                })
            )

        except Exception as exc:
            print(
                json.dumps({
                    "status": "failed",
                    "message_id": message_id,
                    "error": str(exc),
                })
            )

            failures.append({
                "itemIdentifier": message_id
            })

    return {
        "batchItemFailures": failures
    }