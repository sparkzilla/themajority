# Script to fetch featured images from WordPress site for all posts,
# add them to front matter, download at 1200x600, and update with local paths

$ErrorActionPreference = "Continue"
$baseUrl = "https://themajority.scot"
$postsDir = "content\posts"
$imagesDir = "static\images\posts"
$targetWidth = 1200
$targetHeight = 600

# Create images directory if it doesn't exist
if (-not (Test-Path $imagesDir)) {
    New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null
    Write-Host "Created directory: $imagesDir"
}

# Load System.Drawing for image resizing
Add-Type -AssemblyName System.Drawing

function Get-FeaturedImageFromSite {
    param(
        [string]$slug
    )
    
    try {
        # Try different URL patterns
        $urls = @(
            "https://themajority.scot/blog/$slug/",
            "https://themajority.scot/$slug/",
            "https://themajority.scot/blog/$slug"
        )
        
        foreach ($url in $urls) {
            try {
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
                $html = $response.Content
                
                # Try og:image first (most reliable)
                if ($html -match 'og:image.*content="([^"]+)"') {
                    return $matches[1]
                }
                
                # Try twitter:image
                if ($html -match 'twitter:image.*content="([^"]+)"') {
                    return $matches[1]
                }
                
                # Try to find featured image in img tag with wp-post-image class
                if ($html -match 'class="[^"]*wp-post-image[^"]*".*src="([^"]+)"') {
                    return $matches[1]
                }
            }
            catch {
                continue
            }
        }
    }
    catch {
        return $null
    }
    
    return $null
}

function Download-AndResizeImage {
    param(
        [string]$imageUrl,
        [string]$outputPath
    )
    
    try {
        # Try 1200x600 variant first
        $url1200x600 = $imageUrl -replace '\.(jpg|jpeg|png)$', '-1200x600.$1'
        
        try {
            Invoke-WebRequest -Uri $url1200x600 -OutFile $outputPath -TimeoutSec 30 -ErrorAction Stop
            Write-Host "      Downloaded 1200x600 variant"
            return $true
        }
        catch {
            # Download full size
            Invoke-WebRequest -Uri $imageUrl -OutFile $outputPath -TimeoutSec 30 -ErrorAction Stop
            
            # Resize to 1200x600
            $img = [System.Drawing.Image]::FromFile($outputPath)
            $newImg = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
            $graphics = [System.Drawing.Graphics]::FromImage($newImg)
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.DrawImage($img, 0, 0, $targetWidth, $targetHeight)
            
            # Save resized image to temporary file first
            $tempPath = $outputPath + ".tmp"
            $extension = [System.IO.Path]::GetExtension($outputPath).ToLower()
            
            # Always save as JPEG for consistency
            if ($extension -eq '.png') {
                $outputPath = $outputPath -replace '\.png$', '.jpg'
                $tempPath = $outputPath + ".tmp"
            }
            
            $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
            $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 90)
            
            # Save to temp file first
            $newImg.Save($tempPath, $encoder, $encoderParams)
            
            # Clean up
            $graphics.Dispose()
            $newImg.Dispose()
            $img.Dispose()
            
            # Move temp file to final location
            if (Test-Path $outputPath) {
                Remove-Item $outputPath -Force
            }
            Move-Item $tempPath $outputPath -Force
            
            $graphics.Dispose()
            $newImg.Dispose()
            $img.Dispose()
            Write-Host "      Downloaded and resized to 1200x600"
            return $true
        }
    }
    catch {
        Write-Host "      ERROR: $($_.Exception.Message)"
        return $false
    }
}

# Get all markdown files, sorted by modification time (most recent first)
# For testing: only process 10 most recent
$allPostFiles = Get-ChildItem -Path $postsDir -Filter "*.md" | Sort-Object LastWriteTime -Descending
$postFiles = $allPostFiles | Select-Object -First 10

