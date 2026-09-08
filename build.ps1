# build.ps1 - Gorgon Pure Wyrm Library Build and Test Script
# Always clears compiler cache and temporary artifacts after execution.

param (
    [switch]$RunExample,
    [switch]$RunCli,
    [switch]$Clean
)

function Clear-Cache {
    Write-Host "[Gorgon] Cleaning compiler cache and temporary build artifacts..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 400
    Get-ChildItem -Path . -Recurse -Include "*_temp.ll", "*_run.exe", "*.o", "*.obj", "test_sample*.*" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "[Gorgon] Cache cleared." -ForegroundColor Green
}

if ($Clean) {
    Clear-Cache
    exit 0
}

try {
    if ($RunCli) {
        Write-Host "[Gorgon] Running CLI Utility (utils/cli.wyr)..." -ForegroundColor Cyan
        wyrmc run utils/cli.wyr
    } else {
        Write-Host "[Gorgon] Running Example Demonstration (examples/example.wyr)..." -ForegroundColor Cyan
        wyrmc run examples/example.wyr
    }
}
finally {
    Clear-Cache
}
