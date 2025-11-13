// AFHAM Website - Main JavaScript

// Global configuration
const AFHAMWebsite = {
  language: 'en',
  rtl: false,
  animations: {
    enabled: true,
    reducedMotion: false
  }
};

// Language Management
class LanguageManager {
  constructor() {
    this.currentLanguage = 'en';
    this.translations = {};
    this.init();
  }

  init() {
    // Check for saved language preference
    const savedLang = localStorage.getItem('afham-language') || 'en';
    this.setLanguage(savedLang);
    
    // Check for reduced motion preference
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    AFHAMWebsite.animations.reducedMotion = prefersReducedMotion;
    
    // Bind language toggle events
    this.bindEvents();
  }

  bindEvents() {
    const langButtons = document.querySelectorAll('.lang-btn');
    langButtons.forEach(btn => {
      btn.addEventListener('click', (e) => {
        const lang = e.target.id.split('-')[1];
        this.setLanguage(lang);
      });
    });
  }

  setLanguage(lang) {
    this.currentLanguage = lang;
    AFHAMWebsite.language = lang;
    AFHAMWebsite.rtl = lang === 'ar';
    
    // Update UI
    this.updateLanguageButtons();
    this.updateContent();
    this.updateDirection();
    
    // Save preference
    localStorage.setItem('afham-language', lang);
    
    // Dispatch event for other components
    document.dispatchEvent(new CustomEvent('languageChanged', { 
      detail: { language: lang, rtl: AFHAMWebsite.rtl }
    }));
  }

  updateLanguageButtons() {
    document.querySelectorAll('.lang-btn').forEach(btn => {
      btn.classList.remove('active');
    });
    document.getElementById(`lang-${this.currentLanguage}`)?.classList.add('active');
  }

  updateContent() {
    const elements = document.querySelectorAll('[data-en][data-ar]');
    elements.forEach(el => {
      const text = el.getAttribute(`data-${this.currentLanguage}`);
      if (text) {
        el.textContent = text;
      }
    });
  }

  updateDirection() {
    document.documentElement.setAttribute('dir', AFHAMWebsite.rtl ? 'rtl' : 'ltr');
    document.documentElement.setAttribute('lang', this.currentLanguage);
    
    if (AFHAMWebsite.rtl) {
      document.body.classList.add('rtl');
    } else {
      document.body.classList.remove('rtl');
    }
  }
}

// Navigation Management
class NavigationManager {
  constructor() {
    this.navbar = document.querySelector('.navbar');
    this.hamburger = document.querySelector('.hamburger');
    this.navMenu = document.querySelector('.nav-menu');
    this.lastScrollY = window.scrollY;
    
    this.init();
  }

  init() {
    this.bindEvents();
    this.updateNavbar();
  }

  bindEvents() {
    // Scroll handling
    window.addEventListener('scroll', () => {
      this.handleScroll();
    });

    // Mobile menu toggle
    if (this.hamburger) {
      this.hamburger.addEventListener('click', () => {
        this.toggleMobileMenu();
      });
    }

    // Close mobile menu on link click
    document.querySelectorAll('.nav-link').forEach(link => {
      link.addEventListener('click', () => {
        this.closeMobileMenu();
      });
    });

    // Close mobile menu on outside click
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.navbar')) {
        this.closeMobileMenu();
      }
    });
  }

  handleScroll() {
    const currentScrollY = window.scrollY;
    
    // Add/remove scrolled class
    if (currentScrollY > 50) {
      this.navbar.classList.add('scrolled');
    } else {
      this.navbar.classList.remove('scrolled');
    }

    // Hide/show navbar based on scroll direction
    if (currentScrollY > this.lastScrollY && currentScrollY > 100) {
      this.navbar.classList.add('hidden');
    } else {
      this.navbar.classList.remove('hidden');
    }

    this.lastScrollY = currentScrollY;
  }

  toggleMobileMenu() {
    this.navMenu.classList.toggle('active');
    this.hamburger.classList.toggle('active');
    document.body.classList.toggle('menu-open');
  }

  closeMobileMenu() {
    this.navMenu.classList.remove('active');
    this.hamburger.classList.remove('active');
    document.body.classList.remove('menu-open');
  }

  updateNavbar() {
    // Update active nav item based on current page
    const currentPath = window.location.pathname;
    document.querySelectorAll('.nav-link').forEach(link => {
      const href = link.getAttribute('href');
      if (href && (currentPath === href || currentPath.startsWith(href + '/'))) {
        link.classList.add('active');
      }
    });
  }
}

