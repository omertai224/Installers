# update-installers.ps1
# מוריד את הגרסה האחרונה של 4 ה-installers ל-omertai.net
# הרצה: לחיצה כפולה על update-installers.bat, או ידנית מ-PowerShell
#
# לוגיקה לכל installer:
#   Vibe       - GitHub Releases API (גרסה אחרונה אוטומטית)
#   TreeSize   - URL ישיר יציב (jam-software.de)
#   Everything - scrape voidtools.com למספר גרסה אחרון
#   PatchMyPC  - URL ישיר יציב (homeupdater.patchmypc.com)
#
# שדרוגים אטומיים, מורידים ל-.downloading, ואז Move-Item.
# כשל בקובץ אחד לא מבטל את השאר.

$ErrorActionPreference = "Continue"
$ProgressPreference    = "SilentlyContinue"

$dest = "C:\Users\Demo\Documents\GitHub\Installers"
$log  = Join-Path $dest "update-log.txt"

function Write-Log {
    param($msg)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $msg"
    Add-Content -Path $log -Value $line -Encoding utf8
    Write-Host $line
}

function Download-Installer {
    param($name, $url, $output)
    $tmp = "$output.downloading"
    try {
        $oldSize = if (Test-Path $output) { (Get-Item $output).Length } else { 0 }
        Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -UserAgent "Mozilla/5.0 omertai-updater"
        Move-Item -Force $tmp $output
        $newSize = (Get-Item $output).Length
        $newMB   = [math]::Round($newSize / 1MB, 1)
        $oldMB   = [math]::Round($oldSize / 1MB, 1)
        $delta   = if ($oldSize -eq 0)              { "(new)" }
                   elseif ($newSize -ne $oldSize)   { "(was $oldMB MB)" }
                   else                              { "(unchanged)" }
        Write-Log "[$name] OK $newMB MB $delta"
    } catch {
        if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
        Write-Log "[$name] FAILED: $($_.Exception.Message)"
    }
}

Write-Log "=== Update started ==="

# 1. Vibe (תמלול AI), GitHub release
try {
    $api   = Invoke-RestMethod "https://api.github.com/repos/thewh1teagle/vibe/releases/latest" -UseBasicParsing
    $asset = $api.assets | Where-Object { $_.name -like "*x64-setup.exe" } | Select-Object -First 1
    if ($asset) {
        Download-Installer "Vibe ($($api.tag_name))" $asset.browser_download_url (Join-Path $dest "Vibe.exe")
    } else {
        Write-Log "[Vibe] No x64-setup.exe asset in release $($api.tag_name)"
    }
} catch {
    Write-Log "[Vibe] GitHub API failed: $($_.Exception.Message)"
}

# 2. TreeSize Free, URL יציב (גרסה רגילה ~16 MB, לא x86 המקוצר)
Download-Installer "TreeSize" "https://downloads.jam-software.de/treesize_free/TreeSizeFreeSetup.exe" (Join-Path $dest "TreeSize.exe")

# 3. Everything (voidtools), scrape דף ההורדות לגרסה אחרונה
try {
    $page = Invoke-WebRequest "https://www.voidtools.com/downloads/" -UseBasicParsing
    $m    = [regex]::Match($page.Content, 'Everything-([\d\.]+)\.x64-Setup\.exe')
    if ($m.Success) {
        $version = $m.Groups[1].Value
        Download-Installer "Everything ($version)" "https://www.voidtools.com/Everything-$version.x64-Setup.exe" (Join-Path $dest "Everything.exe")
    } else {
        Write-Log "[Everything] Version pattern not found on voidtools.com/downloads/"
    }
} catch {
    Write-Log "[Everything] Page lookup failed: $($_.Exception.Message)"
}

# 4. PatchMyPC Home Updater, URL יציב
Download-Installer "PatchMyPC" "https://homeupdater.patchmypc.com/public/PatchMyPC-HomeUpdater.msi" (Join-Path $dest "PatchMyPC.msi")

Write-Log "=== Update finished ==="
Write-Log ""
