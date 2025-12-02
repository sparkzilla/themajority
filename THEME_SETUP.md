# Bookworm Theme Setup Instructions

## Step 1: Download the Bookworm Theme

1. Visit [GetHugoThemes - Bookworm](https://gethugothemes.com/products/bookworm)
2. Purchase and download the theme package
3. Extract the downloaded `.zip` file

## Step 2: Add Theme to Your Site

Once you have the theme files:

1. **Copy the theme folder:**
   - Extract the downloaded Bookworm theme
   - Copy the `bookworm` folder into your `themes/` directory
   - The path should be: `themes/bookworm/`

2. **Or if you have it as a Git repository:**
   ```bash
   git submodule add <bookworm-repo-url> themes/bookworm
   ```

## Step 3: Update Configuration

The `hugo.toml` file has been updated to use the Bookworm theme. Once you add the theme files, it will automatically work.

## Step 4: Install Dependencies (if required)

Some themes require Node.js dependencies. If Bookworm requires them:

```bash
npm install
```

## Step 5: Start the Server

```bash
hugo server -D
```

Your site will be available at `http://localhost:1313/` (or the port Hugo assigns).

## Step 6: Commit Changes

Once the theme is working:

```bash
git add themes/bookworm
git add hugo.toml
git commit -m "Add Bookworm theme"
git push
```

---

**Note:** If you need help with the theme configuration or have the theme files ready, let me know and I can help you set it up!


