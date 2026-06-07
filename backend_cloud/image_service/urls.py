from django.urls import path
from .views import convert_grayscale, get_resolution

urlpatterns = [
    path('get/resolution', get_resolution, name='get_resolution'),
    path('convert/grayscale', convert_grayscale, name='convert_grayscale'),
]
