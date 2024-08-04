' VBScript for silently running the powershell script as a scheduled task

Dim shell,command


command = "powershell.exe -executionpolicy bypass -NoLogo -NonInteractive -file ""C:\Program Files\NSInfo\NSInfo.ps1"""

set shell = CreateObject("WScript.Shell")

shell.Run command,0