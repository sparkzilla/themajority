(function() {
    'use strict';
    
    function initPagination() {
        const paginationEl = document.getElementById('articles-pagination');
        const articlesGrid = document.getElementById('articles-grid');
        
        if (!paginationEl || !articlesGrid) {
            return;
        }
        
        const totalPages = parseInt(paginationEl.getAttribute('data-total-pages'), 10);
        const perPage = parseInt(paginationEl.getAttribute('data-per-page'), 10);
        const articles = Array.from(articlesGrid.querySelectorAll('.recent-article-card'));
        const prevBtn = document.getElementById('pagination-prev');
        const nextBtn = document.getElementById('pagination-next');
        const numbersContainer = document.getElementById('pagination-numbers');
        
        let currentPage = 1;
        
        function showPage(page, shouldScroll = false) {
            currentPage = page;
            
            // Hide all articles
            articles.forEach((article, index) => {
                const pageNum = Math.floor(index / perPage) + 1;
                if (pageNum === page) {
                    article.style.display = '';
                } else {
                    article.style.display = 'none';
                }
            });
            
            // Update pagination UI
            updatePaginationUI();
            
            // Remove any hash from URL
            if (window.location.hash) {
                window.history.replaceState(null, '', window.location.pathname);
            }
            
            // Only scroll to articles section if user interaction triggered this
            if (shouldScroll) {
                const articlesBox = articlesGrid.closest('.recent-articles-box');
                if (articlesBox) {
                    articlesBox.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
            }
        }
        
        function updatePaginationUI() {
            // Update prev/next buttons
            if (currentPage === 1) {
                prevBtn.classList.add('pagination-disabled');
                prevBtn.style.pointerEvents = 'none';
            } else {
                prevBtn.classList.remove('pagination-disabled');
                prevBtn.style.pointerEvents = '';
            }
            
            if (currentPage === totalPages) {
                nextBtn.classList.add('pagination-disabled');
                nextBtn.style.pointerEvents = 'none';
            } else {
                nextBtn.classList.remove('pagination-disabled');
                nextBtn.style.pointerEvents = '';
            }
            
            // Generate page numbers
            numbersContainer.innerHTML = '';
            const delta = 2;
            
            for (let pageNum = 1; pageNum <= totalPages; pageNum++) {
                const shouldShow = 
                    pageNum <= delta + 1 ||
                    (pageNum >= currentPage - delta && pageNum <= currentPage + delta) ||
                    pageNum >= totalPages - delta;
                
                if (shouldShow) {
                    if (pageNum === currentPage) {
                        const span = document.createElement('span');
                        span.className = 'pagination-number pagination-current';
                        span.textContent = pageNum;
                        numbersContainer.appendChild(span);
                    } else if (
                        pageNum === 1 ||
                        pageNum === totalPages ||
                        (pageNum > currentPage - delta && pageNum < currentPage + delta)
                    ) {
                        const link = document.createElement('a');
                        link.className = 'pagination-number';
                        link.href = '#';
                        link.textContent = pageNum;
                        link.addEventListener('click', function(e) {
                            e.preventDefault();
                            showPage(pageNum, true);
                        });
                        numbersContainer.appendChild(link);
                    } else if (pageNum === delta + 2 || pageNum === totalPages - delta - 1) {
                        const ellipsis = document.createElement('span');
                        ellipsis.className = 'pagination-ellipsis';
                        ellipsis.textContent = '...';
                        numbersContainer.appendChild(ellipsis);
                    }
                }
            }
        }
        
        // Event listeners
        prevBtn.addEventListener('click', function(e) {
            e.preventDefault();
            if (currentPage > 1) {
                showPage(currentPage - 1, true);
            }
        });
        
        nextBtn.addEventListener('click', function(e) {
            e.preventDefault();
            if (currentPage < totalPages) {
                showPage(currentPage + 1, true);
            }
        });
        
        // Remove any existing hash on load
        if (window.location.hash) {
            window.history.replaceState(null, '', window.location.pathname);
        }
        
        // Initialize
        showPage(currentPage);
    }
    
    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initPagination);
    } else {
        initPagination();
    }
})();

