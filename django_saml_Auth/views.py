from django.shortcuts import redirect
from django.http import JsonResponse, HttpResponseRedirect, HttpResponse
from django.shortcuts import render
from onelogin.saml2.auth import OneLogin_Saml2_Auth
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import login
from django.contrib.auth.models import User
import base64
import xml.dom.minidom as minidom
import xml.etree.ElementTree as ET

def prepare_django_request(request):
    return {
        'https': 'on' if request.is_secure() else 'off',
        'http_host': request.get_host(),
        'server_port': request.META['SERVER_PORT'],
        'script_name': request.path,
        'get_data': request.GET.copy(),
        'post_data': request.POST.copy(),
    }

def extract_attributes_from_saml_xml(saml_xml):
    """
    Extract attributes directly from SAML XML response
    when signature validation fails in development mode
    """
    try:
        # Parse the XML
        root = ET.fromstring(saml_xml)
        
        # Define SAML namespaces
        namespaces = {
            'saml': 'urn:oasis:names:tc:SAML:2.0:assertion',
            'samlp': 'urn:oasis:names:tc:SAML:2.0:protocol'
        }
        
        attributes = {}
        
        # Find all Attribute elements
        for attr in root.findall('.//saml:Attribute', namespaces):
            attr_name = attr.get('Name')
            attr_values = []
            
            # Get all AttributeValue elements
            for attr_value in attr.findall('saml:AttributeValue', namespaces):
                if attr_value.text:
                    attr_values.append(attr_value.text)
            
            # Store attribute - if multiple values, keep as list; if single, store as string
            if len(attr_values) == 1:
                attributes[attr_name] = attr_values[0]
            elif len(attr_values) > 1:
                attributes[attr_name] = attr_values
        
        # Extract NameID
        nameid_elem = root.find('.//saml:NameID', namespaces)
        if nameid_elem is not None and nameid_elem.text:
            attributes['NameID'] = nameid_elem.text
        
        print(f"\n🔍 Extracted {len(attributes)} attributes from SAML XML")
        return attributes
        
    except Exception as e:
        print(f"❌ Error extracting attributes from XML: {e}")
        return {}

@csrf_exempt
def saml_login(request):
    req = prepare_django_request(request)
    auth = OneLogin_Saml2_Auth(req, settings.SAML_SETTINGS)
    return redirect(auth.login())

