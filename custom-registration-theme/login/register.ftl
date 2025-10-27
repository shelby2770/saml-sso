<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('firstName','lastName','email','username','password','password-confirm'); section>
    <#if section = "header">
        ${msg("registerTitle")}
    <#elseif section = "form">
        <div id="kc-form">
            <div id="kc-form-wrapper">
                
                <!-- Registration Form -->
                <form id="kc-register-form" class="${properties.kcFormClass!}" action="${url.registrationAction}" method="post">
                    
                    <!-- Username -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="username" class="${properties.kcLabelClass!}">${msg("username")}</label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="text" id="username" class="${properties.kcInputClass!}" 
                                   name="username" value="${(register.formData.username!'')}" 
                                   autocomplete="username" 
                                   aria-invalid="<#if messagesPerField.existsError('username')>true</#if>" />
                            <#if messagesPerField.existsError('username')>
                                <span id="input-error-username" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                    ${kcSanitize(messagesPerField.get('username'))?no_esc}
                                </span>
                            </#if>
                        </div>
                    </div>

                    <!-- Email -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="email" class="${properties.kcLabelClass!}">${msg("email")}</label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="email" id="email" class="${properties.kcInputClass!}" 
                                   name="email" value="${(register.formData.email!'')}" 
                                   autocomplete="email"
                                   aria-invalid="<#if messagesPerField.existsError('email')>true</#if>" />
                            <#if messagesPerField.existsError('email')>
                                <span id="input-error-email" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                    ${kcSanitize(messagesPerField.get('email'))?no_esc}
                                </span>
                            </#if>
                        </div>
                    </div>

                    <!-- First Name -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="firstName" class="${properties.kcLabelClass!}">${msg("firstName")}</label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="text" id="firstName" class="${properties.kcInputClass!}" 
                                   name="firstName" value="${(register.formData.firstName!'')}" />
                        </div>
                    </div>

                    <!-- Last Name -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="lastName" class="${properties.kcLabelClass!}">${msg("lastName")}</label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="text" id="lastName" class="${properties.kcInputClass!}" 
                                   name="lastName" value="${(register.formData.lastName!'')}" />
                        </div>
                    </div>

                    <!-- Password -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="password" class="${properties.kcLabelClass!}">${msg("password")}</label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="password" id="password" class="${properties.kcInputClass!}" 
                                   name="password" autocomplete="new-password"
                                   aria-invalid="<#if messagesPerField.existsError('password')>true</#if>" />
                            <#if messagesPerField.existsError('password')>
                                <span id="input-error-password" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                    ${kcSanitize(messagesPerField.get('password'))?no_esc}
                                </span>
                            </#if>
                        </div>
                    </div>

                    <!-- Password Confirm -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="password-confirm" class="${properties.kcLabelClass!}">${msg("passwordConfirm")}</label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="password" id="password-confirm" class="${properties.kcInputClass!}" 
                                   name="password-confirm" autocomplete="new-password"
                                   aria-invalid="<#if messagesPerField.existsError('password-confirm')>true</#if>" />
                            <#if messagesPerField.existsError('password-confirm')>
                                <span id="input-error-password-confirm" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                    ${kcSanitize(messagesPerField.get('password-confirm'))?no_esc}
                                </span>
                            </#if>
                        </div>
                    </div>

                    <!-- Phone Number (Sensitive - will be encrypted) -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="user.attributes.phone" class="${properties.kcLabelClass!}">
                                📱 Phone Number <small style="color: #666;">(Will be encrypted)</small>
                            </label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="tel" id="user.attributes.phone" class="${properties.kcInputClass!}" 
                                   name="user.attributes.phone" 
                                   value="${(register.formData['user.attributes.phone']!'')}"
                                   placeholder="+1-555-1234" />
                        </div>
                    </div>

                    <!-- Address (Sensitive - will be encrypted) -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="user.attributes.address" class="${properties.kcLabelClass!}">
                                🏠 Address <small style="color: #666;">(Will be encrypted)</small>
                            </label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <textarea id="user.attributes.address" class="${properties.kcInputClass!}" 
                                      name="user.attributes.address" 
                                      rows="2"
                                      placeholder="123 Main Street, City, State">${(register.formData['user.attributes.address']!'')}</textarea>
                        </div>
                    </div>

                    <!-- Hidden fields for encrypted data -->
                    <input type="hidden" id="encrypted-payload" name="user.attributes.encrypted_payload" value="" />
                    <input type="hidden" id="encrypted-payload-chunks" name="user.attributes.encrypted_payload_chunks" value="" />
                    <input type="hidden" id="encrypted-payload-chunk1" name="user.attributes.encrypted_payload_chunk1" value="" />
                    <input type="hidden" id="encrypted-payload-chunk2" name="user.attributes.encrypted_payload_chunk2" value="" />
                    <input type="hidden" id="encrypted-payload-chunk3" name="user.attributes.encrypted_payload_chunk3" value="" />
                    <input type="hidden" id="webauthn-credential-id" name="user.attributes.webauthn_credential_id" value="" />
                    <input type="hidden" id="encryption-salt" name="user.attributes.encryption_salt" value="" />

                    <!-- WebAuthn Encryption Checkbox -->
                    <div class="${properties.kcFormGroupClass!}" style="margin-top: 20px; padding: 15px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 8px; color: white;">
                        <label style="display: flex; align-items: flex-start; cursor: pointer; margin: 0;">
                            <input type="checkbox" id="use-webauthn-encryption" 
                                   style="margin-right: 12px; margin-top: 3px; width: 20px; height: 20px; cursor: pointer;" />
                            <div>
                                <strong style="font-size: 16px;">🔐 Encrypt my sensitive data with security key</strong>
                                <br/>
                                <small style="color: #f0f0f0; line-height: 1.5;">
                                    Your phone number and address will be encrypted using your hardware security key (YubiKey, etc.). 
                                    You'll need to touch your key during registration.
                                </small>
                            </div>
                        </label>
                    </div>

                    <!-- WebAuthn Status Indicator -->
                    <div id="webauthn-status" style="margin-top: 15px; padding: 12px; border-radius: 5px; display: none; font-weight: 500;"></div>

                    <!-- Submit Button -->
                    <div class="${properties.kcFormGroupClass!}" style="margin-top: 30px;">
                        <div id="kc-form-buttons" class="${properties.kcFormButtonsClass!}">
                            <button type="submit" 
                                    class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" 
                                    id="kc-register-btn">
                                ${msg("doRegister")}
                            </button>
                        </div>
                    </div>

                    <!-- Back to Login -->
                    <div class="${properties.kcFormGroupClass!}" style="text-align: center; margin-top: 20px;">
                        <span class="${properties.kcFormOptionsClass!}">
                            <a href="${url.loginUrl}">${kcSanitize(msg("backToLogin"))?no_esc}</a>
                        </span>
                    </div>
                </form>

                <!-- Load encryption script -->
                <script src="${url.resourcesPath}/js/registration-with-webauthn.js"></script>
            </div>
        </div>
    </#if>
</@layout.registrationLayout>
