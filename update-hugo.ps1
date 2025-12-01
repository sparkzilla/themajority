# Update Hugo to Latest Version
$ProgressPreference = 'SilentlyContinue'

Write-Host "Updating Hugo to latest version..." -ForegroundColor Green

# Get latest Hugo version from GitHub API
$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/gohugoio/hugo/releases/latest"
$latestVersion = $latestRelease.tag_name -replace 'v', ''
Write-Host "Latest Hugo version: $latestVersion" -ForegroundColor Yellow

$hugoUrl = "https://github.com/gohugoio/hugo/releases/download/v$latestVersion/hugo_extended_$latestVersion_windows-amd64.zip"
$tempDir = "$env:TEMP\hugo-install"
$zipFile = "$tempDir\hugo.zip"
$extractPath = "$tempDir\hugo"

# Create temp directory
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Download Hugo
Write-Host "Downloading Hugo v$latestVersion..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $hugoUrl -OutFile $zipFile

# Extract Hugo
Write-Host "Extracting Hugo..." -ForegroundColor Yellow
Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force

# Add to PATH (current session)
$hugoExe = Get-ChildItem -Path $extractPath -Filter "hugo.exe" -Recurse | Select-Object -First 1
if ($hugoExe) {
    $hugoDir = $hugoExe.DirectoryName
    $env:Path = ($env:Path -replace [regex]::Escape("$env:TEMP\hugo-install\hugo"), "") -replace ";;", ";"
    $env:Path += ";$hugoDir"
    Write-Host "Hugo updated to: $hugoDir" -ForegroundColor Green
    
    # Update user PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $userPath = $userPath -replace [regex]::Escape("$env:TEMP\hugo-install\hugo"), ""
    $userPath = $userPath.TrimEnd(';')
    if ($userPath -notlike "*$hugoDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$hugoDir", "User")
    } else {
        [Environment]::SetEnvironmentVariable("Path", $userPath, "User")
    }
    
    # Verify installation
    & $hugoExe.FullName version
    Write-Host "`nHugo update complete!" -ForegroundColor Green
}

