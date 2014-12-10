$ErrorActionPreference = "Inquire"



# Configure WinRM
& winrm create winrm/config/Listener?Address=*+Transport=HTTP `@`{Hostname=`"$($ENV:COMPUTERNAME)`"`}
if ($LastExitCode) { throw "Failed to setup WinRM HTTP listener" }

& winrm set winrm/config/service `@`{AllowUnencrypted=`"true`"`}
if ($LastExitCode) { throw "Failed to setup WinRM HTTP listener" }

& winrm set winrm/config/service/auth `@`{Basic=`"true`"`}
if ($LastExitCode) { throw "Failed to setup WinRM basic auth" }

& netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985
if ($LastExitCode) { throw "Failed to setup WinRM HTTP firewall rules" }
