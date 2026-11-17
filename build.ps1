<#
.SYNOPSIS
    Baut das Koerper-Labor ueber apk-builder: native Bruecke (Zwischenablage,
    Teilen, Datei-Backup) und Kamerazugriff fuer die Pulsmessung.
.DESCRIPTION
    Aufbau wie gym-coach\build.ps1. apps\KoerperLabor unter apk-builder wird
    bei jedem Lauf per -Force neu aus dem Template erzeugt, die Patches laufen
    deshalb jedes Mal erneut. Throw-Guards: Aendert sich das Template, bricht
    der Build laut ab, statt still eine APK ohne Kamera zu bauen.

    - AndroidManifest: CAMERA-Berechtigung (Laufzeit-Dialog beim ersten
      Pulstest) und uses-feature ohne Pflicht.
    - strings.xml: Anzeigename "Koerper-Labor" mit Umlaut.
    - android-src\FileBridge.java wird mit dem echten Paketnamen kopiert.
    - MainActivity: Bruecke "KlAndroid", onActivityResult, dazu ein
      WebChromeClient, der getUserMedia (nur Video) an die Android-
      Berechtigung koppelt. Das Template hat bewusst keinen ChromeClient.

    Mit -Release landet die signierte APK zusaetzlich als
    dist\koerperlabor-<Version>.apk (aeltere dist-APKs werden entfernt).
.EXAMPLE
    .\build.ps1 -VersionName 1.1 -VersionCode 2 -Release
#>
[CmdletBinding()]
param(
    [string]$VersionName = '1.2',
    [int]$VersionCode = 3,
    [switch]$Release,
    [switch]$Install
)

$ErrorActionPreference = 'Stop'

# javac lehnt eine UTF-8-BOM ab; PS 5.1 schreibt mit -Encoding utf8 immer eine.
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Write-TextNoBom {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}
function Replace-Once {
    param([string]$Text, [string]$Needle, [string]$Replacement, [string]$What)
    $idx = $Text.IndexOf($Needle)
    if ($idx -lt 0) {
        throw "Patchziel '$What' nicht gefunden - hat sich das apk-builder-Template geaendert?"
    }
    return $Text.Substring(0, $idx) + $Replacement + $Text.Substring($idx + $Needle.Length)
}

$ProjectRoot = $PSScriptRoot
$ApkBuilder  = "D:\claude code projects\apk-builder"
$PackageId   = "com.daniel.koerperlabor"
$AppName     = "KoerperLabor"
$appDir      = Join-Path $ApkBuilder "apps\$AppName"

& "$ApkBuilder\new-app.ps1" -Name $AppName -PackageId $PackageId `
    -WebRoot (Join-Path $ProjectRoot 'web') `
    -Icon (Join-Path $ProjectRoot 'icon.xml') `
    -IconBackground "#12171E" -Portrait -KeepScreenOn `
    -VersionName $VersionName -VersionCode $VersionCode -Force

$mainDir = Join-Path $appDir 'app\src\main'
$javaDir = Join-Path $mainDir ("java\" + $PackageId.Replace('.', '\'))

# --- AndroidManifest.xml: Kamera -------------------------------------------
$manifestPath = Join-Path $mainDir 'AndroidManifest.xml'
$manifest = [System.IO.File]::ReadAllText($manifestPath)
$manifest = Replace-Once $manifest '<uses-permission android:name="android.permission.VIBRATE" />' @'
<uses-permission android:name="android.permission.VIBRATE" />
    <!-- Pulsmessung: Kamera plus Blitz, Laufzeit-Dialog beim ersten Test.
         Nicht Pflicht, damit die App auch ohne Kamera installierbar bleibt. -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.flash" android:required="false" />
'@.TrimEnd() 'VIBRATE-Berechtigung'
Write-TextNoBom -Path $manifestPath -Content $manifest

# --- strings.xml: Anzeigename mit Umlaut -----------------------------------
# Der Umlaut entsteht per Zeichencode: PS 5.1 liest .ps1-Dateien ohne BOM als ANSI.
$stringsPath = Join-Path $mainDir 'res\values\strings.xml'
$strings = [System.IO.File]::ReadAllText($stringsPath)
$label = 'K' + [char]0xF6 + 'rper-Labor'
$strings = Replace-Once $strings "<string name=`"app_name`">$AppName</string>" "<string name=`"app_name`">$label</string>" 'app_name'
Write-TextNoBom -Path $stringsPath -Content $strings

# --- FileBridge.java -------------------------------------------------------
$bridge = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot 'android-src\FileBridge.java'))
$bridge = Replace-Once $bridge 'package __PACKAGE__;' "package $PackageId;" 'package-Platzhalter'
Write-TextNoBom -Path (Join-Path $javaDir 'FileBridge.java') -Content $bridge

