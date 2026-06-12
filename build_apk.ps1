$pubspecPath = "pubspec.yaml"
$content = Get-Content $pubspecPath

# Extract current version
$versionLine = $content | Select-String -Pattern "^version: (.+)"
if ($versionLine) {
    $fullVersion = $versionLine.Matches.Groups[1].Value
    $parts = $fullVersion.Split('+')
    $baseVersion = $parts[0]
    
    if ($parts.Length -gt 1) {
        $buildNumber = [int]$parts[1]
    } else {
        $buildNumber = 0
    }
    
    # Increment build number
    $newBuildNumber = $buildNumber + 1
    $newVersion = "$baseVersion+$newBuildNumber"
    
    # Replace in file
    $content = $content -replace "^version: .*", "version: $newVersion"
    Set-Content -Path $pubspecPath -Value $content
    
    Write-Host "Bumped app version to $newVersion" -ForegroundColor Green
    
    # Build APK
    Write-Host "Building Flutter APK..." -ForegroundColor Cyan
    flutter build apk -t lib/main_prod.dart
    
    Write-Host "Done! APK built with version $newVersion" -ForegroundColor Green
    Write-Host "You can find it in build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Yellow
} else {
    Write-Host "Could not find version in pubspec.yaml" -ForegroundColor Red
}
