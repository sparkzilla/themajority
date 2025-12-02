# Hugo Installation Script for Windows
$ProgressPreference = 'SilentlyContinue'

Write-Host "Installing Hugo..." -ForegroundColor Green

# Get the latest Hugo version
$latestVersion = "0.128.0"
$hugoUrl = "https://github.com/gohugoio/hugo/releases/download/v$latestVersion/hugo_extended_$latestVersion_windows-amd64.zip"
$tempDir = "$env:TEMP\hugo-install"
$zipFile = "$tempDir\hugo.zip"
$extractPath = "$tempDir\hugo"

# Create temp directory
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Download Hugo
Write-Host "Downloading Hugo v$latestVersion..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $hugoUrl -OutFile $zipFile -ErrorAction Stop
    Write-Host "Download complete!" -ForegroundColor Green
} catch {
    Write-Host "Failed to download from primary URL. Trying alternative..." -ForegroundColor Yellow
    # Try without version prefix
    $hugoUrl = "https://github.com/gohugoio/hugo/releases/download/v$latestVersion/hugo_extended_${latestVersion}_windows-amd64.zip"
    Invoke-WebRequest -Uri $hugoUrl -OutFile $zipFile
}

# Extract Hugo
Write-Host "Extracting Hugo..." -ForegroundColor Yellow
Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force

# Add to PATH (current session)
$hugoExe = Get-ChildItem -Path $extractPath -Filter "hugo.exe" -Recurse | Select-Object -First 1
if ($hugoExe) {
    $hugoDir = $hugoExe.DirectoryName
    $env:Path += ";$hugoDir"
    Write-Host "Hugo installed to: $hugoDir" -ForegroundColor Green
    
    # Add to user PATH permanently
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$hugoDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$hugoDir", "User")
        Write-Host "Added Hugo to PATH permanently" -ForegroundColor Green
    }
    
    # Verify installation
    & "$hugoExe.FullName" version
    Write-Host "`nHugo installation complete!" -ForegroundColor Green
} else {
    Write-Host "Error: Could not find hugo.exe after extraction" -ForegroundColor Red
    exit 1
}


