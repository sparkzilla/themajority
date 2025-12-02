# Script to resize all featured images to 1200x600
# Processes images referenced in post front matter

$ErrorActionPreference = "Continue"
$postsDir = "content\posts"
$targetWidth = 1200
$targetHeight = 600

# Load System.Drawing for image resizing
Add-Type -AssemblyName System.Drawing

function Resize-Image {
    param(
        [string]$imagePath,
        [int]$width,
        [int]$height
    )
    
    try {
        if (-not (Test-Path $imagePath)) {
            Write-Host "      ERROR: Image not found: $imagePath"
            return $false
        }
        
        # Load the image
        $img = [System.Drawing.Image]::FromFile($imagePath)
        
        # Check if already correct size
        if ($img.Width -eq $width -and $img.Height -eq $height) {
            Write-Host "      Already $width`x$height - skipping"
            $img.Dispose()
            return @{ Status = "already_correct"; NewPath = $imagePath }
        }
        
        Write-Host "      Resizing from $($img.Width)x$($img.Height) to ${width}x${height}"
        
        # Create new bitmap with target dimensions
        $newImg = New-Object System.Drawing.Bitmap($width, $height)
        $graphics = [System.Drawing.Graphics]::FromImage($newImg)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.DrawImage($img, 0, 0, $width, $height)
        
        # Determine output format
        $extension = [System.IO.Path]::GetExtension($imagePath).ToLower()
        $tempPath = $imagePath + ".tmp"
        
        # Save as JPEG for consistency (convert PNG to JPG)
        if ($extension -eq '.png') {
            $newPath = $imagePath -replace '\.png$', '.jpg'
            $tempPath = $newPath + ".tmp"
        }
        else {
            $newPath = $imagePath
        }
        
        # Save with JPEG encoder for quality control
        $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 90)
        
        # Save to temp file first
        $newImg.Save($tempPath, $encoder, $encoderParams)
        
        # Clean up
        $graphics.Dispose()
        $newImg.Dispose()
        $img.Dispose()
        
        # Replace original with resized version
        if ($newPath -ne $imagePath -and (Test-Path $imagePath)) {
            Remove-Item $imagePath -Force
        }
        if (Test-Path $newPath) {
            Remove-Item $newPath -Force
        }
        Move-Item $tempPath $newPath -Force
        
        Write-Host "      Successfully resized"
        return @{ Status = "resized"; NewPath = $newPath }
    }
    catch {
        Write-Host "      ERROR: $($_.Exception.Message)"
        return @{ Status = "error"; NewPath = $imagePath }
    }
}

# Get all markdown files
$postFiles = Get-ChildItem -Path $postsDir -Filter "*.md"

Write-Host "Found $($postFiles.Count) post files"
Write-Host "Processing featured images...`n"

$processed = 0
$skipped = 0
$errors = 0
$resized = 0
$alreadyCorrect = 0

# Track unique images to avoid processing duplicates
$processedImages = @{}

foreach ($file in $postFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    
    # Extract featuredImage from front matter
    if ($content -match 'featuredImage\s*=\s*"([^"]+)"') {
        $imagePath = $matches[1]
        
        # Skip if URL (not local)
        if ($imagePath -match '^https?://') {
            Write-Host "[SKIP] $($file.Name) - Image is a URL: $imagePath"
            $skipped++
            continue
        }
        
        # Convert to full path
        # Handle paths starting with /images/ or images/
        if ($imagePath -match '^/images/') {
            $fullPath = "static$imagePath"
        }
        elseif ($imagePath -match '^images/') {
            $fullPath = "static/$imagePath"
        }
        else {
            $fullPath = "static/$imagePath"
        }
        
        # Normalize path separators for Windows
        $fullPath = $fullPath -replace '/', '\'
        
        # Skip if already processed (same image used in multiple posts)
        if ($processedImages.ContainsKey($fullPath)) {
            Write-Host "[SKIP] $($file.Name) - Already processed: $imagePath"
            $skipped++
            continue
        }
        
        Write-Host "[PROCESS] $($file.Name) - $imagePath"
        
        # Resize the image
        $result = Resize-Image -imagePath $fullPath -width $targetWidth -height $targetHeight
        
        if ($result.Status -eq "resized") {
            $processedImages[$fullPath] = $true
            $processed++
            $resized++
            
            # Update front matter if path changed (PNG to JPG conversion)
            $newRelativePath = $result.NewPath -replace '^static[\\/]', '' -replace '\\', '/'
            if ($newRelativePath -ne $imagePath) {
                # Convert back to forward slashes for front matter
                if ($newRelativePath -notmatch '^/') {
                    $newRelativePath = $newRelativePath -replace '^images/', '/images/'
                }
                
                # Update front matter
                $frontMatterEnd = $content.IndexOf("+++", 3)
                if ($frontMatterEnd -ne -1) {
                    $frontMatter = $content.Substring(0, $frontMatterEnd + 3)
                    $body = $content.Substring($frontMatterEnd + 3)
                    $newFrontMatter = $frontMatter -replace 'featuredImage\s*=\s*"[^"]+"', "featuredImage = `"$newRelativePath`""
                    $newContent = $newFrontMatter + $body
                    Set-Content -Path $file.FullName -Value $newContent -NoNewline
                    Write-Host "      Updated front matter: $newRelativePath"
                }
            }
        }
        elseif ($result.Status -eq "already_correct") {
            $processedImages[$fullPath] = $true
            $processed++
            $alreadyCorrect++
        }
        else {
            $errors++
        }
    }
    else {
        Write-Host "[SKIP] $($file.Name) - No featuredImage found"
        $skipped++
    }
}

Write-Host "`n=== Summary ==="
Write-Host "Processed: $processed"
Write-Host "Resized: $resized"
Write-Host "Already correct size: $alreadyCorrect"
Write-Host "Skipped: $skipped"
Write-Host "Errors: $errors"

