# Fix image paths - remove leading slash so relURL works correctly with baseURL subdirectory

$postsDir = "content\posts"
$postFiles = Get-ChildItem -Path $postsDir -Filter "*.md"

$fixed = 0

foreach ($file in $postFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $modified = $false
    
    # Fix featuredImage paths - remove leading slash
    if ($content -match 'featuredImage\s*=\s*"/(images/[^"]+)"') {
        $oldPath = "/" + $matches[1]
        $newPath = $matches[1]
        $content = $content -replace [regex]::Escape($oldPath), $newPath
        $modified = $true
    }
    
    # Fix inline image paths in content - remove leading slash from /images/posts/
    if ($content -match 'src="/images/posts/') {
        $content = $content -replace 'src="/images/posts/', 'src="images/posts/'
        $modified = $true
    }
    
    if ($content -match '\]\(/images/posts/') {
        $content = $content -replace '\]\(/images/posts/', '](images/posts/'
        $modified = $true
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $fixed++
        Write-Host "Fixed: $($file.Name)"
    }
}

Write-Host "`nFixed $fixed files"


