#!/bin/bash

cat << 'EOF'

╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║          🔥 ACTIVATE SPICY THEME - STEP BY STEP 🔥              ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

Your spicy theme is DEPLOYED but NOT ACTIVATED yet!
Currently using: Default Keycloak theme (boring white)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 ACTIVATE IN 3 STEPS:

STEP 1: Open Keycloak Admin Console
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Open this URL in your browser:
👉 http://localhost:8080

Login with:
  Username: admin
  Password: admin

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 2: Navigate to Theme Settings
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Click "demo" in the top-left dropdown (select your realm)
2. Click "Realm settings" in the left sidebar
3. Click the "Themes" tab at the top

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 3: Select Spicy Theme
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

In the "Login theme" dropdown:
  ✅ Select: "spicy-theme"

Then:
  ✅ Click the "Save" button at the bottom

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 4: Test It! 🎉
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Open this URL to see the magic:
👉 http://127.0.0.1:8001/saml/login/

Or open a new incognito window and visit:
👉 http://localhost:8080/realms/demo/account

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✨ WHAT YOU'LL SEE:

Instead of boring white:
  ❌ Plain white background
  ❌ Basic form

You'll see SPICY:
  ✅ 🌈 Animated rainbow gradient background
  ✅ 💎 Glassmorphism frosted card
  ✅ 🌟 Glowing purple title
  ✅ ✨ Smooth animations
  ✅ 🔥 Modern professional design

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨 TROUBLESHOOTING:

If theme doesn't appear in dropdown:
  → Check: docker exec keycloak-sso ls /opt/keycloak/themes/
  → Should see: spicy-theme

If still using old theme after saving:
  → Clear browser cache (Ctrl+Shift+R)
  → Or open in incognito/private window

If CSS not loading:
  → Make sure you clicked "Save" after selecting theme
  → Refresh the page (hard refresh)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📸 VISUAL GUIDE:

Admin Console → demo (top-left) → Realm settings (left sidebar) 
→ Themes tab → Login theme: spicy-theme → Save

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 QUICK LINKS:

Admin Console: http://localhost:8080
Test Login:    http://127.0.0.1:8001/saml/login/
Direct Login:  http://localhost:8080/realms/demo/account

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GO ACTIVATE IT NOW! 🚀🔥

EOF
