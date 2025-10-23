#!/bin/bash

# Keycloak Source Code Explorer
# This script clones Keycloak source and helps you explore authentication components

echo "🔍 Keycloak Source Code Explorer"
echo "================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Clone Keycloak source
echo -e "${BLUE}Step 1: Cloning Keycloak source code...${NC}"
cd ~/Projects

if [ -d "keycloak" ]; then
    echo -e "${YELLOW}Keycloak directory already exists. Updating...${NC}"
    cd keycloak
    git fetch
    git checkout 23.0.0
else
    echo "Cloning Keycloak repository..."
    git clone https://github.com/keycloak/keycloak.git
    cd keycloak
    git checkout 23.0.0
fi

echo -e "${GREEN}✓ Keycloak source code ready at: ~/Projects/keycloak${NC}"
echo ""

# Step 2: Show key directories
echo -e "${BLUE}Step 2: Key directories for authentication customization:${NC}"
echo ""
echo "📁 Core SPIs (Your extension points):"
echo "   server-spi/src/main/java/org/keycloak/"
ls -la server-spi/src/main/java/org/keycloak/ 2>/dev/null | grep "^d" | awk '{print "     - " $9}'

echo ""
echo "📁 Authentication implementation:"
echo "   services/src/main/java/org/keycloak/authentication/"
ls -la services/src/main/java/org/keycloak/authentication/ 2>/dev/null | grep "^d" | awk '{print "     - " $9}'

echo ""

# Step 3: Find key authentication files
echo -e "${BLUE}Step 3: Finding key authentication files...${NC}"
echo ""

echo "🔐 Event System (Hook into user events):"
find server-spi -name "*Event*.java" -type f | grep -E "(EventListenerProvider|EventType|Event\.java)" | head -5
echo ""

echo "🔐 Authentication Interfaces:"
find server-spi -name "*Authenticator*.java" -type f | head -5
echo ""

echo "🔐 User Model & Storage:"
find server-spi -name "UserModel.java" -o -name "UserStorageProvider.java"
echo ""

echo "🔐 Built-in Authenticators (Study these!):"
find services/src/main/java/org/keycloak/authentication/authenticators -name "*.java" -type f | head -10
echo ""

# Step 4: Create quick reference
echo -e "${BLUE}Step 4: Creating quick reference file...${NC}"

cat > ~/Projects/keycloak/AUTHENTICATION_FILES_REFERENCE.md << 'EOF'
# 🔍 Keycloak Authentication Files - Quick Reference

## 📌 Must Study Files (Priority Order)

### 1. Event System (Your Main Hook)
```
server-spi/src/main/java/org/keycloak/events/
├── EventListenerProvider.java       ⭐ Implement this to intercept events
├── EventListenerProviderFactory.java
├── EventType.java                   📋 All event types (LOGIN, REGISTER, etc.)
└── Event.java                       📦 Event data structure
```

### 2. Authentication Flow Engine
```
services/src/main/java/org/keycloak/authentication/
├── AuthenticationProcessor.java     🔧 Core auth engine
├── AuthenticationFlowContext.java   📝 Context passed to authenticators
└── AuthenticationFlowError.java     ❌ Error types
```

### 3. Built-in Authenticators (Templates to Copy)
```
services/src/main/java/org/keycloak/authentication/authenticators/browser/
├── UsernamePasswordForm.java        🔐 Password authentication
├── OTPFormAuthenticator.java        🔢 OTP/2FA
├── UsernameForm.java                👤 Username-only form
└── CookieAuthenticator.java         🍪 Remember-me cookie
```

### 4. User Management
```
server-spi/src/main/java/org/keycloak/models/
├── UserModel.java                   👤 User interface
├── RealmModel.java                  🌐 Realm interface
└── UserProvider.java                💾 User storage
```

### 5. REST Endpoints (Entry Points)
```
services/src/main/java/org/keycloak/services/resources/
├── LoginActionsService.java         🚪 Login/Register entry point
├── RealmsResource.java              🌐 Realm endpoints
└── admin/                           ⚙️  Admin API
```

## 🎯 Common Override Scenarios

### Scenario 1: Modify User Data Before DB Save
**File to study:** `server-spi/src/main/java/org/keycloak/events/EventListenerProvider.java`
**What to implement:** EventListenerProvider
**Difficulty:** ⭐ Easy

### Scenario 2: Custom Login Validation
**File to study:** `services/src/.../authenticators/browser/UsernamePasswordForm.java`
**What to implement:** Authenticator interface
**Difficulty:** ⭐⭐ Medium

### Scenario 3: External User Database
**File to study:** `server-spi/src/main/java/org/keycloak/storage/UserStorageProvider.java`
**What to implement:** UserStorageProvider
**Difficulty:** ⭐⭐⭐ Advanced

### Scenario 4: Custom 2FA/MFA
**File to study:** `services/src/.../authenticators/browser/OTPFormAuthenticator.java`
**What to implement:** Authenticator interface
**Difficulty:** ⭐⭐ Medium

## 📖 How to Read the Code

### Step 1: Start with Event Types
```bash
cat server-spi/src/main/java/org/keycloak/events/EventType.java
```
Shows all events you can intercept: LOGIN, REGISTER, UPDATE_PROFILE, etc.

### Step 2: Trace a Login Flow
```bash
# Find where LOGIN event is fired
grep -r "EventType.LOGIN" services/src/
```

### Step 3: Study Username/Password Auth
```bash
cat services/src/main/java/org/keycloak/authentication/authenticators/browser/UsernamePasswordForm.java
```

