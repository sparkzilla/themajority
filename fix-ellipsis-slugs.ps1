# Fix posts with "..." in titles by adding explicit slug fields
# This prevents Hugo from generating slugs with "..." which Windows doesn't allow in directory names

Write-Host "Fixing posts with ellipsis in titles..." -ForegroundColor Green

$postsDir = "content\posts"
$files = Get-ChildItem -Path $postsDir -Filter "*.md" -File

$fixed = 0
$skipped = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    
    # Check if title has "..." and doesn't already have a slug
    if ($content -match 'title\s*=\s*"[^"]*\.\.\.[^"]*"' -and $content -notmatch '^\s*slug\s*=') {
        # Extract the base filename (without extension) for the slug
        $slug = $file.BaseName
        
        # Find the front matter section
        if ($content -match '(?s)(\+\+\+.*?)(\+\+\+)') {
            $frontMatter = $matches[1]
            $closing = $matches[2]
            
            # Add slug field after title
            if ($frontMatter -match '(title\s*=\s*"[^"]*")') {
                $newFrontMatter = $frontMatter -replace '(\+\+\+)', "`$1`nslug = `"$slug`""
                $newContent = $content -replace [regex]::Escape($frontMatter), $newFrontMatter
                
                # Write back to file
                Set-Content -Path $file.FullName -Value $newContent -NoNewline
                Write-Host "Fixed: $($file.Name) -> slug: $slug" -ForegroundColor Green
                $fixed++
            }
        } elseif ($content -match '(?s)(---.*?)(---)') {
            $frontMatter = $matches[1]
            $closing = $matches[2]
            
            # Add slug field after title
            if ($frontMatter -match '(title\s*=\s*"[^"]*")') {
                $newFrontMatter = $frontMatter -replace '(---)', "slug = `"$slug`"`n`$1"
                $newContent = $content -replace [regex]::Escape($frontMatter), $newFrontMatter
                
                # Write back to file
                Set-Content -Path $file.FullName -Value $newContent -NoNewline
                Write-Host "Fixed: $($file.Name) -> slug: $slug" -ForegroundColor Green
                $fixed++
            }
        }
    } else {
        $skipped++
    }
}

Write-Host "`nDone! Fixed $fixed files, skipped $skipped files." -ForegroundColor Green

