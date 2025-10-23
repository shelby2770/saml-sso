package com.mycompany.keycloak;

import org.keycloak.Config;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventListenerProviderFactory;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

/**
 * Factory to create CustomLoginLogger instances
 * Keycloak uses this to instantiate your provider
 */
public class CustomLoginLoggerFactory implements EventListenerProviderFactory {

    @Override
    public EventListenerProvider create(KeycloakSession session) {
        return new CustomLoginLogger(session);
    }

    @Override
    public void init(Config.Scope config) {
        // Initialize configuration if needed
        System.out.println("🚀 Custom Login Logger initialized!");
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
        // Post-initialization
    }

    @Override
    public void close() {
        // Cleanup
    }

    @Override
    public String getId() {
        // This ID is used to identify your provider in Keycloak
        return "custom-login-logger";
    }
}
