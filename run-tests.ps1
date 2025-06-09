# Run tests in pandoc Lua interpreter
param (
    [string]$FilePath = "test.lua"
)
$env = [System.IO.Path]::ChangeExtension($FilePath, '.env')
if (Test-Path $env) {
    $envOpt = "--env-file=$env"
}
docker run --rm -v "$(pwd):/data" $envOpt pandoc/minimal:3.7 --lua-filter=$FilePath
