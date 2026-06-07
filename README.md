# RoboMunch Full Stack Project

This repository contains the RoboMunch mobile app and two backend services:

- `backend.py` — local FastAPI backend that handles chat, image generation, and speech transcription.
- `backend_cloud/` — Django cloud backend scaffold with endpoints to inspect image resolution and convert an image to grayscale.
- `flutter_app/` — Flutter mobile app for chat, prompt generation, image rendering, voice input, and cloud image conversion.

## Local backend (Task 1)

Run the local backend with:

```bash
python backend.py
```

The backend listens on `0.0.0.0:7860` and exposes:

- `POST /chat`
- `POST /paint`
- `POST /transcribe`

## Flutter app

Open `flutter_app` and install dependencies:

```bash
cd flutter_app
flutter pub get
```

Update `flutter_app/lib/main.dart`:

- `backendBaseUrl` should point to your local machine IP when testing from a mobile device on the same network.
  - For Android emulator use `http://10.0.2.2:7860`.
  - For iOS simulator use `http://127.0.0.1:7860`.
  - For a physical phone use your PC's local IP, e.g. `http://192.168.x.x:7860`.
- `cloudBackendBaseUrl` should point to the deployed cloud VM.

Run the app with:

```bash
flutter run
```

## Cloud backend (Task 2)

Build and run the Django cloud backend locally for testing:

```bash
cd backend_cloud
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
python manage.py runserver 0.0.0.0:8000
```

Endpoints:

- `POST /get/resolution` — returns JSON with image width and height.
- `POST /convert/grayscale` — returns a grayscale PNG image.

## CI/CD workflows

The cloud backend includes GitHub Actions workflows in `.github/workflows`:

- `ci.yml` — lint and build checks
- `cd.yml` — Docker build and deploy skeleton for VM deployment?
