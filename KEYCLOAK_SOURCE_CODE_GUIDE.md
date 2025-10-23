# 🔍 Keycloak Source Code Deep Dive - Understanding Authentication Internals

Complete guide to understanding Keycloak's codebase and identifying authentication components to override.

---

## 📚 Table of Contents

1. [Getting Keycloak Source Code](#getting-keycloak-source-code)
2. [Keycloak Architecture Overview](#keycloak-architecture-overview)
3. [Authentication Flow Deep Dive](#authentication-flow-deep-dive)
4. [Key Classes & Interfaces](#key-classes--interfaces)
5. [Where to Override What](#where-to-override-what)
6. [Step-by-Step Code Walkthrough](#step-by-step-code-walkthrough)
7. [Debugging Keycloak Source](#debugging-keycloak-source)

---

## 📥 Getting Keycloak Source Code

### Step 1: Clone Keycloak Repository

```bash
# Clone Keycloak source (version 23.0 to match your Docker image)
cd ~/Projects
git clone https://github.com/keycloak/keycloak.git
cd keycloak

# Checkout version 23.0 (match your Docker image)
git checkout 23.0.0

# Open in your IDE
code .  # VS Code
# or
idea . # IntelliJ IDEA
```

### Step 2: Key Directories to Explore

```
keycloak/
├── server-spi/              ⭐ Service Provider Interfaces (Your extension points)
│   └── src/main/java/org/keycloak/
│       ├── authentication/   🔐 Authentication SPIs
│       ├── events/          📊 Event system
│       ├── models/          💾 Data models (User, Realm, etc.)
│       └── provider/        🔌 Base provider interfaces
│
├── server-spi-private/      ⭐ Internal SPIs (more advanced)
│   └── src/main/java/org/keycloak/
│       ├── authentication/   🔐 Internal auth components
│       ├── sessions/        🎫 Session management
│       └── storage/         💾 Storage providers
│
├── services/                ⭐ Core implementation (How things actually work)
│   └── src/main/java/org/keycloak/
│       ├── authentication/  🔐 Auth implementation
│       ├── forms/           📝 Login forms
│       ├── services/        🌐 REST API services
│       └── events/          📊 Event listeners
│
├── themes/                  🎨 Default themes (login pages, etc.)
│   ├── base/
│   └── keycloak/
│
└── model/                   💾 Data model implementations
    └── jpa/                 Database/JPA entities
```

---

## 🏗️ Keycloak Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      USER (Browser)                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    THEMES (FreeMarker)                           │
│  • login.ftl, register.ftl, etc.                                │
│  • Resources: CSS, JS, Images                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  REST ENDPOINTS (JAX-RS)                         │
│  services/src/.../services/resources/                           │
│  • LoginActionsService.java     - Login handling                │
│  • RegistrationResource.java    - Registration                  │
│  • AuthenticationManager.java   - Auth orchestration            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              AUTHENTICATION FLOW ENGINE                          │
│  services/src/.../authentication/                               │
│  • DefaultAuthenticationFlow.java                               │
│  • AuthenticationProcessor.java                                 │
│  • AuthenticationFlowModel                                      │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   AUTHENTICATORS (SPIs)                          │
│  Built-in:                          Your Custom:                │
│  • UsernamePasswordForm             • CustomAuthenticator       │
│  • OTPFormAuthenticator             • BiometricAuthenticator    │
│  • UsernameForm                     • TwoFactorAuthenticator    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   USER STORAGE LAYER                             │
│  • UserModel interface                                          │
│  • UserProvider implementations                                 │
│  • Custom UserStorageProvider (for external DB)                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      EVENT SYSTEM                                │
│  • EventListenerProvider (Your hooks!)                          │
│  • Pre/Post processing                                          │
│  • Login, Register, Update events                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  DATABASE (JPA/Hibernate)                        │
│  model/jpa/src/.../entities/                                    │
│  • UserEntity, RealmEntity, CredentialEntity                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Authentication Flow Deep Dive

### How Login Actually Works (Code Flow)

#### 1. User Opens Login Page

**File:** `services/src/main/java/org/keycloak/services/resources/LoginActionsService.java`

```java
@Path("/{realm}/login-actions")
public class LoginActionsService {
    
    /**
     * Entry point for login flow
     * URL: /realms/{realm}/login-actions/authenticate
     */
    @Path("authenticate")
    @POST
    public Response authenticate(@FormParam("username") String username,
                                @FormParam("password") String password) {
        
        // 1. Load the authentication flow configuration
        AuthenticationFlowModel flow = realm.getBrowserFlow();
        
        // 2. Create authentication session
        AuthenticationSessionModel authSession = 
            createAuthenticationSession(realm, client);
        
        // 3. Start the authentication processor
        AuthenticationProcessor processor = 
            new AuthenticationProcessor();
        
        processor.setAuthenticationSession(authSession)
                 .setFlowPath(LoginActionsService.AUTHENTICATE_PATH)
                 .setBrowserFlow(true)
                 .setFlowId(flow.getId())
                 .setRealm(realm)
                 .setSession(session)
                 .setUriInfo(uriInfo)
                 .setRequest(request);
        
        // 4. Process the authentication flow
        Response response = processor.authenticate();
        
        return response;
    }
}
```

**🎯 Override Point:** Create custom REST endpoint or modify authentication session creation

---

#### 2. Authentication Processor Executes Flow

**File:** `services/src/main/java/org/keycloak/authentication/AuthenticationProcessor.java`

```java
public class AuthenticationProcessor {
    
    /**
     * Main authentication execution method
     * This iterates through all authenticators in the flow
     */
    public Response authenticate() {
        
        // Get all executions (authenticators) in the flow
        List<AuthenticationExecutionModel> executions = 
            realm.getAuthenticationExecutions(flowId);
        
        for (AuthenticationExecutionModel execution : executions) {
            
            // Get the authenticator factory
            AuthenticatorFactory factory = 
                (AuthenticatorFactory) session.getKeycloakSessionFactory()
                    .getProviderFactory(Authenticator.class, 
                                       execution.getAuthenticator());
            
            // Create authenticator instance
            Authenticator authenticator = factory.create(session);
            
            // Execute the authenticator
            authenticator.authenticate(this);
            
            // Check the result
            if (authenticationSession.getAuthNote(AUTH_COMPLETED) != null) {
                return authenticationComplete();
            }
            
            if (authenticationSession.getAuthNote(AUTH_CHALLENGE) != null) {
                return authenticationChallenge();
            }
        }
        
        return null;
    }
    
    /**
     * Called when authentication succeeds
     */
    protected Response authenticationComplete() {
        
        // 1. Create user session
        UserSessionModel userSession = 
            session.sessions().createUserSession(
                realm, 
                authenticationSession.getAuthenticatedUser(),
                username,
                clientConnection.getRemoteAddr(),
                authMethod,
                false,
                null,
                null
            );
        
        // 2. Fire LOGIN event
        event.event(EventType.LOGIN)
             .user(userSession.getUser())
             .session(userSession)
             .detail(Details.USERNAME, username)
             .success();  // ⭐ Event listeners execute here!
        
        // 3. Generate tokens
        TokenManager.attachAuthenticationSession(session, userSession, authenticationSession);
        
        // 4. Redirect to application
        return redirectAfterSuccessfulFlow();
    }
}
```

**🎯 Override Points:**
- Create custom `Authenticator` to change validation logic
- Use `EventListenerProvider` to hook into post-authentication
- Modify `authenticationComplete()` behavior

---

#### 3. Username/Password Authenticator

**File:** `services/src/main/java/org/keycloak/authentication/authenticators/browser/UsernamePasswordForm.java`

```java
public class UsernamePasswordForm extends AbstractUsernameFormAuthenticator 
                                  implements Authenticator {
    
    @Override
    public void authenticate(AuthenticationFlowContext context) {
        
        // Render the login form
        Response challenge = context.form().createLoginUsernamePassword();
        context.challenge(challenge);
    }
    
    @Override
    public void action(AuthenticationFlowContext context) {
        
        MultivaluedMap<String, String> formData = 
            context.getHttpRequest().getDecodedFormParameters();
        
        // Get username and password from form
        String username = formData.getFirst("username");
        String password = formData.getFirst("password");
        
        // Validate credentials
        boolean valid = validateUserAndPassword(context, username, password);
        
        if (valid) {
            context.success();  // ✅ Authentication successful
        } else {
            // ❌ Authentication failed
            context.getEvent()
                   .event(EventType.LOGIN_ERROR)
                   .error(Errors.INVALID_USER_CREDENTIALS);
            
            context.failure(AuthenticationFlowError.INVALID_CREDENTIALS);
        }
    }
    
    /**
     * The actual credential validation happens here
     */
    protected boolean validateUserAndPassword(
            AuthenticationFlowContext context,
            String username, 
            String password) {
        
        // 1. Find user
        UserModel user = KeycloakModelUtils.findUserByNameOrEmail(
            context.getSession(), 
            context.getRealm(), 
            username
        );
        
        if (user == null) {
            return false;  // User not found
        }
        
        // 2. Check if user is enabled
        if (!user.isEnabled()) {
            return false;
        }
        
        // 3. Validate password
        CredentialProvider credentialProvider = 
            context.getSession().getProvider(CredentialProvider.class);
        
        boolean valid = credentialProvider.isValid(
            context.getRealm(),
            user,
            UserCredentialModel.password(password)
        );
        
        if (!valid) {
            // Increment failed login count
            user.setAttribute("failedLoginAttempts", 
                String.valueOf(getFailedAttempts(user) + 1));
            return false;
        }
        
        // 4. Set authenticated user in session
        context.setUser(user);
        
        return true;
    }
}
```

**🎯 Override Points:**
- Create custom authenticator to change password validation
- Add additional checks (IP whitelist, device fingerprinting, etc.)
- Modify failed login attempt handling

---

#### 4. User Model & Storage

**File:** `server-spi/src/main/java/org/keycloak/models/UserModel.java`

```java
/**
 * User interface - this is what you work with
 */
public interface UserModel {
    
    String getId();
    String getUsername();
    void setUsername(String username);
    
    String getEmail();
    void setEmail(String email);
    
    String getFirstName();
    void setFirstName(String firstName);
    
    String getLastName();
    void setLastName(String lastName);
    
    boolean isEnabled();
    void setEnabled(boolean enabled);
    
    // Custom attributes (key-value pairs)
    void setSingleAttribute(String name, String value);
    String getFirstAttribute(String name);
    List<String> getAttribute(String name);
    Map<String, List<String>> getAttributes();
    
    // Credentials
    void setCredential(CredentialModel cred);
    List<CredentialModel> getCredentials();
    
    // Roles & Groups
    Set<RoleModel> getRoleMappings();
    Set<GroupModel> getGroups();
}
```

**File:** `server-spi/src/main/java/org/keycloak/storage/UserStorageProvider.java`

```java
/**
 * Implement this to use external user database
 */
public interface UserStorageProvider extends Provider {
    
    /**
     * Find user by username
     */
    UserModel getUserByUsername(RealmModel realm, String username);
    
    /**
     * Find user by email
     */
    UserModel getUserByEmail(RealmModel realm, String email);
    
    /**
     * Search users
     */
    List<UserModel> searchForUser(String search, RealmModel realm);
    
    /**
     * Validate credentials
     */
    boolean isValid(RealmModel realm, UserModel user, CredentialInput input);
}
```

**🎯 Override Points:**
- Implement `UserStorageProvider` for external database
- Extend `UserModel` behavior with custom attributes
- Create custom credential validation

---

#### 5. Event System (Your Main Hook!)

**File:** `server-spi/src/main/java/org/keycloak/events/EventListenerProvider.java`

```java
/**
 * This is THE interface to implement for intercepting events
 */
public interface EventListenerProvider extends Provider {
    
    /**
     * Called when user events occur (login, register, etc.)
     */
    void onEvent(Event event);
    
    /**
     * Called when admin events occur
     */
    void onEvent(AdminEvent event, boolean includeRepresentation);
}
```

**File:** `server-spi/src/main/java/org/keycloak/events/Event.java`

```java
/**
 * Event object contains all the information
 */
public class Event {
    
    private EventType type;           // LOGIN, REGISTER, LOGOUT, etc.
    private String realmId;           // Which realm
    private String clientId;          // Which client/app
    private String userId;            // Which user
    private String ipAddress;         // User's IP
    private String error;             // Error message if failed
    private Map<String, String> details;  // Additional details
    
    // EventType enum
    public enum EventType {
        LOGIN,
        LOGIN_ERROR,
        REGISTER,
        REGISTER_ERROR,
        LOGOUT,
        CODE_TO_TOKEN,
        UPDATE_EMAIL,
        UPDATE_PROFILE,
        UPDATE_PASSWORD,
        // ... many more
    }
}
```

**How Events Flow Through Your Custom Listener:**

```java
// Your implementation
public class CustomEventListenerProvider implements EventListenerProvider {
    
    @Override
    public void onEvent(Event event) {
        
        // This is called AFTER the event happens but BEFORE final commit
        // You can still modify user data here!
        
        if (event.getType() == EventType.REGISTER) {
            // User just registered
            String userId = event.getUserId();
            UserModel user = session.users().getUserById(realm, userId);
            
            // MODIFY USER DATA BEFORE IT'S COMMITTED
            user.setSingleAttribute("registrationIP", event.getIpAddress());
            user.setSingleAttribute("timestamp", String.valueOf(System.currentTimeMillis()));
            
            // Validate email domain
            if (!user.getEmail().endsWith("@company.com")) {
                user.setEnabled(false);
                user.setSingleAttribute("requiresApproval", "true");
            }
        }
        
        if (event.getType() == EventType.LOGIN) {
            // User logged in successfully
            String userId = event.getUserId();
            UserModel user = session.users().getUserById(realm, userId);
            
            // Track login
            int loginCount = Integer.parseInt(
                user.getFirstAttribute("loginCount") != null ? 
                user.getFirstAttribute("loginCount") : "0"
            );
            user.setSingleAttribute("loginCount", String.valueOf(loginCount + 1));
            user.setSingleAttribute("lastLoginIP", event.getIpAddress());
            user.setSingleAttribute("lastLoginTime", String.valueOf(System.currentTimeMillis()));
        }
    }
}
```

---

## 🎯 Where to Override What

### Authentication Flow Customization Matrix

| What You Want | Which Interface | File Location | Difficulty |
|---------------|----------------|---------------|------------|
| **Modify user data before DB save** | `EventListenerProvider` | `server-spi/src/.../events/` | ⭐ Easy |
| **Custom login validation** | `Authenticator` | `server-spi/src/.../authentication/` | ⭐⭐ Medium |
| **External user database** | `UserStorageProvider` | `server-spi/src/.../storage/` | ⭐⭐⭐ Advanced |
| **Custom 2FA/MFA** | `Authenticator` | `server-spi/src/.../authentication/` | ⭐⭐ Medium |
| **Change password rules** | `CredentialProvider` | `server-spi-private/src/.../credential/` | ⭐⭐⭐ Advanced |
| **Modify SAML tokens** | `ProtocolMapper` | `server-spi/src/.../protocol/` | ⭐⭐ Medium |
| **Custom registration flow** | `FormAction` | `server-spi/src/.../forms/` | ⭐⭐ Medium |
| **Add required actions** | `RequiredActionProvider` | `server-spi/src/.../authentication/` | ⭐⭐ Medium |
| **Custom theme logic** | `ThemeProvider` | `server-spi/src/.../theme/` | ⭐ Easy |

---

## 📖 Key Files to Study

### Must Read (Priority Order)

1. **Authentication Flow Entry Point**
   ```
   services/src/main/java/org/keycloak/services/resources/LoginActionsService.java
   ```
   - Entry point for all login/register actions
   - Shows how flows are initiated

2. **Authentication Processor**
   ```
   services/src/main/java/org/keycloak/authentication/AuthenticationProcessor.java
   ```
   - Core authentication engine
   - Executes authenticators in sequence
   - Handles success/failure

3. **Username/Password Authenticator**
   ```
   services/src/main/java/org/keycloak/authentication/authenticators/browser/UsernamePasswordForm.java
   ```
   - Default password authentication
   - Shows credential validation
   - Template for custom authenticators

4. **Event Listener Interface**
   ```
   server-spi/src/main/java/org/keycloak/events/EventListenerProvider.java
   ```
   - Your main hook into Keycloak
   - Intercept all user events

5. **User Model**
   ```
   server-spi/src/main/java/org/keycloak/models/UserModel.java
   ```
   - User data structure
   - Custom attributes

6. **Authentication Session**
   ```
   server-spi/src/main/java/org/keycloak/sessions/AuthenticationSessionModel.java
   ```
   - Temporary session during auth
   - Stores auth state

---

## 🔍 How to Read the Code

### Step-by-Step Investigation Process

#### Step 1: Start with Event Types

```bash
# Find all event types
cd ~/Projects/keycloak
grep -r "enum EventType" --include="*.java"

# Look at: server-spi/src/main/java/org/keycloak/events/EventType.java
cat server-spi/src/main/java/org/keycloak/events/EventType.java
```

#### Step 2: Trace Login Flow

```bash
# Find where LOGIN event is fired
grep -r "EventType.LOGIN" --include="*.java" services/

# This shows you:
# - Where login happens
# - What data is available
# - When you can intercept
```

#### Step 3: Find Authentication Interfaces

```bash
# List all authenticator interfaces
find server-spi -name "*Authenticator*.java" -type f

# Key ones:
# - Authenticator.java
# - AuthenticatorFactory.java
# - FormAuthenticator.java
```

#### Step 4: Study Built-in Implementations

```bash
# See how Keycloak implements password auth
cat services/src/main/java/org/keycloak/authentication/authenticators/browser/UsernamePasswordForm.java

# See how Keycloak implements OTP
cat services/src/main/java/org/keycloak/authentication/authenticators/browser/OTPFormAuthenticator.java
```

---

## 🛠️ Practical Example: Tracing a Login Request

### URL: User clicks "Login"

```
Browser Request:
POST /realms/demo/login-actions/authenticate
username=testuser
password=password123
```

### Code Execution Path:

```
1. LoginActionsService.authenticate()
   ↓
2. AuthenticationProcessor.authenticate()
   ↓
3. Load authentication flow (e.g., "browser" flow)
   ↓
4. Execute authenticators in sequence:
   │
   ├─→ UsernamePasswordForm.authenticate()
   │   └─→ Shows login form
   │
   ├─→ User submits form
   │
   ├─→ UsernamePasswordForm.action()
   │   ├─→ validateUserAndPassword()
   │   │   ├─→ Find user in database
   │   │   ├─→ Check if enabled
   │   │   ├─→ Validate password
   │   │   └─→ Return true/false
   │   │
   │   └─→ If valid: context.success()
   │
   ├─→ OTPFormAuthenticator.authenticate() (if enabled)
   │   └─→ Shows OTP form
   │
   └─→ All authenticators passed
       ↓
5. AuthenticationProcessor.authenticationComplete()
   ├─→ Create UserSessionModel
   ├─→ Fire Event: EventType.LOGIN
   │   └─→ ⭐ YOUR EventListenerProvider.onEvent() CALLED HERE
   │       └─→ You can modify user data now!
   ├─→ Generate tokens
   └─→ Redirect to application
```

---

## 🔬 Setting Up for Source Code Debugging

### Option 1: Import Keycloak in IDE

```bash
# Clone Keycloak
cd ~/Projects
git clone https://github.com/keycloak/keycloak.git
cd keycloak
git checkout 23.0.0

# Import in IntelliJ IDEA:
# 1. File → Open → Select keycloak directory
# 2. Wait for Maven import to complete
# 3. Enable "Sources" for modules you want to study
```

### Option 2: Attach Debugger to Running Container

Edit `docker-compose.yml`:

```yaml
services:
  keycloak:
    image: quay.io/keycloak/keycloak:23.0
    environment:
      # Enable debug mode
      DEBUG: "true"
      DEBUG_PORT: "*:8787"
    ports:
      - "8080:8080"
      - "8787:8787"  # Debug port
    command:
      - start-dev
      - --debug
```

Then in IntelliJ:
1. Run → Edit Configurations
2. Add → Remote JVM Debug
3. Host: localhost, Port: 8787
4. Set breakpoints in Keycloak source
5. Click Debug

---

## 📝 Creating Your Custom Authenticator

### Example: IP Whitelist Authenticator

Based on studying `UsernamePasswordForm.java`, create your own:

```java
package com.mycompany.keycloak;

import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.Authenticator;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;

import javax.ws.rs.core.Response;
import java.util.Arrays;
import java.util.List;

/**
 * Custom authenticator that checks IP whitelist
 * Based on studying Keycloak's UsernamePasswordForm.java
 */
public class IPWhitelistAuthenticator implements Authenticator {
    
    // Allowed IPs (in real app, load from config)
    private static final List<String> ALLOWED_IPS = Arrays.asList(
        "127.0.0.1",
        "192.168.1.100",
        "10.0.0.50"
    );

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        
        // Get client IP address
        String clientIP = context.getConnection().getRemoteAddr();
        
        // Check if IP is whitelisted
        if (ALLOWED_IPS.contains(clientIP)) {
            // IP is allowed, continue authentication
            context.success();
        } else {
            // IP is not allowed, block access
            context.getEvent()
                   .error("ip_not_whitelisted");
            
            Response challenge = context.form()
                .setError("Access denied from your location")
                .createErrorPage(Response.Status.FORBIDDEN);
            
            context.failure(AuthenticationFlowError.INVALID_USER, challenge);
        }
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        // Not needed for this authenticator
    }

    @Override
    public boolean requiresUser() {
        return false;  // Can check IP before user is identified
    }

    @Override
    public boolean configuredFor(KeycloakSession session, 
                                 RealmModel realm, 
                                 UserModel user) {
        return true;  // Always available
    }

    @Override
    public void setRequiredActions(KeycloakSession session, 
                                   RealmModel realm, 
                                   UserModel user) {
        // No required actions
    }

    @Override
    public void close() {
        // Cleanup if needed
    }
}
```

---

## 🎯 Next Steps

1. **Clone Keycloak source**: `git clone https://github.com/keycloak/keycloak.git`
2. **Study these files** (in this order):
   - `server-spi/src/.../events/EventListenerProvider.java`
   - `services/src/.../authentication/AuthenticationProcessor.java`
   - `services/src/.../authenticators/browser/UsernamePasswordForm.java`
3. **Trace a login** by following the code
4. **Identify what you want to override**
5. **Implement your custom SPI**

---

## 📚 Additional Resources

- **Keycloak Source**: https://github.com/keycloak/keycloak
- **Server Developer Guide**: https://www.keycloak.org/docs/latest/server_development/
- **JavaDoc**: https://www.keycloak.org/docs-api/23.0/javadocs/

---

**You're now equipped to understand Keycloak's internals!** 🔍

Start by cloning the source and tracing a login flow. The code is well-organized and you'll quickly identify what to override.
