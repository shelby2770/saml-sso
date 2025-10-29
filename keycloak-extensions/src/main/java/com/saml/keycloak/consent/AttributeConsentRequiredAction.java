package com.saml.keycloak.consent;

import org.keycloak.authentication.RequiredActionContext;
import org.keycloak.authentication.RequiredActionProvider;
import org.keycloak.models.UserModel;
import org.keycloak.sessions.AuthenticationSessionModel;

import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import java.util.ArrayList;
import java.util.List;

/**
 * Required Action Provider for Attribute Consent
 * 
 * This displays the attribute selection page after authentication
 * and before SAML assertion generation.
 */
public class AttributeConsentRequiredAction implements RequiredActionProvider {

    public static final String PROVIDER_ID = "ATTRIBUTE_CONSENT";
    private static final String SELECTED_ATTRIBUTES_NOTE = "selected_attributes";

    @Override
    public void evaluateTriggers(RequiredActionContext context) {
        // Check if this is a SAML authentication
        AuthenticationSessionModel authSession = context.getAuthenticationSession();
        String protocol = authSession.getProtocol();
        
        // Only trigger for SAML protocol
        if ("saml".equals(protocol)) {
            UserModel user = context.getUser();
            
            // Check if user has encrypted attributes
            if (hasEncryptedAttributes(user)) {
                context.getUser().addRequiredAction(PROVIDER_ID);
            }
        }
    }

    @Override
    public void requiredActionChallenge(RequiredActionContext context) {
        // Display the attribute consent page
        Response challenge = context.form()
                .createForm("attribute-consent.ftl");
        context.challenge(challenge);
    }

    @Override
    public void processAction(RequiredActionContext context) {
        MultivaluedMap<String, String> formData = context.getHttpRequest().getDecodedFormParameters();
        
        // Check if user cancelled
        if (formData.containsKey("cancel")) {
            context.failure();
            return;
        }

        // Get selected attributes
        List<String> selectedAttributes = formData.get("selected_attributes");
        
        if (selectedAttributes == null || selectedAttributes.isEmpty()) {
            // No attributes selected, show error
            context.challenge(
                context.form()
                    .setError("Please select at least one attribute to share")
                    .createForm("attribute-consent.ftl")
            );
            return;
        }

        // Store selected attributes in authentication session
        AuthenticationSessionModel authSession = context.getAuthenticationSession();
        authSession.setAuthNote(SELECTED_ATTRIBUTES_NOTE, String.join(",", selectedAttributes));

        // Mark action as complete
        context.success();
    }

    @Override
    public void close() {
        // No resources to close
    }

    /**
     * Check if user has any encrypted attributes
     */
    private boolean hasEncryptedAttributes(UserModel user) {
        return user.getFirstAttribute("encrypted_firstName") != null ||
               user.getFirstAttribute("encrypted_lastName") != null ||
               user.getFirstAttribute("encrypted_email") != null ||
               user.getFirstAttribute("encrypted_age") != null ||
               user.getFirstAttribute("encrypted_mobile") != null ||
               user.getFirstAttribute("encrypted_address") != null ||
               user.getFirstAttribute("encrypted_profession") != null;
    }
}