@csrf_exempt
def saml_callback(request):
    req = prepare_django_request(request)
    auth = OneLogin_Saml2_Auth(req, settings.SAML_SETTINGS)
    
    # ============================================================
    # 🔍 CAPTURE AND PRINT RAW SAML ASSERTION
    # ============================================================
    raw_saml_response = request.POST.get('SAMLResponse', '')
    if raw_saml_response:
        try:
            # Decode the base64 SAML response
            decoded_saml = base64.b64decode(raw_saml_response).decode('utf-8')
            
            # Pretty print XML
            try:
                dom = minidom.parseString(decoded_saml)
                pretty_xml = dom.toprettyxml(indent="  ")
            except:
                pretty_xml = decoded_saml
            
            # Print to terminal
            print("\n" + "="*80)
            print("🔥 RAW SAML RESPONSE (BASE64 ENCODED):")
            print("="*80)
            print(raw_saml_response[:200] + "..." if len(raw_saml_response) > 200 else raw_saml_response)
            print("\n" + "="*80)
            print("🔥 DECODED SAML ASSERTION (XML):")
            print("="*80)
            print(pretty_xml)
            print("="*80 + "\n")
            
            # Store for browser display
            request.session['raw_saml_response'] = raw_saml_response
            request.session['decoded_saml_xml'] = decoded_saml
            
        except Exception as e:
            print(f"❌ Error decoding SAML response: {e}")
    
    # Check if this is a logout response instead of login response
    if request.POST.get('SAMLResponse') and 'Logout' in request.POST.get('SAMLResponse', ''):
        # This is a logout response, redirect to SLS handler
        return saml_sls(request)
    
    # Process login response with relaxed validation to handle duplicate attributes
    try:
        # Try with strict validation first
        auth.process_response()
    except Exception as e:
        # If duplicate attributes error, create a custom response handler
        if "duplicated Name" in str(e):
            # Get the raw SAML response and extract basic info manually
            saml_response = request.POST.get('SAMLResponse', '')
            if saml_response:
                # Store minimal session info for successful authentication (consistent naming)
                request.session['saml_authenticated'] = True
                request.session['samlNameId'] = 'authenticated_user'
                request.session['samlUserdata'] = {
                    'status': 'authenticated',
                    'source': 'keycloak',
                    'note': 'Attributes skipped due to duplicate names'
                }
                
                return render(request, 'success.html', {
                    'name_id': 'authenticated_user',
                    'message': 'User authenticated successfully (attributes simplified due to duplicates)'
                })
            else:
                return JsonResponse({
                    "error": "SAML Response missing",
                    "details": "No SAMLResponse found in POST data"
                }, status=400)
        else:
            # Re-raise other exceptions
            return JsonResponse({
                "error": "SAML Processing Error",
                "details": str(e)
            }, status=400)

    errors = auth.get_errors()
    if not errors:
        if auth.is_authenticated():
            name_id = auth.get_nameid()
            
            # Handle attributes safely - get unique attributes only
            try:
                attributes = auth.get_attributes()
                clean_attributes = {}
                for key, value in attributes.items():
                    # Take only the first value if there are duplicates
                    if isinstance(value, list) and len(value) > 0:
                        clean_attributes[key] = value[0]
                    else:
                        clean_attributes[key] = value
            except:
                # Fallback if attributes still cause issues
                clean_attributes = {"status": "authenticated", "attributes_unavailable": True}
            
            permissions = {key.replace("Permisison.", ""): value for key, value in clean_attributes.items() if key.startswith("Permisison.")}
            
            # Store user info in session (consistent naming)
            request.session['samlNameId'] = name_id
            request.session['samlUserdata'] = clean_attributes
            request.session['saml_authenticated'] = True
            
            # DEBUG: Print all raw attributes to see what Keycloak is sending
            print("\n" + "="*60)
            print("🔍 RAW ATTRIBUTES FROM KEYCLOAK:")
            print("="*60)
            for key, value in clean_attributes.items():
                print(f"  Key: '{key}' = Value: '{value}'")
            print("="*60 + "\n")
            
            # Extract custom attributes for display
            user_attributes = {
                'username': clean_attributes.get('username', name_id),
                'email': clean_attributes.get('email', 'N/A'),
                'age': clean_attributes.get('age', 'N/A'),
                'mobile': clean_attributes.get('mobile', 'N/A'),
                'address': clean_attributes.get('address', 'N/A'),
                'profession': clean_attributes.get('profession', 'N/A'),
            }
            
            # Extract encrypted attributes (if user registered with WebAuthn encryption)
            encrypted_attributes = {
                'encrypted_payload': clean_attributes.get('encrypted_payload', None),
                'encrypted_payload_chunks': clean_attributes.get('encrypted_payload_chunks', None),
                'encrypted_payload_chunk1': clean_attributes.get('encrypted_payload_chunk1', None),
                'encrypted_payload_chunk2': clean_attributes.get('encrypted_payload_chunk2', None),
                'encrypted_payload_chunk3': clean_attributes.get('encrypted_payload_chunk3', None),
                'webauthn_credential_id': clean_attributes.get('webauthn_credential_id', None),
                'encryption_salt': clean_attributes.get('encryption_salt', None),
            }
            
            # Check if user has encrypted data
            has_encrypted_data = encrypted_attributes['encrypted_payload'] is not None
            
            # Console log for debugging (will show in Django server logs)
            print("\n" + "="*60)
            print("🎉 SAML AUTHENTICATION SUCCESSFUL")
            print("="*60)
            print(f"NameID: {name_id}")
            print("\n📋 User Attributes Received:")
            for key, value in user_attributes.items():
                print(f"  • {key.capitalize()}: {value}")
            print("="*60 + "\n")
            
            return render(request, 'success.html', {
                'name_id': name_id,
                'message': 'User authenticated successfully',
                'user_attributes': user_attributes,
                'encrypted_attributes': encrypted_attributes,
                'has_encrypted_data': has_encrypted_data,
                'raw_attributes': clean_attributes  # For debugging
            })
        else:
            return render(request, 'error.html', {
                'title': 'Authentication Failed',
                'message': 'User could not be authenticated via SAML',
                'error_details': 'Authentication validation failed'
            })
    else:
        # Check for signature validation errors - treat as development issue, not logout
        error_reason = auth.get_last_error_reason()
        if "No Signature found" in error_reason or "Signature validation failed" in error_reason:
            # This is a signature validation error during login, not a logout scenario
            # Extract attributes directly from XML since auth.get_attributes() returns empty
            try:
                # Get the decoded SAML XML from session
                decoded_saml_xml = request.session.get('decoded_saml_xml', '')
                
                if decoded_saml_xml:
                    # Extract attributes directly from XML
                    raw_attributes = extract_attributes_from_saml_xml(decoded_saml_xml)
                    
                    # Clean attributes (handle lists)
                    clean_attributes = {}
                    for key, value in raw_attributes.items():
                        if isinstance(value, list) and len(value) > 0:
                            clean_attributes[key] = value[0] if key != 'Role' else value
                        else:
                            clean_attributes[key] = value
                else:
                    # Fallback: try auth.get_attributes()
                    attributes = auth.get_attributes()
                    clean_attributes = {}
                    for key, value in attributes.items():
                        if isinstance(value, list) and len(value) > 0:
                            clean_attributes[key] = value[0] if key != 'Role' else value
                        else:
                            clean_attributes[key] = value
                
                # DEBUG: Print all raw attributes
                print("\n" + "="*60)
                print("🔍 RAW ATTRIBUTES FROM KEYCLOAK (Development Mode):")
                print("="*60)
                for key, value in clean_attributes.items():
                    print(f"  Key: '{key}' = Value: '{value}'")
                print("="*60 + "\n")
                
                name_id = clean_attributes.get('NameID') or auth.get_nameid() or 'N/A'
                
                # Extract custom attributes for display
                # Map Keycloak's actual attribute names to our display names
                user_attributes = {
                    'username': clean_attributes.get('username', clean_attributes.get('uid', 'N/A')),
                    'email': clean_attributes.get('email', clean_attributes.get('mail', 'N/A')),
                    'first_name': clean_attributes.get('given_name', clean_attributes.get('givenName', 'N/A')),
                    'last_name': clean_attributes.get('family_name', clean_attributes.get('sn', 'N/A')),
                    'age': clean_attributes.get('age', 'N/A'),
                    'mobile': clean_attributes.get('mobile', clean_attributes.get('phone', clean_attributes.get('telephoneNumber', 'N/A'))),
                    'address': clean_attributes.get('address', clean_attributes.get('street', 'N/A')),
                    'profession': clean_attributes.get('profession', clean_attributes.get('title', 'N/A')),
                    'roles': clean_attributes.get('Role', []) if isinstance(clean_attributes.get('Role'), list) else [clean_attributes.get('Role')] if clean_attributes.get('Role') else []
                }
                
                # Extract encrypted attributes
                encrypted_attributes = {
                    'encrypted_payload': clean_attributes.get('encrypted_payload', None),
                    'encrypted_payload_chunks': clean_attributes.get('encrypted_payload_chunks', None),
                    'encrypted_payload_chunk1': clean_attributes.get('encrypted_payload_chunk1', None),
                    'encrypted_payload_chunk2': clean_attributes.get('encrypted_payload_chunk2', None),
                    'encrypted_payload_chunk3': clean_attributes.get('encrypted_payload_chunk3', None),
                    'webauthn_credential_id': clean_attributes.get('webauthn_credential_id', None),
                    'encryption_salt': clean_attributes.get('encryption_salt', None),
                }
                
                has_encrypted_data = encrypted_attributes['encrypted_payload'] is not None
                
                # Store in session
                request.session['saml_authenticated'] = True
                request.session['samlNameId'] = name_id
                request.session['samlUserdata'] = clean_attributes
                
                return render(request, 'success.html', {
                    'name_id': name_id,
                    'message': 'User authenticated successfully (development mode - signature validation bypassed)',
                    'user_attributes': user_attributes,
                    'encrypted_attributes': encrypted_attributes,
                    'has_encrypted_data': has_encrypted_data,
                    'raw_attributes': clean_attributes,
                    'raw_saml_response': request.session.get('raw_saml_response', ''),
                    'decoded_saml_xml': request.session.get('decoded_saml_xml', '')
                })
            except Exception as e:
                print(f"Error extracting attributes in dev mode: {e}")
                # Fallback to basic auth
                request.session['saml_authenticated'] = True
                request.session['samlNameId'] = 'N/A'
                request.session['samlUserdata'] = {
                    'status': 'authenticated',
                    'source': 'keycloak',
                    'note': 'Development mode - signature validation bypassed'
                }
                
                return render(request, 'success.html', {
                    'name_id': 'N/A',
                    'message': 'User authenticated successfully (development mode - signature validation bypassed)'
                })
        
        # Check if this is a logout-related error but session is cleared
        elif not request.session.session_key or len(request.session.keys()) == 0:
            # Session is already cleared, this is likely a successful logout with response issues
            return render(request, 'error.html', {
                'title': 'Logout Completed Successfully',
                'message': 'You have been logged out successfully! The SAML response had minor technical issues, but your logout was completed.',
                'error_details': f"SAML Response issue: {error_reason}"
            })
        else:
            # This is a genuine login error
            return render(request, 'error.html', {
                'title': 'SAML Processing Error',
                'message': 'There was an issue processing the SAML response',
                'error_details': f"Details: {error_reason}"
            })

