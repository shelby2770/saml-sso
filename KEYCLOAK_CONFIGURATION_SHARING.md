# 🔧 Keycloak Configuration: Where It's Stored & How to Share with Team

## 🎯 The Problem You're Facing

```
You (Developer A):                Your Teammate (Developer B):
├─ Keycloak with demo realm      ├─ Keycloak with ONLY master realm
├─ testuser configured            ├─ No testuser OR old version
├─ 2 SAML clients (SP1, SP2)      ├─ Missing SAML clients
├─ Custom attributes (6 total)    ├─ No custom attributes
└─ Everything works! ✅           └─ Nothing configured! ❌

WHY? Configuration changes are in Docker VOLUME, not in Git!
```

---

## 📂 Where Keycloak Configuration is Stored

### Two Storage Locations

```
┌─────────────────────────────────────────────────────────────────────┐
│          1. DOCKER VOLUME (Runtime Storage) - NOT IN GIT            │
└─────────────────────────────────────────────────────────────────────┘

Location: Docker volume "keycloak_data"
Physical path (Linux): /var/lib/docker/volumes/django-saml-2_keycloak_data/
Contains:
  ├─ H2 Database files (.mv.db, .lock.db, .trace.db)
  ├─ User accounts with passwords
  ├─ User attributes (age, mobile, address, profession)
  ├─ Realm settings
  ├─ Client configurations
  ├─ Protocol mappers
  ├─ Sessions
  └─ All runtime data

⚠️  This is LOCAL to your machine!
⚠️  Your teammate CANNOT access this!
⚠️  Not tracked by Git!


┌─────────────────────────────────────────────────────────────────────┐
│       2. REALM EXPORT JSON (Portable Configuration) - IN GIT        │
└─────────────────────────────────────────────────────────────────────┘

Location: ./demo-realm.json (in your Git repo)
Contains:
  ├─ Realm settings
  ├─ Users (defined at export time)
  ├─ Clients
  ├─ Roles
  ├─ Protocol mappers
  ├─ Identity providers
  └─ Themes configuration

✅ This IS tracked by Git!
✅ Your teammate CAN use this!
⚠️  But it might be outdated!
```

---

## 🚨 Why Your Teammate Sees Only Master Realm

### The Root Cause

```
YOU MADE CHANGES IN KEYCLOAK ADMIN UI:
├─ Added testuser
├─ Configured custom attributes (age, mobile, address, profession)
├─ Created SAML clients (SP1, SP2)
├─ Added protocol mappers
└─ Set up realm settings

WHERE THESE CHANGES WERE SAVED:
❌ NOT in demo-realm.json (the file in Git)
✅ IN keycloak_data Docker volume (only on your machine)

WHEN TEAMMATE CLONES REPO:
├─ Gets old demo-realm.json (without your changes)
├─ Imports this old version
└─ Missing all your recent configurations!
```

---

## ✅ SOLUTION: Export & Share Current Configuration

### Method 1: Export via Admin Console (Easiest)

#### Step 1: Open Keycloak Admin Console

```bash
# Make sure Keycloak is running
bash start-keycloak.sh

# Then visit: http://localhost:8080
# Login: admin / admin
# Select "demo" realm (top-left dropdown)
```

#### Step 2: Export Realm

```
1. Click: "Realm settings" (left sidebar)
2. Click: "Action" dropdown (top-right) → "Partial export"
3. Check these boxes:
   ☑️ Include groups and roles
   ☑️ Include clients  
   ☑️ Include users
   
4. Click: "Export"
5. Browser downloads: realm-export.json
```

#### Step 3: Replace Old File & Commit

```bash
# Replace the old demo-realm.json
mv ~/Downloads/realm-export.json ./demo-realm.json

# Commit to Git
git add demo-realm.json
git commit -m "Update Keycloak realm export with latest configuration"
git push
```

---

### Method 2: Export via CLI (Automated)

