# Final Restoration Script
# 1. Reads slug and image URL from XML
# 2. Downloads image from live site to static/images/restored (if not exists)
# 3. Updates markdown front matter with CORRECT relative path
# 4. Ensures no duplicate lines in content

$xmlPath = "wp-export\posts export.xml"
$postsDir = "content\posts"
$imagesDir = "static\images\restored"

# Create images directory
if (-not (Test-Path $imagesDir)) {
    New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null
}

Write-Host "Reading XML file..." -ForegroundColor Yellow
[xml]$xml = Get-Content -Path $xmlPath

$updated = 0
$downloaded = 0
$failed = 0
$skipped = 0

# Iterate through all items
foreach ($item in $xml.rss.channel.item) {
    # 1. Get the Slug
    $slug = $item.post_name.'#cdata-section'
    if (-not $slug) { $slug = $item.post_name }
    if (-not $slug) { continue }

    # 2. Get the Image URL
    $imageUrl = $null
    foreach ($meta in $item.postmeta) {
        $key = $meta.meta_key.'#cdata-section'
        if (-not $key) { $key = $meta.meta_key }
        
        if ($key -eq 'essb_cached_image') {
            $imageUrl = $meta.meta_value.'#cdata-section'
            if (-not $imageUrl) { $imageUrl = $meta.meta_value }
            break
        }
    }

    if ($imageUrl) {
        # Find the markdown file
        $mdFile = Join-Path $postsDir "$slug.md"
        
        if (Test-Path $mdFile) {
            $content = Get-Content -Path $mdFile -Raw
            
            # Determine local filename
            $filename = Split-Path $imageUrl -Leaf
            $filename = $filename -replace '[^a-zA-Z0-9\.-]', '_'
            $localPath = Join-Path $imagesDir $filename
            $webPath = "images/restored/$filename" # Relative path, NO leading slash
            
            # Download the image if it doesn't exist
            if (-not (Test-Path $localPath)) {
                try {
                    Invoke-WebRequest -Uri $imageUrl -OutFile $localPath -ErrorAction Stop
                    $downloaded++
                } catch {
                    Write-Host "Failed to download: $imageUrl for $slug" -ForegroundColor Red
                    $failed++
                    continue
                }
            }
            
            # Update markdown
            # We want to ensure featuredImage is set correctly in front matter
            
            $needsUpdate = $false
            
            # Check if it has the correct path already
            if ($content -match "featuredImage\s*=\s*`"$([regex]::Escape($webPath))`"") {
                $skipped++
                continue
            }
            
            # If it has a broken path (leading slash), replace it
            if ($content -match 'featuredImage\s*=\s*"/images/restored/') {
                $content = $content -replace 'featuredImage\s*=\s*"/images/restored/', 'featuredImage = "images/restored/'
                $needsUpdate = $true
            } 
            # If it's missing entirely (or was deleted by cleanup), add it
            elseif ($content -notmatch 'featuredImage\s*=') {
                if ($content -match '(?m)^title\s*=\s*".*"') {
                    $content = $content -replace '(?m)(^title\s*=\s*".*")', "`$1`nfeaturedImage = `"$webPath`""
                    $needsUpdate = $true
                } else {
                    # Fallback: insert after first +++
                    $content = $content -replace '(?s)^(\+\+\+\s*\r?\n)', "`$1featuredImage = `"$webPath`"`n"
                    $needsUpdate = $true
                }
            }
            
            if ($needsUpdate) {
                Set-Content -Path $mdFile -Value $content -NoNewline
                Write-Host "Updated: $slug" -ForegroundColor Green
                $updated++
            }
        }
    }
}

Write-Host "`nSummary:"
Write-Host "Downloaded: $downloaded"
Write-Host "Updated posts: $updated"
Write-Host "Failed downloads: $failed"
Write-Host "Skipped (already correct): $skipped"
