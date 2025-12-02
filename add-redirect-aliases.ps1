# Add redirect aliases to all posts
# This script adds aliases with the old URL format to preserve SEO

Write-Host "Adding redirect aliases to posts..." -ForegroundColor Green

$postsDir = "content\posts"
$files = Get-ChildItem -Path $postsDir -Filter "*.md" -File

$processed = 0
$skipped = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    
    # Skip if already has aliases
    if ($content -match 'aliases\s*=') {
        Write-Host "Skipping $($file.Name) - already has aliases" -ForegroundColor Yellow
        $skipped++
        continue
    }
    
    # Extract date and slug from front matter
    if ($content -match 'date\s*=\s*(\d{4})-(\d{2})-(\d{2})') {
        $year = $matches[1]
        $month = $matches[2]
        $day = $matches[3]
        
        # Extract slug from filename (remove .md extension)
        $slug = $file.BaseName
        
        # Create old URL format
        $oldUrl = "/blog/$year/$month/$day/$slug/"
        
        # Find the end of front matter (+++ or ---)
        if ($content -match '(?s)(\+\+\+.*?\+\+\+)') {
            $frontMatter = $matches[1]
            
            # Add aliases before the closing +++
            $newFrontMatter = $frontMatter -replace '(\+\+\+)', "aliases = [`"$oldUrl`"]`n`$1"
            
            # Replace in content
            $newContent = $content -replace [regex]::Escape($frontMatter), $newFrontMatter
            
            # Write back to file
            Set-Content -Path $file.FullName -Value $newContent -NoNewline
            Write-Host "Added alias to $($file.Name): $oldUrl" -ForegroundColor Green
            $processed++
        } elseif ($content -match '(?s)(---.*?---)') {
            # Handle YAML front matter
            $frontMatter = $matches[1]
            
            # Add aliases before the closing ---
            $newFrontMatter = $frontMatter -replace '(---)', "aliases:`n  - `"$oldUrl`"`n`$1"
            
            # Replace in content
            $newContent = $content -replace [regex]::Escape($frontMatter), $newFrontMatter
            
            # Write back to file
            Set-Content -Path $file.FullName -Value $newContent -NoNewline
            Write-Host "Added alias to $($file.Name): $oldUrl" -ForegroundColor Green
            $processed++
        } else {
            Write-Host "Warning: Could not parse front matter in $($file.Name)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Warning: Could not find date in $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "`nDone! Processed: $processed, Skipped: $skipped" -ForegroundColor Green
Write-Host "`nAll old URLs will now redirect to the new /articles/[slug]/ format." -ForegroundColor Cyan


