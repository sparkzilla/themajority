$count = 0
Get-ChildItem -Path "content\posts\*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match 'featuredImage\s*=') {
        $count++
    }
}
Write-Host "Posts with featuredImage: $count"
Write-Host "Total posts: $((Get-ChildItem -Path 'content\posts\*.md').Count)"


