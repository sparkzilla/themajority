# Hugo Static Site

A Hugo static site configured for deployment to GitHub Pages and Kinsta.

## 🚀 Quick Start

### Prerequisites

- Git installed
- Hugo Extended installed (see Installation section below)
- **Note:** The Ananke theme requires Hugo 0.146.0+. GitHub Actions will use the latest version automatically, but for local development you may need to update Hugo.

### Installation

#### Windows

If Hugo is not already installed, run:

```powershell
powershell -ExecutionPolicy Bypass -File install-hugo.ps1
```

Or download Hugo manually from [Hugo Releases](https://github.com/gohugoio/hugo/releases) and add it to your PATH.

### Local Development

1. **Start the development server:**
   ```bash
   hugo server -D
   ```

2. **View your site:**
   Open [http://localhost:1313](http://localhost:1313) in your browser.

3. **Create new content:**
   ```bash
   hugo new posts/my-new-post.md
   ```

4. **Build the site:**
   ```bash
   hugo --minify
   ```

The built site will be in the `public/` directory.

## 📦 Deployment

### GitHub Pages

1. **Create a GitHub repository:**
   - Go to [GitHub](https://github.com) and create a new repository
   - Do NOT initialize it with a README, .gitignore, or license

2. **Connect your local repository:**
   ```bash
   git remote add origin https://github.com/yourusername/your-repo-name.git
   git branch -M main
   git add .
   git commit -m "Initial commit"
   git push -u origin main
   ```

3. **Enable GitHub Pages:**
   - Go to your repository on GitHub
   - Navigate to **Settings** > **Pages**
   - Under **Source**, select **GitHub Actions**
   - The workflow will automatically deploy your site on every push to `main`

4. **Update baseURL:**
   - Edit `hugo.toml` and update the `baseURL` to match your GitHub Pages URL:
     ```toml
     baseURL = 'https://yourusername.github.io/'
     ```
   - Or for custom domains:
     ```toml
     baseURL = 'https://yourdomain.com/'
     ```

Your site will be available at `https://yourusername.github.io/your-repo-name/` (or your custom domain).

### Kinsta

1. **Push to GitHub:**
   - Make sure your site is pushed to a GitHub repository

2. **Connect to Kinsta:**
   - Log in to [MyKinsta](https://my.kinsta.com/)
   - Navigate to **Static Sites** > **Add site**
   - Select **GitHub** as your Git provider
   - Authorize Kinsta to access your repositories

3. **Configure Build Settings:**
   - Select your repository
   - **Build command:** `hugo --minify`
   - **Node version:** Leave as default (not required for Hugo)
   - **Publish directory:** `public`
   - Click **Create site**

4. **Update baseURL:**
   - After deployment, Kinsta will provide you with a URL
   - Update `hugo.toml`:
     ```toml
     baseURL = 'https://yoursite.kinsta.app/'
     ```
   - Commit and push the change

The `kinsta.json` file is already configured with the correct build settings.

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions workflow
├── archetypes/             # Content templates
├── assets/                 # Asset files (CSS, JS, etc.)
├── content/                # Site content
│   └── posts/             # Blog posts
├── data/                   # Data files
├── layouts/                # Custom layouts (overrides theme)
├── static/                 # Static files (images, etc.)
├── themes/                 # Hugo themes
│   └── ananke/            # Ananke theme (Git submodule)
├── hugo.toml              # Hugo configuration
├── kinsta.json            # Kinsta deployment config
└── README.md              # This file
```

## 🎨 Customization

### Change Theme

1. Browse themes at [Hugo Themes](https://themes.gohugo.io/)
2. Add a theme as a submodule:
   ```bash
   git submodule add https://github.com/theme-author/theme-name.git themes/theme-name
   ```
3. Update `hugo.toml`:
   ```toml
   theme = 'theme-name'
   ```

### Add Content

- **Create a new post:**
  ```bash
  hugo new posts/my-post.md
  ```

- **Create a new page:**
  ```bash
  hugo new about.md
  ```

### Configuration

Edit `hugo.toml` to customize:
- Site title and description
- Theme settings
- Menu structure
- Social media links
- And more!

## 🔧 Troubleshooting

### Hugo not found

If you get "hugo: command not found":
- Make sure Hugo is installed and in your PATH
- On Windows, you may need to restart your terminal after installation

### Theme compatibility warnings

If you see warnings about theme compatibility:
- **For local development:** Update Hugo to the latest version (0.146.0+)
- **For deployment:** Don't worry! GitHub Actions and Kinsta use the latest Hugo version automatically
- To update Hugo on Windows, download from [Hugo Releases](https://github.com/gohugoio/hugo/releases) and replace your existing Hugo installation

### Build errors

- Check that your theme is compatible with your Hugo version
- Run `hugo version` to check your Hugo version
- Some themes require Hugo Extended (this site uses Extended)

### GitHub Pages not updating

- Check that GitHub Actions workflow is enabled in repository settings
- Verify the workflow file is in `.github/workflows/`
- Check the Actions tab for any errors

### Kinsta deployment fails

- Verify build command is `hugo --minify`
- Check that publish directory is `public`
- Review build logs in MyKinsta dashboard

## 📚 Resources

- [Hugo Documentation](https://gohugo.io/documentation/)
- [Hugo Themes](https://themes.gohugo.io/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Kinsta Static Site Hosting](https://kinsta.com/docs/static-site-hosting/)

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

Happy building! 🎉

