/**
 * Custom Alert System for Keycloak Login
 * Shows beautiful animated alerts for success/error states
 */

(function() {
    'use strict';

    // Alert manager
    const AlertManager = {
        // Show success alert
        showSuccess: function(message) {
            this.show({
                type: 'success',
                icon: '🎉',
                title: 'Login Successful!',
                message: message || 'Welcome! Redirecting you to your application...',
                duration: 5000
            });
        },

        // Show error alert
        showError: function(message) {
            this.show({
                type: 'error',
                icon: '❌',
                title: 'Login Failed',
                message: message || 'Invalid username or password. Please try again.',
                duration: 5000
            });
        },

        // Show processing alert
        showProcessing: function() {
            this.show({
                type: 'success',
                icon: '<div class="custom-alert-spinner"></div>',
                title: 'Authenticating...',
                message: 'Please wait while we verify your credentials.',
                duration: 0, // Don't auto-close
                closeable: false
            });
        },

        // Generic show method
        show: function(config) {
            // Remove any existing alerts
            this.removeAll();

            // Create alert element
            const alert = document.createElement('div');
            alert.className = `custom-alert custom-alert-${config.type}`;
            alert.setAttribute('role', 'alert');
            alert.setAttribute('aria-live', 'assertive');

            // Build alert HTML
            let iconHTML = config.icon;
            if (config.icon && !config.icon.includes('<')) {
                iconHTML = `<span class="custom-alert-icon">${config.icon}</span>`;
            }

            let closeButton = '';
            if (config.closeable !== false) {
                closeButton = '<button class="custom-alert-close" aria-label="Close">&times;</button>';
            }

            alert.innerHTML = `
                ${iconHTML}
                <div class="custom-alert-content">
                    <div class="custom-alert-title">${config.title}</div>
                    <div class="custom-alert-message">${config.message}</div>
                </div>
                ${closeButton}
            `;

            // Add to document
            document.body.appendChild(alert);

            // Add close handler
            if (config.closeable !== false) {
                const closeBtn = alert.querySelector('.custom-alert-close');
                closeBtn.addEventListener('click', () => {
                    this.remove(alert);
                });
            }

            // Auto-remove after duration
            if (config.duration > 0) {
                setTimeout(() => {
                    this.remove(alert);
                }, config.duration);
            }

            return alert;
        },

        // Remove specific alert
        remove: function(alert) {
            if (alert && alert.parentNode) {
                alert.style.animation = 'fadeOut 0.3s ease-out forwards';
                setTimeout(() => {
                    if (alert.parentNode) {
                        alert.parentNode.removeChild(alert);
                    }
                }, 300);
            }
        },

        // Remove all alerts
        removeAll: function() {
            const alerts = document.querySelectorAll('.custom-alert');
            alerts.forEach(alert => this.remove(alert));
        }
    };

    // Wait for DOM to be ready
    function init() {
        // Check for error messages from Keycloak
        const errorDiv = document.querySelector('.alert-error, #kc-error-message, .kc-feedback-text');
        if (errorDiv && errorDiv.textContent.trim()) {
            const errorMessage = errorDiv.textContent.trim();
            // Hide Keycloak's default error
            errorDiv.style.display = 'none';
            // Show custom alert
            AlertManager.showError(errorMessage);
        }

        // Check if there's a success message (from URL parameter or session)
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('success') === 'true') {
            AlertManager.showSuccess();
        }

        // Intercept form submission
        const loginForm = document.getElementById('kc-form-login');
        if (loginForm) {
            loginForm.addEventListener('submit', function(e) {
                // Show processing alert
                AlertManager.showProcessing();
                
                // Let the form submit naturally
                // The page will redirect, so we don't need to handle the response
            });
        }

        // Check for authentication errors in URL
        const error = urlParams.get('error');
        const errorDescription = urlParams.get('error_description');
        if (error) {
            let message = 'Authentication failed. Please try again.';
            if (errorDescription) {
                message = decodeURIComponent(errorDescription);
            } else if (error === 'invalid_credentials') {
                message = 'Invalid username or password.';
            } else if (error === 'user_disabled') {
                message = 'Your account has been disabled. Please contact support.';
            } else if (error === 'account_locked') {
                message = 'Your account is temporarily locked. Please try again later.';
            }
            AlertManager.showError(message);
        }

        // Add keyboard shortcut (Escape to close alerts)
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                AlertManager.removeAll();
            }
        });
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // Make AlertManager available globally for testing
    window.KeycloakAlerts = AlertManager;

})();
