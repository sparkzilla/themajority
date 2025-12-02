#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('Generating search-index.json...');

const postsDir = path.join(__dirname, 'content', 'posts');
const outputDir = path.join(__dirname, '_site');
const outputFile = path.join(outputDir, 'search-index.json');

if (!fs.existsSync(postsDir)) {
  console.error('Posts directory not found:', postsDir);
  process.exit(1);
}

// Ensure output directory exists
if (!fs.existsSync(outputDir)) {
  console.log('Creating output directory:', outputDir);
  fs.mkdirSync(outputDir, { recursive: true });
}

const posts = fs.readdirSync(postsDir)
  .filter(file => file.endsWith('.md'))
  .map(file => {
    const filePath = path.join(postsDir, file);
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Skip draft posts
    if (content.match(/draft\s*=\s*true/) || content.match(/draft:\s*true/)) {
      return null;
    }
    
    return { file, content, filePath };
  })
  .filter(post => post !== null);

const index = [];

for (const post of posts) {
  const { content, file } = post;
  
  let title = '';
  let slug = '';
  let date = '';
  let body = '';
  
  // Parse TOML front matter (+++)
  let frontMatterMatch = content.match(/^\+\+\+([\s\S]*?)\+\+\+([\s\S]*)/);
  if (frontMatterMatch) {
    const frontMatter = frontMatterMatch[1];
    body = frontMatterMatch[2];
    
    const titleMatch = frontMatter.match(/title\s*=\s*["']([^"']+)["']/) || 
                      frontMatter.match(/title\s*=\s*([^\r\n]+)/);
    if (titleMatch) title = titleMatch[1].trim();
    
    const slugMatch = frontMatter.match(/slug\s*=\s*["']([^"']+)["']/) ||
                     frontMatter.match(/slug\s*=\s*([^\r\n]+)/);
    if (slugMatch) slug = slugMatch[1].trim();
    
    const dateMatch = frontMatter.match(/date\s*=\s*(\d{4}-\d{2}-\d{2})/);
    if (dateMatch) date = dateMatch[1];
  } 
  // Parse YAML front matter (---)
  else {
    frontMatterMatch = content.match(/^---([\s\S]*?)---([\s\S]*)/);
    if (frontMatterMatch) {
      const frontMatter = frontMatterMatch[1];
      body = frontMatterMatch[2];
      
      const titleMatch = frontMatter.match(/title:\s*["']([^"']+)["']/) ||
                        frontMatter.match(/title:\s*(.+)/);
      if (titleMatch) title = titleMatch[1].trim();
      
      const slugMatch = frontMatter.match(/slug:\s*["']([^"']+)["']/) ||
                       frontMatter.match(/slug:\s*(.+)/);
      if (slugMatch) slug = slugMatch[1].trim();
      
      const dateMatch = frontMatter.match(/date:\s*(\d{4}-\d{2}-\d{2})/);
      if (dateMatch) date = dateMatch[1];
    } else {
      body = content;
    }
  }
  
  // If no slug, generate from filename
  if (!slug) {
    slug = path.basename(file, '.md');
  }
  
  // If no title, use slug as fallback
  if (!title) {
    title = slug
      .split('-')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }
  
  if (!slug) continue;
  
  // Clean body content
  let plainBody = body
    .replace(/<[^>]+>/g, '') // Remove HTML tags
    .replace(/\[([^\]]+)\]\([^\)]+\)/g, '$1') // Remove markdown links, keep text
    .replace(/\s+/g, ' ') // Normalize whitespace
    .trim();
  
  const summary = plainBody.length > 150 
    ? plainBody.substring(0, 150) + '...' 
    : plainBody;
  
  index.push({
    title,
    url: `/articles/${slug}/`,
    content: plainBody,
    date,
    summary
  });
}

const json = JSON.stringify(index, null, 0);
fs.writeFileSync(outputFile, json, 'utf8');
console.log(`Generated search-index.json with ${index.length} posts`);

