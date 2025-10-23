# 🎯 Keycloak Java Customization - Quick Start

Complete setup for customizing Keycloak with Java, including custom login pages and database logic modifications.

## 📚 Documentation Files

1. **KEYCLOAK_JAVA_DEEP_DIVE.md** - Complete guide with code examples
2. **KEYCLOAK_CUSTOMIZATION.md** - Theme and provider customization (Docker-based)
3. **DJANGO_SSO_WEBAUTHN_GUIDE.md** - Alternative: Build SSO with Django (no Keycloak)

## 🚀 Quick Start (5 Steps)

### Step 1: Install Prerequisites

```bash
# Install Java 17 and Maven
sudo apt update
sudo apt install openjdk-17-jdk openjdk-17-jdk-headless maven

# Verify installation
java -version   # Should show 17.x.x
mvn -version    # Should show Maven 3.x.x
```

### Step 2: Run Setup Script

```bash
# Automated setup
bash setup-keycloak-customization.sh
```

This creates:
```
keycloak-customization/          # Java provider project
├── src/main/java/               # Your Java code goes here
├── src/main/resources/          # SPI registration files
├── pom.xml                      # Maven configuration
└── target/                      # Compiled JAR (after build)

keycloak/themes/mytheme/         # Custom theme
├── login/                       # Login page customization
│   ├── login.ftl               # HTML template
│   └── resources/
│       ├── css/custom.css      # Custom styles
│       ├── js/custom.js        # Custom JavaScript
│       └── img/logo.png        # Your logo
└── theme.properties            # Theme configuration
```

### Step 3: Add Your Custom Code

Follow **KEYCLOAK_JAVA_DEEP_DIVE.md** to create custom providers.

Example structure:
```java
keycloak-customization/src/main/java/com/mycompany/keycloak/
├── CustomEventListenerProvider.java         # Main provider logic
├── CustomEventListenerProviderFactory.java  # Provider factory
├── CustomAuthenticator.java                 # Custom authentication
└── CustomUserStorageProvider.java          # Custom database
```

Register your provider:
```
keycloak-customization/src/main/resources/META-INF/services/
└── org.keycloak.events.EventListenerProviderFactory
    (contains: com.mycompany.keycloak.CustomEventListenerProviderFactory)
```

### Step 4: Build and Deploy

```bash
# Build your custom provider
cd keycloak-customization
mvn clean package

# Verify JAR is created
ls -la target/keycloak-custom-extensions.jar
```

### Step 5: Update Docker and Restart

Edit `docker-compose.yml` to mount your custom provider and theme:

```yaml
services:
  keycloak:
    # ... existing config ...
    volumes:
      - ./demo-realm.json:/opt/keycloak/data/import/demo-realm.json
      - keycloak_data:/opt/keycloak/data
      # Add these lines:
      - ./keycloak/themes/mytheme:/opt/keycloak/themes/mytheme
      - ./keycloak-customization/target/keycloak-custom-extensions.jar:/opt/keycloak/providers/keycloak-custom-extensions.jar
```

Restart Keycloak:
```bash
bash stop-keycloak.sh
bash start-keycloak.sh
```

## 🔄 Development Workflow

### When You Make Code Changes:

```bash
# Quick rebuild and reload (automated)
bash rebuild-and-reload.sh
```

This script:
1. ✅ Rebuilds your Java code
2. ✅ Creates new JAR file
3. ✅ Restarts Keycloak
4. ✅ Loads your updated provider

### Manual Workflow:

```bash
# 1. Edit your Java code
vim keycloak-customization/src/main/java/com/mycompany/keycloak/CustomEventListenerProvider.java

# 2. Rebuild
cd keycloak-customization && mvn clean package && cd ..

# 3. Restart Keycloak
docker-compose restart keycloak

# 4. Watch logs
docker-compose logs -f keycloak | grep "com.mycompany"
```

## 🎨 Enable Your Customizations

### Enable Custom Theme:

1. Open http://localhost:8080
2. Login: `admin` / `admin`
3. Select **demo** realm
4. Go to: **Realm Settings** → **Themes**
5. Set **Login theme**: `mytheme`
6. Click **Save**

### Enable Custom Event Listener:

1. In Admin Console, go to: **Realm Settings** → **Events**
2. Click **Config** tab
3. Under **Event Listeners**, add: `custom-event-listener`
4. Click **Save**

## 🧪 Testing Your Customizations

### Test Custom Event Listener:

```bash
# Create a test user via Admin Console:
# 1. Go to: Users → Add User
# 2. Fill in:
#    - Username: testjava
#    - Email: test@example.com
#    - First Name: john
#    - Last Name: doe
# 3. Click Save

# Check logs to see your custom logic:
docker-compose logs keycloak | grep "com.mycompany"

# Expected output:
# 🎉 New user registration detected!
# 📝 Modifying user data for: testjava
# ✓ Email normalized: test@example.com
# ✓ Registration timestamp added: 2025-10-20T...
# ✓ Reference ID generated: USR-1729456789
# ✅ User registration data processed successfully
```