# --- MainActivity.java -----------------------------------------------------
$mainActivityPath = Join-Path $javaDir 'MainActivity.java'
$java = [System.IO.File]::ReadAllText($mainActivityPath)

$java = Replace-Once $java 'webView.setWebViewClient(new LocalWebViewClient());' @'
webView.setWebViewClient(new LocalWebViewClient());

        // Native Bruecke und Kamera: siehe koerper-labor\build.ps1.
        fileBridge = new FileBridge(this, webView);
        webView.addJavascriptInterface(fileBridge, "KlAndroid");
        webView.setWebChromeClient(new CamChromeClient());
'@.TrimEnd() 'setWebViewClient'

$java = Replace-Once $java '    /** Haelt lokale Seiten im WebView' @'
    // ---- Bruecke und Kamera (eingefuegt von koerper-labor\build.ps1) ----
    private FileBridge fileBridge;
    private static final int REQ_CAMERA = 4843;
    private android.webkit.PermissionRequest pendingCam;

    @SuppressWarnings("deprecation")
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (fileBridge != null) fileBridge.onResult(requestCode, resultCode, data);
    }

    /**
     * getUserMedia der Web-App. Erlaubt wird nur Video (kein Mikrofon). Im
     * WebView laufen ausschliesslich die mitgelieferten lokalen Seiten
     * (LocalWebViewClient schickt alles andere an den Browser, die App hat
     * keine INTERNET-Berechtigung), deshalb genuegt die Android-Berechtigung
     * als Schranke.
     */
    private class CamChromeClient extends android.webkit.WebChromeClient {
        @Override
        public void onPermissionRequest(final android.webkit.PermissionRequest request) {
            runOnUiThread(() -> {
                boolean video = false;
                for (String r : request.getResources()) {
                    if (android.webkit.PermissionRequest.RESOURCE_VIDEO_CAPTURE.equals(r)) video = true;
                }
                if (!video) { request.deny(); return; }
                if (checkSelfPermission(android.Manifest.permission.CAMERA)
                        == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    request.grant(new String[] { android.webkit.PermissionRequest.RESOURCE_VIDEO_CAPTURE });
                    return;
                }
                if (pendingCam != null) pendingCam.deny();
                pendingCam = request;
                requestPermissions(new String[] { android.Manifest.permission.CAMERA }, REQ_CAMERA);
            });
        }

        @Override
        public void onPermissionRequestCanceled(android.webkit.PermissionRequest request) {
            if (request == pendingCam) pendingCam = null;
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode != REQ_CAMERA || pendingCam == null) return;
        android.webkit.PermissionRequest r = pendingCam;
        pendingCam = null;
        if (grantResults.length > 0
                && grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED) {
            r.grant(new String[] { android.webkit.PermissionRequest.RESOURCE_VIDEO_CAPTURE });
        } else {
            r.deny();
        }
    }

    /** Haelt lokale Seiten im WebView
'@ 'LocalWebViewClient-Kommentar'

Write-TextNoBom -Path $mainActivityPath -Content $java
Write-Host "  [ok] Bruecke und Kamera eingebaut" -ForegroundColor Green

$buildArgs = @{ App = $AppName }
if ($Release) { $buildArgs.Release = $true }
if ($Install) { $buildArgs.Install = $true }
& "$ApkBuilder\build-apk.ps1" @buildArgs

if ($Release) {
    $latest = Get-ChildItem (Join-Path $ApkBuilder 'out') -Filter "$AppName-release-*.apk" |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) { throw "Keine Release-APK in apk-builder\out gefunden" }
    $dist = Join-Path $ProjectRoot 'dist'
    if (-not (Test-Path $dist)) { New-Item -ItemType Directory -Path $dist | Out-Null }
    Get-ChildItem $dist -Filter 'koerperlabor-*.apk' | Remove-Item -Force
    $target = Join-Path $dist "koerperlabor-$VersionName.apk"
    Copy-Item $latest.FullName $target -Force
    Write-Host "  [ok] $target" -ForegroundColor Green
}