### Step 4: Look at User Model
```bash
cat server-spi/src/main/java/org/keycloak/models/UserModel.java
```

## 🔬 Code Flow Example: User Login

```
1. Browser POST /realms/demo/login-actions/authenticate
   ↓
2. LoginActionsService.authenticate()
   Location: services/src/.../resources/LoginActionsService.java
   ↓
3. AuthenticationProcessor.authenticate()
   Location: services/src/.../authentication/AuthenticationProcessor.java
   ↓
4. UsernamePasswordForm.action()
   Location: services/src/.../authenticators/browser/UsernamePasswordForm.java
   ↓
5. validateUserAndPassword()
   - Finds user
   - Checks if enabled
   - Validates password
   ↓
6. AuthenticationProcessor.authenticationComplete()
   - Creates user session
   - Fires LOGIN event  ⭐ Your EventListener called here!
   - Generates tokens
   ↓
7. Redirect to application
```

## 🎨 Frontend (Themes)

```
themes/src/main/resources/theme/
├── base/                            📦 Base theme (parent)
│   └── login/
│       ├── template.ftl             🎭 Main template
│       ├── login.ftl                🔐 Login page
│       ├── register.ftl             📝 Registration page
│       └── resources/               🎨 CSS, JS, images
│
└── keycloak/                        🎨 Default Keycloak theme
    └── login/
        └── resources/
            └── css/login.css
```

## 🛠️ Quick Commands

```bash
# Find all authenticators
find services -name "*Authenticator*.java" -type f

# Find event listeners
find server-spi -name "*Event*.java" -type f

# Find user storage providers
find server-spi -name "*Storage*.java" -type f

# Search for specific functionality
grep -r "validatePassword" services/src/

# See how password is hashed
grep -r "PasswordHashProvider" server-spi/
```

## 📚 Next Steps

1. Read EventListenerProvider.java - understand events
2. Read UsernamePasswordForm.java - see how auth works
3. Read AuthenticationProcessor.java - see flow control
4. Implement your own EventListener first (easiest)
5. Then try custom Authenticator

---

Happy code exploring! 🚀
EOF

echo -e "${GREEN}✓ Created reference file: ~/Projects/keycloak/AUTHENTICATION_FILES_REFERENCE.md${NC}"
echo ""

# Step 5: Open key files for viewing
echo -e "${BLUE}Step 5: Key files to study:${NC}"
echo ""
echo "📖 Study these files in order:"
echo ""
echo "1. Event System:"
echo "   cat ~/Projects/keycloak/server-spi/src/main/java/org/keycloak/events/EventListenerProvider.java"
echo ""
echo "2. Event Types:"
echo "   cat ~/Projects/keycloak/server-spi/src/main/java/org/keycloak/events/EventType.java"
echo ""
echo "3. Authentication Processor:"
echo "   cat ~/Projects/keycloak/services/src/main/java/org/keycloak/authentication/AuthenticationProcessor.java"
echo ""
echo "4. Username/Password Auth:"
echo "   cat ~/Projects/keycloak/services/src/main/java/org/keycloak/authentication/authenticators/browser/UsernamePasswordForm.java"
echo ""
echo "5. User Model:"
echo "   cat ~/Projects/keycloak/server-spi/src/main/java/org/keycloak/models/UserModel.java"
echo ""

# Step 6: Create search helper
cat > ~/Projects/keycloak/search-auth-code.sh << 'SEARCHEOF'
#!/bin/bash
# Helper script to search Keycloak authentication code

case "$1" in
    "events")
        echo "🔍 Searching for event-related code..."
        find server-spi services -name "*Event*.java" -type f
        ;;
    "auth")
        echo "🔍 Searching for authentication code..."
        find services/src/main/java/org/keycloak/authentication -name "*.java" -type f
        ;;
    "user")
        echo "🔍 Searching for user model code..."
        find server-spi -name "*User*.java" -type f | grep -E "(UserModel|UserProvider|UserStorage)"
        ;;
    "login")
        echo "🔍 Searching for login flow..."
        grep -r "EventType.LOGIN" services/src/ --include="*.java"
        ;;
    *)
        echo "Usage: ./search-auth-code.sh [events|auth|user|login]"
        echo ""
        echo "Examples:"
        echo "  ./search-auth-code.sh events  - Find event-related files"
        echo "  ./search-auth-code.sh auth    - Find authentication files"
        echo "  ./search-auth-code.sh user    - Find user model files"
        echo "  ./search-auth-code.sh login   - Find where login happens"
        ;;
esac
SEARCHEOF

chmod +x ~/Projects/keycloak/search-auth-code.sh
echo -e "${GREEN}✓ Created search helper: ~/Projects/keycloak/search-auth-code.sh${NC}"
echo ""

# Final summary
echo ""
echo -e "${GREEN}=====================================================${NC}"
echo -e "${GREEN}✅ Keycloak Source Code Setup Complete!${NC}"
echo -e "${GREEN}=====================================================${NC}"
echo ""
echo "📍 Keycloak source location: ~/Projects/keycloak"
echo "📖 Quick reference: ~/Projects/keycloak/AUTHENTICATION_FILES_REFERENCE.md"
echo "🔍 Search helper: ~/Projects/keycloak/search-auth-code.sh"
echo ""
echo "🎯 Next steps:"
echo "1. cd ~/Projects/keycloak"
echo "2. cat AUTHENTICATION_FILES_REFERENCE.md"
echo "3. Start reading EventListenerProvider.java"
echo "4. Open in IDE: code . (VS Code) or idea . (IntelliJ)"
echo ""
echo "🚀 You're ready to explore Keycloak's internals!"
