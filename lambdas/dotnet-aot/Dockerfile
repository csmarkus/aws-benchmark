FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Install Native AOT prerequisites
RUN apt-get update && \
    apt-get install -y clang zlib1g-dev libicu-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Copy the .csproj and restore
COPY BenchmarkLambdaAot.csproj ./
RUN dotnet restore

# Copy everything else and publish
COPY . ./
RUN dotnet publish -c Release -r linux-x64 --self-contained true /p:PublishAot=true -o /app

# Final zip step for Lambda
WORKDIR /app
RUN apt-get update && apt-get install -y zip && \
    mkdir -p /publish && \
    zip -r /publish/lambda-aot.zip . && \
    echo "✅ Lambda zipped to /publish/lambda-aot.zip"