// Smooth Scrolling for Anchor Links
class SmoothScrollManager {
  constructor() {
    this.init();
  }

  init() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
      anchor.addEventListener('click', (e) => {
        e.preventDefault();
        const target = document.querySelector(anchor.getAttribute('href'));
        if (target) {
          this.scrollToElement(target);
        }
      });
    });
  }

  scrollToElement(element) {
    const offset = 80; // Account for fixed navbar
    const elementPosition = element.offsetTop - offset;
    
    window.scrollTo({
      top: elementPosition,
      behavior: 'smooth'
    });
  }
}

// Intersection Observer for Animations
class AnimationManager {
  constructor() {
    this.observers = new Map();
    this.init();
  }

  init() {
    if (AFHAMWebsite.animations.reducedMotion) {
      return; // Skip animations if user prefers reduced motion
    }

    this.createObservers();
    this.observeElements();
  }

  createObservers() {
    // Fade in animation observer
    this.observers.set('fadeIn', new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('fade-in-up');
          this.observers.get('fadeIn').unobserve(entry.target);
        }
      });
    }, { 
      threshold: 0.1,
      rootMargin: '0px 0px -50px 0px'
    }));

    // Counter animation observer
    this.observers.set('counter', new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.animateCounter(entry.target);
          this.observers.get('counter').unobserve(entry.target);
        }
      });
    }, { threshold: 0.5 }));
  }

  observeElements() {
    // Observe elements for fade-in animation
    const fadeElements = document.querySelectorAll('.feature-card, .healthcare-feature, .program-card');
    fadeElements.forEach(el => {
      this.observers.get('fadeIn').observe(el);
    });

    // Observe stat numbers for counter animation
    const statNumbers = document.querySelectorAll('.stat-number');
    statNumbers.forEach(el => {
      this.observers.get('counter').observe(el);
    });
  }

  animateCounter(element) {
    const text = element.textContent;
    const number = parseInt(text.replace(/\D/g, ''));
    
    if (isNaN(number)) return;

    const duration = 2000;
    const steps = 60;
    const increment = number / steps;
    const stepDuration = duration / steps;
    
    let currentNumber = 0;
    
    const timer = setInterval(() => {
      currentNumber += increment;
      
      if (currentNumber >= number) {
        element.textContent = text;
        clearInterval(timer);
      } else {
        const displayNumber = Math.floor(currentNumber);
        element.textContent = text.replace(number.toString(), displayNumber.toString());
      }
    }, stepDuration);
  }
}

// Copy to Clipboard Functionality
function copyCode(elementId) {
  const element = document.getElementById(elementId);
  if (!element) return;

  const text = element.textContent;
  
  if (navigator.clipboard) {
    navigator.clipboard.writeText(text).then(() => {
      showNotification('Code copied to clipboard!', 'success');
    }).catch(() => {
      fallbackCopyToClipboard(text);
    });
  } else {
    fallbackCopyToClipboard(text);
  }
}

function fallbackCopyToClipboard(text) {
  const textArea = document.createElement('textarea');
  textArea.value = text;
  textArea.style.position = 'fixed';
  textArea.style.left = '-999999px';
  textArea.style.top = '-999999px';
  document.body.appendChild(textArea);
  textArea.focus();
  textArea.select();
  
  try {
    document.execCommand('copy');
    showNotification('Code copied to clipboard!', 'success');
  } catch (err) {
    showNotification('Failed to copy code', 'error');
  }
  
  document.body.removeChild(textArea);
}

