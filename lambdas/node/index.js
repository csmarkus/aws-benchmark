const AWS = require("aws-sdk");
const docClient = new AWS.DynamoDB.DocumentClient();

const TABLE_NAME = process.env.TABLE_NAME;

exports.handler = async (event) => {
  const start = performance.now();

  const queryParams = event.queryStringParameters || {};
  const count = Math.max(1, Math.min(parseInt(queryParams.count || "10", 10), 10000));

  const keys = Array.from({ length: count }, () => ({
    id: `item-${Math.floor(Math.random() * 10000)}`
  }));

  // BatchGetItem supports 100 total items max, 25 per table per batch
  const items = [];
  for (let i = 0; i < keys.length; i += 25) {
    const batch = keys.slice(i, i + 25);

    const params = {
      RequestItems: {
        [TABLE_NAME]: {
          Keys: batch
        }
      }
    };

    try {
      const data = await docClient.batchGet(params).promise();
      items.push(...(data.Responses[TABLE_NAME] || []));
    } catch (err) {
      console.error("BatchGetItem error:", err);
    }
  }

  const internalDuration = performance.now() - start;

  return {
    statusCode: 200,
    body: JSON.stringify({
      count: items.length,
      internal_duration_ms: Math.round(internalDuration),
      items: items
    })
  };
};