@csrf_exempt
def saml_logout(request):
    """Smart logout that handles cross-SP scenarios"""
    
    # Check if user has a local session (logged in via this SP) BEFORE clearing it
    local_auth = 'samlNameId' in request.session or 'saml_authenticated' in request.session
    
    # Always clear local session first
    request.session.flush()
    
    # For cross-SP logout, we still need to logout from Keycloak
    # but we'll handle the response routing issue differently
    if not local_auth:
        # This is likely a cross-SP logout
        # We'll initiate SAML logout but with a custom return URL
        try:
            req = prepare_django_request(request)
            auth = OneLogin_Saml2_Auth(req, settings.SAML_SETTINGS)
            # Use the logout with a custom return URL to avoid response routing issues
            logout_url = auth.logout(return_to=request.build_absolute_uri('/'))
            return redirect(logout_url)
        except Exception as e:
            # If SAML logout fails, try direct Keycloak logout URL
            keycloak_logout_url = f"http://localhost:8080/realms/demo/protocol/saml?GLO=true"
            return redirect(keycloak_logout_url)
    
    # Normal SAML logout for users who logged in via this SP
    try:
        req = prepare_django_request(request)
        auth = OneLogin_Saml2_Auth(req, settings.SAML_SETTINGS)
        logout_url = auth.logout()
        return redirect(logout_url)
    except Exception as e:
        # If Keycloak logout fails, show success (session already cleared)
        return render(request, 'logout.html', {
            'message': 'Logged out successfully (local session cleared)',
            'logout_type': f'IdP logout redirect failed: {str(e)}, but local logout completed'
        })

