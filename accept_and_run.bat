@echo off
set JAVA_HOME=C:\Users\bre\AppData\Local\Java\jdk-17.0.18+8
set PATH=%JAVA_HOME%\bin;%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin;%PATH%
(echo y&echo y&echo y&echo y&echo y&echo y&echo y&echo y&echo y&echo y) | sdkmanager --licenses
C:\src\flutter\bin\flutter.bat run -d R3CT90C5J0V --android-skip-build-dependency-validation
