#!/bin/bash
set -e

# Download and install Hugo Extended if not already available
if ! command -v hugo &> /dev/null; then
    echo "Installing Hugo Extended..."
    curl -L https://github.com/gohugoio/hugo/releases/latest/download/hugo_extended_Linux-64bit.tar.gz -o hugo.tar.gz
    tar -xzf hugo.tar.gz hugo
    chmod +x hugo
    export PATH=$PWD:$PATH
fi

# Build the site
echo "Building site with Hugo..."
hugo --minify

# Generate search index
echo "Generating search index..."
node generate-search-index.js

echo "Build complete!"

