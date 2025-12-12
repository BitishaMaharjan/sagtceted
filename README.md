# Flutter App

A simple Flutter app that reads a backend URL from a `.env` file.

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/BitishaMaharjan/sagtceted.git
cd my_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Create a `.env` File

If the `.env` file does not exist, create it in the root of the project:

```bash
touch .env
```

Add the backend URL inside `.env`:
https://github.com/BitishaMaharjan/sagtcetedBackend.git

```bash
echo "BACKEND_URL=http://192.168.1.65:8000/predict-gas" >> .env
```

> You can replace this URL with your own backend server URL if needed.

### 4. Run the App

```bash
flutter run
```

### 5. Build APK

```bash
flutter build apk --release
```

* The generated APK will be located at:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Notes

* Ensure your backend server is running and accessible from your device.
* If using a local IP (`192.168.x.x`), make sure your device is on the same network.
* The app reads the `BACKEND_URL` from the `.env` file automatically using `flutter_dotenv`.

---

## Optional: Git Ignore for `.env`

To prevent accidentally committing your `.env` file, add the following to your `.gitignore`:

```
# Environment Variables
.env
```
