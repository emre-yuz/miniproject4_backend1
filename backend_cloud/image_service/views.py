import io
from django.http import HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from PIL import Image


def _read_image_from_request(request):
    image_file = request.FILES.get('image')
    if image_file is None:
        return None, JsonResponse({'error': 'Missing image file.'}, status=400)

    try:
        image = Image.open(image_file)
        image.load()
        return image, None
    except Exception as exc:
        return None, JsonResponse({'error': f'Invalid image file: {exc}'}, status=400)


@csrf_exempt
def get_resolution(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed.'}, status=405)

    image, error_response = _read_image_from_request(request)
    if error_response:
        return error_response

    width, height = image.size
    return JsonResponse({'width': width, 'height': height, 'resolution': f'{width}x{height}'})


@csrf_exempt
def convert_grayscale(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed.'}, status=405)

    image, error_response = _read_image_from_request(request)
    if error_response:
        return error_response

    grayscale = image.convert('L').convert('RGB')
    buffer = io.BytesIO()
    grayscale.save(buffer, format='PNG')
    buffer.seek(0)
    return HttpResponse(buffer.getvalue(), content_type='image/png')
