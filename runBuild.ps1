# Clone all 3 repos
git clone https://github.com/wpilibsuite/GradleRIO
git clone https://github.com/wpilibsuite/wpilibinstaller
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

Set-Content -Path .\wpilibinstaller\gradle.properties -Value "gradleRioVersion: $pubVersion"

Set-Location .\wpilibinstaller



./gradlew generateInstallers "-PvscodeLoc=$baseLocation\build\WPILib.vsix" "-PpublishVersion=$pubVersion"

if ($lastexitcode -ne 0) {
  throw ("Exec: " + $errorMessage)
}

Set-Location $baseLocation

#Stop our daemons
Set-Location .\vscode-wpilib

.\gradlew.bat --stop

Set-Location $baseLocation

