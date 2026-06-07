from django.urls import include, path

urlpatterns = [
    path('', include('image_service.urls')),
]
