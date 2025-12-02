# Check image sizes from the website
$singlePost = Invoke-WebRequest -Uri 'https://themajority.scot/blog/2025/09/23/what-happened-to-the-abolish-holyrood-party/' -UseBasicParsing
$homepage = Invoke-WebRequest -Uri 'https://themajority.scot/' -UseBasicParsing

Write-Host "=== Single Post Page ==="
if ($singlePost.Content -match 'og:image:width.*content="(\d+)"') {
    $width = $matches[1]
}
if ($singlePost.Content -match 'og:image:height.*content="(\d+)"') {
    $height = $matches[1]
}
if ($width -and $height) {
    Write-Host "Featured image (og:image): ${width}x${height}"
}

if ($singlePost.Content -match 'big-preview.*width="(\d+)".*height="(\d+)"') {
    Write-Host "Displayed image: $($matches[1])x$($matches[2])"
}

Write-Host "`n=== Homepage ==="
if ($homepage.Content -match 'width="(\d+)".*height="(\d+)".*wp-content/uploads.*\.jpg') {
    Write-Host "Post card images: $($matches[1])x$($matches[2])"
}


