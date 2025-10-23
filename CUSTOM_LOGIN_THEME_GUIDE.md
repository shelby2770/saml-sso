# 🎨 Custom Login Theme with Alerts

## Overview
This custom Keycloak theme adds beautiful animated alerts to the login page that show:
- ✅ **Success alerts** when login is successful
- ❌ **Error alerts** when login fails (wrong password, disabled account, etc.)
- 🔄 **Processing alerts** while authentication is in progress

## Features

### 🎉 Success Alerts
- Displays when user successfully authenticates
- Beautiful purple gradient with animation
- Auto-closes after 5 seconds
- Shows "Login Successful! Welcome!" message

### ❌ Error Alerts
- Displays when login fails
- Pink/red gradient with animation
- Shows specific error message (e.g., "Invalid username or password")
- Auto-closes after 5 seconds

### 🔄 Processing Alerts
- Shows immediately when "Sign In" is clicked
- Displays loading spinner
- Message: "Authenticating... Please wait while we verify your credentials"

### ✨ Design Features
- Smooth slide-in animation from right
- Pulse animation on icons
- Gradient backgrounds
- Closeable with × button or ESC key
- Responsive design
- Modern, clean UI

## Installation Steps

### Step 1: Deploy Theme to Keycloak

Run the deployment script:

```bash
cd "/home/shelby70/Projects/Django-SAML (2)"
bash deploy-custom-login-theme.sh
```

This will:
1. Copy theme files to Keycloak container
2. Restart Keycloak
3. Wait for Keycloak to be ready

### Step 2: Activate Theme in Keycloak

1. Open Keycloak Admin Console: http://localhost:8080
2. Login with: `admin` / `admin`
3. Select **demo** realm (top-left dropdown)
4. Navigate to: **Realm settings** → **Themes** tab
5. In **Login theme** dropdown, select: **custom-login-theme**
6. Click **Save**

### Step 3: Test the Theme

1. Open: http://127.0.0.1:8001/api/saml/login/
2. You'll be redirected to Keycloak login page

**Test Success:**
- Enter: `testuser` / `password123`
- Click "Sign In"
- See processing alert → success alert → redirect

**Test Error:**
- Enter: `testuser` / `wrongpassword`
- Click "Sign In"
- See processing alert → error alert

## File Structure

```
custom-login-theme/
├── theme.properties                          # Root theme config
├── login/                                    # Login theme folder
│   ├── theme.properties                      # Login theme config
│   ├── login.ftl                            # Login page template
│   └── resources/
│       ├── css/
│       │   └── custom-alerts.css            # Alert styles
│       └── js/
│           └── custom-alerts.js             # Alert JavaScript logic
```

## How It Works

### 1. Custom CSS (`custom-alerts.css`)
- Defines alert container styles
- Creates gradient backgrounds
- Implements animations (slideInRight, fadeOut, pulse, bounceIn)
- Styles success/error/processing states
- Adds hover effects to buttons

### 2. Custom JavaScript (`custom-alerts.js`)
- `AlertManager` object manages all alerts
- Detects Keycloak error messages and replaces them with custom alerts
- Intercepts form submission to show processing alert
- Handles URL parameters for success/error states
- Keyboard shortcut (ESC) to close alerts

### 3. Login Template (`login.ftl`)
- FreeMarker template for login page
- Integrates custom CSS and JS files
- Maintains Keycloak's default structure
- Compatible with Keycloak 23.0

## Customization

### Change Alert Colors

Edit `custom-alerts.css`:

```css
/* Success alert - change gradient colors */
.custom-alert-success {
    background: linear-gradient(135deg, #YOUR_COLOR1 0%, #YOUR_COLOR2 100%);
}

/* Error alert - change gradient colors */
.custom-alert-error {
    background: linear-gradient(135deg, #YOUR_COLOR1 0%, #YOUR_COLOR2 100%);
}
```

### Change Alert Messages

Edit `custom-alerts.js`:

```javascript
// Success message
showSuccess: function(message) {
    this.show({
        title: 'Your Custom Title!',
        message: message || 'Your custom success message',
        // ... rest of config
    });
}

// Error message
showError: function(message) {
    this.show({
        title: 'Your Custom Error Title',
        message: message || 'Your custom error message',
        // ... rest of config
    });
}
```

### Change Alert Duration

Edit `custom-alerts.js`:

```javascript
duration: 5000  // Change to desired milliseconds (e.g., 3000 = 3 seconds)
```

### Change Animation Speed

