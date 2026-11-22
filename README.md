# travel_mn

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

main.dart  (апп эхлэх цэг)
  └→ router.dart  (аль дэлгэц рүү явахыг шийднэ)
       ├→ state/auth_service.dart  (нэвтэрсэн эсэх)
       ├→ data/places.dart         (газруудын жагсаалт)
       └→ screens/  (8 дэлгэц)
            ├→ login_screen
            ├→ home_screen
            ├→ detail_screen
            ├→ add_place_screen
            ├→ map_picker_screen
            ├→ places_map_screen
            ├→ settings_screen
            └→ change_password_screen



login_screen
  └→ auth_service  (auth.login)

home_screen
  ├→ data/places        (жагсаалт)
  ├→ favorites          (дуртай шүүлтүүр)
  ├→ ratings            (үнэлгээгээр эрэмбэлэх)
  ├→ auth_service       (гарах)
  ├→ app_drawer         (хажуугийн цэс)
  ├→ place_card         (карт)
  └→ detail_screen      (том дэлгэцэд PlaceDetailView)

detail_screen
  ├→ ratings            (үнэлгээ өгөх, дундаж)
  ├→ geo                (координат форматлах)
  ├→ favorite_button, place_image
  ├→ star_rating, rating_input
  └→ map_picker_screen  (MapPickerArgs)

add_place_screen
  ├→ config             (maxPlaceImages, cameraSupported)
  ├→ data/places        (seasons жагсаалт)
  ├→ geo                (УБ-аас зай тооцох)
  ├→ image_picker 📦    (гадны package)
  └→ map_picker_screen  (MapPickerArgs)

map_picker_screen
  ├→ geocoding_service  (хайх, reverse)
  ├→ picked_location
  ├→ geo, config
  └→ flutter_map 📦     (газрын зураг)

places_map_screen
  ├→ data/places
  ├→ config
  └→ flutter_map 📦

settings_screen
  └→ auth_service  (email, logout)

change_password_screen
  ├→ auth_service  (changePassword)
  ├→ validators    (нууц үгийн шалгалт, хүч)
  └→ password_field


