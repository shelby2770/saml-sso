# 🗄️ Keycloak Database Communication Guide

## Overview

Keycloak communicates with a database to persist all its data. This guide explains how Keycloak connects to databases, where configuration happens, and how to customize it.

---

## 📊 Your Current Setup

### Database Configuration

**From your `docker-compose.yml`:**

```yaml
environment:
  KC_DB: dev-file  # ← Database type
```

**What this means:**
- **Database Type**: `dev-file` (H2 file-based database)
- **Location**: `/opt/keycloak/data/h2/keycloakdb.mv.db` (inside container)
- **Persistence**: Data stored in Docker volume `keycloak_data`
- **Use Case**: Development/testing only (NOT for production)

---

## 🏗️ Keycloak Database Architecture

### How Keycloak Connects to Database

```
┌─────────────────────────────────────────────────────────────────────┐
│                         KEYCLOAK ARCHITECTURE                        │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│   REST API Layer     │  ← HTTP endpoints (8080)
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│  Service Layer       │  ← Business logic
│  • UserService       │
│  • RealmService      │
│  • ClientService     │
│  • SessionService    │
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│   JPA/Hibernate      │  ← ORM (Object-Relational Mapping)
│   Entity Manager     │
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│   JDBC Driver        │  ← Database driver
│   (H2, PostgreSQL,   │
│    MySQL, etc.)      │
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│    DATABASE          │  ← Your current: H2 file database
│  /opt/keycloak/data/ │
│  h2/keycloakdb.mv.db │
└──────────────────────┘
```

---

## 📂 Key Files & Configuration

### 1. Docker Compose Configuration (`docker-compose.yml`)

**Location**: `/home/shelby70/Projects/Django-SAML (2)/docker-compose.yml`

**Database-related environment variables:**

```yaml
environment:
  # Database type: dev-file, postgres, mysql, mariadb, mssql
  KC_DB: dev-file
  
  # For production databases, you'd also set:
  # KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
  # KC_DB_USERNAME: keycloak
  # KC_DB_PASSWORD: keycloak_password
  # KC_DB_SCHEMA: public
```

**Volume mapping for data persistence:**

```yaml
volumes:
  - keycloak_data:/opt/keycloak/data  # ← Database files stored here
```

### 2. Keycloak Configuration File (Inside Container)

**Location (inside container)**: `/opt/keycloak/conf/keycloak.conf`

This file is generated automatically based on environment variables. To view it:

```bash
docker exec keycloak-sso cat /opt/keycloak/conf/keycloak.conf
```

**It contains:**
```properties
# Database configuration
db=dev-file
db-url-host=localhost
db-url-database=keycloakdb
db-username=sa
db-password=
```

### 3. Hibernate Configuration (Automatic)

Keycloak uses Hibernate ORM internally. Configuration is automatic based on `KC_DB` setting.

**Files (inside Keycloak JAR):**
- `/opt/keycloak/lib/lib/main/org.hibernate.orm.core-*.jar`
- Hibernate properties embedded in Keycloak code

---

## 🗂️ Database Schema

### What's Stored in the Database

#### Core Tables:

```sql
-- Users and Authentication
USER_ENTITY              -- User accounts
USER_ATTRIBUTE           -- Custom user attributes (age, mobile, etc.)
CREDENTIAL               -- Passwords (hashed)
USER_SESSION             -- Active sessions
AUTHENTICATION_EXECUTION -- Auth flows

-- Realms and Clients
REALM                    -- Realms (demo, master, etc.)
CLIENT                   -- SAML/OIDC clients (saml-sp-1, saml-sp-2)
CLIENT_SCOPE            -- Client scopes
PROTOCOL_MAPPER         -- Attribute mappers

-- Roles and Groups
KEYCLOAK_ROLE           -- Roles
KEYCLOAK_GROUP          -- Groups
USER_ROLE_MAPPING       -- User-role associations

-- Configuration
COMPONENT                -- Custom components
RESOURCE_SERVER         -- Authorization settings
```

### Example: User Data Storage

When you create a user with custom attributes, here's how it's stored:

```sql
-- USER_ENTITY table
INSERT INTO USER_ENTITY (ID, USERNAME, EMAIL, FIRST_NAME, LAST_NAME, ...)
VALUES ('uuid-123', 'testuser', 'test@example.com', 'Test', 'User', ...);

-- USER_ATTRIBUTE table (custom attributes)
INSERT INTO USER_ATTRIBUTE (ID, USER_ID, NAME, VALUE)
VALUES 
  ('attr-1', 'uuid-123', 'age', '30'),
  ('attr-2', 'uuid-123', 'mobile', '+1-555-0100'),
  ('attr-3', 'uuid-123', 'address', '123 Main Street, NYC'),
  ('attr-4', 'uuid-123', 'profession', 'Software Developer');

-- CREDENTIAL table (password hash)
INSERT INTO CREDENTIAL (ID, USER_ID, TYPE, SECRET_DATA, CREDENTIAL_DATA)
VALUES ('cred-1', 'uuid-123', 'password', '{"value":"<bcrypt-hash>","salt":"..."}', '...');
```

---

## 🔄 Data Flow: User Login

### Step-by-Step Database Queries

```
User clicks "Sign In"
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 1. Keycloak receives login request                                  │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 2. Query database for user                                          │
│    SQL: SELECT * FROM USER_ENTITY WHERE USERNAME = 'testuser'       │
│         AND REALM_ID = 'demo-realm-id'                              │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 3. Verify user is enabled                                           │
│    Check: ENABLED = true                                            │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 4. Fetch user credentials                                           │
│    SQL: SELECT * FROM CREDENTIAL WHERE USER_ID = 'uuid-123'         │
│         AND TYPE = 'password'                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 5. Verify password (bcrypt hash comparison)                         │
│    Compare: user_input vs stored_hash                               │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 6. Fetch custom attributes                                          │
│    SQL: SELECT NAME, VALUE FROM USER_ATTRIBUTE                      │
│         WHERE USER_ID = 'uuid-123'                                  │
│    Result: age=30, mobile=+1-555-0100, address=..., profession=...  │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 7. Fetch client configuration for SAML mappers                      │
│    SQL: SELECT * FROM CLIENT WHERE CLIENT_ID = 'saml-sp-1'          │
│    SQL: SELECT * FROM PROTOCOL_MAPPER WHERE CLIENT_ID = '...'       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 8. Create user session                                              │
│    SQL: INSERT INTO USER_SESSION (ID, USER_ID, REALM_ID, ...)       │
│         VALUES ('session-xyz', 'uuid-123', 'realm-id', ...)         │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│ 9. Generate SAML response with attributes                           │
│    Include: username, email, age, mobile, address, profession       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
        Send SAML response to Django
```

---

## 🔧 Switching to Production Database

### PostgreSQL Example

#### Step 1: Create `docker-compose-postgres.yml`

```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15
    container_name: keycloak-postgres
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: keycloak_secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - saml-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U keycloak"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Keycloak with PostgreSQL
  keycloak:
    image: quay.io/keycloak/keycloak:23.0
    container_name: keycloak-sso
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      
      # PostgreSQL configuration
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: keycloak_secure_password
      KC_DB_SCHEMA: public
      
      # Other settings
      KC_HOSTNAME_STRICT: "false"
      KC_HOSTNAME_STRICT_HTTPS: "false"
      KC_HTTP_ENABLED: "true"
      KC_HOSTNAME: localhost
      KC_HOSTNAME_PORT: 8080
    ports:
      - "8080:8080"
    command:
      - start
      - --import-realm
    volumes:
      - ./demo-realm.json:/opt/keycloak/data/import/demo-realm.json
    networks:
      - saml-network

networks:
  saml-network:
    driver: bridge

volumes:
  postgres_data:
```

#### Step 2: Start with PostgreSQL

```bash
# Stop current Keycloak
docker-compose down

# Start with PostgreSQL
docker-compose -f docker-compose-postgres.yml up -d

# Check logs
docker logs -f keycloak-sso
```

---

## 🔍 Inspecting Database Content

### Access H2 Database (Current Setup)

```bash
# 1. Connect to Keycloak container
docker exec -it keycloak-sso bash

# 2. Navigate to data directory
cd /opt/keycloak/data/h2

# 3. List database files
ls -lah
# Output: keycloakdb.mv.db

# 4. Use H2 Console (if enabled)
# Start Keycloak with H2 console:
# Add to docker-compose.yml environment:
KC_DB_URL_PROPERTIES: ";AUTO_SERVER=TRUE"
```

### Query Database Directly (PostgreSQL)

```bash
# Connect to PostgreSQL
docker exec -it keycloak-postgres psql -U keycloak

# List all users
SELECT id, username, email, first_name, last_name 
FROM user_entity 
WHERE realm_id = (SELECT id FROM realm WHERE name = 'demo');

# Get user attributes
SELECT u.username, ua.name, ua.value
FROM user_entity u
JOIN user_attribute ua ON u.id = ua.user_id
WHERE u.username = 'testuser';

# List all clients
SELECT client_id, name, protocol
FROM client
WHERE realm_id = (SELECT id FROM realm WHERE name = 'demo');

# Count active sessions
SELECT COUNT(*) FROM user_session;
```

