# Useful Development Commands

## Run App (with JDK 17)
Use this command to run the app if you encounter Java version errors.
```powershell
$env:JAVA_HOME="C:\Program Files\Java\jdk-17"; $env:PATH="$env:JAVA_HOME\bin;$env:PATH"; flutter run
```

## Mirror Android Screen (scrcpy)
Displays your Android device screen on your computer. Requires [scrcpy](https://github.com/Genymobile/scrcpy) to be installed.
```powershell
scrcpy
```

## Clean & Reinstall Dependencies
Fixes most build issues by cleaning the project and re-fetching packages.
```powershell
flutter clean; flutter pub get
```

## Build APK (with JDK 17)
Builds a release APK.
```powershell
$env:JAVA_HOME="C:\Program Files\Java\jdk-17"; $env:PATH="$env:JAVA_HOME\bin;$env:PATH"; flutter build apk
```

## Watch for Code Changes (Build Runner)
If you are using code generation (Riverpod, Isar, etc.), run this to auto-generate files.
```powershell
flutter pub run build_runner watch --delete-conflicting-outputs
```
