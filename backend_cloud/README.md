# Backend Cloud Service

This Django service provides two endpoints for the RoboMunch cloud backend:

- `POST /get/resolution` — returns the image resolution as JSON.
- `POST /convert/grayscale` — returns the grayscale version of the uploaded image.

## Run locally

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py runserver 0.0.0.0:8000
```

## Docker

```bash
docker build -t rodomunch-backend-cloud .
docker run -p 8000:8000 rodomunch-backend-cloud
```

## Notes

- This repo is intended to be deployed to a Linux VM.
- Use `cloudBackendBaseUrl` in the Flutter app to point to the deployed VM.
