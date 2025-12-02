# Mark duplicate post files (-1, -2, etc.) as drafts
# This prevents them from being built and causing path errors

Write-Host "Marking duplicate posts as drafts..." -ForegroundColor Green

$postsDir = "content\posts"
$files = Get-ChildItem -Path $postsDir -Filter "*.md" -File

$marked = 0
$skipped = 0

foreach ($file in $files) {
    # Check if filename matches pattern for duplicates (-1, -2, etc.)
    if ($file.Name -match '-\d+\.md$') {
        $content = Get-Content -Path $file.FullName -Raw
        $originalContent = $content
        
        # Check if already marked as draft
        if ($content -match 'draft\s*=\s*true') {
            Write-Host "Already draft: $($file.Name)" -ForegroundColor Yellow
            $skipped++
            continue
        }
        
        # Replace draft = false with draft = true
        if ($content -match 'draft\s*=\s*false') {
            $content = $content -replace 'draft\s*=\s*false', 'draft = true'
        } else {
            # If no draft field exists, add it after the title or date
            if ($content -match '(?s)(\+\+\+.*?)(title\s*=\s*"[^"]*")') {
                $content = $content -replace '(\+\+\+.*?)(title\s*=\s*"[^"]*")', '$1$2`ndraft = true'
            } elseif ($content -match '(?s)(\+\+\+.*?)(date\s*=\s*[^\n]+)') {
                $content = $content -replace '(\+\+\+.*?)(date\s*=\s*[^\n]+)', '$1$2`ndraft = true'
            } else {
                # If we can't find a good place, just add it after the opening +++
                $content = $content -replace '(\+\+\+)', '$1`ndraft = true'
            }
        }
        
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            Write-Host "Marked as draft: $($file.Name)" -ForegroundColor Green
            $marked++
        }
    }
}

Write-Host "`nDone! Marked $marked files as drafts, skipped $skipped files." -ForegroundColor Green

