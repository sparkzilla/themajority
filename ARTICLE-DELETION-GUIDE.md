# Article Deletion Guide

This guide explains how to mark and delete articles in your Hugo site.

## Overview

The system uses a `deleted: true` field in the front matter of markdown files to mark articles for deletion. This allows you to:
- Review what's marked before deleting
- Unmark articles if needed
- See marked articles in both the web interface and scripts

## Scripts

### 1. List Articles by Date
View all articles sorted by date (oldest first), with deletion status highlighted.

```powershell
.\list-articles-by-date.ps1
```

**Features:**
- Shows all articles sorted by date (oldest first)
- Highlights articles marked for deletion in red
- Shows draft status
- Displays file paths for easy reference

### 2. Mark Articles for Deletion

#### Mark a single article:
```powershell
.\mark-article-for-deletion.ps1 -FileName "article-name.md"
```

#### Mark all articles before a specific date:
```powershell
.\mark-article-for-deletion.ps1 -DateBefore "2021-01-01"
```

#### Mark articles in a date range:
```powershell
.\mark-article-for-deletion.ps1 -DateFrom "2020-01-01" -DateTo "2020-12-31"
```

#### List all marked articles:
```powershell
.\mark-article-for-deletion.ps1 -ListMarked
```

#### Unmark an article:
```powershell
.\mark-article-for-deletion.ps1 -FileName "article-name.md" -Unmark
```

### 3. Delete Marked Articles

**⚠️ WARNING: This permanently deletes files!**

#### Preview what will be deleted (dry run):
```powershell
.\delete-marked-articles.ps1 -WhatIf
```

#### Delete with backup:
```powershell
.\delete-marked-articles.ps1 -Backup
```

#### Delete without backup:
```powershell
.\delete-marked-articles.ps1
```

**Safety features:**
- Shows list of articles to be deleted
- Requires typing "DELETE" to confirm
- Optional backup to `content/posts/_backup_YYYYMMDD_HHMMSS/`

## Web Interface

Visit `/articles-by-date/` in your browser to see:
- All articles sorted by date (oldest first)
- Visual indicators for articles marked for deletion (red border and badge)
- File paths for each article
- Summary statistics

## Workflow Example

1. **Review articles:**
   ```powershell
   .\list-articles-by-date.ps1
   ```

2. **Mark articles before 2021:**
   ```powershell
   .\mark-article-for-deletion.ps1 -DateBefore "2021-01-01"
   ```

3. **Review what's marked:**
   ```powershell
   .\mark-article-for-deletion.ps1 -ListMarked
   ```
   Or visit `/articles-by-date/` in your browser

4. **Unmark any articles you want to keep:**
   ```powershell
   .\mark-article-for-deletion.ps1 -FileName "article-to-keep.md" -Unmark
   ```

5. **Preview deletion (optional):**
   ```powershell
   .\delete-marked-articles.ps1 -WhatIf
   ```

6. **Delete with backup:**
   ```powershell
   .\delete-marked-articles.ps1 -Backup
   ```

## Manual Marking

You can also manually add `deleted = true` to any article's front matter:

```markdown
+++
title = "Article Title"
date = 2020-01-01T00:00:00Z
draft = false
deleted = true
+++
```

## Notes

- Marked articles are still visible in the site until you run the delete script
- The `deleted` field is only used for marking - it doesn't automatically hide articles
- Always use `-Backup` when deleting to be safe
- The backup folder is created in `content/posts/_backup_YYYYMMDD_HHMMSS/`

