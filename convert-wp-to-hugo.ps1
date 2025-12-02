# WordPress to Hugo Converter
# Converts WordPress XML export to Hugo markdown files

param(
    [string]$XmlFile = "wp-export\posts export.xml",
    [string]$OutputDir = "content\posts"
)

Write-Host "WordPress to Hugo Converter" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green
Write-Host ""

# Check if XML file exists
if (-not (Test-Path $XmlFile)) {
    Write-Host "Error: XML file not found: $XmlFile" -ForegroundColor Red
    exit 1
}

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Created output directory: $OutputDir" -ForegroundColor Yellow
}

# Load XML file
Write-Host "Loading XML file..." -ForegroundColor Yellow
[xml]$xml = Get-Content $XmlFile -Encoding UTF8

# Create namespace manager
$nsmgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$nsmgr.AddNamespace("wp", "http://wordpress.org/export/1.2/")
$nsmgr.AddNamespace("content", "http://purl.org/rss/1.0/modules/content/")
$nsmgr.AddNamespace("excerpt", "http://wordpress.org/export/1.2/excerpt/")
$nsmgr.AddNamespace("dc", "http://purl.org/dc/elements/1.1/")

# Count items
$items = $xml.SelectNodes("//item")
$totalItems = $items.Count
Write-Host "Found $totalItems posts to convert" -ForegroundColor Yellow
Write-Host ""

$converted = 0
$skipped = 0
$errors = 0

foreach ($item in $items) {
    try {
        # Get namespaced elements
        $postType = $item.SelectSingleNode("wp:post_type", $nsmgr).InnerText
        $status = $item.SelectSingleNode("wp:status", $nsmgr).InnerText
        
        # Only process published posts
        if ($postType -ne 'post' -or $status -ne 'publish') {
            $skipped++
            continue
        }

        # Get post data
        $title = $item.SelectSingleNode("title").InnerText
        $contentNode = $item.SelectSingleNode("content:encoded", $nsmgr)
        $content = if ($contentNode) { $contentNode.InnerText } else { "" }
        $excerptNode = $item.SelectSingleNode("excerpt:encoded", $nsmgr)
        $excerpt = if ($excerptNode) { $excerptNode.InnerText } else { "" }
        $postDateNode = $item.SelectSingleNode("wp:post_date", $nsmgr)
        $postDate = if ($postDateNode) { $postDateNode.InnerText } else { "" }
        $postNameNode = $item.SelectSingleNode("wp:post_name", $nsmgr)
        $postName = if ($postNameNode) { $postNameNode.InnerText } else { "" }
        $authorNode = $item.SelectSingleNode("dc:creator", $nsmgr)
        $author = if ($authorNode) { $authorNode.InnerText } else { "" }
        
        # Skip if no title or content
        if ([string]::IsNullOrWhiteSpace($title) -or [string]::IsNullOrWhiteSpace($content)) {
            $skipped++
            continue
        }

        # Parse date
        $date = [DateTime]::Parse($postDate)
        $dateStr = $date.ToString("yyyy-MM-dd")
        
        # Create filename from post name or title
        if ([string]::IsNullOrWhiteSpace($postName)) {
            $fileName = $title -replace '[^\w\s-]', '' -replace '\s+', '-' -replace '-+', '-'
            $fileName = $fileName.Trim('-').ToLower()
        } else {
            $fileName = $postName
        }
        
        # Ensure unique filename
        $filePath = Join-Path $OutputDir "$fileName.md"
        $counter = 1
        while (Test-Path $filePath) {
            $filePath = Join-Path $OutputDir "$fileName-$counter.md"
            $counter++
        }

        # Extract categories and tags
        $categories = @()
        $tags = @()
        
        $categoryNodes = $item.SelectNodes("category")
        foreach ($cat in $categoryNodes) {
            $domain = $cat.GetAttribute("domain")
            $catText = $cat.InnerText
            if ($domain -eq 'category') {
                $categories += $catText
            } elseif ($domain -eq 'post_tag') {
                $tags += $catText
            }
        }

        # Escape quotes in title for TOML
        $escapedTitle = $title -replace '\\', '\\\\' -replace '"', '\"'
        
        # Build front matter - collect all fields first
        $frontMatterFields = @()
        $frontMatterFields += "title = `"$escapedTitle`""
        $frontMatterFields += "date = $($date.ToString("yyyy-MM-ddTHH:mm:ssZ"))"
        $frontMatterFields += "draft = false"
        
        # Add author if available
        if (-not [string]::IsNullOrWhiteSpace($author)) {
            $frontMatterFields += "author = `"$author`""
        }
        
        # Add categories
        if ($categories.Count -gt 0) {
            $catList = ($categories | ForEach-Object { "`"$_`"" }) -join ", "
            $frontMatterFields += "categories = [$catList]"
        }
        
        # Add tags
        if ($tags.Count -gt 0) {
            $tagList = ($tags | ForEach-Object { "`"$_`"" }) -join ", "
            $frontMatterFields += "tags = [$tagList]"
        }
        
        # Add excerpt as description if available
        if (-not [string]::IsNullOrWhiteSpace($excerpt)) {
            $excerptText = $excerpt -replace '<[^>]+>', '' -replace '"', '\"'
            if ($excerptText.Length -gt 200) {
                $excerptText = $excerptText.Substring(0, 200) + "..."
            }
            $frontMatterFields += "description = `"$excerptText`""
        }
        
        # Build complete front matter
        $frontMatter = "+++`n" + ($frontMatterFields -join "`n") + "`n+++"

        # Clean up content - extract content from WordPress shortcodes
        # Remove WordPress shortcode tags but keep their content
        $content = $content -replace '\[av_[^\]]+\]', ''  # Remove opening shortcodes
        $content = $content -replace '\[/av_[^\]]+\]', ''  # Remove closing shortcodes
        $content = $content -replace '\[[^\]]+\]', ''  # Remove any remaining shortcodes
        $content = $content -replace '<!--.*?-->', ''  # Remove HTML comments
        
        # Convert Twitter URLs to embed blocks (handle both plain URLs and wrapped in <p> tags)
        $content = $content -replace '(?s)<p>\s*https://twitter\.com/(\w+)/status/(\d+)\s*</p>', '<blockquote class="twitter-tweet" data-theme="light"><p lang="en" dir="ltr"><a href="https://twitter.com/$1/status/$2?ref_src=twsrc%5Etfw"></a></p></blockquote>'
        $content = $content -replace '(?s)^\s*https://twitter\.com/(\w+)/status/(\d+)\s*$', '<blockquote class="twitter-tweet" data-theme="light"><p lang="en" dir="ltr"><a href="https://twitter.com/$1/status/$2?ref_src=twsrc%5Etfw"></a></p></blockquote>'
        
        # Remove excessive blank lines
        $content = $content -replace '\r\n\s*\r\n\s*\r\n+', "`r`n`r`n"  # Replace 3+ blank lines with 2
        $content = $content.Trim()
        
        # Write markdown file
        $markdown = $frontMatter + "`n`n" + $content
        
        # Fix encoding issues
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($filePath, $markdown, $utf8NoBom)
        
        $converted++
        if ($converted % 10 -eq 0) {
            Write-Host "Converted $converted posts..." -ForegroundColor Cyan
        }
    }
    catch {
        $errors++
        Write-Host "Error converting post: $($item.title) - $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Conversion Complete!" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host "Converted: $converted posts" -ForegroundColor Green
Write-Host "Skipped: $skipped posts" -ForegroundColor Yellow
Write-Host "Errors: $errors posts" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Posts saved to: $OutputDir" -ForegroundColor Cyan

