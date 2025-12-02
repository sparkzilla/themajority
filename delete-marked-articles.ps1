# Delete all articles marked with "deleted: true" in their front matter
# Usage: .\delete-marked-articles.ps1 [-WhatIf] [-Backup]

param(
    [switch]$WhatIf,
    [switch]$Backup
)

$contentPath = "content\posts"
$backupPath = "content\posts\_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

Write-Host "Scanning for articles marked for deletion..." -ForegroundColor Cyan

$markedArticles = @()
Get-ChildItem -Path $contentPath -Filter "*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match 'deleted\s*=\s*true') {
        $date = "Unknown"
        if ($content -match 'date\s*=\s*(\d{4}-\d{2}-\d{2})') {
            $date = $matches[1]
        }
        
        $title = "Untitled"
        if ($content -match 'title\s*=\s*"([^"]+)"') {
            $title = $matches[1]
        }
        
        $markedArticles += [PSCustomObject]@{
            File = $_
            Date = $date
            Title = $title
        }
    }
}

if ($markedArticles.Count -eq 0) {
    Write-Host "No articles marked for deletion." -ForegroundColor Green
    exit
}

Write-Host "`nFound $($markedArticles.Count) articles marked for deletion:" -ForegroundColor Red
Write-Host "========================================`n" -ForegroundColor Red

$count = 0
foreach ($article in $markedArticles) {
    $count++
    Write-Host "$count. $($article.Date) - $($article.Title)" -ForegroundColor Red
    Write-Host "   File: $($article.File.Name)" -ForegroundColor DarkGray
}

if ($WhatIf) {
    Write-Host "`n[WHAT IF MODE] - No files will be deleted." -ForegroundColor Yellow
    exit
}

Write-Host "`nWARNING: This will permanently delete $($markedArticles.Count) articles!" -ForegroundColor Red
$confirm = Read-Host "Type 'DELETE' to confirm deletion"

if ($confirm -ne "DELETE") {
    Write-Host "Deletion cancelled." -ForegroundColor Yellow
    exit
}

if ($Backup) {
    Write-Host "`nCreating backup in: $backupPath" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    
    foreach ($article in $markedArticles) {
        Copy-Item -Path $article.File.FullName -Destination (Join-Path $backupPath $article.File.Name)
    }
    Write-Host "Backup created." -ForegroundColor Green
}

Write-Host "`nDeleting articles..." -ForegroundColor Red
$deletedCount = 0
foreach ($article in $markedArticles) {
    try {
        Remove-Item -Path $article.File.FullName -Force
        Write-Host "Deleted: $($article.File.Name)" -ForegroundColor Red
        $deletedCount++
    } catch {
        Write-Error "Failed to delete: $($article.File.Name) - $_"
    }
}

Write-Host "`nDeleted $deletedCount of $($markedArticles.Count) articles." -ForegroundColor Green
if ($Backup) {
    Write-Host "Backup saved to: $backupPath" -ForegroundColor Cyan
}

