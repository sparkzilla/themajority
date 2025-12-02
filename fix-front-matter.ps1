# Fix front matter - move featuredImage inside the +++ block

$postsDir = "content\posts"
$postFiles = Get-ChildItem -Path $postsDir -Filter "*.md"

$fixed = 0

foreach ($file in $postFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $lines = $content -split "`r?`n"
    
    # Check if featuredImage is outside front matter (after +++ but before next +++ or content)
    $inFrontMatter = $false
    $foundFeaturedImage = $false
    $featuredImageLine = ""
    $newLines = @()
    $skipNext = $false
    
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        
        if ($line -match '^\+\+\+$') {
            if (-not $inFrontMatter) {
                # Opening +++
                $inFrontMatter = $true
                $newLines += $line
            }
            else {
                # Closing +++ - check if featuredImage was found outside
                if ($foundFeaturedImage -and $featuredImageLine) {
                    # Add featuredImage before closing +++
                    $newLines += $featuredImageLine
                    $featuredImageLine = ""
                    $foundFeaturedImage = $false
                }
                $newLines += $line
                $inFrontMatter = $false
            }
        }
        elseif ($inFrontMatter) {
            # Inside front matter
            if ($line -match 'featuredImage\s*=') {
                # Already in front matter, keep it
                $newLines += $line
            }
            else {
                $newLines += $line
            }
        }
        else {
            # Outside front matter
            if ($line -match 'featuredImage\s*=') {
                # Found featuredImage outside - store it to add before next closing +++
                $featuredImageLine = $line
                $foundFeaturedImage = $true
                # Don't add this line yet
            }
            else {
                $newLines += $line
            }
        }
    }
    
    # If we found featuredImage outside and haven't added it, add it before the first closing +++
    if ($foundFeaturedImage -and $featuredImageLine) {
        # Find the first closing +++ and insert before it
        for ($i = 0; $i -lt $newLines.Length; $i++) {
            if ($newLines[$i] -match '^\+\+\+$' -and $i -gt 0) {
                # Insert before this closing +++
                $newLines = $newLines[0..($i-1)] + $featuredImageLine + $newLines[$i..($newLines.Length-1)]
                break
            }
        }
    }
    
    $newContent = $newLines -join "`n"
    
    if ($newContent -ne $content) {
        Set-Content -Path $file.FullName -Value $newContent -NoNewline
        $fixed++
        Write-Host "Fixed: $($file.Name)"
    }
}

Write-Host "`nFixed $fixed files"