Create this export script:

```bash
#!/bin/bash
# File: export-keycloak-config.sh

echo "🔄 Exporting Keycloak configuration..."

# Export realm using Keycloak admin CLI
docker exec keycloak-sso /opt/keycloak/bin/kc.sh export \
  --file /tmp/demo-realm-export.json \
  --realm demo \
  --users realm_file

# Copy export file from container
docker cp keycloak-sso:/tmp/demo-realm-export.json ./demo-realm.json

echo "✅ Export complete! File: demo-realm.json"
echo ""
echo "📦 Next steps:"
echo "   git add demo-realm.json"
echo "   git commit -m 'Update Keycloak configuration'"
echo "   git push"
```

Make it executable:

```bash
chmod +x export-keycloak-config.sh
```

Run it whenever you make changes:

```bash
./export-keycloak-config.sh
```

---

## 🔄 How Your Teammate Should Import

### Fresh Import (Recommended)

```bash
# 1. Clone repo
git clone <your-repo>
cd Django-SAML-2

# 2. Remove any existing Keycloak data
docker-compose down -v
# This removes the keycloak_data volume

# 3. Start Keycloak (will import demo-realm.json)
bash start-keycloak.sh

# 4. Verify import succeeded
docker logs keycloak-sso | grep "Imported realm demo"

# 5. Test
# Visit: http://localhost:8080
# Login: admin / admin
# Check: "demo" realm exists in dropdown
```

---

## 📋 Verify Your Export Has Everything

Create this verification script:

```bash
#!/bin/bash
# File: verify-realm-export.sh

echo "🔍 Analyzing demo-realm.json..."
echo ""

# Check if file exists
if [ ! -f "demo-realm.json" ]; then
    echo "❌ demo-realm.json NOT FOUND!"
    exit 1
fi

echo "✅ demo-realm.json found"
echo "📊 File size: $(du -h demo-realm.json | cut -f1)"
echo ""

# Check for key elements
echo "Checking contents:"
echo ""

USER_COUNT=$(grep -c '"username"' demo-realm.json || echo "0")
echo "👤 Users: $USER_COUNT"

CLIENT_COUNT=$(grep -c '"clientId"' demo-realm.json || echo "0")
echo "🔐 Clients: $CLIENT_COUNT"

if grep -q '"age"' demo-realm.json 2>/dev/null; then
    echo "✅ Custom attribute 'age' found"
else
    echo "⚠️  Custom attribute 'age' NOT found"
fi

if grep -q '"mobile"' demo-realm.json 2>/dev/null; then
    echo "✅ Custom attribute 'mobile' found"
else
    echo "⚠️  Custom attribute 'mobile' NOT found"
fi

if grep -q '"address"' demo-realm.json 2>/dev/null; then
    echo "✅ Custom attribute 'address' found"
else
    echo "⚠️  Custom attribute 'address' NOT found"
fi

if grep -q '"profession"' demo-realm.json 2>/dev/null; then
    echo "✅ Custom attribute 'profession' found"
else
    echo "⚠️  Custom attribute 'profession' NOT found"
fi

echo ""
echo "💡 If custom attributes are missing, re-export from Admin Console!"
```

Make it executable:

```bash
chmod +x verify-realm-export.sh
```

Run it to check:

```bash
./verify-realm-export.sh
```

---

## 🎯 Quick Fix for Your Teammate NOW

Send this message to your teammate:

```
Hey! The demo realm is in the repo, but you need to do a fresh import.

Run these commands:

cd your-project-folder
git pull
docker-compose down -v
bash start-keycloak.sh

Wait 30 seconds, then visit http://localhost:8080
You should see the "demo" realm in the dropdown!

Login as:
- Admin: admin/admin
- Test user: testuser/password123
```

---

## 💡 Best Practices for Team Development

### 1. Export After Every Change

