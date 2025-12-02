#!/bin/bash
set -e

# Download and install Hugo Extended if not already available
if ! command -v hugo &> /dev/null; then
    echo "Installing Hugo Extended..."
    # Get the latest release version
    HUGO_VERSION=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//')
    echo "Downloading Hugo Extended version ${HUGO_VERSION}..."
    
    # Download with proper redirect handling
    curl -L -f "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz" -o hugo.tar.gz
    
    if [ ! -f hugo.tar.gz ] || [ ! -s hugo.tar.gz ]; then
        echo "Failed to download Hugo, trying alternative method..."
        curl -L -f "https://github.com/gohugoio/hugo/releases/latest/download/hugo_extended_Linux-64bit.tar.gz" -o hugo.tar.gz
    fi
    
    # Extract Hugo
    tar -xzf hugo.tar.gz hugo
    chmod +x hugo
    export PATH=$PWD:$PATH
    echo "Hugo installed successfully"
fi

# Build the site
echo "Building site with Hugo..."
hugo --minify

# Generate search index
echo "Generating search index..."
node generate-search-index.js

echo "Build complete!"

