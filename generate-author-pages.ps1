# Script to generate author pages from data/authors.yaml
# This creates markdown files in content/authors/ for each author

$authorsFile = "data/authors.yaml"
$outputDir = "content/authors"

# Create authors directory if it doesn't exist
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    Write-Host "Created directory: $outputDir"
}

# Read the authors YAML file
$content = Get-Content $authorsFile -Raw

# Parse YAML (simple parsing for this format)
$lines = Get-Content $authorsFile
$authors = @{}

foreach ($line in $lines) {
    $line = $line.Trim()
    # Skip comments and empty lines
    if ($line -match '^#|^\s*$') {
        continue
    }
    # Match "username: "Display Name""
    if ($line -match '^([^:]+):\s*"([^"]+)"') {
        $username = $matches[1].Trim()
        $displayName = $matches[2].Trim()
        $authors[$username] = $displayName
    }
}

# Generate a markdown file for each author
foreach ($username in $authors.Keys) {
    $displayName = $authors[$username]
    $filename = "$outputDir/$username.md"
    
    $frontMatter = @"
+++
title = "$displayName"
slug = "$username"
+++
"@
    
    Set-Content -Path $filename -Value $frontMatter
    Write-Host "Created: $filename"
}

Write-Host "`nGenerated $($authors.Count) author pages in $outputDir"

