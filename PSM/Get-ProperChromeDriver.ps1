<#
.DESCRIPTION
    Script to download correct version of ChromeDriver for PSM (Chrome 115 and higher)
#>
#
## Set for your environment
#
$Chrome32InstallationPath = 'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe'
$CyberArkInstallationPath = 'D:\Program Files (x86)\CyberArk\PSM\'
#
# Get current version of installed Chrome
$chrome = (Get-WmiObject -Class CIM_DataFile -Filter "Name='$($Chrome32InstallationPath)'" | Select-Object Version).Version
if ($chrome -and $chrome -match '(\d+)\.(\d+)\.(\d+)\.(\d+)') {
    $chromeversion = $matches
    # Get List of current downloads for Chrome For Testing (See https://chromedriver.chromium.org/downloads/version-selection )
    $result = Invoke-WebRequest -URI https://googlechromelabs.github.io/chrome-for-testing/latest-versions-per-milestone-with-downloads.json
    $content = $result.content | ConvertFrom-JSON
    #
    # Find the latest version of Chrome Driver that is less than or equal to your 32-Bit chrome installed version
    #   It appears that they only keep one version of the driver for each milestone.
    #
    if ($content.milestones.$milestone) {
        if ($content.milestones.$milestone.Version -match '(\d+)\.(\d+)\.(\d+)\.(\d+)') {
            $cftVersion = $matches
            if ([int]($cftVersion[2]) -le [int]($chromeversion[2]) -and 
                [int]($cftVersion[3]) -le [int]($chromeversion[3]) -and
                [int]($cftVersion[4]) -le [int]($chromeversion[4])) {
                $uri = ($content.milestones.$milestone.downloads.chromedriver | Where-Object { $_.platform -eq 'win32' }).url
                if ($uri) {
                    $outfilebase = "D:\Install\chromedriver-win32-$($cftVersion[1]).$($cftVersion[2]).$($cftVersion[3]).$($cftVersion[4])"
                    if (Test-Path "$($outfilebase)\chromedriver-win32\chromedriver.exe" -PathType Leaf) {
                        Write-Host "Current Version $($outfilebase) is latest version"
                    }
                    else {
                        $outfile = "$($outfilebase).zip"
                        Invoke-Webrequest -URI $uri -Outfile $outfile
                        Expand-Archive -LiteralPath $outfile -DestinationPath $outfilebase
                        Copy-Item "$($Outfilebase)\chromedriver-win32\chromedriver.exe" "$($CyberArkInstallationPath)Components\chromedriver.exe"
                        Unblock-File "$($CyberArkInstallationPath)Components\chromedriver.exe"
                    }
                }
                else {
                    Write-Host "Win32 Chromedriver for $($chrome) not found"
                }
            }
            else {
                Write-Host "Milestone and Version for $($chrome) not found"
            }
        }
        else {
            Write-Host "Version Number $($chrome) isn't formed correctly"
        }
    }
    else {
        Write-Host "Milestone for $($chrome) not found"
    }
}
else {
    Write-Host "Unexpected Chrome Version installed: '$($chrome)'"
}        