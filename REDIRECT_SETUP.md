# URL Redirect Setup for SEO

This document explains how the permanent redirects (301) are set up to preserve SEO when migrating from `/blog/:year/:month/:day/:slug/` to `/articles/:slug/`.

## What Was Changed

1. **Permalink Structure** (`hugo.toml`)
   - Changed from: `/blog/:year/:month/:day/:slug/`
   - Changed to: `/articles/:slug/`
   - This fixes Windows path length issues while keeping URLs shorter

2. **Alias Template** (`themes/majority/layouts/_default/alias.html`)
   - Creates HTML redirect pages with:
     - **Canonical links** - Tells search engines the new URL is permanent (301 equivalent)
     - **Meta refresh** - Immediate redirect for users
     - **JavaScript fallback** - Ensures redirect works in all browsers
     - **SEO meta tags** - Properly configured for search engines

3. **Redirect Scripts**
   - `add-redirect-aliases.ps1` - Adds old URL aliases to all posts
   - `generate-redirects-file.ps1` - Generates `_redirects` file for Netlify/Vercel

## How It Works

### For Search Engines (SEO)
- **Canonical links** tell Google and other search engines that the new URL is the permanent, canonical version
- Search engines will update their indexes to use the new URLs
- This is effectively a 301 permanent redirect for SEO purposes

### For Users
- **Meta refresh** redirects users immediately (0 seconds)
- **JavaScript fallback** ensures redirect works even if meta refresh is disabled
- Users are seamlessly redirected to the new URL structure

### For Static Hosting
- **GitHub Pages**: Uses the alias template (client-side redirects with canonical links)
- **Netlify/Vercel**: Can use the `_redirects` file for true server-side 301 redirects

## Running the Setup

1. **Add aliases to all posts:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File add-redirect-aliases.ps1
   ```

2. **Generate _redirects file (optional, for Netlify/Vercel):**
   ```powershell
   powershell -ExecutionPolicy Bypass -File generate-redirects-file.ps1
   ```

3. **Build and deploy:**
   ```powershell
   hugo --minify
   ```

## Verification

After deployment, test that:
- Old URLs redirect to new URLs (e.g., `/blog/2023/03/20/its-a-love-story-baby-just-say-yes/` → `/articles/its-a-love-story-baby-just-say-yes/`)
- Canonical links are present in the redirect pages
- Search engines can crawl and index the new URLs

## Notes

- The canonical link is the most important part for SEO - it tells search engines this is a permanent move
- Google typically updates their index within a few weeks after seeing canonical redirects
- The old URLs will continue to work indefinitely, redirecting to the new structure


