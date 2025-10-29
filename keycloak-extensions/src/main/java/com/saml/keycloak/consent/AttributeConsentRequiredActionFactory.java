package com.saml.keycloak.consent;

import org.keycloak.Config;
import org.keycloak.authentication.RequiredActionFactory;
import org.keycloak.authentication.RequiredActionProvider;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

/**
 * Factory for creating AttributeConsentRequiredAction instances
 */
public class AttributeConsentRequiredActionFactory implements RequiredActionFactory {

    @Override
    public String getDisplayText() {
        return "Attribute Consent for SAML";
    }

    @Override
    public RequiredActionProvider create(KeycloakSession session) {
        return new AttributeConsentRequiredAction();
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

    @Override
    public String getId() {
        return AttributeConsentRequiredAction.PROVIDER_ID;
    }
}
