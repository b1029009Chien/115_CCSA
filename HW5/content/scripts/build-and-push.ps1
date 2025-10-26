<#
build-and-push.ps1
用途: 在本機建置 backend/frontend 映像，標記為 <hubUser>/hw5-api:latest 與 <hubUser>/hw5-web:latest，並推到 Docker Hub。
使用範例:
  # 互動登入並推送到預設使用者 (chien)
  .\build-and-push.ps1 -HubUser chien

  # 只 build 與 tag，不推 (調試用)
  .\build-and-push.ps1 -HubUser yourname -SkipPush

參數:
  -HubUser: Docker Hub 使用者名稱或組織 (required)
  -SkipPush: 若提供則只 build & tag，不執行 push
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$HubUser,

    [switch]$SkipPush
)

function FailIfLastExitNonZero($msg) {
    if ($LASTEXITCODE -ne 0) {
        Write-Error $msg
        exit $LASTEXITCODE
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
# scripts live in HW5/content/scripts so the content dir is one level up
$projectContentDir = Resolve-Path "$scriptDir\.." | Select-Object -ExpandProperty Path
$backendDir = Join-Path $projectContentDir 'backend'
$frontendDir = Join-Path $projectContentDir 'frontend'

Write-Host "Project content dir: $projectContentDir"
Write-Host "Backend dir: $backendDir"
Write-Host "Frontend dir: $frontendDir"

# 建置 backend
Write-Host "Building backend image as $HubUser/hw5-api:latest..."
docker build -t $("$HubUser/hw5-api:latest") $backendDir
FailIfLastExitNonZero "Backend build failed."

# 建置 frontend
Write-Host "Building frontend image as $HubUser/hw5-web:latest..."
docker build -t $("$HubUser/hw5-web:latest") $frontendDir
FailIfLastExitNonZero "Frontend build failed."

# 顯示本地映像清單的重點
Write-Host "Local images (filtered):"
docker images --format "{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}" | Select-String -Pattern "hw5-api|hw5-web|$HubUser" -Quiet | Out-Null
# (上面為簡單提示；您也可以手動執行 `docker images` 來確認)

if (-not $SkipPush) {
    Write-Host "Ensure you're logged into Docker Hub. If not, this will prompt you to login."
    docker login
    FailIfLastExitNonZero "Docker login failed or cancelled."

    Write-Host "Pushing $HubUser/hw5-api:latest..."
    docker push $("$HubUser/hw5-api:latest")
    if ($LASTEXITCODE -ne 0) { Write-Error "Push failed for $HubUser/hw5-api:latest"; exit $LASTEXITCODE }

    Write-Host "Pushing $HubUser/hw5-web:latest..."
    docker push $("$HubUser/hw5-web:latest")
    if ($LASTEXITCODE -ne 0) { Write-Error "Push failed for $HubUser/hw5-web:latest"; exit $LASTEXITCODE }

    Write-Host "Push completed. Verify on Docker Hub (https://hub.docker.com/r/$HubUser/hw5-api and $HubUser/hw5-web)."
} else {
    Write-Host "SkipPush specified — images built & tagged but not pushed."
}
