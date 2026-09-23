import json
import os

import boto3


s3 = boto3.client("s3")

BUCKET_NAME = os.environ["BUCKET_NAME"]


def lambda_handler(event, context):
    failures = []

    for record in event["Records"]:
        message_id = record["messageId"]

        try:
            eventbridge_event = json.loads(record["body"])

            detail = eventbridge_event["detail"]

            object_id = detail.get("id", message_id)

            key = f"objects/{object_id}.json"

            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=key,
                Body=json.dumps(detail).encode("utf-8"),
                ContentType="application/json",
            )

            print(
                json.dumps({
                    "status": "stored",
                    "message_id": message_id,
                    "bucket": BUCKET_NAME,
                    "key": key,
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