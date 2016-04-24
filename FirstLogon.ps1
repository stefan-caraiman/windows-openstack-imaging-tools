$ErrorActionPreference = "Stop"

function getOSVersion(){
    $v = (Get-WmiObject Win32_OperatingSystem).Version.Split('.')

    return New-Object psobject -Property @{
        Major = [int]::Parse($v[0])
        Minor = [int]::Parse($v[1])
        Build = [int]::Parse($v[2])
    }
}

function getVirtioDriversFolder(){
    $architectureMapping = @{}
    $architectureMapping['32-bit']='X86'
    $architectureMapping['64-bit']='AMD64'
    $osVersionMapping = @{}
    $osVersionMapping[0]='VISTA'
    $osVersionMapping[1]='WIN7'
    $osVersionMapping[2]='WIN8'
    $osVersionMapping[3]='WIN8'

    $osArchitecture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
    $archFolder = $architectureMapping[$osArchitecture]

    $osVersion = getOSVersion
    $versionFolder = $osVersionMapping[$osVersion.Minor]
    if (($osVersion.Major -ne 6) -or !$versionFolder) { throw "Unsupported Windows version" }

    $virtIOPath = Join-Path -Path $versionFolder -ChildPath $archFolder
    #$drive = (gwmi Win32_CDROMDrive | where {(Test-Path (join-path -Path $_.Drive -ChildPath $virtIOPath ))}).Drive
    $drive = "E:"
    if (! $drive) { throw "VirtIO drivers not found" }

    return join-path -Path $drive -ChildPath $virtIOPath | join-path -ChildPath "*.inf"
}

function installVirtIOTools2012($virtioDriversPath) {
    $Host.UI.RawUI.WindowTitle = "Downloading VirtIO drivers script..."
    $virtioScriptPath = "$ENV:Temp\InstallVirtIODrivers.js"
    $url = "$baseUrl/InstallVirtIODrivers.js"
    (new-object System.Net.WebClient).DownloadFile($url, $virtioScriptPath)

    Write-Host "Installing VirtIO drivers from: $virtioDriversPath"
    & cscript $virtioScriptPath $virtioDriversPath
    if (!$?) { throw "InstallVirtIO failed" }
    del $virtioScriptPath
}

function installVirtIOToolsPre2012($virtioDriversPath) {
    $Host.UI.RawUI.WindowTitle = "Downloading VirtIO certificate..."
    $virtioCertPath = "$ENV:Temp\VirtIO.cer"
    $url = "$baseUrl/VirtIO.cer"
    (new-object System.Net.WebClient).DownloadFile($url, $virtioCertPath)

    $Host.UI.RawUI.WindowTitle = "Installing VirtIO certificate..."
    $cacert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($virtioCertPath)
    $castore = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::TrustedPublisher,`
                     [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
    $castore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $castore.Add($cacert)

    Write-Host "Installing VirtIO drivers from: $virtioDriversPath"
    Start-process -Wait pnputil "-i -a $virtioDriversPath"
    if (!$?) { throw "InstallVirtIO failed" }

    del $virtioCertPath
    $castore.Remove($cacert)
}

function getHypervisor() {
    $checkHypervisorExeUrl = "https://github.com/cloudbase/checkhypervisor/raw/master/bin/checkhypervisor.exe"
    $checkHypervisorExePath = "$ENV:Temp\checkhypervisor.exe"
    Invoke-WebRequest -Uri $checkHypervisorExeUrl -OutFile $checkHypervisorExePath

    $hypervisor = & $checkHypervisorExePath

    if ($LastExitCode -eq 1) {
        Write-Host "No hypervisor detected."
    } else {
        return $hypervisor
    }
}

$logonScriptPath = "$ENV:SystemRoot\Temp\Logon.ps1"

try
{
    $Host.UI.RawUI.WindowTitle = "Setting Password Expiration To False For User CiAdmin"
    cmd /C wmic useraccount where "name='CiAdmin'" set PasswordExpires=FALSE

    # Disable UAC so that using /runas for Start-Process will work.
    # Also, it will require a reboot and since Logon.ps1 runs after
    # we restart, we add this modifier here.
    $Host.UI.RawUI.WindowTitle = "Disabling uac"
    Set-ItemProperty -path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system" -name EnableLUA -value 0
    
    $Host.UI.RawUI.WindowTitle = "Downloading Logon script..."
    $baseUrl = "https://raw.github.com/PCManticore/windows-openstack-imaging-tools/master"
    (new-object System.Net.WebClient).DownloadFile("$baseUrl/Logon.ps1", $logonScriptPath)

    $hypervisorStr = getHypervisor
    Write-Host "Hypervisor: $hypervisorStr"
    # TODO: Add XenServer / XCP
    switch($hypervisorStr)
    {
        "VMwareVMware"
        {
            # Note: this command will generate a reboot.
            # "/qn REBOOT=ReallySuppress" does not seem to work properly
            $Host.UI.RawUI.WindowTitle = "Installing VMware tools..."
            E:\setup64.exe `/s `/v `/qn `/l `"$ENV:Temp\vmware_tools_install.log`"
            if (!$?) { throw "VMware tools setup failed" }
        }
        "KVMKVMKVM"
        {
            $virtioDriversPath = getVirtioDriversFolder
            $osVersion = getOSVersion

            if (($osVersion.Major -ge 6) -and ($osVersion.Minor -ge 2)) {
                installVirtIOTools2012 $virtioDriversPath
            }
            else {
                installVirtIOToolsPre2012 $virtioDriversPath
            }

            shutdown /r /t 0
        }
    }
}
catch
{
    $host.ui.WriteErrorLine($_.Exception.ToString())
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    # Prevents the setup from proceeding
    if ( Test-Path $logonScriptPath ) { del $logonScriptPath }
    throw
}
