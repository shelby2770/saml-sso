package com.mycompany.keycloak;

import org.jboss.logging.Logger;
import org.keycloak.events.Event;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventType;
import org.keycloak.events.admin.AdminEvent;
import org.keycloak.models.KeycloakSession;

/**
 * Custom Event Listener - Logs all authentication events
 * This is the SIMPLEST example to start with!
 */
public class CustomLoginLogger implements EventListenerProvider {
    
    private static final Logger log = Logger.getLogger(CustomLoginLogger.class);
    private final KeycloakSession session;
    
    public CustomLoginLogger(KeycloakSession session) {
        this.session = session;
    }

    @Override
    public void onEvent(Event event) {
        // Log every user event
        log.infof("🔔 EVENT: %s - User: %s - IP: %s", 
            event.getType(), 
            event.getUserId(), 
            event.getIpAddress()
        );
        
        // Special handling for login
        if (event.getType() == EventType.LOGIN) {
            log.infof("✅ LOGIN SUCCESS: User %s logged in from %s", 
                event.getDetails().get("username"),
                event.getIpAddress()
            );
            
            // TODO: Here you can:
            // - Send to your analytics database
            // - Send notification email
            // - Update user's last_login timestamp
            // - Check for suspicious login patterns
        }
        
        // Handle failed login
        if (event.getType() == EventType.LOGIN_ERROR) {
            log.warnf("❌ LOGIN FAILED: %s - Error: %s", 
                event.getDetails().get("username"),
                event.getError()
            );
            
            // TODO: Track failed attempts, lock account after X failures
        }
        
        // Handle registration
        if (event.getType() == EventType.REGISTER) {
            log.infof("👤 NEW USER REGISTERED: %s", event.getDetails().get("username"));
            
            // TODO: Send welcome email, create profile in your DB
        }
    }

    @Override
    public void onEvent(AdminEvent adminEvent, boolean includeRepresentation) {
        // Log admin actions
        log.infof("⚙️ ADMIN EVENT: %s - Resource: %s", 
            adminEvent.getOperationType(),
            adminEvent.getResourceType()
        );
    }

    @Override
    public void close() {
        // Cleanup resources if needed
    }
}