Edit `custom-alerts.css`:

```css
animation: slideInRight 0.5s ease-out;  /* Change 0.5s to desired speed */
```

## Testing Alert Types

### Test Success Alert (Manual Trigger)

Open browser console on login page and run:

```javascript
window.KeycloakAlerts.showSuccess('Custom success message!');
```

### Test Error Alert (Manual Trigger)

```javascript
window.KeycloakAlerts.showError('Custom error message!');
```

### Test Processing Alert

```javascript
window.KeycloakAlerts.showProcessing();
```

## Troubleshooting

### Theme Not Showing

**Problem:** Custom theme doesn't appear in dropdown

**Solution:**
```bash
# Check theme files in container
docker exec keycloak-sso ls -la /opt/keycloak/themes/

# Redeploy theme
bash deploy-custom-login-theme.sh
```

### Alerts Not Appearing

**Problem:** Login page shows but alerts don't appear

**Solutions:**
1. Check browser console for JavaScript errors (F12)
2. Verify theme is activated in Realm settings
3. Clear browser cache (Ctrl+Shift+Delete)
4. Verify CSS/JS files loaded (Network tab in browser DevTools)

### Theme Breaks After Keycloak Restart

**Problem:** Theme disappears after restarting Keycloak

**Solution:**
Theme files are stored in container, which is ephemeral. Either:
1. Redeploy theme after restart: `bash deploy-custom-login-theme.sh`
2. Or mount theme as volume in docker-compose.yml:

```yaml
volumes:
  - ./custom-login-theme:/opt/keycloak/themes/custom-login-theme
```

### CSS Not Applying

**Problem:** Alerts show but styling is wrong

**Solution:**
1. Check `login/theme.properties` includes CSS file
2. Clear browser cache
3. Verify CSS file path: `/opt/keycloak/themes/custom-login-theme/login/resources/css/custom-alerts.css`

## Advanced Features

### Add Sound Effects

Add to `custom-alerts.js`:

```javascript
showSuccess: function(message) {
    // Play success sound
    new Audio('/path/to/success.mp3').play();
    
    this.show({...});
}
```

### Add Vibration (Mobile)

```javascript
showError: function(message) {
    // Vibrate on error (mobile devices)
    if (navigator.vibrate) {
        navigator.vibrate([100, 50, 100]);
    }
    
    this.show({...});
}
```

### Track Analytics

```javascript
show: function(config) {
    // Send to analytics
    if (window.gtag) {
        gtag('event', 'login_alert', {
            alert_type: config.type,
            alert_message: config.message
        });
    }
    
    // ... rest of show method
}
```

## API Reference

### AlertManager Methods

```javascript
// Show success alert
window.KeycloakAlerts.showSuccess(message);

// Show error alert
window.KeycloakAlerts.showError(message);

// Show processing alert
window.KeycloakAlerts.showProcessing();

// Show custom alert
window.KeycloakAlerts.show({
    type: 'success' | 'error',
    icon: '🎉' | '<html>',
    title: 'Alert Title',
    message: 'Alert message',
    duration: 5000,  // 0 = don't auto-close
    closeable: true  // show × button
});

// Remove specific alert
window.KeycloakAlerts.remove(alertElement);

// Remove all alerts
window.KeycloakAlerts.removeAll();
```

## Screenshots & Examples

### Success Alert
- Background: Purple gradient (667eea → 764ba2)
- Icon: 🎉
- Title: "Login Successful!"
- Message: "Welcome! Redirecting you to your application..."
- Duration: 5 seconds
- Animation: Slides in from right, fades out

### Error Alert
- Background: Pink gradient (f093fb → f5576c)
- Icon: ❌
- Title: "Login Failed"
- Message: "Invalid username or password. Please try again."
- Duration: 5 seconds
- Animation: Slides in from right, fades out

### Processing Alert
- Background: Purple gradient
- Icon: Loading spinner
- Title: "Authenticating..."
- Message: "Please wait while we verify your credentials."
- Duration: Infinite (until page redirect)
- Animation: Slides in from right

## Related Documentation

- `COMPLETE_USER_FLOW.md` - Complete authentication flow
- `CUSTOM_PROVIDER_SUCCESS.md` - Custom provider setup
- `KEYCLOAK_SETUP.md` - Keycloak initial setup

## Credits

- Theme based on Keycloak default theme
- Custom alerts designed for Django-SAML project
- Animations inspired by modern UI/UX practices

---

**🎉 Enjoy your custom login experience with beautiful alerts!**
