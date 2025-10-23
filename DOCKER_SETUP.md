# 🐳 Docker Setup Guide for Django SAML Project

This guide explains how to run Keycloak as a containerized Identity Provider while keeping your Django applications running locally for development.

## 📋 Prerequisites

- Docker and Docker Compose installed
- Python 3.x with Django environment set up
- Basic knowledge of SAML and SSO concepts

## 🚀 Quick Start

### 1. Start Keycloak IdP

Use the provided startup script for the easiest setup:

```bash
# Make sure you're in the project root directory
cd /home/shelby70/Downloads/Django-SAML\ \(2\)

# Start Keycloak using the provided script
./start-keycloak.sh
```

**Or manually with Docker Compose:**

```bash
# Start Keycloak container
docker-compose up -d keycloak

# Check if Keycloak is ready
curl http://localhost:8080/realms/demo
```

### 2. Start Django Service Providers

**Terminal 1 - Start SP1:**

```bash
cd SAML_DJNAGO
python manage.py runserver 127.0.0.1:8001
```

**Terminal 2 - Start SP2:**

```bash
cd SAML_DJNAGO_2
python manage.py runserver 127.0.0.1:8002
```

## 🔧 Configuration Details

### Docker Compose Configuration

- **Service**: `keycloak`
- **Image**: `quay.io/keycloak/keycloak:23.0`
- **Port**: `8080:8080`
- **Network**: Custom bridge network `saml-network`
- **Realm Import**: Automatic import of `demo-realm.json`

### Pre-configured Components

✅ **Keycloak Admin Console**

- URL: http://localhost:8080
- Username: `admin`
- Password: `admin`

✅ **Demo Realm**

- Realm Name: `demo`
- Test User: `testuser / password123`
- Email: `testuser@example.com`

✅ **SAML Clients (Service Providers)**

- **SP1**: `django-saml-app` → http://127.0.0.1:8001
- **SP2**: `django-saml-app-sp2` → http://127.0.0.1:8002

## 🌐 Testing the Setup

### 1. Verify Keycloak is Running

```bash
# Check realm availability
curl http://localhost:8080/realms/demo

# View Keycloak admin console
open http://localhost:8080
```

### 2. Test Django Applications

**Service Provider 1:**

- Home: http://127.0.0.1:8001/
- Login: http://127.0.0.1:8001/api/saml/login/
- Metadata: http://127.0.0.1:8001/api/saml/metadata/

**Service Provider 2:**

- Home: http://127.0.0.1:8002/
- Login: http://127.0.0.1:8002/api/saml/login/
- Metadata: http://127.0.0.1:8002/api/saml/metadata/

### 3. SSO Flow Testing

1. **Login to SP1**: Navigate to http://127.0.0.1:8001 and click "Login with SAML"
2. **Authenticate**: Use `testuser / password123`
3. **Cross-SP Access**: Open http://127.0.0.1:8002 in a new tab - you should be automatically logged in
4. **Logout Testing**: Test various logout scenarios from the home pages

## 🛠️ Useful Docker Commands

### Container Management

```bash
# Start Keycloak
docker-compose up -d keycloak

# Stop Keycloak
docker-compose down

# View logs
docker-compose logs keycloak

# Restart Keycloak
docker-compose restart keycloak
```

### Data Management

```bash
# Remove everything (including volumes)
docker-compose down -v

# Rebuild if needed
docker-compose up -d --build keycloak
```

### Health Checks

```bash
# Check container status
docker-compose ps

# Check if Keycloak is responding
curl -f http://localhost:8080/realms/demo || echo "Not ready yet"
```

## 🔍 Troubleshooting

### Common Issues

**1. Keycloak takes time to start**

- First run can take 2-3 minutes
- Use the startup script which includes waiting logic

**2. Port conflicts**

- Ensure port 8080 is not used by other services
- Check with: `lsof -i :8080`

**3. Realm not imported**

- Check if `demo-realm.json` exists in project root
- Verify Docker volume mapping in `docker-compose.yml`

**4. Django apps can't reach Keycloak**

- Ensure Keycloak is running: `docker-compose ps`
- Test connectivity: `curl http://localhost:8080/realms/demo`

### Debug Commands

```bash
# View Keycloak container logs
docker-compose logs -f keycloak

# Check Django settings
cd SAML_DJNAGO && python manage.py shell
>>> from django.conf import settings
>>> print(settings.SAML_SETTINGS['idp']['entityId'])

# Test SAML metadata generation
curl http://127.0.0.1:8001/api/saml/metadata/
```

## 📁 Project Structure

```
Django-SAML/
├── docker-compose.yml          # Keycloak container config
├── start-keycloak.sh          # Startup script
├── demo-realm.json            # Pre-configured realm
├── SAML_DJNAGO/              # Django SP1 (port 8001)
├── SAML_DJNAGO_2/            # Django SP2 (port 8002)
└── django_saml_Auth/         # Shared SAML auth logic
```

## 🎯 Benefits of This Setup

- **Development Friendly**: Django apps run locally for easy debugging
- **Production-like IdP**: Keycloak runs in container like production
- **Isolated**: IdP data persists in Docker volumes
- **Portable**: Easy to reset/recreate IdP environment
- **Realistic**: Tests real network communication between services

## 🔄 Next Steps

1. **Customize Realm**: Modify `demo-realm.json` for your needs
2. **Add Users**: Create additional test users in Keycloak
3. **Configure Attributes**: Add custom SAML attributes
4. **SSL Setup**: Configure HTTPS for production-like testing
5. **Monitoring**: Add logging and monitoring for SAML flows

---

🎉 **You're now ready to develop and test SAML SSO with a containerized IdP!**
