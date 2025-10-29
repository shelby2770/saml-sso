/**
 * Attribute Consent Page JavaScript
 * Handles attribute selection for SAML SSO with encrypted attributes
 */

(function() {
    'use strict';

    console.log('🔐 Attribute Consent Module Loaded');

    let selectedCount = 0;

    /**
     * Update selection counter
     */
    function updateCounter() {
        const checkboxes = document.querySelectorAll('.attribute-checkbox:checked');
        selectedCount = checkboxes.length;
        
        const countText = document.getElementById('count-text');
        const submitBtn = document.getElementById('submit-btn');
        
        if (selectedCount === 0) {
            countText.textContent = 'No attributes selected';
            countText.style.color = '#666';
            submitBtn.disabled = true;
        } else if (selectedCount === 1) {
            countText.textContent = '1 attribute selected';
            countText.style.color = '#2196f3';
            submitBtn.disabled = false;
        } else {
            countText.textContent = `${selectedCount} attributes selected`;
            countText.style.color = '#2196f3';
            submitBtn.disabled = false;
        }

        console.log(`📊 Selected ${selectedCount} attributes`);
    }

    /**
     * Handle "Select All" checkbox
     */
    function handleSelectAll(event) {
        const isChecked = event.target.checked;
        const checkboxes = document.querySelectorAll('.attribute-checkbox');
        
        checkboxes.forEach(checkbox => {
            checkbox.checked = isChecked;
        });

        updateCounter();
        
        if (isChecked) {
            console.log('✅ All attributes selected');
        } else {
            console.log('❌ All attributes deselected');
        }
    }

    /**
     * Handle individual checkbox changes
     */
    function handleCheckboxChange() {
        updateCounter();
        
        // Update "Select All" checkbox state
        const selectAllCheckbox = document.getElementById('select-all');
        const checkboxes = document.querySelectorAll('.attribute-checkbox');
        const checkedCheckboxes = document.querySelectorAll('.attribute-checkbox:checked');
        
        if (checkedCheckboxes.length === checkboxes.length) {
            selectAllCheckbox.checked = true;
            selectAllCheckbox.indeterminate = false;
        } else if (checkedCheckboxes.length > 0) {
            selectAllCheckbox.checked = false;
            selectAllCheckbox.indeterminate = true;
        } else {
            selectAllCheckbox.checked = false;
            selectAllCheckbox.indeterminate = false;
        }
    }

    /**
     * Handle form submission
     */
    function handleFormSubmit(event) {
        const checkboxes = document.querySelectorAll('.attribute-checkbox:checked');
        
        if (checkboxes.length === 0) {
            event.preventDefault();
            alert('⚠️ Please select at least one attribute to share with the service provider.');
            return false;
        }

        // Log selected attributes
        console.log('📤 Submitting selected attributes:');
        checkboxes.forEach(checkbox => {
            console.log(`   ✓ ${checkbox.value}`);
        });

        return true;
    }

    /**
     * Initialize on page load
     */
    document.addEventListener('DOMContentLoaded', function() {
        console.log('🚀 Initializing Attribute Consent Page...');

        // Get elements
        const selectAllCheckbox = document.getElementById('select-all');
        const attributeCheckboxes = document.querySelectorAll('.attribute-checkbox');
        const form = document.getElementById('attribute-consent-form');
        
        // Add event listeners
        if (selectAllCheckbox) {
            selectAllCheckbox.addEventListener('change', handleSelectAll);
            console.log('✅ "Select All" checkbox initialized');
        }

        attributeCheckboxes.forEach(checkbox => {
            checkbox.addEventListener('change', handleCheckboxChange);
        });
        console.log(`✅ ${attributeCheckboxes.length} attribute checkboxes initialized`);

        if (form) {
            form.addEventListener('submit', handleFormSubmit);
            console.log('✅ Form submission handler initialized');
        }

        // Initial counter update
        updateCounter();

        console.log('✅ Attribute Consent Page ready');
    });

})();
