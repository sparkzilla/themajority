// Search functionality for Hugo static site
let searchData = [];
let searchIndex = null;

// Initialize UI immediately when DOM is ready
function setupSearchUI() {
    const searchToggle = document.getElementById('search-toggle');
    const searchBox = document.getElementById('search-box');
    const searchInput = document.getElementById('search-input');
    const searchResults = document.getElementById('search-results');
    
    if (!searchToggle || !searchBox || !searchInput || !searchResults) {
        console.warn('Search elements not found');
        return;
    }
    
    // Toggle search box
    searchToggle.addEventListener('click', (e) => {
        e.stopPropagation();
        searchBox.classList.toggle('active');
        if (searchBox.classList.contains('active')) {
            searchInput.focus();
        }
    });
    
    // Close search when clicking outside
    document.addEventListener('click', (e) => {
        if (!searchBox.contains(e.target) && !searchToggle.contains(e.target)) {
            searchBox.classList.remove('active');
            searchResults.innerHTML = '';
            searchInput.value = '';
        }
    });
    
    // Search as user types
    let searchTimeout;
    searchInput.addEventListener('input', (e) => {
        // Auto-open search box when user starts typing
        if (!searchBox.classList.contains('active')) {
            searchBox.classList.add('active');
        }
        
        clearTimeout(searchTimeout);
        const query = e.target.value.trim().toLowerCase();
        
        console.log('Search input:', query, 'Index loaded:', !!searchIndex, 'Data length:', searchData.length);
        
        if (query.length < 2) {
            searchResults.innerHTML = '';
            searchResults.classList.remove('has-results');
            return;
        }
        
        if (!searchIndex) {
            searchResults.innerHTML = '<div class="search-no-results">Loading search index... Please wait.</div>';
            console.warn('Search index not loaded yet. Data:', searchData);
            return;
        }
        
        searchTimeout = setTimeout(() => {
            performSearch(query);
        }, 200);
    });
    
    // Handle keyboard navigation
    searchInput.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            searchBox.classList.remove('active');
            searchResults.innerHTML = '';
            searchInput.value = '';
        }
    });
}

function initSearch(data) {
    console.log('Initializing search with data:', data);
    if (!data || !Array.isArray(data)) {
        console.error('Search data is not a valid array:', data);
        return;
    }
    searchData = data;
    // Build search index (simple word-based)
    searchIndex = searchData.map((post, index) => ({
        index: index,
        words: (post.title + ' ' + post.content + ' ' + (post.summary || '')).toLowerCase().split(/\s+/)
    }));
    console.log('Search index built with', searchIndex.length, 'items');
}

function performSearch(query) {
    const queryWords = query.toLowerCase().split(/\s+/).filter(w => w.length > 0);
    const results = [];
    
    searchIndex.forEach(item => {
        const post = searchData[item.index];
        let score = 0;
        
        // Calculate relevance score
        queryWords.forEach(qWord => {
            // Title matches are worth more
            if (post.title.toLowerCase().includes(qWord)) {
                score += 10;
            }
            // Content matches
            const contentMatches = item.words.filter(w => w.includes(qWord)).length;
            score += contentMatches;
        });
        
        if (score > 0) {
            results.push({ post, score });
        }
    });
    
    // Sort by score (highest first)
    results.sort((a, b) => b.score - a.score);
    
    // Limit to top 10 results
    displayResults(results.slice(0, 10), query);
}

function displayResults(results, query) {
    const searchResults = document.getElementById('search-results');
    if (!searchResults) return;
    
    if (results.length === 0) {
        searchResults.innerHTML = '<div class="search-no-results">No results found</div>';
        searchResults.classList.remove('has-results');
        return;
    }
    
    searchResults.classList.add('has-results');
    searchResults.innerHTML = results.map(result => {
        const { post } = result;
        const highlightedTitle = highlightText(post.title, query);
        const summary = post.summary || post.content.substring(0, 150) + '...';
        const highlightedSummary = highlightText(summary, query);
        
        return `
            <a href="${post.url}" class="search-result-item">
                <h4 class="search-result-title">${highlightedTitle}</h4>
                <p class="search-result-summary">${highlightedSummary}</p>
                <time class="search-result-date">${post.date}</time>
            </a>
        `;
    }).join('');
}

function highlightText(text, query) {
    const words = query.split(/\s+/).filter(w => w.length > 0);
    let highlighted = text;
    
    words.forEach(word => {
        const regex = new RegExp(`(${word})`, 'gi');
        highlighted = highlighted.replace(regex, '<mark>$1</mark>');
    });
    
    return highlighted;
}

// Export for initialization
window.initSearch = initSearch;
window.setupSearchUI = setupSearchUI;

// Auto-initialize UI when script loads
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupSearchUI);
} else {
    setupSearchUI();
}

