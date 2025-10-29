package com.saml.keycloak.mapper;

import org.keycloak.Config;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.protocol.ProtocolMapper;
import org.keycloak.protocol.ProtocolMapperFactory;
import org.keycloak.protocol.saml.mappers.SAMLAttributeStatementMapper;
import org.keycloak.provider.ProviderConfigProperty;

import java.util.ArrayList;
import java.util.List;

/**
 * Factory for creating EncryptedAttributeMapper instances
 */
public class EncryptedAttributeMapperFactory implements ProtocolMapperFactory, SAMLAttributeStatementMapper {

    public static final String PROVIDER_ID = EncryptedAttributeMapper.PROVIDER_ID;

    private static final List<ProviderConfigProperty> configProperties = new ArrayList<>();

    @Override
    public String getProtocol() {
        return "saml";
    }

    @Override
    public String getDisplayCategory() {
        return "Attribute Mapper";
    }

    @Override
    public String getDisplayType() {
        return "Encrypted Attribute Mapper";
    }

    @Override
    public String getHelpText() {
        return "Maps only selected encrypted user attributes to SAML assertion";
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        return configProperties;
    }

    @Override
    public ProtocolMapper create(KeycloakSession session) {
        return new EncryptedAttributeMapper();
    }

    @Override
    public void init(Config.Scope config) {
        // No initialization needed
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
        // No post-initialization needed
    }

    @Override
    public void close() {
        // No resources to close
    }
}
