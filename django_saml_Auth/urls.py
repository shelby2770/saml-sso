from django.urls import path
from . import views  # Import your SAML views

urlpatterns = [
    path('login/', views.saml_login, name='saml_login'),
    path('callback/', views.saml_callback, name='saml_callback'),
    path('logout/', views.saml_logout, name='saml_logout'),
    path('simple-logout/', views.simple_logout, name='simple_logout'),
    path('cross-sp-logout/', views.cross_sp_logout, name='cross_sp_logout'),
    path('sls/', views.saml_sls, name='saml_sls'),
    path('metadata/', views.metadata, name='saml_metadata'),
]
