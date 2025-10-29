<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=true; section>
    <#if section = "header">
        🔐 Select Attributes to Share
    <#elseif section = "form">
        <div id="kc-form">
            <div id="kc-form-wrapper">
                
                <!-- Attribute Selection Form -->
                <form id="attribute-consent-form" class="${properties.kcFormClass!}" action="${url.loginAction}" method="post">
                    
                    <!-- Information Box -->
                    <div style="background: #e3f2fd; border: 2px solid #2196f3; border-radius: 8px; padding: 20px; margin-bottom: 30px;">
                        <h3 style="margin: 0 0 15px 0; color: #1565c0; display: flex; align-items: center; gap: 10px;">
                            <span style="font-size: 24px;">🛡️</span>
                            <span>Privacy Control</span>
                        </h3>
                        <p style="margin: 0; color: #1565c0; line-height: 1.6;">
                            <strong>Service Provider:</strong> <span style="color: #0d47a1;">${client.clientId}</span><br/>
                            Select which encrypted attributes you want to share with this service provider.
                            Your data remains encrypted end-to-end.
                        </p>
                    </div>

                    <!-- Attributes List -->
                    <div style="background: white; border: 1px solid #e0e0e0; border-radius: 8px; padding: 20px; margin-bottom: 20px;">
                        <h4 style="margin: 0 0 20px 0; color: #333; font-size: 16px; font-weight: 600;">
                            📋 Available Encrypted Attributes
                        </h4>

                        <!-- Select All / Deselect All -->
                        <div style="margin-bottom: 20px; padding: 15px; background: #f5f5f5; border-radius: 6px;">
                            <label style="display: flex; align-items: center; gap: 10px; cursor: pointer; font-weight: 500;">
                                <input type="checkbox" id="select-all" style="width: 20px; height: 20px; cursor: pointer;">
                                <span style="font-size: 15px;">🎯 Select All Attributes</span>
                            </label>
                        </div>

                        <!-- Individual Attributes -->
                        <div id="attributes-list" style="display: grid; gap: 15px;">
                            
                            <!-- First Name -->
                            <#if (user.firstName)??>
                                <label class="attribute-item" style="display: flex; align-items: center; gap: 12px; padding: 15px; border: 2px solid #e0e0e0; border-radius: 8px; cursor: pointer; transition: all 0.2s;">
                                    <input type="checkbox" name="selected_attributes" value="encrypted_firstName" class="attribute-checkbox" style="width: 18px; height: 18px; cursor: pointer;">
                                    <div style="flex: 1;">
                                        <div style="font-weight: 600; color: #333; margin-bottom: 4px;">
                                            👤 First Name
                                        </div>
                                        <div style="font-size: 13px; color: #666; font-family: monospace;">
                                            🔐 Encrypted: ${user.firstName[0..20]}...
                                        </div>
                                    </div>
                                </label>
                            </#if>

                            <!-- Last Name -->
                            <#if (user.lastName)??>
                                <label class="attribute-item" style="display: flex; align-items: center; gap: 12px; padding: 15px; border: 2px solid #e0e0e0; border-radius: 8px; cursor: pointer; transition: all 0.2s;">
                                    <input type="checkbox" name="selected_attributes" value="encrypted_lastName" class="attribute-checkbox" style="width: 18px; height: 18px; cursor: pointer;">
                                    <div style="flex: 1;">
                                        <div style="font-weight: 600; color: #333; margin-bottom: 4px;">
                                            👤 Last Name
                                        </div>
                                        <div style="font-size: 13px; color: #666; font-family: monospace;">
                                            🔐 Encrypted: ${user.lastName[0..20]}...
                                        </div>
                                    </div>
                                </label>
                            </#if>

                            <!-- Email -->
                            <#if (user.email)??>
                                <label class="attribute-item" style="display: flex; align-items: center; gap: 12px; padding: 15px; border: 2px solid #e0e0e0; border-radius: 8px; cursor: pointer; transition: all 0.2s;">
                                    <input type="checkbox" name="selected_attributes" value="encrypted_email" class="attribute-checkbox" style="width: 18px; height: 18px; cursor: pointer;">
                                    <div style="flex: 1;">
                                        <div style="font-weight: 600; color: #333; margin-bottom: 4px;">
                                            📧 Email Address
                                        </div>
                                        <div style="font-size: 13px; color: #666; font-family: monospace;">
                                            🔐 Encrypted: ${user.email[0..20]}...
                                        </div>
                                    </div>
                                </label>
                            </#if>

                            <!-- Age -->
                            <#if (user.attributes.encrypted_age)??>
                                <label class="attribute-item" style="display: flex; align-items: center; gap: 12px; padding: 15px; border: 2px solid #e0e0e0; border-radius: 8px; cursor: pointer; transition: all 0.2s;">
                                    <input type="checkbox" name="selected_attributes" value="encrypted_age" class="attribute-checkbox" style="width: 18px; height: 18px; cursor: pointer;">
                                    <div style="flex: 1;">
                                        <div style="font-weight: 600; color: #333; margin-bottom: 4px;">
                                            🎂 Age
                                        </div>
                                        <div style="font-size: 13px; color: #666; font-family: monospace;">
                                            🔐 Encrypted: ${user.attributes.encrypted_age[0][0..20]}...
                                        </div>
                                    </div>
                                </label>
                            </#if>

                            <!-- Mobile -->
                            <#if (user.attributes.encrypted_mobile)??>
                                <label class="attribute-item" style="display: flex; align-items: center; gap: 12px; padding: 15px; border: 2px solid #e0e0e0; border-radius: 8px; cursor: pointer; transition: all 0.2s;">
                                    <input type="checkbox" name="selected_attributes" value="encrypted_mobile" class="attribute-checkbox" style="width: 18px; height: 18px; cursor: pointer;">
                                    <div style="flex: 1;">
                                        <div style="font-weight: 600; color: #333; margin-bottom: 4px;">
                                            📱 Mobile Number
                                        </div>
                                        <div style="font-size: 13px; color: #666; font-family: monospace;">
                                            🔐 Encrypted: ${user.attributes.encrypted_mobile[0][0..20]}...
                                        </div>
                                    </div>
                                </label>
                            </#if>

                            <!-- Address -->
                            <#if (user.attributes.encrypted_address)??>
                                <label class="attribute-item" style="display: flex; align-items: center; gap: 12px; padding: 15px; border: 2px solid #e0e0e0; border-radius: 8px; cursor: pointer; transition: all 0.2s;">
                                    <input type="checkbox" name="selected_attributes" value="encrypted_address" class="attribute-checkbox" style="width: 18px; height: 18px; cursor: pointer;">
                                    <div style="flex: 1;">
                                        <div style="font-weight: 600; color: #333; margin-bottom: 4px;">
                                            🏠 Address
                                        </div>
                                        <div style="font-size: 13px; color: #666; font-family: monospace;">
                                            🔐 Encrypted: ${user.attributes.encrypted_address[0][0..20]}...
                                        </div>
                                    </div>
                                </label>
                            </#if>

                            <!-- Profession -->
                            <#if (user.attributes.encrypted_profession)??>
                                <label class="attribute-item" style="display: flex; align-items: center; gap: 12px; padding: 15px; border: 2px solid #e0e0e0; border-radius: 8px; cursor: pointer; transition: all 0.2s;">
                                    <input type="checkbox" name="selected_attributes" value="encrypted_profession" class="attribute-checkbox" style="width: 18px; height: 18px; cursor: pointer;">
                                    <div style="flex: 1;">
                                        <div style="font-weight: 600; color: #333; margin-bottom: 4px;">
                                            💼 Profession
                                        </div>
                                        <div style="font-size: 13px; color: #666; font-family: monospace;">
                                            🔐 Encrypted: ${user.attributes.encrypted_profession[0][0..20]}...
                                        </div>
                                    </div>
                                </label>
                            </#if>

                        </div>

                        <!-- Selection Counter -->
                        <div id="selection-count" style="margin-top: 20px; padding: 15px; background: #f5f5f5; border-radius: 6px; text-align: center; font-weight: 600; color: #666;">
                            <span id="count-text">No attributes selected</span>
                        </div>
                    </div>

                    <!-- Warning Box -->
                    <div style="background: #fff3e0; border: 2px solid #ff9800; border-radius: 8px; padding: 15px; margin-bottom: 20px;">
                        <p style="margin: 0; color: #e65100; display: flex; align-items: start; gap: 10px; line-height: 1.6;">
                            <span style="font-size: 20px;">⚠️</span>
                            <span>
                                <strong>Privacy Notice:</strong> Only selected attributes will be shared with the service provider.
                                All data remains encrypted and can only be decrypted with your YubiKey.
                            </span>
                        </p>
                    </div>

                    <!-- Buttons -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div id="kc-form-buttons" class="${properties.kcFormButtonsClass!}" style="display: flex; gap: 15px;">
                            
                            <!-- Cancel Button -->
                            <button type="submit" name="cancel" value="true"
                                    class="${properties.kcButtonClass!} ${properties.kcButtonDefaultClass!}" 
                                    style="flex: 1; padding: 15px; background: #757575; border: none; border-radius: 8px; color: white; font-weight: 600; cursor: pointer;">
                                ❌ Cancel Login
                            </button>
                            
                            <!-- Share Button -->
                            <button type="submit" id="submit-btn"
                                    class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!}" 
                                    style="flex: 2; padding: 15px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border: none; border-radius: 8px; color: white; font-weight: 600; cursor: pointer; font-size: 16px;">
                                ✅ Share Selected Attributes
                            </button>
                        </div>
                    </div>

                </form>

                <!-- Load JavaScript -->
                <script src="${url.resourcesPath}/js/attribute-consent.js"></script>

                <style>
                    .attribute-item:hover {
                        border-color: #667eea !important;
                        background: #f8f9ff !important;
                    }
                    
                    .attribute-item:has(input:checked) {
                        border-color: #667eea !important;
                        background: #f0f4ff !important;
                    }

                    #submit-btn:disabled {
                        opacity: 0.5;
                        cursor: not-allowed;
                    }
                </style>
            </div>
        </div>
    </#if>
</@layout.registrationLayout>
