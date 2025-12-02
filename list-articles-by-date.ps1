# List all articles sorted by date (oldest first)
# This helps identify early articles for deletion

$contentPath = "content\posts"
$articles = @()

Write-Host "Scanning articles in $contentPath..." -ForegroundColor Cyan

Get-ChildItem -Path $contentPath -Filter "*.md" | ForEach-Object {
    $file = $_
    $content = Get-Content $file.FullName -Raw
    
    # Extract date from front matter
    if ($content -match '(?s)\+\+\+.*?date\s*=\s*(\d{4}-\d{2}-\d{2})') {
        $dateStr = $matches[1]
        $date = [DateTime]::ParseExact($dateStr, "yyyy-MM-dd", $null)
        
        # Extract title
        $title = "Untitled"
        if ($content -match 'title\s*=\s*"([^"]+)"') {
            $title = $matches[1]
        } elseif ($content -match "title\s*=\s*'([^']+)'") {
            $title = $matches[1]
        }
        
        # Extract draft status
        $isDraft = $false
        if ($content -match 'draft\s*=\s*(true|false)') {
            $isDraft = $matches[1] -eq "true"
        }
        
        # Extract deleted status
        $isMarkedForDeletion = $false
        if ($content -match 'deleted\s*=\s*true') {
            $isMarkedForDeletion = $true
        }
        
        $articles += [PSCustomObject]@{
            Date = $date
            DateString = $dateStr
            Title = $title
            FileName = $file.Name
            FilePath = $file.FullName
            IsDraft = $isDraft
            IsMarkedForDeletion = $isMarkedForDeletion
        }
    } else {
        Write-Warning "Could not parse date from: $($file.Name)"
    }
}

# Sort by date (oldest first)
$sortedArticles = $articles | Sort-Object Date

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Articles by Date (Oldest First)" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$count = 0
foreach ($article in $sortedArticles) {
    $count++
    $draftStatus = if ($article.IsDraft) { " [DRAFT]" } else { "" }
    $deletedStatus = if ($article.IsMarkedForDeletion) { " [MARKED FOR DELETION]" } else { "" }
    
    if ($article.IsMarkedForDeletion) {
        $color = "Red"
    } elseif ($article.IsDraft) {
        $color = "DarkGray"
    } else {
        $color = "White"
    }
    
    Write-Host "$count. " -NoNewline -ForegroundColor Yellow
    Write-Host "$($article.DateString) " -NoNewline -ForegroundColor Cyan
    Write-Host "- " -NoNewline
    Write-Host "$($article.Title)$draftStatus$deletedStatus" -ForegroundColor $color
    Write-Host "   File: " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($article.FileName)" -ForegroundColor DarkGray
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Summary" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Total Articles: $($sortedArticles.Count)" -ForegroundColor Cyan
Write-Host "Draft Articles: $(($sortedArticles | Where-Object { $_.IsDraft }).Count)" -ForegroundColor Cyan
Write-Host "Published Articles: $(($sortedArticles | Where-Object { -not $_.IsDraft }).Count)" -ForegroundColor Cyan
Write-Host "Marked for Deletion: $(($sortedArticles | Where-Object { $_.IsMarkedForDeletion }).Count)" -ForegroundColor Red

if ($sortedArticles.Count -gt 0) {
    Write-Host "`nOldest Article: $($sortedArticles[0].DateString) - $($sortedArticles[0].Title)" -ForegroundColor Yellow
    Write-Host "Newest Article: $($sortedArticles[-1].DateString) - $($sortedArticles[-1].Title)" -ForegroundColor Yellow
}

Write-Host "`nTo mark an article for deletion:" -ForegroundColor Magenta
Write-Host "  .\mark-article-for-deletion.ps1 -FileName '<filename>'" -ForegroundColor DarkGray
Write-Host "`nTo mark articles before a date:" -ForegroundColor Magenta
Write-Host "  .\mark-article-for-deletion.ps1 -DateBefore '2021-01-01'" -ForegroundColor DarkGray
Write-Host "`nTo list marked articles:" -ForegroundColor Magenta
Write-Host "  .\mark-article-for-deletion.ps1 -ListMarked" -ForegroundColor DarkGray
Write-Host "`nTo delete all marked articles:" -ForegroundColor Magenta
Write-Host "  .\delete-marked-articles.ps1 [-Backup]" -ForegroundColor DarkGray

