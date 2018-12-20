# Clone all 3 repos
Remove-Item .\gradlerio -Recurse -Force
Remove-Item .\wpilibinstaller -Recurse -Force
Remove-Item .\vscode-wpilib -Recurse -Force
Remove-Item .\build -Recurse -Force

git clone https://github.com/wpilibsuite/gradlerio
git clone https://github.com/wpilibsuite/wpilibinstaller
git clone https://github.com/wpilibsuite/vscode-wpilib

$pubVersion = "4242.0.0-nightly"
$versionGradleString = "-PpublishVersion=$pubVersion"

# Patch and build GradleRIO
# version regex
$regex = "repo\.url.+=.+('|"")http:\/\/first\.wpi\.edu\/FRC\/roborio\/maven\/release('|"")";

$updateGradle = Get-Content -Path .\gradlerio\versionupdates.gradle

$updateGradle = $updateGradle -creplace $regex, "repo.url = ""http://first.wpi.edu/FRC/roborio/maven/development"""

Set-Content -Path .\gradlerio\versionupdates.gradle -Value $updateGradle

$baseLocation = Get-Location

Set-Location .\gradlerio

.\gradlew.bat UpdateVersions $versionGradleString

.\gradlew.bat publishToMavenLocal $versionGradleString

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

New-Item -ItemType Directory -Path $baseLocation\build

Copy-Item -Path "vscode-wpilib-$pubVersion.vsix" -Destination $baseLocation\build\WPILib.vsix

Set-Location $baseLocation\vscode-wpilib\wpilib-utility-standalone

npm install

npm run compile

npm run packageWindows

Set-Location $baseLocation

#Handle Installer

$regex = """edu\.wpi\.first\.GradleRIO"".+version.+"".+"""

$updateGradleRio = Get-Content -Path .\wpilibinstaller\gradleriobase\build.gradle

$updateGradleRio = $updateGradleRio -creplace $regex, "id ""edu.wpi.first.GradleRIO"" version ""$pubVersion"""

Set-Content -Path .\wpilibinstaller\gradleriobase\build.gradle -Value $updateGradleRio

Set-Location .\wpilibinstaller

./gradlew generateInstallers "-PvscodeLoc=$baseLocation\build\WPILib.vsix"

Set-Location $baseLocation

#Stop our daemons
Set-Location .\vscode-wpilib

.\gradlew.bat --stop

Set-Location $baseLocation

