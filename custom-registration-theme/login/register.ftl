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
                            <label for="email" class="${properties.kcLabelClass!}">
                                ${msg("email")} <small style="color: #666;">(Will be encrypted)</small>
                            </label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="email" id="email" class="${properties.kcInputClass!} plaintext-field" 
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
                            <label for="firstName" class="${properties.kcLabelClass!}">
                                ${msg("firstName")} <small style="color: #666;">(Will be encrypted)</small>
                            </label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="text" id="firstName" class="${properties.kcInputClass!} plaintext-field" 
                                   name="firstName" value="${(register.formData.firstName!'')}" />
                        </div>
                    </div>

                    <!-- Last Name -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="lastName" class="${properties.kcLabelClass!}">
                                ${msg("lastName")} <small style="color: #666;">(Will be encrypted)</small>
                            </label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="text" id="lastName" class="${properties.kcInputClass!} plaintext-field" 
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

                    <!-- Age (Will be encrypted) -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="user.attributes.age" class="${properties.kcLabelClass!}">
                                🎂 Age <small style="color: #666;">(Will be encrypted)</small>
                            </label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="number" id="user.attributes.age" class="${properties.kcInputClass!} plaintext-field" 
                                   name="user.attributes.age" 
                                   value="${(register.formData['user.attributes.age']!'')}"
                                   placeholder="25" min="1" max="150" />
                        </div>
                    </div>

                    <!-- Phone Number (Will be encrypted) -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="user.attributes.mobile" class="${properties.kcLabelClass!}">
                                📱 Mobile <small style="color: #666;">(Will be encrypted)</small>
                            </label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="tel" id="user.attributes.mobile" class="${properties.kcInputClass!} plaintext-field" 
                                   name="user.attributes.mobile" 
                                   value="${(register.formData['user.attributes.mobile']!'')}"
                                   placeholder="+1-555-1234" />
                        </div>
                    </div>

                    <!-- Address (Will be encrypted) -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="user.attributes.address" class="${properties.kcLabelClass!}">
                                🏠 Address <small style="color: #666;">(Will be encrypted)</small>
                            </label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <textarea id="user.attributes.address" class="${properties.kcInputClass!} plaintext-field" 
                                      name="user.attributes.address" 
                                      rows="2"
                                      placeholder="123 Main Street, City, State">${(register.formData['user.attributes.address']!'')}</textarea>
                        </div>
                    </div>

                    <!-- Profession (Will be encrypted) -->
                    <div class="${properties.kcFormGroupClass!}">
                        <div class="${properties.kcLabelWrapperClass!}">
                            <label for="user.attributes.profession" class="${properties.kcLabelClass!}">
                                💼 Profession <small style="color: #666;">(Will be encrypted)</small>
                            </label>
                        </div>
                        <div class="${properties.kcInputWrapperClass!}">
                            <input type="text" id="user.attributes.profession" class="${properties.kcInputClass!} plaintext-field" 
                                   name="user.attributes.profession" 
                                   value="${(register.formData['user.attributes.profession']!'')}"
                                   placeholder="Software Developer" />
                        </div>
                    </div>

                    <!-- Hidden fields for encrypted data -->
                    <input type="hidden" id="encrypted-firstName" name="user.attributes.encrypted_firstName" value="" />
                    <input type="hidden" id="encrypted-lastName" name="user.attributes.encrypted_lastName" value="" />
                    <input type="hidden" id="encrypted-email" name="user.attributes.encrypted_email" value="" />
                    <input type="hidden" id="encrypted-age" name="user.attributes.encrypted_age" value="" />
                    <input type="hidden" id="encrypted-mobile" name="user.attributes.encrypted_mobile" value="" />
                    <input type="hidden" id="encrypted-address" name="user.attributes.encrypted_address" value="" />
                    <input type="hidden" id="encrypted-profession" name="user.attributes.encrypted_profession" value="" />
                    <input type="hidden" id="wrapped-key" name="user.attributes.wrapped_key" value="" />
                    <input type="hidden" id="webauthn-credential-id" name="user.attributes.webauthn_credential_id" value="" />
                    <input type="hidden" id="encryption-salt" name="user.attributes.encryption_salt" value="" />
                    <input type="hidden" id="public-key" name="user.attributes.public_key" value="" />

                    <!-- WebAuthn Status Indicator -->
                    <div id="webauthn-status" style="margin: 20px 0; padding: 15px; border-radius: 8px; display: none; font-weight: 500;"></div>

                    <!-- Submit Buttons -->
                    <div class="${properties.kcFormGroupClass!}" style="margin-top: 30px;">
                        <div id="kc-form-buttons" class="${properties.kcFormButtonsClass!}">
                            <!-- Normal Register Button (No Encryption) -->
                            <button type="submit" 
                                    class="${properties.kcButtonClass!} ${properties.kcButtonDefaultClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" 
                                    id="kc-register-normal-btn"
                                    style="margin-bottom: 15px; background: #6c757d;">
                                📝 Register Without Encryption
                            </button>
                            
                            <!-- Encrypt & Register Button (With YubiKey) -->
                            <button type="button" 
                                    class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" 
                                    id="kc-register-encrypted-btn"
                                    style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); font-weight: bold;">
                                🔐 Encrypt & Register with YubiKey
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
                <script src="${url.resourcesPath}/js/registration-encryption-yubikey.js"></script>
            </div>
        </div>
    </#if>
</@layout.registrationLayout>
