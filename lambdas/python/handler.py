import json
import os
import time
import boto3
import random

TABLE_NAME = os.environ['TABLE_NAME']
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    start = time.perf_counter()

    query = event.get("queryStringParameters", {}) or {}
    count = int(query.get("count", "10"))
    count = max(1, min(count, 10000))  # Clamp value between 1 and 10,000

    keys = [{"id": f"item-{i}"} for i in random.sample(range(10000), count)]

    # Batch read (25 items max per batch)
    items = []
    for i in range(0, len(keys), 25):
        batch_keys = keys[i:i+25]
        response = dynamodb.batch_get_item(
            RequestItems={
                TABLE_NAME: {"Keys": batch_keys}
            }
        )
        items.extend(response['Responses'].get(TABLE_NAME, []))

    internal_duration = (time.perf_counter() - start) * 1000

    return {
        "statusCode": 200,
        "body": json.dumps({
            "count": len(items),
            "internal_duration_ms": round(internal_duration, 2),
            "items": items
        })
    }
