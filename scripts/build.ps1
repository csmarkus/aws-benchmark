# Ensure script stops on errors
$ErrorActionPreference = "Stop"

Write-Host "📦 Packaging Lambda projects..." -ForegroundColor Cyan

# Paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$basePath = Resolve-Path (Join-Path $scriptDir "..")
$lambdasPath = Join-Path $basePath "lambdas"

# Ensure lambdas directory exists
if (!(Test-Path $lambdasPath)) {
    New-Item -ItemType Directory -Path $lambdasPath | Out-Null
}

# --- Check for AWS Lambda Tools ---
Write-Host "`n🔍 Checking for AWS Lambda Tools CLI..."
$lambdaToolInstalled = dotnet tool list -g | Select-String "amazon.lambda.tools"
if (-not $lambdaToolInstalled) {
    Write-Host "❌ AWS Lambda Tools CLI not found." -ForegroundColor Red
    Write-Host "👉 Install it with: dotnet tool install -g Amazon.Lambda.Tools"
    exit 1
}

# --- Node.js Lambda ---
$nodePath = Join-Path $lambdasPath "node"
$nodeZip = Join-Path $lambdasPath "node.zip"

Write-Host "`n🔧 Zipping Node.js Lambda..."
Push-Location $nodePath
if (Test-Path $nodeZip) { Remove-Item $nodeZip }
Compress-Archive -Path * -DestinationPath $nodeZip
Pop-Location
Write-Host "✅ Node.js zipped: $nodeZip"

# --- Python Lambda ---
$pythonPath = Join-Path $lambdasPath "python"
$pythonZip = Join-Path $lambdasPath "python.zip"

Write-Host "`n🐍 Zipping Python Lambda..."
Push-Location $pythonPath
if (Test-Path $pythonZip) { Remove-Item $pythonZip }
Compress-Archive -Path * -DestinationPath $pythonZip
Pop-Location
Write-Host "✅ Python zipped: $pythonZip"

# --- .NET Lambda (non-AOT) ---
$dotnetPath = Join-Path $lambdasPath "dotnet"
$dotnetZip = Join-Path $lambdasPath "dotnet.zip"

Write-Host "`n🛠 Packaging .NET (no AOT) Lambda..."
Push-Location $dotnetPath
if (Test-Path $dotnetZip) { Remove-Item $dotnetZip }

try {
    dotnet lambda package -c Release -o $dotnetZip
    Write-Host "✅ .NET packaged: $dotnetZip"
} catch {
    Write-Host "❌ .NET (no AOT) packaging failed. Skipping zip creation." -ForegroundColor Red
}
Pop-Location

# --- .NET AOT Lambda ---
Write-Host "`n🐳 Building .NET AOT Lambda via Docker..."
$dockerfilePath = Join-Path $lambdasPath "dotnet-aot"
$dotnetAotZip = Join-Path $lambdasPath "dotnet-aot.zip"

Push-Location $dockerfilePath
try {
    docker build -t lambda-aot-builder .
    docker create --name lambda-aot lambda-aot-builder | Out-Null

    if (Test-Path $dotnetAotZip) { Remove-Item $dotnetAotZip }

    docker cp lambda-aot:/publish/lambda-aot.zip $dotnetAotZip
    docker rm lambda-aot | Out-Null

    Write-Host "✅ .NET AOT Docker-built and zipped: $dotnetAotZip"
} catch {
    Write-Host "❌ Docker-based .NET AOT packaging failed. Skipping zip creation." -ForegroundColor Red
}
Pop-Location

Write-Host "`n🎉 All Lambda packages processed!" -ForegroundColor Green
