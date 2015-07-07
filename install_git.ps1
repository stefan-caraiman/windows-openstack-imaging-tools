$gitUrl = "https://github.com/msysgit/msysgit/releases/download/Git-1.9.5-preview20150319/Git-1.9.5-preview20150319.exe"
$GitInstallPath = "$ENV:Temp\git-installer"
(new-object System.Net.WebClient).DownloadFile($gitUrl, $GitInstallPath)
cmd.exe /C call $GitInstallPath /silent
setx PATH "$env:PATH;${env:ProgramFiles(x86)}\Git\cmd;"