Write-Host "Testing on 10 most recent posts (out of $($allPostFiles.Count) total)"
Write-Host "Starting process...`n"

$downloaded = 0
$skipped = 0
$errors = 0
$added = 0

foreach ($file in $postFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $frontMatterEnd = $content.IndexOf("+++", 3)
    
    if ($frontMatterEnd -eq -1) {
        Write-Host "[SKIP] $($file.Name) - Invalid front matter"
        $skipped++
        continue
    }
    
    $frontMatter = $content.Substring(0, $frontMatterEnd + 3)
    $body = $content.Substring($frontMatterEnd + 3)
    
    # Check if already has featuredImage
    $hasFeaturedImage = $frontMatter -match 'featuredImage\s*='
    $currentImageUrl = $null
    
    if ($hasFeaturedImage) {
        if ($frontMatter -match 'featuredImage\s*=\s*"([^"]+)"') {
            $currentImageUrl = $matches[1]
            
            # Skip if already local
            if ($currentImageUrl -notmatch '^https?://') {
                Write-Host "[SKIP] $($file.Name) - Already has local image"
                $skipped++
                continue
            }
        }
    }
    
    # Get slug from filename (remove -2, -1 suffixes)
    $slug = $file.BaseName -replace '-2$', '' -replace '-1$', ''
    
    # If no featuredImage, try to get from site
    if (-not $currentImageUrl) {
        Write-Host "[FETCH] $($file.Name) - Getting featured image from site..."
        $currentImageUrl = Get-FeaturedImageFromSite -slug $slug
        
        if (-not $currentImageUrl) {
            Write-Host "[ERROR] $($file.Name) - Could not find featured image"
            $errors++
            continue
        }
        
        Write-Host "      Found: $currentImageUrl"
        $added++
    }
    
    # Generate local filename
    $urlParts = $currentImageUrl -split '/'
    $filename = $urlParts[-1]
    # Remove any size suffix if present
    $filename = $filename -replace '-\d+x\d+\.', '.'
    # Add 1200x600 suffix
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    $extension = [System.IO.Path]::GetExtension($filename)
    $localFilename = "${baseName}-1200x600${extension}"
    $localPath = Join-Path $imagesDir $localFilename
    
    # Download and resize
    Write-Host "[DOWNLOAD] $($file.Name) - $localFilename"
    $success = Download-AndResizeImage -imageUrl $currentImageUrl -outputPath $localPath
    
    if (-not $success) {
        $errors++
        continue
    }
    
    # Update front matter
    $localImagePath = "/images/posts/$localFilename"
    
    if ($hasFeaturedImage) {
        # Update existing
        $newFrontMatter = $frontMatter -replace 'featuredImage\s*=\s*"[^"]+"', "featuredImage = `"$localImagePath`""
    }
    else {
        # Add new - find the closing +++ and insert before it
        $lines = $frontMatter -split "`r?`n"
        $newLines = @()
        $foundClosing = $false
        
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -match '^\+\+\+$' -and $i -gt 0 -and -not $foundClosing) {
                # This is the closing +++, add featuredImage before it
                $newLines += "featuredImage = `"$localImagePath`""
                $foundClosing = $true
            }
            $newLines += $lines[$i]
        }
        
        if (-not $foundClosing) {
            # No closing +++ found, add it
            $newLines += "featuredImage = `"$localImagePath`""
            $newLines += "+++"
        }
        
        $newFrontMatter = $newLines -join "`n"
    }
    
    # Write updated content
    $newContent = $newFrontMatter + $body
    Set-Content -Path $file.FullName -Value $newContent -NoNewline
    
    $downloaded++
    
    # Small delay to avoid overwhelming the server
    Start-Sleep -Milliseconds 200
}

Write-Host "`n=== Summary ==="
Write-Host "Downloaded: $downloaded"
Write-Host "Added from site: $added"
Write-Host "Skipped: $skipped"
Write-Host "Errors: $errors"