---

## 🎯 Custom Database Integration

### Creating Custom User Storage SPI

If you want to connect Keycloak to your own external database:

#### 1. User Storage SPI Interface

```java
package com.example.keycloak.storage;

import org.keycloak.component.ComponentModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.storage.UserStorageProviderFactory;

public class CustomUserStorageProviderFactory 
    implements UserStorageProviderFactory<CustomUserStorageProvider> {
    
    @Override
    public CustomUserStorageProvider create(KeycloakSession session, 
                                           ComponentModel model) {
        // Connect to your external database
        String jdbcUrl = model.getConfig().getFirst("jdbcUrl");
        String username = model.getConfig().getFirst("username");
        String password = model.getConfig().getFirst("password");
        
        return new CustomUserStorageProvider(session, model, 
                                            jdbcUrl, username, password);
    }
    
    @Override
    public String getId() {
        return "custom-user-storage";
    }
}
```

#### 2. User Storage Provider Implementation

```java
public class CustomUserStorageProvider implements UserLookupProvider {
    
    private Connection dbConnection;
    
    @Override
    public UserModel getUserByUsername(String username, RealmModel realm) {
        // Query YOUR database
        String sql = "SELECT * FROM your_users WHERE username = ?";
        try (PreparedStatement stmt = dbConnection.prepareStatement(sql)) {
            stmt.setString(1, username);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                // Create Keycloak user from your data
                return new CustomUserAdapter(session, realm, rs);
            }
        }
        return null;
    }
    
    // Implement other methods...
}
```

---

## 📊 Database Performance

### Connection Pool Configuration

For production PostgreSQL:

```yaml
environment:
  # Connection pool settings
  KC_DB_POOL_INITIAL_SIZE: 10
  KC_DB_POOL_MIN_SIZE: 10
  KC_DB_POOL_MAX_SIZE: 50
  
  # Query timeout
  KC_TRANSACTION_XA_ENABLED: false
```

### Database Indexes

Keycloak creates indexes automatically, but you can optimize:

```sql
-- Custom index for faster user attribute lookups
CREATE INDEX idx_user_attr_name_value 
ON user_attribute(name, value);

-- Index for session queries
CREATE INDEX idx_user_session_realm 
ON user_session(realm_id, user_id);
```

---

## 🔐 Database Security

### Connection Encryption (PostgreSQL SSL)

```yaml
environment:
  KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak?sslmode=require
  KC_DB_URL_PROPERTIES: "?sslmode=require&sslcert=/path/to/client.crt&sslkey=/path/to/client.key"
```

### Backup & Recovery

```bash
# Backup PostgreSQL
docker exec keycloak-postgres pg_dump -U keycloak keycloak > backup.sql

# Restore
docker exec -i keycloak-postgres psql -U keycloak keycloak < backup.sql

# Backup H2 (current setup)
docker cp keycloak-sso:/opt/keycloak/data/h2/keycloakdb.mv.db ./backup/
```

---

## 📝 Summary

### Your Current Setup

| Aspect | Configuration |
|--------|--------------|
| **Database Type** | H2 (dev-file) |
| **Location** | `/opt/keycloak/data/h2/keycloakdb.mv.db` |
| **Configuration** | `KC_DB=dev-file` in docker-compose.yml |
| **Persistence** | Docker volume `keycloak_data` |
| **Use Case** | Development/Testing |

### Key Takeaways

1. **Environment Variables** control database connection (`KC_DB`, `KC_DB_URL`, etc.)
2. **Hibernate/JPA** handles ORM and SQL generation automatically
3. **User attributes** stored in `USER_ATTRIBUTE` table
4. **All configuration** persisted in database (realms, clients, mappers)
5. **For production**, switch to PostgreSQL/MySQL

### Files to Know

- **Configuration**: `docker-compose.yml` (environment variables)
- **Data**: Docker volume `keycloak_data` → `/opt/keycloak/data`
- **Schema**: Automatic via Hibernate (200+ tables)

---

## 🔗 Related Documentation

- `docker-compose.yml` - Your current database configuration
- Official Keycloak Docs: https://www.keycloak.org/server/db
- Database migration guide: https://www.keycloak.org/docs/latest/upgrading/

---

**Need to switch to PostgreSQL or MySQL? Let me know and I'll help you set it up!** 🚀
