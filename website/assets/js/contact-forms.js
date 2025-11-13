// AFHAM Contact Forms - Interactive JavaScript

// Contact Form Handler
class ContactFormManager {
    constructor() {
        this.contactForm = document.getElementById('contactForm');
        this.newsletterForm = document.getElementById('newsletterForm');
        this.formSuccess = document.getElementById('formSuccess');
        
        this.init();
    }

    init() {
        if (this.contactForm) {
            this.bindContactFormEvents();
        }
        
        if (this.newsletterForm) {
            this.bindNewsletterFormEvents();
        }
    }

    bindContactFormEvents() {
        this.contactForm.addEventListener('submit', (e) => {
            this.handleContactFormSubmit(e);
        });

        // Real-time validation
        const requiredFields = this.contactForm.querySelectorAll('input[required], select[required], textarea[required]');
        requiredFields.forEach(field => {
            field.addEventListener('blur', () => {
                this.validateField(field);
            });
            
            field.addEventListener('input', () => {
                this.clearFieldError(field);
            });
        });

        // Phone number formatting
        const phoneField = document.getElementById('phone');
        if (phoneField) {
            phoneField.addEventListener('input', (e) => {
                this.formatPhoneNumber(e.target);
            });
        }
    }

    bindNewsletterFormEvents() {
        this.newsletterForm.addEventListener('submit', (e) => {
            this.handleNewsletterSubmit(e);
        });
    }

    async handleContactFormSubmit(e) {
        e.preventDefault();
        
        // Show loading state
        const submitBtn = this.contactForm.querySelector('button[type="submit"]');
        const originalText = submitBtn.innerHTML;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> <span data-en="Sending..." data-ar="جاري الإرسال...">Sending...</span>';
        submitBtn.disabled = true;

        try {
            // Validate form
            if (!this.validateContactForm()) {
                throw new Error('Please fix the validation errors');
            }

            // Collect form data
            const formData = this.collectContactFormData();
            
            // Send to backend (replace with your endpoint)
            const response = await this.submitContactForm(formData);
            
            if (response.success) {
                this.showSuccessMessage();
                this.resetContactForm();
                
                // Track form submission
                if (typeof AnalyticsDashboard !== 'undefined') {
                    AnalyticsDashboard.trackEvent('Contact Form Submitted', {
                        inquiry_type: formData.inquiryType,
                        organization: formData.organization || 'none'
                    });
                }
            } else {
                throw new Error(response.message || 'Failed to send message');
            }
        } catch (error) {
            console.error('Contact form error:', error);
            this.showErrorMessage(error.message);
        } finally {
            // Restore button
            submitBtn.innerHTML = originalText;
            submitBtn.disabled = false;
        }
    }

    async handleNewsletterSubmit(e) {
        e.preventDefault();
        
        const submitBtn = this.newsletterForm.querySelector('button[type="submit"]');
        const emailField = document.getElementById('newsletterEmail');
        const originalText = submitBtn.innerHTML;
        
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
        submitBtn.disabled = true;

        try {
            const email = emailField.value.trim();
            
            if (!this.validateEmail(email)) {
                throw new Error('Please enter a valid email address');
            }

            // Send to newsletter service (replace with your endpoint)
            const response = await this.submitNewsletter({ email });
            
            if (response.success) {
                this.showNotification('Successfully subscribed to newsletter!', 'success');
                emailField.value = '';
                
                // Track newsletter signup
                if (typeof AnalyticsDashboard !== 'undefined') {
                    AnalyticsDashboard.trackEvent('Newsletter Signup', {
                        source: 'contact_page'
                    });
                }
            } else {
                throw new Error(response.message || 'Failed to subscribe');
            }
        } catch (error) {
            console.error('Newsletter error:', error);
            this.showNotification(error.message, 'error');
        } finally {
            submitBtn.innerHTML = originalText;
            submitBtn.disabled = false;
        }
    }

    validateContactForm() {
        let isValid = true;
        const requiredFields = this.contactForm.querySelectorAll('input[required], select[required], textarea[required]');
        
        requiredFields.forEach(field => {
            if (!this.validateField(field)) {
                isValid = false;
            }
        });

        // Validate email format
        const emailField = document.getElementById('email');
        if (emailField && !this.validateEmail(emailField.value)) {
            this.showFieldError(emailField, 'Please enter a valid email address');
            isValid = false;
        }

        // Validate privacy checkbox
        const privacyCheckbox = document.getElementById('privacy');
        if (privacyCheckbox && !privacyCheckbox.checked) {
            this.showFieldError(privacyCheckbox, 'You must agree to the Privacy Policy');
            isValid = false;
        }

        return isValid;
    }

    validateField(field) {
        const value = field.value.trim();
        
        if (field.hasAttribute('required') && !value) {
            this.showFieldError(field, 'This field is required');
            return false;
        }

        if (field.type === 'email' && value && !this.validateEmail(value)) {
            this.showFieldError(field, 'Please enter a valid email address');
            return false;
        }

        this.clearFieldError(field);
        return true;
    }

    validateEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    showFieldError(field, message) {
        this.clearFieldError(field);
        
        const errorElement = document.createElement('span');
        errorElement.className = 'field-error';
        errorElement.textContent = message;
        
        field.classList.add('error');
        field.parentNode.appendChild(errorElement);
    }

    clearFieldError(field) {
        field.classList.remove('error');
        const existingError = field.parentNode.querySelector('.field-error');
        if (existingError) {
            existingError.remove();
        }
    }

    collectContactFormData() {
        const formData = new FormData(this.contactForm);
        const data = {};
        
        for (let [key, value] of formData.entries()) {
            data[key] = value;
        }
        
        return data;
    }

