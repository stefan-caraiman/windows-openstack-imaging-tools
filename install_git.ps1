Function global:ADD-PATH()
{
param
(
[parameter(Mandatory=$True)]
[String[]]$AddedFolder
)

# Get the current search path from the environment keys in the registry.

$OldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path

# See if a new folder has been supplied.

IF (!$AddedFolder)
{ Return ‘No Folder Supplied. $ENV:PATH Unchanged’}

# See if the new folder exists on the file system.

IF (!(TEST-PATH $AddedFolder))
{ Return ‘Folder Does not Exist, Cannot be added to $ENV:PATH’ }

# See if the new Folder is already in the path.

IF ($ENV:PATH | Select-String -SimpleMatch $AddedFolder)
{ Return ‘Folder already within $ENV:PATH' }

# Set the New Path

$NewPath=$OldPath+’;’+$AddedFolder

Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $newPath
}

$gitUrl = "https://github.com/msysgit/msysgit/releases/download/Git-1.9.5-preview20150319/Git-1.9.5-preview20150319.exe"
$GitInstallPath = "$ENV:Temp\git-installer.exe"
(new-object System.Net.WebClient).DownloadFile($gitUrl, $GitInstallPath)
cmd.exe /C call $GitInstallPath /silent
ADD-PATH("${env:ProgramFiles(x86)}\Git\cmd;")
