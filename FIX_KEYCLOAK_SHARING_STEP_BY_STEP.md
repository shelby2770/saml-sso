# 🚀 STEP-BY-STEP GUIDE: Fix Keycloak Configuration Sharing

## Problem to Solve
Your teammate cloned the repo but only sees the master realm (no demo realm with custom attributes)

---

## 📋 Complete Solution (Step-by-Step)

### PART A: YOU (Configuration Owner) - Export & Share

---

#### **STEP 1: Check if Keycloak is Running**

```bash
cd "/home/shelby70/Projects/Django-SAML (2)"
bash status.sh
```

**Expected output:**
```
✅ Keycloak is running on http://localhost:8080
```

**If NOT running:**
```bash
bash start-keycloak.sh
```

Wait 30 seconds for Keycloak to fully start.

---

#### **STEP 2: Export Your Current Configuration**

**Method A - Using Admin Console (RECOMMENDED):**

1. Open browser and go to: **http://localhost:8080**

2. Login with:
   - Username: `admin`
   - Password: `admin`

3. Select **"demo"** realm from the dropdown (top-left corner)

4. Click **"Realm settings"** in the left sidebar

5. Click **"Action"** dropdown button (top-right) → Select **"Partial export"**

6. In the export dialog, **CHECK ALL THREE BOXES**:
   - ☑️ **Include groups and roles**
   - ☑️ **Include clients**
   - ☑️ **Include users**

7. Click **"Export"** button

8. Your browser will download a file named `realm-export.json`

9. **Move the downloaded file to your project folder:**
   ```bash
   mv ~/Downloads/realm-export.json "/home/shelby70/Projects/Django-SAML (2)/demo-realm.json"
   ```

**Method B - Using Export Script (ALTERNATIVE):**

```bash
./export-keycloak-config.sh
```

If this fails, use Method A instead.

---

#### **STEP 3: Verify the Export Has Everything**

```bash
./verify-realm-export.sh
```

**Expected output:**
```
✅ demo-realm.json found
📊 File size: 15K or larger
👤 Users: 1
   Found:
     - testuser
🔐 Clients: 2
   Found:
     - django-saml-app
     - http://127.0.0.1:8002/api/saml/metadata/
     
✅ Custom attribute 'age' found
✅ Custom attribute 'mobile' found
✅ Custom attribute 'address' found
✅ Custom attribute 'profession' found
✅ Custom attribute 'email' found
✅ Custom attribute 'username' found
```

**If any custom attributes show ⚠️ NOT found:**
- Go back to STEP 2 and re-export
- Make sure you checked ALL boxes in the export dialog

---

#### **STEP 4: Check What Changed**

```bash
git status
git diff demo-realm.json
```

You should see changes showing the custom attributes being added.

---

#### **STEP 5: Commit to Git**

```bash
git add demo-realm.json
git commit -m "Export complete Keycloak configuration with custom user attributes"
```

---

#### **STEP 6: Push to GitHub**

```bash
git push origin main
```

**If you get authentication errors:**
```bash
# Use personal access token or SSH key
git push origin main
```

---

#### **STEP 7: Notify Your Teammate**

Send this message to your teammate:

```
Hey! I just pushed the complete Keycloak configuration.

To get it working on your machine, run these commands:

cd your-project-folder
git pull origin main
docker-compose down -v
bash start-keycloak.sh

Wait 30 seconds, then visit http://localhost:8080
The demo realm should now be there with all settings!

Test user: testuser / password123
```

---

### PART B: YOUR TEAMMATE (Configuration Receiver) - Import & Use

---

#### **STEP 1: Pull Latest Code**

```bash
cd your-project-folder
git pull origin main
```

**Expected output:**
```
Updating abc1234..def5678
 demo-realm.json | 150 ++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 150 insertions(+)
```

---

#### **STEP 2: Verify demo-realm.json Exists**

```bash
ls -lh demo-realm.json
```

**Expected output:**
```
-rw-r--r-- 1 user user 15K Oct 25 10:30 demo-realm.json
```

**If file is missing or very small (< 5K):**
- Ask the original developer to re-export and push again

---

#### **STEP 3: Stop Keycloak and Remove Old Data**

```bash
# Stop all containers
docker-compose down

# Remove the old Keycloak volume (THIS IS IMPORTANT!)
docker-compose down -v
```

**What this does:**
- Stops Keycloak container
- **Deletes the keycloak_data volume** (removes old configuration)
- This forces Keycloak to import demo-realm.json on next startup

---

#### **STEP 4: Verify Volume is Deleted**

```bash
docker volume ls | grep keycloak
```

**Expected output:**
```
(empty - no keycloak volumes should be listed)
```

**If you still see a keycloak volume:**
```bash
docker volume rm django-saml-2_keycloak_data
# Or whatever the volume name is
```

---

#### **STEP 5: Start Keycloak with Fresh Import**

```bash
bash start-keycloak.sh
```

**Expected output:**
```
Starting keycloak-sso ... done
✅ Keycloak is ready!
```

---

#### **STEP 6: Watch Import Process (Optional)**

In another terminal:

```bash
docker logs -f keycloak-sso | grep -i import
```

**Expected to see:**
```
INFO  [org.keycloak.exportimport] (main) Importing realm demo from file...
INFO  [org.keycloak.exportimport] (main) Imported realm demo
```

Press `Ctrl+C` to stop watching logs.

---

#### **STEP 7: Verify Demo Realm Exists**

Open browser and go to: **http://localhost:8080**

1. Login:
   - Username: `admin`
   - Password: `admin`

2. Check the realm dropdown (top-left):
   - Should show: **master** and **demo**

3. Select **"demo"** realm

4. Click **"Users"** (left sidebar)

5. Click on **"testuser"**

