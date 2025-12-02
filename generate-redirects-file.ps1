# Generate _redirects file for Netlify and other services that support it
# This creates server-side 301 redirects which are better for SEO

Write-Host "Generating _redirects file..." -ForegroundColor Green

$postsDir = "content\posts"
$files = Get-ChildItem -Path $postsDir -Filter "*.md" -File
$redirects = @()

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    
    # Extract date and slug from front matter
    if ($content -match 'date\s*=\s*(\d{4})-(\d{2})-(\d{2})') {
        $year = $matches[1]
        $month = $matches[2]
        $day = $matches[3]
        
        # Extract slug from filename (remove .md extension)
        $slug = $file.BaseName
        
        # Create old and new URL formats
        $oldUrl = "/blog/$year/$month/$day/$slug/"
        $newUrl = "/articles/$slug/"
        
        # Add redirect rule (301 = permanent redirect)
        $redirects += "$oldUrl $newUrl 301"
    }
}

# Write to static/_redirects (Hugo will copy this to public/)
$staticDir = "static"
if (-not (Test-Path $staticDir)) {
    New-Item -ItemType Directory -Path $staticDir | Out-Null
}

$redirectsFile = Join-Path $staticDir "_redirects"
$redirects | Out-File -FilePath $redirectsFile -Encoding UTF8

Write-Host "`nGenerated $($redirects.Count) redirect rules in $redirectsFile" -ForegroundColor Green
Write-Host "This file will be copied to public/ during Hugo build." -ForegroundColor Cyan
Write-Host "`nNote: GitHub Pages doesn't support _redirects files natively." -ForegroundColor Yellow
Write-Host "This file works with Netlify, Vercel, and other services that support it." -ForegroundColor Yellow