```bash
# After making changes in Keycloak Admin UI:
./export-keycloak-config.sh
git add demo-realm.json
git commit -m "Keycloak: added custom user attributes"
git push
```

### 2. Document Changes

Create a `KEYCLOAK_CHANGES.md`:

```markdown
# Keycloak Configuration Changes

## 2025-10-25
- Added testuser (password123)
- Created SAML clients for SP1 and SP2
- Configured custom attributes: age, mobile, address, profession
- Added 6 protocol mappers

## 2025-10-20
- Initial realm setup
- Configured realm settings
```

### 3. Always Pull Before Changes

```bash
# Before making Keycloak changes:
git pull  # Get latest config
bash stop-keycloak.sh
docker volume rm django-saml-2_keycloak_data
bash start-keycloak.sh  # Import latest
# Now make your changes
```

---

## 🗂️ What Should Be in Git

### ✅ Include

```
demo-realm.json          # ← IMPORTANT! Keep updated!
docker-compose.yml
start-keycloak.sh
stop-keycloak.sh
requirements.txt
custom-login-theme/
README.md
```

### ❌ Exclude (.gitignore)

```
keycloak_data/          # Docker volume
db.sqlite3
*.log
__pycache__/
venv/
env/
```

---

## 🔍 Debugging Checklist

If teammate still sees only master realm:

```bash
# 1. Check if demo-realm.json is in repo
git ls-files | grep demo-realm.json
# Should output: demo-realm.json

# 2. Check file has content
wc -l demo-realm.json
# Should be > 50 lines

# 3. Check for demo realm in file
grep '"realm": "demo"' demo-realm.json
# Should find it

# 4. Check Docker logs
docker logs keycloak-sso | grep -i "import"
# Should see: "Imported realm demo"

# 5. Force fresh import
docker-compose down -v
docker-compose up -d
docker logs -f keycloak-sso
# Watch for import messages
```

---

## 📊 Complete Workflow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                     YOU (Original Dev)                        │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ Make changes in Keycloak Admin UI
                            ↓
              ┌──────────────────────────────┐
              │ Changes saved to Docker      │
              │ volume (keycloak_data)       │
              └─────────────┬────────────────┘
                            │
                            │ Run export script
                            ↓
              ┌──────────────────────────────┐
              │ demo-realm.json updated      │
              └─────────────┬────────────────┘
                            │
                            │ git add, commit, push
                            ↓
              ┌──────────────────────────────┐
              │ GitHub Repository            │
              └─────────────┬────────────────┘
                            │
                            │ git pull
                            ↓
┌──────────────────────────────────────────────────────────────┐
│                  TEAMMATE (Other Dev)                         │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ docker-compose down -v
                            │ bash start-keycloak.sh
                            ↓
              ┌──────────────────────────────┐
              │ Keycloak imports             │
              │ demo-realm.json              │
              └─────────────┬────────────────┘
                            │
                            ↓
              ┌──────────────────────────────┐
              │ ✅ Demo realm ready!         │
              │ All configs match            │
              └──────────────────────────────┘
```

---

## 🚀 Action Items RIGHT NOW

### For You:

1. **Export current config**
   ```bash
   ./export-keycloak-config.sh
   # OR use Admin Console method above
   ```

2. **Verify export**
   ```bash
   ./verify-realm-export.sh
   ```

3. **Commit to Git**
   ```bash
   git add demo-realm.json
   git commit -m "Export complete Keycloak configuration"
   git push
   ```

4. **Notify team**
   Post in your team chat:
   ```
   📢 Keycloak config updated!
   
   To get latest:
   git pull
   docker-compose down -v
   bash start-keycloak.sh
   ```

---

**Key Takeaway:** 

Keycloak configuration lives in TWO places:
1. **Docker volume** (runtime, local only) ← Your changes go here
2. **demo-realm.json** (export file, in Git) ← Team gets this

You MUST export from #1 to #2 after making changes, otherwise your team won't get them! 🔄
