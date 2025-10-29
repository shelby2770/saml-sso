package com.saml.keycloak.mapper;

import org.keycloak.dom.saml.v2.assertion.AttributeStatementType;
import org.keycloak.dom.saml.v2.assertion.AttributeType;
import org.keycloak.models.AuthenticatedClientSessionModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.ProtocolMapperModel;
import org.keycloak.models.UserModel;
import org.keycloak.models.UserSessionModel;
import org.keycloak.protocol.saml.mappers.AbstractSAMLProtocolMapper;
import org.keycloak.protocol.saml.mappers.SAMLAttributeStatementMapper;
import org.keycloak.provider.ProviderConfigProperty;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * SAML Protocol Mapper for Encrypted Attributes
 * 
 * This mapper includes only the selected encrypted attributes
 * in the SAML assertion based on user's consent.
 */
public class EncryptedAttributeMapper extends AbstractSAMLProtocolMapper implements SAMLAttributeStatementMapper {

    public static final String PROVIDER_ID = "saml-encrypted-attribute-mapper";
    private static final String SELECTED_ATTRIBUTES_NOTE = "selected_attributes";

    private static final List<ProviderConfigProperty> configProperties = new ArrayList<>();

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
    public List<ProviderConfigProperty> getConfigProperties() {
        return configProperties;
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }

    @Override
    public void transformAttributeStatement(AttributeStatementType attributeStatement,
                                            ProtocolMapperModel mappingModel,
                                            KeycloakSession session,
                                            UserSessionModel userSession,
                                            AuthenticatedClientSessionModel clientSession) {

        UserModel user = userSession.getUser();
        
        // Get selected attributes from authentication session note
        String selectedAttributesStr = clientSession.getNote(SELECTED_ATTRIBUTES_NOTE);
        
        if (selectedAttributesStr == null || selectedAttributesStr.isEmpty()) {
            // No attributes selected, return
            return;
        }

        List<String> selectedAttributes = Arrays.asList(selectedAttributesStr.split(","));

        // Add selected encrypted attributes to SAML assertion
        for (String attributeName : selectedAttributes) {
            String attributeValue = user.getFirstAttribute(attributeName);
            
            if (attributeValue != null && !attributeValue.isEmpty()) {
                AttributeType attributeType = new AttributeType(attributeName);
                attributeType.addAttributeValue(attributeValue);
                attributeStatement.addAttribute(new AttributeStatementType.ASTChoiceType(attributeType));
            }
        }

        // Always include encryption metadata (wrapped_key, credential_id, salt, etc.)
        addEncryptionMetadata(attributeStatement, user);

        // Always include username (not encrypted)
        AttributeType usernameAttr = new AttributeType("username");
        usernameAttr.addAttributeValue(user.getUsername());
        attributeStatement.addAttribute(new AttributeStatementType.ASTChoiceType(usernameAttr));
    }

    /**
     * Add encryption metadata required for decryption
     */
    private void addEncryptionMetadata(AttributeStatementType attributeStatement, UserModel user) {
        String[] metadataAttributes = {
            "wrapped_key",
            "webauthn_credential_id",
            "encryption_salt",
            "public_key",
            "encryption_iv",
            "wrapping_iv"
        };

        for (String metadataAttr : metadataAttributes) {
            String value = user.getFirstAttribute(metadataAttr);
            if (value != null && !value.isEmpty()) {
                AttributeType attributeType = new AttributeType(metadataAttr);
                attributeType.addAttributeValue(value);
                attributeStatement.addAttribute(new AttributeStatementType.ASTChoiceType(attributeType));
            }
        }
    }
}