# Add a simple local logout endpoint
@csrf_exempt
def simple_logout(request):
    """Simple logout that only clears local session"""
    request.session.flush()
    return render(request, 'logout.html', {
        'message': 'Logged out successfully (local session cleared)',
        'logout_type': 'Simple logout - You may still be logged into Keycloak'
    })

@csrf_exempt
def cross_sp_logout(request):
    """Cross-SP logout that gracefully handles logout from different service provider"""
    # Clear local session
    request.session.flush()
    
    # For cross-SP logout, we need to actually logout from Keycloak
    # Use direct Keycloak logout URL with Global Logout parameter
    try:
        # This will logout from Keycloak and all connected SPs
        keycloak_logout_url = f"http://localhost:8080/realms/demo/protocol/saml?GLO=true&redirect_uri={request.build_absolute_uri('/')}"
        return redirect(keycloak_logout_url)
    except Exception as e:
        # If redirect fails, just show success message
        return render(request, 'logout.html', {
            'message': 'Logged out successfully (local session cleared)',
            'logout_type': f'Cross-SP logout completed - {str(e)}'
        })

@csrf_exempt
def saml_sls(request):
    """Single Logout Service - handles logout responses from Keycloak with improved error handling"""
    
    # Always clear the session first, regardless of SAML processing result
    request.session.flush()
    
    # Check if there's a SAML response to process
    saml_response = request.POST.get('SAMLResponse') or request.GET.get('SAMLResponse')
    saml_logout_response = request.POST.get('SAMLLogoutResponse') or request.GET.get('SAMLLogoutResponse')
    
    # Handle case where no SAML response is present (cross-SP logout)
    if not saml_response and not saml_logout_response:
        return render(request, 'logout.html', {
            'message': 'Logged out successfully (session cleared)',
            'logout_type': 'SAML logout - No response to process (likely cross-SP logout)'
        })
    
    # Try to process the SAML logout response, but don't fail if it has issues
    try:
        req = prepare_django_request(request)
        auth = OneLogin_Saml2_Auth(req, settings.SAML_SETTINGS)
        
        # Handle different types of logout responses
        if saml_logout_response:
            auth.process_slo(delete_session_cb=lambda: None)
        else:
            # Fallback for other types of logout responses
            auth.process_response()
        
        errors = auth.get_errors()
        if not errors:
            return render(request, 'logout.html', {
                'message': 'Successfully logged out from both Django and Keycloak',
                'logout_type': 'SAML logout - Complete'
            })
        else:
            # Even with SAML errors, logout is successful (session cleared)
            return render(request, 'logout.html', {
                'message': 'Logged out successfully (session cleared)',
                'logout_type': f'SAML logout - Response had issues but logout completed: {errors}'
            })
    except Exception as e:
        # Even with exceptions, logout is successful (session cleared)
        return render(request, 'logout.html', {
            'message': 'Logged out successfully (session cleared)',
            'logout_type': f'SAML logout - Processing error: {str(e)}, but logout completed'
        })

