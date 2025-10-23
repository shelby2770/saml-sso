# 🎯 Quick Reference - Attribute Mapper Settings

Use this as a quick reference while configuring SAML attribute mappers.

---

## For SP1 and SP2 (Both need the same 6 mappers)

### Mapper 1: Username
```
Type:                     User Property
Name:                     username-mapper
Property:                 username
SAML Attribute Name:      username
SAML Attribute NameFormat: Basic
```

### Mapper 2: Email
```
Type:                     User Property
Name:                     email-mapper
Property:                 email
SAML Attribute Name:      email
SAML Attribute NameFormat: Basic
```

### Mapper 3: Age
```
Type:                     User Attribute
Name:                     age-mapper
User Attribute:           age
SAML Attribute Name:      age
SAML Attribute NameFormat: Basic
```

### Mapper 4: Mobile
```
Type:                     User Attribute
Name:                     mobile-mapper
User Attribute:           mobile
SAML Attribute Name:      mobile
SAML Attribute NameFormat: Basic
```

### Mapper 5: Address
```
Type:                     User Attribute
Name:                     address-mapper
User Attribute:           address
SAML Attribute Name:      address
SAML Attribute NameFormat: Basic
```

### Mapper 6: Profession
```
Type:                     User Attribute
Name:                     profession-mapper
User Attribute:           profession
SAML Attribute Name:      profession
SAML Attribute NameFormat: Basic
```

---

## Test User Attributes

```
age:         30
mobile:      +1-555-0100
address:     123 Main Street, New York, NY 10001
profession:  Software Developer
```

---

## Navigation Paths

**Add Custom Attributes**:
- Realm Settings → User profile → Create attribute

**Enable WebAuthn**:
- Authentication → Required actions → Enable both WebAuthn options

**Create Auth Flow**:
- Authentication → Flows → Create flow

**Add SAML Mappers**:
- Clients → saml-sp-1 → Client scopes → saml-sp-1-dedicated → Add mapper

**Update User**:
- Users → testuser → Attributes

---

**Pro Tip**: Keep this file open in a separate tab while configuring!
