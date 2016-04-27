$ErrorActionPreference = "Stop"

try
{
    $Host.UI.RawUI.WindowTitle = "Winrm config..."
    $winrmLUrl = "https://raw.github.com/stefan-caraiman/windows-openstack-imaging-tools/master/SetupWinRMAccess.ps1"
    $winrmPath = "$ENV:Temp\SetupWinRMAccess.ps1"
    (new-object System.Net.WebClient).DownloadFile($winrmLUrl, $winrmPath)
    powershell -NoLogo -NonInteractive -ExecutionPolicy RemoteSigned -File $winrmPath

    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name Unattend*
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoLogonCount

    $Host.UI.RawUI.WindowTitle = "Running Sysprep..."
    if([Environment]::Is64BitOperatingSystem -eq "True"){
        $unattendXMLUrl = "https://raw.githubusercontent.com/stefan-caraiman/windows-openstack-imaging-tools/master/Unattend64.xml"
        $unattendXMLPath = "$ENV:Temp\Unattend64.xml"
    } else {
        $unattendXMLUrl = "https://raw.githubusercontent.com/stefan-caraiman/windows-openstack-imaging-tools/master/Unattend32.xml"
        $unattendXMLPath = "$ENV:Temp\Unattend32.xml"
    }
    (new-object System.Net.WebClient).DownloadFile($unattendXMLUrl, $unattendXMLPath)
    & "$ENV:SystemRoot\System32\Sysprep\Sysprep.exe" `/generalize `/oobe `/unattend:"$unattendXMLPath" `/shutdown
}
catch
{
    $host.ui.WriteErrorLine($_.Exception.ToString())
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    throw
}
