from django.contrib import admin
from django.urls import path, include
from django_saml_Auth.views import home

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/saml/', include('django_saml_Auth.urls')), 
    path('', home, name='home'),
]
