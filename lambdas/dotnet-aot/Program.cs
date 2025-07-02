using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Amazon.Lambda.APIGatewayEvents;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;

var handler = async (APIGatewayProxyRequest request, ILambdaContext context) =>
{
    var tableName = Environment.GetEnvironmentVariable("TABLE_NAME")!;
    var client = new AmazonDynamoDBClient();
    var sw = Stopwatch.StartNew();

    var count = 10;
    if (request.QueryStringParameters?.TryGetValue("count", out var countStr) == true)
        int.TryParse(countStr, out count);
    count = Math.Clamp(count, 1, 10000);

    var random = new Random();
    var keys = Enumerable.Range(0, count)
        .Select(_ => new Dictionary<string, AttributeValue>
        {
            ["id"] = new AttributeValue { S = $"item-{random.Next(10000)}" }
        }).ToList();

    var items = new List<Dictionary<string, AttributeValue>>();
    for (int i = 0; i < keys.Count; i += 25)
    {
        var batch = keys.Skip(i).Take(25).ToList();
        var response = await client.BatchGetItemAsync(new BatchGetItemRequest
        {
            RequestItems = new Dictionary<string, KeysAndAttributes>
            {
                [tableName] = new KeysAndAttributes { Keys = batch }
            }
        });

        if (response.Responses.TryGetValue(tableName, out var results))
            items.AddRange(results);
    }

    sw.Stop();

    var responseBody = new
    {
        count = items.Count,
        internal_duration_ms = sw.Elapsed.TotalMilliseconds,
        items = items.Select(i => new { id = i["id"].S, value = i["value"].S })
    };

    return new APIGatewayProxyResponse
    {
        StatusCode = 200,
        Body = JsonSerializer.Serialize(responseBody),
        Headers = new Dictionary<string, string> { { "Content-Type", "application/json" } }
    };
};

await LambdaBootstrapBuilder.Create(handler, new DefaultLambdaJsonSerializer())
    .Build()
    .RunAsync();