// Notification System
function showNotification(message, type = 'info') {
  const notification = document.createElement('div');
  notification.className = `notification notification-${type}`;
  notification.textContent = message;
  
  notification.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 12px 24px;
    background: ${type === 'success' ? '#10b981' : type === 'error' ? '#ef4444' : '#3b82f6'};
    color: white;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    z-index: 10000;
    transform: translateX(100%);
    transition: transform 0.3s ease;
    font-weight: 500;
  `;
  
  document.body.appendChild(notification);
  
  // Animate in
  setTimeout(() => {
    notification.style.transform = 'translateX(0)';
  }, 100);
  
  // Animate out and remove
  setTimeout(() => {
    notification.style.transform = 'translateX(100%)';
    setTimeout(() => {
      document.body.removeChild(notification);
    }, 300);
  }, 3000);
}

// Search Functionality (for docs)
class SearchManager {
  constructor() {
    this.searchInput = document.getElementById('docs-search');
    this.searchResults = null;
    this.searchIndex = [];
    
    if (this.searchInput) {
      this.init();
    }
  }

  init() {
    this.createSearchResults();
    this.bindEvents();
    this.buildSearchIndex();
  }

  createSearchResults() {
    this.searchResults = document.createElement('div');
    this.searchResults.className = 'search-results';
    this.searchResults.style.cssText = `
      position: absolute;
      top: 100%;
      left: 0;
      right: 0;
      background: white;
      border: 1px solid var(--gray-200);
      border-top: none;
      border-radius: 0 0 8px 8px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      max-height: 400px;
      overflow-y: auto;
      z-index: 1000;
      display: none;
    `;
    
    this.searchInput.parentNode.appendChild(this.searchResults);
  }

  bindEvents() {
    this.searchInput.addEventListener('input', (e) => {
      const query = e.target.value.trim();
      if (query.length >= 2) {
        this.performSearch(query);
      } else {
        this.hideResults();
      }
    });

    this.searchInput.addEventListener('focus', () => {
      if (this.searchInput.value.trim().length >= 2) {
        this.showResults();
      }
    });

    document.addEventListener('click', (e) => {
      if (!e.target.closest('.search-box')) {
        this.hideResults();
      }
    });
  }

  buildSearchIndex() {
    // Build search index from page content
    const headings = document.querySelectorAll('h1, h2, h3, h4');
    const paragraphs = document.querySelectorAll('p');
    
    headings.forEach(heading => {
      this.searchIndex.push({
        title: heading.textContent,
        content: heading.textContent,
        url: `#${heading.id || ''}`,
        type: 'heading'
      });
    });

    paragraphs.forEach(p => {
      const heading = this.findNearestHeading(p);
      this.searchIndex.push({
        title: heading ? heading.textContent : 'Content',
        content: p.textContent,
        url: heading ? `#${heading.id || ''}` : '#',
        type: 'content'
      });
    });
  }

  findNearestHeading(element) {
    let current = element.previousElementSibling;
    while (current) {
      if (/^H[1-6]$/.test(current.tagName)) {
        return current;
      }
      current = current.previousElementSibling;
    }
    return null;
  }

  performSearch(query) {
    const results = this.searchIndex
      .filter(item => 
        item.title.toLowerCase().includes(query.toLowerCase()) ||
        item.content.toLowerCase().includes(query.toLowerCase())
      )
      .slice(0, 5);

    this.renderResults(results, query);
    this.showResults();
  }

  renderResults(results, query) {
    if (results.length === 0) {
      this.searchResults.innerHTML = `
        <div style="padding: 16px; text-align: center; color: var(--gray-500);">
          No results found for "${query}"
        </div>
      `;
      return;
    }

    this.searchResults.innerHTML = results.map(result => `
      <a href="${result.url}" style="
        display: block;
        padding: 12px 16px;
        border-bottom: 1px solid var(--gray-100);
        color: var(--gray-700);
        text-decoration: none;
        transition: background-color 0.15s ease;
      " onmouseover="this.style.backgroundColor='var(--gray-50)'" 
         onmouseout="this.style.backgroundColor='transparent'">
        <div style="font-weight: 500; margin-bottom: 4px;">
          ${this.highlightQuery(result.title, query)}
        </div>
        <div style="font-size: 14px; color: var(--gray-500);">
          ${this.highlightQuery(this.truncateText(result.content, 100), query)}
        </div>
      </a>
    `).join('');
  }

  highlightQuery(text, query) {
    const regex = new RegExp(`(${query})`, 'gi');
    return text.replace(regex, '<mark style="background-color: #fef3c7; padding: 1px 2px; border-radius: 2px;">$1</mark>');
  }

  truncateText(text, maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength).trim() + '...';
  }

  showResults() {
    this.searchResults.style.display = 'block';
  }

  hideResults() {
    this.searchResults.style.display = 'none';
  }
}

