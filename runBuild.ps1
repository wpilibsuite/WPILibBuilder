# Clone all 3 repos
# Clone installer 4 times, once per OS
git clone https://github.com/wpilibsuite/GradleRIO
git clone https://github.com/wpilibsuite/wpilibinstaller wpilibinstallerwin64
git clone https://github.com/wpilibsuite/wpilibinstaller wpilibinstallermac
git clone https://github.com/wpilibsuite/wpilibinstaller wpilibinstallerlinux
git clone https://github.com/wpilibsuite/vscode-wpilib

# Build number isn't semver, TODO make it semver
$pubVersion = $env:BUILD_BUILDNUMBER

if (!$pubVersion) {
  $pubVersion = "4242.0.0-nightly"
} else {
  $pubVersion = $pubVersion + "-nightly"
}

$pubVersion = "4242.0.0-nightly"

Write-Host $pubVersion

New-Item -ItemType Directory -Path $env:USERPROFILE\.gradle

Set-Content -Path $env:USERPROFILE\.gradle\gradle.properties -Value "org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8"

$versionGradleString = "-PpublishVersion=$pubVersion"

# Patch and build GradleRIO
$baseLocation = Get-Location

New-Item -ItemType Directory -Path $baseLocation\installers
New-Item -ItemType Directory -Path $baseLocation\installers\win
New-Item -ItemType Directory -Path $baseLocation\installers\linux
New-Item -ItemType Directory -Path $baseLocation\installers\mac

Set-Location .\gradlerio

.\gradlew.bat UpdateVersions $versionGradleString -PuseDevelopment

.\gradlew.bat publishToMavenLocal $versionGradleString -PuseDevelopment

Set-Location $baseLocation

#Patch and build vscode
Set-Content -Path .\vscode-wpilib\vscode-wpilib\resources\gradle\version.txt -Value $pubVersion

Set-Location .\vscode-wpilib

.\gradlew.bat updateAllDependencies updateVersions $versionGradleString

Set-Location .\vscode-wpilib

npm install

npm run lint

npm run webpack

npm run gulp

npm run vscePackage

Copy-Item -Path "vscode-wpilib-$pubVersion.vsix" -Destination $baseLocation\build\WPILib.vsix

Set-Location $baseLocation\vscode-wpilib\wpilib-utility-standalone

npm install

npm run compile

npm run packageWindows

Set-Location $baseLocation

#Handle Installer

# $regex = "id ""edu\.wpi\.first\.GradleRIO"".+version.+"".+"""

# $updateGradleRio = Get-Content -Path .\wpilibinstaller\gradleriobase\build.gradle

# $updateGradleRio = $updateGradleRio -creplace $regex, "id ""edu.wpi.first.GradleRIO"" version ""$pubVersion"""

# Set-Content -Path .\wpilibinstaller\gradleriobase\build.gradle -Value $updateGradleRio

# Win64

Set-Content -Path .\wpilibinstallerwin64\gradle.properties -Value "gradleRioVersion: $pubVersion"

Set-Location .\wpilibinstallerwin64

./gradlew generateInstallers "-PvscodeLoc=$baseLocation\build\WPILib.vsix" "-PpublishVersion=$pubVersion"

if ($lastexitcode -ne 0) {
  throw ("Exec: " + $errorMessage)
}

Move-Item -Path build\outputs -Destination "$baseLocation\installers\win"

./gradlew cleanOfflineRepository clean

if ($lastexitcode -ne 0) {
  throw ("Exec: " + $errorMessage)
}

Set-Location $baseLocation

# Mac

Set-Content -Path .\wpilibinstallermac\gradle.properties -Value "gradleRioVersion: $pubVersion"

Set-Location .\wpilibinstallermac

./gradlew generateInstallers "-PvscodeLoc=$baseLocation\build\WPILib.vsix" "-PpublishVersion=$pubVersion" "-PmacBuild"

if ($lastexitcode -ne 0) {
  throw ("Exec: " + $errorMessage)
}

Move-Item -Path build\outputs -Destination "$baseLocation\installers\mac"

./gradlew cleanOfflineRepository clean

if ($lastexitcode -ne 0) {
  throw ("Exec: " + $errorMessage)
}

Set-Location $baseLocation

# Linux

Set-Content -Path .\wpilibinstallerlinux\gradle.properties -Value "gradleRioVersion: $pubVersion"

Set-Location .\wpilibinstallerlinux

./gradlew generateInstallers "-PvscodeLoc=$baseLocation\build\WPILib.vsix" "-PpublishVersion=$pubVersion" "-PlinuxBuild"

if ($lastexitcode -ne 0) {
  throw ("Exec: " + $errorMessage)
}

Move-Item -Path build\outputs -Destination "$baseLocation\installers\linux"

./gradlew cleanOfflineRepository clean

if ($lastexitcode -ne 0) {
  throw ("Exec: " + $errorMessage)
}

Set-Location $baseLocation

#Stop our daemons
Set-Location .\vscode-wpilib

.\gradlew.bat --stop

Set-Location $baseLocation

