import requests
import time

lambda_urls = {
    "dotnet":       "https://your-url/benchmark-dotnet",
    "dotnet-aot":   "https://your-url/benchmark-dotnet-aot",
    "dotnet-aot-ss":"https://your-url/benchmark-dotnet-aot-ss",
    "node":         "https://your-url/benchmark-node",
    "node-ss":      "https://your-url/benchmark-node-ss",
    "python":       "https://your-url/benchmark-python",
    "python-ss":    "https://your-url/benchmark-python-ss"
}

counts = [10, 100, 1000, 10000]

for count in counts:
    print(f"\n=== Benchmarking {count} items ===")
    for name, url in lambda_urls.items():
        full_url = f"{url}?count={count}"
        try:
            start = time.perf_counter()
            response = requests.get(full_url)
            total_time = (time.perf_counter() - start) * 1000
            response.raise_for_status()

            data = response.json()
            print(f"{name.ljust(15)} | Total: {total_time:.2f} ms | Internal: {data.get('internal_duration_ms')} ms | Items: {data.get('count')}")
        except Exception as e:
            print(f"{name.ljust(15)} | ERROR: {str(e)}")
