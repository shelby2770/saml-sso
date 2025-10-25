# 🎯 QUICK ANSWER: Where Keycloak Config Is Stored

## The Problem

**Your teammate cloned your repo but only sees the master realm (no demo realm)**

## Why This Happens

```
┌─────────────────────────────────────────────────────────────────┐
│  Keycloak configuration is stored in TWO places:                │
└─────────────────────────────────────────────────────────────────┘

1. ❌ Docker Volume (NOT in Git)
   Location: /var/lib/docker/volumes/django-saml-2_keycloak_data/
   Contains: H2 database with ALL your changes
   Problem: Only exists on YOUR machine!

2. ✅ demo-realm.json (IN Git)
   Location: ./demo-realm.json
   Contains: Exported realm configuration
   Status: ⚠️ OUTDATED (missing custom attributes!)
```

## What's Missing from Your demo-realm.json

✅ **What's there:**
- testuser account
- 2 SAML clients (SP1, SP2)
- Basic email and username

❌ **What's missing:**
- Custom attributes: age, mobile, address, profession
- Protocol mappers for custom attributes
- Any changes you made after the last export

## The Solution (3 Steps)

### Step 1: Export Current Configuration

**Option A - Admin Console (Easiest):**

```bash
# 1. Make sure Keycloak is running
bash start-keycloak.sh

# 2. Open browser: http://localhost:8080
# 3. Login: admin / admin
# 4. Select "demo" realm (top-left dropdown)
# 5. Click: Realm settings (left sidebar)
# 6. Click: Action → Partial export (top-right)
# 7. Check ALL boxes:
#    ☑️ Include groups and roles
#    ☑️ Include clients
#    ☑️ Include users
# 8. Click: Export
# 9. Move file:
mv ~/Downloads/realm-export.json ./demo-realm.json
```

**Option B - Script (Automated):**

```bash
./export-keycloak-config.sh
```

### Step 2: Verify Export

```bash
./verify-realm-export.sh
```

Should show:
- ✅ Custom attribute 'age' found
- ✅ Custom attribute 'mobile' found
- ✅ Custom attribute 'address' found
- ✅ Custom attribute 'profession' found

### Step 3: Commit and Push

```bash
git add demo-realm.json
git commit -m "Export complete Keycloak configuration with custom attributes"
git push
```

## How Your Teammate Should Use It

```bash
# 1. Pull latest code
git pull

# 2. Delete old Keycloak data
docker-compose down -v

# 3. Start fresh (will import demo-realm.json)
bash start-keycloak.sh

# 4. Verify
# Visit: http://localhost:8080
# Should see "demo" realm in dropdown
# testuser should have all 6 custom attributes
```

## Why This Works

```
docker-compose.yml has:
  command:
    - start-dev
    - --import-realm  ← This imports demo-realm.json on first startup!
  
  volumes:
    - ./demo-realm.json:/opt/keycloak/data/import/demo-realm.json
    - keycloak_data:/opt/keycloak/data

When Keycloak starts with empty volume:
1. Checks /opt/keycloak/data/import/ folder
2. Finds demo-realm.json
3. Imports it → Creates demo realm
4. Saves to keycloak_data volume

Your teammate needs fresh volume (docker-compose down -v)
so Keycloak imports the latest demo-realm.json!
```

## Important Notes

1. **Always export after making changes** in Keycloak Admin UI
2. **The import only works on first startup** (empty volume)
3. **Custom attributes live in the database**, not automatically in export
4. **Your teammate must delete old volume** (`-v` flag) to trigger re-import

## Your Current Status

**Analysis of your demo-realm.json:**
```
✅ Has: demo realm, testuser, 2 SAML clients
❌ Missing: Custom attributes (age, mobile, address, profession)

YOU NEED TO RE-EXPORT! Use Step 1 above.
```

---

**TL;DR:** 

Your Keycloak configuration is in a Docker volume (local only). To share with teammates, export to `demo-realm.json` and commit to Git. Your current export is missing custom attributes, so re-export now!

**Next action:** Run `./export-keycloak-config.sh` or use Admin Console to export with all custom attributes included.
