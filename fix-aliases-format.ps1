# Fix incorrectly formatted aliases in posts
# This script removes aliases that were added before the opening +++ and ensures they're only inside front matter

Write-Host "Fixing aliases format in posts..." -ForegroundColor Green

$postsDir = "content\posts"
$files = Get-ChildItem -Path $postsDir -Filter "*.md" -File

$processed = 0
$fixed = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
    $needsFix = $false
    
    # Remove any aliases line that appears before the opening +++
    if ($content -match '^aliases\s*=\s*\[.*?\]') {
        Write-Host "Fixing $($file.Name) - removing aliases before opening +++" -ForegroundColor Yellow
        $needsFix = $true
        # Remove the line that starts with aliases = at the beginning of the file
        $content = $content -replace '^aliases\s*=\s*\[.*?\]\s*\r?\n', ''
    }
    
    # Check for duplicate aliases inside front matter and remove duplicates
    if ($content -match '(?s)(\+\+\+.*?aliases\s*=.*?aliases\s*=.*?\+\+\+)') {
        Write-Host "Fixing $($file.Name) - removing duplicate aliases" -ForegroundColor Yellow
        $needsFix = $true
        
        # Split into lines and process
        $lines = $content -split '\r?\n'
        $inFrontMatter = $false
        $aliasFound = $false
        $newLines = @()
        
        foreach ($line in $lines) {
            if ($line -match '^\+\+\+$') {
                if (-not $inFrontMatter) {
                    $inFrontMatter = $true
                    $aliasFound = $false
                } else {
                    $inFrontMatter = $false
                }
                $newLines += $line
            } elseif ($inFrontMatter -and $line -match '^aliases\s*=') {
                # Only keep the first aliases line we find
                if (-not $aliasFound) {
                    $newLines += $line
                    $aliasFound = $true
                }
                # Skip duplicate aliases
            } else {
                $newLines += $line
            }
        }
        
        $content = $newLines -join "`n"
    }
    
    if ($needsFix -and $content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Fixed $($file.Name)" -ForegroundColor Green
        $fixed++
        $processed++
    }
}

Write-Host "`nDone! Processed: $processed, Fixed: $fixed" -ForegroundColor Green

