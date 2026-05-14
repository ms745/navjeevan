# navjeevan

A new Flutter project.


<img width="458" height="858" alt="image" src="https://github.com/user-attachments/assets/568cb96a-3fd0-4569-b7b4-68aa010b648a" />
<img width="460" height="972" alt="image" src="https://github.com/user-attachments/assets/e1254ab1-33a5-40e5-9aae-c87a3e40822a" />
<img width="460" height="825" alt="image" src="https://github.com/user-attachments/assets/9c6bd856-590b-46c6-9de2-c388b71ebba9" />
<img width="457" height="831" alt="image" src="https://github.com/user-attachments/assets/24ebbb1a-0049-4457-9451-ebf8cfa8fcec" />
<img width="462" height="872" alt="image" src="https://github.com/user-attachments/assets/5f954f3a-669a-4346-9513-e4ad01a51376" />
<img width="462" height="975" alt="image" src="https://github.com/user-attachments/assets/55b0aa5f-bf0c-4118-b7c0-c4b43f4d5401" />
<img width="450" height="971" alt="image" src="https://github.com/user-attachments/assets/ac6f9422-2139-4de3-a1ca-6da34288c558" />
<img width="467" height="985" alt="image" src="https://github.com/user-attachments/assets/0e2be648-7e3b-4672-a674-5009d8ef162a" />






## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

flutter run emulator-5554
## Google Maps Setup

Add your Google Maps API key before running the map screen:

- Android: set MAPS_API_KEY=YOUR_KEY in android/gradle.properties
- iOS: set MAPS_API_KEY=YOUR_KEY in ios/Flutter/Debug.xcconfig and ios/Flutter/Release.xcconfig

## Cloudinary Setup (Document/Photo Uploads)

This app now uploads parent and mother documents/photos to Cloudinary.

Create an **unsigned upload preset** in Cloudinary, then run the app with:

flutter run --dart-define=CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME --dart-define=CLOUDINARY_UPLOAD_PRESET=YOUR_UNSIGNED_PRESET

### Cloudinary Management in Firestore

Every successful upload also creates/updates a Firestore document in:

- `cloudinary_management/{docId}`

This metadata is linked to both workflows:

- Adoptive parent verification docs (`adoptive_families`)
- Mother surrender child docs/photos (`mother_requests`)

Stored metadata includes:

- Cloudinary asset info (`publicId`, `assetId`, `resourceType`, `format`, `bytes`, URL)
- Ownership + request linkage (user, collection, request/entity id, role context)
- Document verification state (`Pending` / `Verified` / `Rejected`) and notes
- Lifecycle tracking (`Active` / `Superseded` when re-upload replaces prior file)

Admin verification UIs consume this synced metadata via per-document fields (provider + asset id path) in:

- Parent verification tab
- Mother request review tab

Then run:

flutter clean
flutter pub get
flutter pub upgrade
flutter run
# navjeevan
