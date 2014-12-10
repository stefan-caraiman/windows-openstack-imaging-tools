$ErrorActionPreference = "Inquire"



# Configure WinRM
function RemoveExistingWinRMHttpListener() {
    $httpListener = Get-Item -Path wsman:\localhost\listener\* | where {$_.Keys.Contains("Transport=HTTP")}
    if ($httpListener) {
        Remove-Item -Recurse -Force -Path ("wsman:\localhost\listener\" + $httpsListener.Name)
    }
}

RemoveExistingWinRMHttpListener

& winrm create winrm/config/Listener?Address=*+Transport=HTTP `@`{Hostname=`"$($ENV:COMPUTERNAME)`"`}
if ($LastExitCode) { throw "Failed to setup WinRM HTTP listener" }

& winrm set winrm/config/service `@`{AllowUnencrypted=`"true`"`}
if ($LastExitCode) { throw "Failed to setup WinRM HTTP listener" }

& winrm set winrm/config/service/auth `@`{Basic=`"true`"`}
if ($LastExitCode) { throw "Failed to setup WinRM basic auth" }

& netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985
if ($LastExitCode) { throw "Failed to setup WinRM HTTP firewall rules" }