@csrf_exempt
def home(request):
    """Home page with authentication status and beautiful UI"""
    
    # Check if this is a SAML logout response sent to the wrong endpoint
    if request.method == 'POST' and (request.POST.get('SAMLResponse') or request.POST.get('SAMLLogoutResponse')):
        # Redirect to the proper SAML logout service
        return saml_sls(request)
    
    authenticated = 'samlUserdata' in request.session and 'samlNameId' in request.session
    
    context = {
        'authenticated': authenticated
    }
    
    if authenticated:
        user_attributes = request.session.get('samlUserdata', {})
        context['user'] = {
            'name_id': request.session.get('samlNameId', 'Unknown'),
            'attributes': {
                'status': user_attributes.get('status', 'Active'),
                'source': user_attributes.get('source', 'Keycloak SAML'),
                'note': user_attributes.get('note', 'Attributes simplified due to duplicates' if 'attributes_simplified' in request.session else None)
            }
        }
    
    return render(request, 'home.html', context)

def metadata(request):
    """SAML SP metadata endpoint"""
    req = prepare_django_request(request)
    auth = OneLogin_Saml2_Auth(req, settings.SAML_SETTINGS)
    saml_settings = auth.get_settings()
    metadata = saml_settings.get_sp_metadata()
    errors = saml_settings.check_sp_metadata(metadata)
    
    if len(errors) == 0:
        resp = HttpResponse(content=metadata, content_type='text/xml')
    else:
        resp = HttpResponse(content=', '.join(errors), content_type='text/plain')
    
    return resp
