Option Explicit

Dim shell, fileSystem, folderPath, scriptPath, command

Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

folderPath = fileSystem.GetParentFolderName(WScript.ScriptFullName)
scriptPath = fileSystem.BuildPath(folderPath, "YouTube-Downloader.ps1")

command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command " _
    & Chr(34) _
    & "$arquivo = '" & Replace(scriptPath, "'", "''") & "'; " _
    & "$codigo = [System.IO.File]::ReadAllText($arquivo, [System.Text.Encoding]::UTF8); " _
    & "Invoke-Expression $codigo" _
    & Chr(34)

shell.Run command, 0, False

Set fileSystem = Nothing
Set shell = Nothing
