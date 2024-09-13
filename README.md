# Truora SDK for Flutter

[![pub package](https://img.shields.io/pub/v/truora_sdk.svg)](https://pub.dev/packages/truora_sdk)

A Flutter plugin that provides functionality to integrate Truora's Digital Identity (DI) into your Flutter applications. This package includes classes and protocols to initiate identity processes and handle their results.

## Setup

Create Flutter project and add the Trurora SDK dependency to it.

```bash
flutter create MyApp
```

Add the dependency:

```bash
cd MyApp
flutter pub add truora_sdk
```

### iOS

Adapt `Info.plist` by adding the related permissions based on the verifications  your flow will use:

* For verifications that require the camera add `NSCameraUsageDesscription`.
* For geolocation verification add `NSLocationWhenInUseUsageDescription`.
* To allow uploading gallery files in document verification add `NSPhotoLibraryUsageDescription`.

Also, add the following to your `Podfile` file:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',

        ## dart: PermissionGroup.camera
        'PERMISSION_CAMERA=1',

        ## dart: PermissionGroup.photos
        'PERMISSION_PHOTOS=1',

        ## dart: [PermissionGroup.location, PermissionGroup.locationAlways, PermissionGroup.locationWhenInUse]
        'PERMISSION_LOCATION=1',
      ]
    end
  end
end
```

Note: Only add the permissions used.

Then run the following command to update pods:

```bash
cd ios && pod install
```

### Android

Adapt `AndroidManifest.xml` by adding the related permissions based on the verifications your flow will use:

* For verifications that require the camera, add:

``` xml
<uses-feature android:name="android.hardware.camera" android:required="true" />

<uses-permission android:name="android.permission.CAMERA" />
```

* For geolocation verification, add:

``` xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

* To allow uploading gallery files in document verification, add:

``` xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## How to use

In your `build()` method, the TruoraSDK widget is configured with several properties:

* token:
This is the API token used to authorize and start the identity verification process.

* requiredPermissions:
A list of permissions that the SDK requires. The possible permissions are:
  * TruoraPermission.camera: To access the camera for the identity verification.
  * TruoraPermission.location: To access Location for the geolocation verification.
  * TruoraPermission.photos: To access the gallery to upload photos in document verification.

* Callback Functions:
The TruoraSDK allows you to handle events like errors, process steps completion, process success, and failure.
  * onError: If an error occurs during the process, this callback is triggered.
  * onStepsCompleted: Once the identity verification steps are completed, this callback is invoked.
  * onProcessSucceeded: If the identity verification succeeds, this callback is triggered.
  * onProcessFailed: If the identity verification fails, this callback is called.

For example:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: TruoraSDK(
        token: 'replace_me',

        // Add needed permisisions for process
        requiredPermissions: const [
          TruoraPermission.camera,
          TruoraPermission.location
        ],

        onError: (errorMessage) {
          _showErrorDialog(context, errorMessage);
        },

        onStepsCompleted: (processID) {
          _navigateToResultsPage('completed', processID, context);
        },

        onProcessSucceeded: (processID) {
          _navigateToResultsPage('success', processID, context);
        },

        onProcessFailed: (processID) {
          _navigateToResultsPage('failure', processID, context);
        }),
  );
}
```

## Notes

Know more about Truora and request a demo [here](https://www.truora.com/en/).
