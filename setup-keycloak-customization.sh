#!/bin/bash

# Keycloak Java Customization - Quick Setup Script
# This script sets up the complete development environment

echo "🚀 Keycloak Java Customization - Quick Setup"
echo "============================================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check Java
echo -e "${BLUE}Checking Java installation...${NC}"
if ! command -v java &> /dev/null; then
    echo -e "${RED}❌ Java not found. Installing OpenJDK 17...${NC}"
    sudo apt update
    sudo apt install -y openjdk-17-jdk openjdk-17-jdk-headless maven
else
    echo -e "${GREEN}✓ Java found: $(java -version 2>&1 | head -n 1)${NC}"
fi

# Check Maven
echo -e "${BLUE}Checking Maven installation...${NC}"
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}❌ Maven not found. Installing...${NC}"
    sudo apt install -y maven
else
    echo -e "${GREEN}✓ Maven found: $(mvn -version | head -n 1)${NC}"
fi

echo ""
echo -e "${BLUE}Creating project structure...${NC}"

# Create main customization directory
mkdir -p keycloak-customization/src/main/java/com/mycompany/keycloak
mkdir -p keycloak-customization/src/main/resources/META-INF/services
mkdir -p keycloak-customization/src/test/java

# Create theme directories
mkdir -p keycloak/themes/mytheme/login/resources/{css,js,img}
mkdir -p keycloak/themes/mytheme/account/resources/{css,js,img}
mkdir -p keycloak/themes/mytheme/email

echo -e "${GREEN}✓ Project structure created${NC}"

# Create pom.xml if it doesn't exist
if [ ! -f "keycloak-customization/pom.xml" ]; then
    echo -e "${BLUE}Creating pom.xml...${NC}"
    cat > keycloak-customization/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.mycompany</groupId>
    <artifactId>keycloak-custom-extensions</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>Keycloak Custom Extensions</name>

    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <keycloak.version>23.0.0</keycloak.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.keycloak</groupId>
            <artifactId>keycloak-core</artifactId>
            <version>${keycloak.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.keycloak</groupId>
            <artifactId>keycloak-server-spi</artifactId>
            <version>${keycloak.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.keycloak</groupId>
            <artifactId>keycloak-server-spi-private</artifactId>
            <version>${keycloak.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.keycloak</groupId>
            <artifactId>keycloak-services</artifactId>
            <version>${keycloak.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.jboss.logging</groupId>
            <artifactId>jboss-logging</artifactId>
            <version>3.5.3.Final</version>
            <scope>provided</scope>
        </dependency>
    </dependencies>

    <build>
        <finalName>${project.artifactId}</finalName>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
            </plugin>
        </plugins>
    </build>
</project>
EOF
    echo -e "${GREEN}✓ pom.xml created${NC}"
fi

# Create theme.properties
if [ ! -f "keycloak/themes/mytheme/theme.properties" ]; then
    echo -e "${BLUE}Creating theme.properties...${NC}"
    cat > keycloak/themes/mytheme/theme.properties << 'EOF'
parent=keycloak
import=common/keycloak
styles=css/login.css css/custom.css
scripts=js/custom.js
locales=en
EOF
    echo -e "${GREEN}✓ theme.properties created${NC}"
fi

# Create placeholder logo
if [ ! -f "keycloak/themes/mytheme/login/resources/img/logo.png" ]; then
    echo -e "${BLUE}Creating placeholder logo...${NC}"
    # Create a simple text file as placeholder
    echo "Put your logo.png here (80x80 recommended)" > keycloak/themes/mytheme/login/resources/img/logo.png
fi

# Test Maven compilation
echo ""
echo -e "${BLUE}Testing Maven setup...${NC}"
cd keycloak-customization
mvn clean compile

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Maven setup successful!${NC}"
else
    echo -e "${RED}❌ Maven compilation failed${NC}"
    exit 1
fi

cd ..

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "Next steps:"
echo "1. Read: KEYCLOAK_JAVA_DEEP_DIVE.md"
echo "2. Add your Java code to: keycloak-customization/src/main/java/"
echo "3. Build: cd keycloak-customization && mvn clean package"
echo "4. Update docker-compose.yml to mount the JAR"
echo "5. Restart Keycloak: bash stop-keycloak.sh && bash start-keycloak.sh"
echo ""
echo "Happy coding! 🚀"
