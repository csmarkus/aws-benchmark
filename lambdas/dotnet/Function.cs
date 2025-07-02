using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Amazon.Lambda.APIGatewayEvents;
using Amazon.Lambda.Core;
using System.Diagnostics;
using System.Text.Json;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

public class Function
{
    private static readonly string TableName = Environment.GetEnvironmentVariable("TABLE_NAME")!;
    private readonly IAmazonDynamoDB _dynamo = new AmazonDynamoDBClient();

    public async Task<APIGatewayProxyResponse> FunctionHandler(APIGatewayProxyRequest request, ILambdaContext context)
    {
        var sw = Stopwatch.StartNew();

        var count = 10;
        if (request.QueryStringParameters?.TryGetValue("count", out var countStr) == true)
            int.TryParse(countStr, out count);
        count = Math.Clamp(count, 1, 10000);

        var random = new Random();
        var keys = Enumerable.Range(0, count)
                             .Select(_ => new Dictionary<string, AttributeValue>
                             {
                                 { "id", new AttributeValue { S = $"item-{random.Next(10000)}" } }
                             })
                             .ToList();

        var items = new List<Dictionary<string, AttributeValue>>();

        for (int i = 0; i < keys.Count; i += 25)
        {
            var batch = keys.Skip(i).Take(25).ToList();
            var requestBatch = new BatchGetItemRequest
            {
                RequestItems = new Dictionary<string, KeysAndAttributes>
                {
                    [TableName] = new KeysAndAttributes { Keys = batch }
                }
            };

            var response = await _dynamo.BatchGetItemAsync(requestBatch);
            if (response.Responses.TryGetValue(TableName, out var resultItems))
                items.AddRange(resultItems);
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
    }
}