### Verify Custom Attributes:

1. In Admin Console, go to: **Users**
2. Click on `testjava`
3. Go to **Attributes** tab
4. You should see custom attributes:
   - `registrationTimestamp`
   - `referenceId`
   - `accountType`
   - `accountStatus`
   - `loginCount`
   - etc.

## 📋 Available Helper Scripts

| Script | Purpose |
|--------|---------|
| `setup-keycloak-customization.sh` | Initial setup (run once) |
| `rebuild-and-reload.sh` | Rebuild Java code and reload Keycloak |
| `start-keycloak.sh` | Start Keycloak |
| `stop-keycloak.sh` | Stop Keycloak |
| `status.sh` | Check Keycloak status |

## 🐛 Debugging

### View All Logs:
```bash
docker-compose logs -f keycloak
```

### View Only Your Custom Provider Logs:
```bash
docker-compose logs -f keycloak | grep "com.mycompany"
```

### Check if JAR is Mounted:
```bash
docker exec keycloak-sso ls -la /opt/keycloak/providers/
```

### Check if Theme is Mounted:
```bash
docker exec keycloak-sso ls -la /opt/keycloak/themes/
```

### Access Keycloak Shell:
```bash
docker exec -it keycloak-sso /bin/bash
```

## 📖 What You Can Customize

### 1. Login Page (Theme)
- ✅ HTML structure (FreeMarker templates)
- ✅ CSS styling
- ✅ JavaScript behavior
- ✅ Custom branding, logos, colors
- ✅ Client-side validation
- ✅ Multi-language support

### 2. Backend Logic (Java Providers)
- ✅ Modify user data before DB storage
- ✅ Custom authentication flows
- ✅ Integrate external databases
- ✅ Add custom validation rules
- ✅ Track user activity
- ✅ Implement custom business logic
- ✅ Modify SAML/OIDC tokens
- ✅ Add required actions

## 🎓 Learning Path

### Beginner Level:
1. ✅ Event Listener (intercept user events)
2. ✅ Theme customization (login page)
3. ✅ Protocol Mapper (add token claims)

### Intermediate Level:
4. Custom Authenticator (authentication logic)
5. Required Action Provider (force user actions)
6. REST Endpoint Provider (custom APIs)

### Advanced Level:
7. User Storage Provider (external user DB)
8. User Federation Provider (LDAP/AD integration)
9. Authentication Flow (complete auth redesign)

## 🔗 Key Resources

- **Keycloak SPI Docs**: https://www.keycloak.org/docs/latest/server_development/
- **Java Tutorial**: https://dev.java/learn/
- **Maven Guide**: https://maven.apache.org/guides/getting-started/
- **FreeMarker Templates**: https://freemarker.apache.org/docs/

## 💡 Pro Tips

1. **Start Simple**: Begin with Event Listener, it's the easiest SPI
2. **Use Logging**: Add `logger.info()` everywhere to understand flow
3. **Check Logs Often**: `docker-compose logs -f keycloak | grep "com.mycompany"`
4. **Test Incrementally**: Build → Deploy → Test → Repeat
5. **Read Keycloak Source**: Available on GitHub for reference
6. **Join Community**: Keycloak has active mailing lists and forums

## ⚠️ Common Issues

### Issue: Provider Not Loading
**Solution**: 
- Check SPI registration file exists in `META-INF/services/`
- Verify file name matches interface exactly
- Check for typos in provider class name

### Issue: Build Fails
**Solution**:
- Ensure Java 17+ is installed: `java -version`
- Check pom.xml Keycloak version matches Docker image (23.0.0)
- Run: `mvn clean install -U`

### Issue: Changes Not Visible
**Solution**:
- Rebuild: `mvn clean package`
- Restart Keycloak: `docker-compose restart keycloak`
- Clear browser cache
- Wait 30 seconds after restart

### Issue: Theme Not Showing
**Solution**:
- Verify mount in docker-compose.yml
- Check theme.properties exists
- Select theme in Admin Console
- Restart Keycloak

## 🎯 Next Steps

1. ✅ Run `bash setup-keycloak-customization.sh`
2. ✅ Read `KEYCLOAK_JAVA_DEEP_DIVE.md` (comprehensive guide)
3. ✅ Write your first Event Listener
4. ✅ Build and deploy with `bash rebuild-and-reload.sh`
5. ✅ Test and iterate!

## 🆘 Need Help?

- Check `KEYCLOAK_JAVA_DEEP_DIVE.md` for detailed examples
- Check `KEYCLOAK_CUSTOMIZATION.md` for Docker/theme info
- View logs: `docker-compose logs -f keycloak`
- Keycloak Mailing List: https://www.keycloak.org/community

---

**You're ready to customize Keycloak with Java!** 🚀

Start with the Event Listener example in `KEYCLOAK_JAVA_DEEP_DIVE.md` - it's the best way to learn!
