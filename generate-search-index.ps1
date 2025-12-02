# Simple script to generate search-index.json
Write-Host "Generating search-index.json..."

$posts = Get-ChildItem -Path "content\posts" -Filter "*.md" | Where-Object { 
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }
    -not ($content -match 'draft\s*=\s*true')
}

$index = @()

foreach ($post in $posts) {
    $content = Get-Content $post.FullName -Raw -Encoding UTF8
    
    # Parse front matter
    $title = ""
    $slug = ""
    $date = ""
    $summary = ""
    
    if ($content -match '(?s)\+\+\+(.*?)\+\+\+(.*)') {
        $frontMatter = $matches[1]
        $body = $matches[2]
        
        if ($frontMatter -match 'title\s*=\s*[""]([^""]+)[""]') { $title = $matches[1] }
        elseif ($frontMatter -match "title\s*=\s*['']([^'']+)['']") { $title = $matches[1] }
        elseif ($frontMatter -match 'title\s*=\s*([^\r\n]+)') { $title = $matches[1].Trim() }
        
        if ($frontMatter -match 'slug\s*=\s*[""]([^""]+)[""]') { $slug = $matches[1] }
        elseif ($frontMatter -match "slug\s*=\s*['']([^'']+)['']") { $slug = $matches[1] }
        elseif ($frontMatter -match 'slug\s*=\s*([^\r\n]+)') { $slug = $matches[1].Trim() }
        
        if ($frontMatter -match 'date\s*=\s*(\d{4}-\d{2}-\d{2})') { $date = $matches[1] }
        elseif ($frontMatter -match 'date\s*=\s*(\d{4}-\d{2}-\d{2})T') { $date = $matches[1] }
    }
    elseif ($content -match '(?s)---(.*?)---(.*)') {
        $frontMatter = $matches[1]
        $body = $matches[2]
        
        if ($frontMatter -match 'title:\s*[""]([^""]+)[""]') { $title = $matches[1] }
        elseif ($frontMatter -match "title:\s*['']([^'']+)['']") { $title = $matches[1] }
        elseif ($frontMatter -match 'title:\s*(.+)') { $title = $matches[1].Trim() }
        
        if ($frontMatter -match 'slug:\s*[""]([^""]+)[""]') { $slug = $matches[1] }
        elseif ($frontMatter -match "slug:\s*['']([^'']+)['']") { $slug = $matches[1] }
        elseif ($frontMatter -match 'slug:\s*(.+)') { $slug = $matches[1].Trim() }
        
        if ($frontMatter -match 'date:\s*(\d{4}-\d{2}-\d{2})') { $date = $matches[1] }
    }
    
    # If no slug, generate from filename
    if (-not $slug) {
        $slug = [System.IO.Path]::GetFileNameWithoutExtension($post.Name)
    }
    
    # If no title, use slug as fallback
    if (-not $title) {
        $title = $slug -replace '-', ' ' -replace '\b\w', { $_.Value.ToUpper() }
    }
    
    if (-not $slug) { continue }
    
    # Clean body content
    $plainBody = $body -replace '<[^>]+>', '' -replace '\[([^\]]+)\]\([^\)]+\)', '$1' -replace '\s+', ' ' -replace '^\s+|\s+$', ''
    $summary = if ($plainBody.Length -gt 150) { $plainBody.Substring(0, 150) + "..." } else { $plainBody }
    
    $index += [PSCustomObject]@{
        title = $title
        url = "/articles/$slug/"
        content = $plainBody
        date = $date
        summary = $summary
    }
}

$json = ($index | ConvertTo-Json -Depth 10 -Compress)
[System.IO.File]::WriteAllText("$PSScriptRoot\_site\search-index.json", $json, [System.Text.Encoding]::UTF8)
Write-Host "Generated search-index.json with $($index.Count) posts"

