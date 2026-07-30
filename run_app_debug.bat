@echo off
set JAVA_HOME=C:\Users\bre\AppData\Local\Java\jdk-17.0.18+8
set PATH=%JAVA_HOME%\bin;%LOCALAPPDATA%\Android\Sdk\platform-tools;%PATH%
C:\src\flutter\bin\flutter.bat run -d R3CT90C5J0V --android-skip-build-dependency-validation > build_out.txt 2>&1