// Analytics Integration
class AnalyticsManager {
  constructor() {
    this.init();
  }

  init() {
    // Track page views
    this.trackPageView();
    
    // Track interactions
    this.bindInteractionEvents();
  }

  trackPageView() {
    if (typeof plausible !== 'undefined') {
      plausible('pageview');
    }
  }

  trackEvent(eventName, properties = {}) {
    if (typeof plausible !== 'undefined') {
      plausible(eventName, { props: properties });
    }
    
    // Also send to console in development
    if (window.location.hostname === 'localhost') {
      console.log('Analytics Event:', eventName, properties);
    }
  }

  bindInteractionEvents() {
    // Track button clicks
    document.querySelectorAll('.btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const text = btn.textContent.trim();
        const href = btn.getAttribute('href');
        
        this.trackEvent('Button Click', {
          button_text: text,
          button_href: href || 'none'
        });
      });
    });

    // Track external links
    document.querySelectorAll('a[href^="http"]').forEach(link => {
      link.addEventListener('click', () => {
        const url = link.getAttribute('href');
        this.trackEvent('External Link', { url });
      });
    });

    // Track language switches
    document.addEventListener('languageChanged', (e) => {
      this.trackEvent('Language Switch', {
        language: e.detail.language,
        rtl: e.detail.rtl
      });
    });
  }
}

// Performance Monitoring
class PerformanceMonitor {
  constructor() {
    this.metrics = {};
    this.init();
  }

  init() {
    this.measurePageLoad();
    this.observeWebVitals();
  }

  measurePageLoad() {
    window.addEventListener('load', () => {
      const perfData = performance.getEntriesByType('navigation')[0];
      
      this.metrics = {
        pageLoadTime: perfData.loadEventEnd - perfData.fetchStart,
        domContentLoaded: perfData.domContentLoadedEventEnd - perfData.fetchStart,
        firstPaint: performance.getEntriesByType('paint')[0]?.startTime || 0
      };

      // Log metrics in development
      if (window.location.hostname === 'localhost') {
        console.log('Performance Metrics:', this.metrics);
      }
    });
  }

  observeWebVitals() {
    // Observe Largest Contentful Paint (LCP)
    if ('PerformanceObserver' in window) {
      const observer = new PerformanceObserver((list) => {
        const entries = list.getEntries();
        const lastEntry = entries[entries.length - 1];
        this.metrics.lcp = lastEntry.startTime;
      });
      
      try {
        observer.observe({ entryTypes: ['largest-contentful-paint'] });
      } catch (e) {
        // LCP not supported
      }
    }
  }

  getMetrics() {
    return this.metrics;
  }
}

// Initialize everything when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  // Initialize core managers
  const languageManager = new LanguageManager();
  const navigationManager = new NavigationManager();
  const smoothScrollManager = new SmoothScrollManager();
  const animationManager = new AnimationManager();
  const searchManager = new SearchManager();
  const analyticsManager = new AnalyticsManager();
  const performanceMonitor = new PerformanceMonitor();

  // Make managers globally accessible for debugging
  if (window.location.hostname === 'localhost') {
    window.AFHAM = {
      languageManager,
      navigationManager,
      smoothScrollManager,
      animationManager,
      searchManager,
      analyticsManager,
      performanceMonitor
    };
  }

  // Show page after initialization to prevent FOUC
  document.body.style.opacity = '1';
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    AFHAMWebsite,
    LanguageManager,
    NavigationManager,
    copyCode,
    showNotification
  };
}