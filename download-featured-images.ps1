# Script to download featured images from WordPress site at 1200x600
# and update Hugo posts with local image paths

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

# Get all markdown files
$postFiles = Get-ChildItem -Path $postsDir -Filter "*.md"

Write-Host "Found $($postFiles.Count) post files"
Write-Host "Starting download process...`n"

$downloaded = 0
$skipped = 0
$errors = 0

foreach ($file in $postFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    
    # Check if post already has a local featuredImage
    if ($content -match 'featuredImage\s*=\s*"([^"]+)"') {
        $currentImage = $matches[1]
        
        # Skip if already using local path
        if ($currentImage -notmatch '^https?://') {
            Write-Host "[SKIP] $($file.Name) - already has local image"
            $skipped++
            continue
        }
        
        # Extract the image URL
        $imageUrl = $currentImage
        
        # Try to get 1200x600 variant first
        $imageUrl1200x600 = $imageUrl -replace '\.(jpg|jpeg|png)$', '-1200x600.$1'
        
        # Generate local filename
        $urlParts = $imageUrl -split '/'
        $filename = $urlParts[-1]
        # Remove any size suffix if present
        $filename = $filename -replace '-\d+x\d+\.', '.'
        # Add 1200x600 suffix
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filename)
        $extension = [System.IO.Path]::GetExtension($filename)
        $localFilename = "${baseName}-1200x600${extension}"
        $localPath = Join-Path $imagesDir $localFilename
        
        try {
            # Try downloading 1200x600 variant first
            try {
                Write-Host "[TRY] $($file.Name) - Attempting 1200x600 variant..."
                Invoke-WebRequest -Uri $imageUrl1200x600 -OutFile $localPath -ErrorAction Stop
                Write-Host "[OK]  $($file.Name) - Downloaded 1200x600 variant"
            }
            catch {
                # If 1200x600 doesn't exist, try full size
                Write-Host "[TRY] $($file.Name) - 1200x600 not found, trying full size..."
                Invoke-WebRequest -Uri $imageUrl -OutFile $localPath -ErrorAction Stop
                
                # Resize to 1200x600 using .NET
                Write-Host "[RESIZE] $($file.Name) - Resizing to 1200x600..."
                Add-Type -AssemblyName System.Drawing
                $img = [System.Drawing.Image]::FromFile($localPath)
                $newImg = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
                $graphics = [System.Drawing.Graphics]::FromImage($newImg)
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.DrawImage($img, 0, 0, $targetWidth, $targetHeight)
                
                # Save resized image
                $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
                $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
                $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 90)
                $newImg.Save($localPath, $encoder, $encoderParams)
                
                $graphics.Dispose()
                $newImg.Dispose()
                $img.Dispose()
                Write-Host "[OK]  $($file.Name) - Resized to 1200x600"
            }
            
            # Update the markdown file with local path
            $localImagePath = "/images/posts/$localFilename"
            $newContent = $content -replace 'featuredImage\s*=\s*"[^"]+"', "featuredImage = `"$localImagePath`""
            Set-Content -Path $file.FullName -Value $newContent -NoNewline
            $downloaded++
        }
        catch {
            Write-Host "[ERROR] $($file.Name) - Failed to download: $($_.Exception.Message)"
            $errors++
        }
    }
    else {
        # No featuredImage found - try to get it from the live site
        # Extract slug from filename
        $slug = $file.BaseName -replace '-2$', '' -replace '-1$', ''
        
        # Try to fetch from live site (this is optional - you might want to skip this)
        Write-Host "[SKIP] $($file.Name) - No featuredImage in front matter"
        $skipped++
    }
}

Write-Host "`n=== Summary ==="
Write-Host "Downloaded: $downloaded"
Write-Host "Skipped: $skipped"
Write-Host "Errors: $errors"
