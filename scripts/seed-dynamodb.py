import boto3

TABLE_NAME = "benchmark-items"
ITEM_COUNT = 10000

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

print(f"Seeding {ITEM_COUNT} items into table: {TABLE_NAME}")
with table.batch_writer() as batch:
    for i in range(ITEM_COUNT):
        batch.put_item(Item={
            "id": f"item-{i}",
            "value": f"This is test item number {i}"
        })

print("✅ Seeding complete.")
