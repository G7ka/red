@echo off
set JAVA_HOME=C:\Users\bre\AppData\Local\Java\jdk-17.0.18+8
set PATH=%JAVA_HOME%\bin;%LOCALAPPDATA%\Android\Sdk\platform-tools;%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin;%PATH%
cd /d D:\flutter_projects\penguin_app
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat run -d R3CT90C5J0V --android-skip-build-dependency-validation
