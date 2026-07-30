@echo off
set JAVA_HOME=C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot
set PATH=%JAVA_HOME%\bin;%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin;%PATH%
echo y | sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
