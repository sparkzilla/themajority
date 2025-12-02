# Script to find and fix broken image links in article content
# Downloads images from WordPress URLs and updates links to local paths

$ErrorActionPreference = "Continue"
$baseUrl = "https://themajority.scot"
$postsDir = "content\posts"
$imagesDir = "static\images\posts"

# Create images directory if it doesn't exist
if (-not (Test-Path $imagesDir)) {
    New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null
}

# Get all markdown files
$postFiles = Get-ChildItem -Path $postsDir -Filter "*.md"

Write-Host "Scanning $($postFiles.Count) posts for image links...`n"

$fixed = 0
$downloaded = 0
$errors = 0

foreach ($file in $postFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $modified = $false
    
    # Find all WordPress image URLs in the content
    $imagePattern = 'https?://themajority\.scot/wp-content/uploads/([^")\s]+\.(jpg|jpeg|png|gif|webp))'
    $matches = [regex]::Matches($content, $imagePattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    if ($matches.Count -gt 0) {
        Write-Host "[FIX] $($file.Name) - Found $($matches.Count) image(s)"
        
        foreach ($match in $matches) {
            $imageUrl = $match.Value
            $imagePath = $match.Groups[1].Value
            
            # Generate local filename
            $urlParts = $imageUrl -split '/'
            $filename = $urlParts[-1]
            # Remove any size suffix if present
            $filename = $filename -replace '-\d+x\d+\.', '.'
            $localPath = Join-Path $imagesDir $filename
            $localUrl = "/images/posts/$filename"
            
            # Download image if it doesn't exist
            if (-not (Test-Path $localPath)) {
                try {
                    Write-Host "      Downloading: $filename"
                    Invoke-WebRequest -Uri $imageUrl -OutFile $localPath -TimeoutSec 30 -ErrorAction Stop
                    $downloaded++
                }
                catch {
                    Write-Host "      ERROR downloading $imageUrl : $($_.Exception.Message)"
                    $errors++
                    continue
                }
            }
            
            # Replace URL in content
            $content = $content -replace [regex]::Escape($imageUrl), $localUrl
            $modified = $true
        }
        
        if ($modified) {
            # Also fix img src attributes
            $content = $content -replace 'src="https://themajority\.scot/wp-content/uploads/([^"]+)"', 'src="/images/posts/$1"'
            
            # Fix markdown image syntax
            $content = $content -replace '!\[([^\]]+)\]\(https://themajority\.scot/wp-content/uploads/([^\)]+)\)', '![$1](/images/posts/$2)'
            
            Set-Content -Path $file.FullName -Value $content -NoNewline
            $fixed++
            Write-Host "      Updated $($file.Name)`n"
        }
    }
}

Write-Host "`n=== Summary ==="
Write-Host "Files fixed: $fixed"
Write-Host "Images downloaded: $downloaded"
Write-Host "Errors: $errors"