6. Click **"Attributes"** tab

7. Verify these attributes exist:
   - `age`: 30
   - `mobile`: +1-555-0100
   - `address`: 123 Main Street, NYC
   - `profession`: Software Developer

---

#### **STEP 8: Test SAML Login**

**Start Django Service Providers:**

```bash
# Make sure virtual environment is set up
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt

# Start SP1
python manage.py runserver 127.0.0.1:8001 &

# Start SP2 (in another terminal)
cd SAML_DJNAGO_2
python manage.py runserver 127.0.0.1:8002 &
```

**Test the login:**

1. Visit: **http://127.0.0.1:8001/api/saml/login/**

2. You'll be redirected to Keycloak login page

3. Login with:
   - Username: `testuser`
   - Password: `password123`

4. After successful login, you should see:
   - Welcome message
   - All 6 custom attributes displayed (username, email, age, mobile, address, profession)

---

### PART C: TROUBLESHOOTING (If Something Goes Wrong)

---

#### **Problem 1: Teammate Still Sees Only Master Realm**

**Solution:**

```bash
# Make absolutely sure the volume is deleted
docker-compose down
docker volume ls | grep keycloak
docker volume rm <volume-name-if-exists>

# Check demo-realm.json exists and has content
cat demo-realm.json | head -20

# Start fresh
docker-compose up -d

# Watch logs for import
docker logs -f keycloak-sso
# Look for: "Imported realm demo"
```

---

#### **Problem 2: Demo Realm Exists but No Custom Attributes**

**Cause:** Export was done without checking all boxes

**Solution (for YOU - original developer):**

```bash
# Re-export using Admin Console (Method A in STEP 2)
# Make sure to check ALL boxes
# Replace demo-realm.json
# Commit and push again
git add demo-realm.json
git commit -m "Re-export with custom attributes included"
git push
```

**Solution (for TEAMMATE):**

```bash
# Pull again
git pull

# Delete volume and restart
docker-compose down -v
bash start-keycloak.sh
```

---

#### **Problem 3: Export Script Fails**

**Solution:**

Just use the Admin Console method (Method A). It's more reliable.

---

#### **Problem 4: Git Push Fails (Authentication)**

**Solution A - Using HTTPS with Personal Access Token:**

```bash
# Create token at: https://github.com/settings/tokens
# Use the token as password when pushing

git push https://github.com/shelby2770/saml-sso.git main
# Username: shelby2770
# Password: <your-personal-access-token>
```

**Solution B - Using SSH:**

```bash
# Make sure SSH key is set up
# Change remote to SSH
git remote set-url origin git@github.com:shelby2770/saml-sso.git
git push origin main
```

---

#### **Problem 5: Import Seems Stuck**

**Solution:**

```bash
# Check Keycloak logs
docker logs keycloak-sso

# If you see errors about file not found:
# Check the volume mount in docker-compose.yml
docker-compose config | grep demo-realm

# Should show:
# - ./demo-realm.json:/opt/keycloak/data/import/demo-realm.json
```

---

### PART D: BEST PRACTICES FOR FUTURE

---

#### **After Every Keycloak Change:**

```bash
# 1. Export
./export-keycloak-config.sh

# 2. Verify
./verify-realm-export.sh

# 3. Commit
git add demo-realm.json
git commit -m "Keycloak: <description of what you changed>"

# 4. Push
git push origin main

# 5. Notify team
# Post in team chat: "Keycloak config updated. Run: git pull && docker-compose down -v && bash start-keycloak.sh"
```

---

#### **Document Your Changes:**

Create/update `KEYCLOAK_CHANGES.md`:

```markdown
# Keycloak Configuration Changes

## 2025-10-25 - Custom User Attributes
- Added custom attributes to testuser: age, mobile, address, profession
- Created SAML protocol mappers for custom attributes
- Configured attribute mapping for both SP1 and SP2

## 2025-10-20 - Initial Setup
- Created demo realm
- Added testuser (password123)
- Configured SAML clients
```

---

#### **Set Up Git Hooks (Optional):**

```bash
# Create pre-commit hook to remind you to export
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
if docker ps | grep -q keycloak-sso; then
    echo "⚠️  Keycloak is running. Did you export the latest config?"
    echo "   Run: ./export-keycloak-config.sh"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
EOF

chmod +x .git/hooks/pre-commit
```

---

## 📊 QUICK REFERENCE CHECKLIST

### For YOU (Original Developer):

- [ ] Step 1: Check Keycloak is running
- [ ] Step 2: Export via Admin Console (check ALL boxes!)
- [ ] Step 3: Verify export has custom attributes
- [ ] Step 4: Check git diff
- [ ] Step 5: Commit demo-realm.json
- [ ] Step 6: Push to GitHub
- [ ] Step 7: Notify teammate

### For TEAMMATE:

- [ ] Step 1: Git pull
- [ ] Step 2: Verify demo-realm.json exists
- [ ] Step 3: docker-compose down -v (DELETE volume!)
- [ ] Step 4: Verify volume deleted
- [ ] Step 5: Start Keycloak
- [ ] Step 6: Watch import logs
- [ ] Step 7: Verify demo realm in Admin Console
- [ ] Step 8: Test SAML login

---

## 🎯 Summary

**The problem:**
- Keycloak config is in Docker volume (local only)
- Git only has old demo-realm.json

**The solution:**
1. Export current config to demo-realm.json
2. Commit and push to Git
3. Teammate pulls, deletes old volume, starts fresh
4. Keycloak imports demo-realm.json on startup

**Key point:**
The `-v` flag in `docker-compose down -v` is CRITICAL! It deletes the old volume so Keycloak will import the latest demo-realm.json.

---

**Ready to start? Begin with PART A, STEP 1! 🚀**
