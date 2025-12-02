# Mark articles for deletion by adding a "deleted: true" field to front matter
# Usage: .\mark-article-for-deletion.ps1 -FileName "article-name.md"
#        .\mark-article-for-deletion.ps1 -DateBefore "2021-01-01"
#        .\mark-article-for-deletion.ps1 -DateRange "2020-01-01" "2020-12-31"

param(
    [string]$FileName,
    [string]$DateBefore,
    [string]$DateFrom,
    [string]$DateTo,
    [switch]$Unmark,
    [switch]$ListMarked
)

$contentPath = "content\posts"

function MarkArticle($filePath, $markAsDeleted) {
    $content = Get-Content $filePath -Raw -Encoding UTF8
    
    if ($markAsDeleted) {
        # Check if already marked
        if ($content -match 'deleted\s*=\s*true') {
            Write-Host "Already marked: $($filePath | Split-Path -Leaf)" -ForegroundColor Yellow
            return $false
        }
        
        # Add deleted: true after draft field or at the end of front matter
        if ($content -match '(?s)(\+\+\+.*?)(draft\s*=\s*[^\r\n]+)') {
            $newContent = $content -replace '(?s)(\+\+\+.*?)(draft\s*=\s*[^\r\n]+)', "`$1`$2`r`ndeleted = true"
        } elseif ($content -match '(?s)(\+\+\+.*?)(\+\+\+)') {
            # Add before closing +++
            $newContent = $content -replace '(?s)(\+\+\+.*?)(\+\+\+)', "`$1deleted = true`r`n`$2"
        } else {
            Write-Warning "Could not parse front matter in: $filePath"
            return $false
        }
        
        Set-Content -Path $filePath -Value $newContent -Encoding UTF8 -NoNewline
        Write-Host "Marked for deletion: $($filePath | Split-Path -Leaf)" -ForegroundColor Red
        return $true
    } else {
        # Unmark - remove deleted field
        if ($content -match 'deleted\s*=\s*true') {
            $newContent = $content -replace '(?s)\r?\ndeleted\s*=\s*true\r?\n', "`r`n"
            $newContent = $newContent -replace '(?s)\r?\ndeleted\s*=\s*true', ""
            Set-Content -Path $filePath -Value $newContent -Encoding UTF8 -NoNewline
            Write-Host "Unmarked: $($filePath | Split-Path -Leaf)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Not marked: $($filePath | Split-Path -Leaf)" -ForegroundColor Yellow
            return $false
        }
    }
}

function GetArticleDate($filePath) {
    $content = Get-Content $filePath -Raw
    if ($content -match 'date\s*=\s*(\d{4}-\d{2}-\d{2})') {
        return [DateTime]::ParseExact($matches[1], "yyyy-MM-dd", $null)
    }
    return $null
}

if ($ListMarked) {
    Write-Host "Articles marked for deletion:" -ForegroundColor Red
    Write-Host "============================`n" -ForegroundColor Red
    
    $markedCount = 0
    Get-ChildItem -Path $contentPath -Filter "*.md" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if ($content -match 'deleted\s*=\s*true') {
            $markedCount++
            $date = GetArticleDate $_.FullName
            $dateStr = if ($date) { $date.ToString("yyyy-MM-dd") } else { "Unknown" }
            
            $title = "Untitled"
            if ($content -match 'title\s*=\s*"([^"]+)"') {
                $title = $matches[1]
            }
            
            Write-Host "$markedCount. $dateStr - $title" -ForegroundColor Red
            Write-Host "   File: $($_.Name)" -ForegroundColor DarkGray
        }
    }
    
    if ($markedCount -eq 0) {
        Write-Host "No articles marked for deletion." -ForegroundColor Green
    } else {
        Write-Host "`nTotal marked: $markedCount" -ForegroundColor Red
    }
    exit
}

if ($FileName) {
    $filePath = Join-Path $contentPath $FileName
    if (Test-Path $filePath) {
        MarkArticle $filePath (-not $Unmark) | Out-Null
    } else {
        Write-Error "File not found: $filePath"
    }
    exit
}

if ($DateBefore) {
    $cutoffDate = [DateTime]::ParseExact($DateBefore, "yyyy-MM-dd", $null)
    Write-Host "Marking articles before $DateBefore..." -ForegroundColor Cyan
    
    $count = 0
    Get-ChildItem -Path $contentPath -Filter "*.md" | ForEach-Object {
        $date = GetArticleDate $_.FullName
        if ($date -and $date -lt $cutoffDate) {
            if (MarkArticle $_.FullName $true) {
                $count++
            }
        }
    }
    Write-Host "Marked $count articles for deletion." -ForegroundColor Green
    exit
}

if ($DateFrom -and $DateTo) {
    $fromDate = [DateTime]::ParseExact($DateFrom, "yyyy-MM-dd", $null)
    $toDate = [DateTime]::ParseExact($DateTo, "yyyy-MM-dd", $null)
    Write-Host "Marking articles from $DateFrom to $DateTo..." -ForegroundColor Cyan
    
    $count = 0
    Get-ChildItem -Path $contentPath -Filter "*.md" | ForEach-Object {
        $date = GetArticleDate $_.FullName
        if ($date -and $date -ge $fromDate -and $date -le $toDate) {
            if (MarkArticle $_.FullName $true) {
                $count++
            }
        }
    }
    Write-Host "Marked $count articles for deletion." -ForegroundColor Green
    exit
}

Write-Host @"
Usage:
  Mark single article:
    .\mark-article-for-deletion.ps1 -FileName "article-name.md"
  
  Mark articles before a date:
    .\mark-article-for-deletion.ps1 -DateBefore "2021-01-01"
  
  Mark articles in date range:
    .\mark-article-for-deletion.ps1 -DateFrom "2020-01-01" -DateTo "2020-12-31"
  
  Unmark an article:
    .\mark-article-for-deletion.ps1 -FileName "article-name.md" -Unmark
  
  List all marked articles:
    .\mark-article-for-deletion.ps1 -ListMarked
"@