    async submitContactForm(data) {
        // Replace this with your actual backend endpoint
        const endpoint = '/api/contact';
        
        try {
            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data)
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            return await response.json();
        } catch (error) {
            // Fallback for demo - simulate success
            console.warn('Using fallback form submission (demo mode)');
            
            // Simulate API delay
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            // Simulate success response
            return { success: true, message: 'Message sent successfully' };
        }
    }

    async submitNewsletter(data) {
        // Replace this with your actual newsletter service endpoint
        const endpoint = '/api/newsletter';
        
        try {
            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data)
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            return await response.json();
        } catch (error) {
            // Fallback for demo
            console.warn('Using fallback newsletter signup (demo mode)');
            
            await new Promise(resolve => setTimeout(resolve, 800));
            
            return { success: true, message: 'Subscribed successfully' };
        }
    }

    showSuccessMessage() {
        this.contactForm.style.display = 'none';
        this.formSuccess.style.display = 'block';
        
        // Scroll to success message
        this.formSuccess.scrollIntoView({ behavior: 'smooth' });
    }

    showErrorMessage(message) {
        this.showNotification(message, 'error');
    }

    showNotification(message, type = 'info') {
        // Use the global notification system from main.js
        if (typeof showNotification === 'function') {
            showNotification(message, type);
        } else {
            alert(message); // Fallback
        }
    }

    resetContactForm() {
        this.contactForm.reset();
        this.clearAllFieldErrors();
    }

    clearAllFieldErrors() {
        const errorFields = this.contactForm.querySelectorAll('.error');
        const errorMessages = this.contactForm.querySelectorAll('.field-error');
        
        errorFields.forEach(field => field.classList.remove('error'));
        errorMessages.forEach(error => error.remove());
    }

    formatPhoneNumber(phoneField) {
        let value = phoneField.value.replace(/\D/g, '');
        
        // Format for Saudi Arabia (+966)
        if (value.startsWith('966')) {
            value = value.replace(/^966(\d{3})(\d{3})(\d{4})/, '+966 $1 $2 $3');
        }
        // Format for other international numbers
        else if (value.length >= 10) {
            value = value.replace(/(\d{3})(\d{3})(\d{4})/, '$1 $2 $3');
        }
        
        phoneField.value = value;
    }
}

// Global reset form function for success page
window.resetForm = function() {
    const contactForm = document.getElementById('contactForm');
    const formSuccess = document.getElementById('formSuccess');
    
    if (contactForm && formSuccess) {
        formSuccess.style.display = 'none';
        contactForm.style.display = 'block';
        contactForm.reset();
        
        // Scroll back to form
        contactForm.scrollIntoView({ behavior: 'smooth' });
    }
};

// Auto-resize textarea
class TextareaAutoResize {
    constructor() {
        this.init();
    }

    init() {
        const textareas = document.querySelectorAll('textarea');
        textareas.forEach(textarea => {
            textarea.addEventListener('input', () => {
                this.autoResize(textarea);
            });
            
            // Initial resize
            this.autoResize(textarea);
        });
    }

    autoResize(textarea) {
        textarea.style.height = 'auto';
        textarea.style.height = textarea.scrollHeight + 'px';
    }
}

// Form field animations
class FormAnimations {
    constructor() {
        this.init();
    }

    init() {
        this.addFocusAnimations();
        this.addFieldValidationAnimations();
    }

    addFocusAnimations() {
        const formFields = document.querySelectorAll('input, select, textarea');
        
        formFields.forEach(field => {
            field.addEventListener('focus', () => {
                field.parentNode.classList.add('focused');
            });
            
            field.addEventListener('blur', () => {
                if (!field.value) {
                    field.parentNode.classList.remove('focused');
                }
            });
            
            // Check if field has value on load
            if (field.value) {
                field.parentNode.classList.add('focused');
            }
        });
    }

    addFieldValidationAnimations() {
        const formFields = document.querySelectorAll('input[required], select[required], textarea[required]');
        
        formFields.forEach(field => {
            field.addEventListener('invalid', (e) => {
                e.target.classList.add('shake');
                setTimeout(() => {
                    e.target.classList.remove('shake');
                }, 500);
            });
        });
    }
}

// Character counter for textarea
class CharacterCounter {
    constructor() {
        this.init();
    }

    init() {
        const textareas = document.querySelectorAll('textarea');
        textareas.forEach(textarea => {
            if (textarea.hasAttribute('maxlength')) {
                this.addCounter(textarea);
            }
        });
    }

    addCounter(textarea) {
        const maxLength = textarea.getAttribute('maxlength');
        const counter = document.createElement('div');
        counter.className = 'character-counter';
        
        const updateCounter = () => {
            const currentLength = textarea.value.length;
            counter.textContent = `${currentLength}/${maxLength}`;
            
            if (currentLength > maxLength * 0.9) {
                counter.classList.add('warning');
            } else {
                counter.classList.remove('warning');
            }
        };
        
        textarea.addEventListener('input', updateCounter);
        textarea.parentNode.appendChild(counter);
        updateCounter();
    }
}

// Initialize all form functionality
document.addEventListener('DOMContentLoaded', () => {
    const contactFormManager = new ContactFormManager();
    const textareaAutoResize = new TextareaAutoResize();
    const formAnimations = new FormAnimations();
    const characterCounter = new CharacterCounter();
    
    // Make form manager globally accessible
    window.contactFormManager = contactFormManager;
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        ContactFormManager,
        TextareaAutoResize,
        FormAnimations,
        CharacterCounter
    };
}