# https://gist.github.com/dieseltravis/3066def0ddaf7a8a0b6d
# Powershell script that updates the background image with a image and writes out system info text to it.

# Configuration:

# Font Family name
$font="Arial"
# Font size in pixels
$size= 10.0
$headerFontSize = 12
$spaceBetweenHeaderAndInfo = 408
# spacing in pixels
$textPaddingLeft = 10
$textPaddingTop = 10
$textItemSpace = 1
# Title
$HeaderString = "DEPARTMENT OF EDUCATION" 
# End Configuration
# Get information to write out to wallpaper

$wallpaperImagesHistory0 = Get-ItemPropertyValue -Path 'Registry::HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Name BackgroundHistoryPath0
$wallpaperImagesHistory1 = Get-ItemPropertyValue -Path 'Registry::HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Name BackgroundHistoryPath1
$wallpaperImagesHistory2 = Get-ItemPropertyValue -Path 'Registry::HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Name BackgroundHistoryPath2
$wallpaperImagesHistory3 = Get-ItemPropertyValue -Path 'Registry::HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Name BackgroundHistoryPath3
$wallpaperImageOutput = "$env:LOCALAPPDATA\Temp" # --> C:\Users\%username%\AppData\Local\Temp
$logOutput = "C:\DECApps\Logs\APP_NSInfoData.log"

$UserName = $env:USERNAME
$UserSearch = New-Object DirectoryServices.DirectorySearcher -Property @{
    Filter = "(&(objectCategory=person)(objectClass=user)(sAMAccountName= $UserName))"}
$UserResult = $UserSearch.FindOne()
$UserAttr=$UserResult.GetDirectoryEntry()
$ActiveClient = $UserAttr.Name # AD Attribute - name 
if([string]::IsNullOrEmpty($ActiveClient))
{
    $ActiveClient =  "Unknown"
}
else
{
   $ActiveClient = $ActiveClient
}
$DeviceName = $env:COMPUTERNAME
$DeviceSearch = New-Object DirectoryServices.DirectorySearcher -Property @{
    Filter = "(&(objectCategory=computer)(objectClass=computer)(cn= $DeviceName))"}
$DeviceResult = $DeviceSearch.FindOne()
$DeviceAttr=$DeviceResult.GetDirectoryEntry()
$Attr2 = $DeviceAttr.extensionattribute2 # Room Allocation
if([string]::IsNullOrEmpty($Attr2))
{
    $RoomAllocation =  "Unknown"
}
else
{
   $RoomAllocation = $Attr2
}
$Attr3 = $DeviceAttr.extensionattribute3 # Device Type
if([string]::IsNullOrEmpty($Attr3))
{
    $DeviceType = "Unknown"
}
else
{
   $DeviceType = $Attr3
}
$Attr4 = $DeviceAttr.extensionattribute4 # Device Role
if([string]::IsNullOrEmpty($Attr4))
{
    $DeviceRole = "Unknown"
}
else
{
   $DeviceRole = $Attr4
}
$RegBuildVersion = Get-ItemPropertyValue -Path 'Registry::HKLM\SOFTWARE\DET\Build\' -Name MOE_BUILD_VERSION # Build Version
#$DeviceAttr.extensionattribute5 
if($RegBuildVersion -eq $null)
{
    $BuildVersion = "Unknown"    
}
else
{
   $BuildVersion = $RegBuildVersion
}
<#
$Attr6 = $DeviceAttr.extensionattribute6 # Unit Name
if([string]::IsNullOrEmpty($Attr6))
{
    $UnitName = "Unknown"
}
else
{
   $UnitName = $Attr6
}
$Attr7 = $DeviceAttr.extensionattribute7 # Unit Manager
if([string]::IsNullOrEmpty($Attr7))
{
    $UnitManager = "Unknown"    
}
else
{
   $UnitManager = $Attr7
}
$Attr8 = $DeviceAttr.extensionattribute8 # Device Custodian
if([string]::IsNullOrEmpty($Attr8))
{
    $DeviceCustodian = "Unknown"
}
else
{
   $DeviceCustodian = $Attr8
}
#>

$Vendor = (Get-WmiObject Win32_Computersystem).Manufacturer
$MTM = (Get-WmiObject Win32_Computersystem).Model
$SerialNUmber = (Get-WmiObject -Class:Win32_BIOS).SerialNumber

$Memory = "$([math]::round((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1024)) MB"

#Calculate C: Drive Free Space
$CDisk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$CDisk = @{'FreeSpace' = [Math]::Round($CDisk.FreeSpace / 1GB)}
$FreeSpace = $CDisk.FreeSpace

$OSArchitecture =  (Get-WmiObject Win32_OperatingSystem).OSArchitecture
$OSEdition = (Get-WmiObject win32_operatingsystem).caption

$getDisplayVersion =  ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion)
If($getDisplayVersion -eq $null)
{
    $DisplayVersion = ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId) #use releaseid if display version is not found (<=1909)
}
else
{
    $DisplayVersion = ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion)
}

$DomainName = $env:USERDOMAIN

$siteName =  [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name
$siteContainerDN = ("CN=Sites," + "CN=Configuration,DC=DETNSW,DC=WIN")
$siteDN = "CN=" + $siteName + "," + $siteContainerDN
$querySite = new-object system.directoryservices.directorysearcher
$querySite.SearchRoot = "LDAP://$($siteDN)" 
$FoundSite = $querySite.findone()
$siteProperty = $FoundSite.Properties.description.split(",")
$LocationCode = $siteProperty[0]
$CurrentLocation = $siteProperty[1]

if([string]::IsNullOrEmpty($CurrentLocation)) 
{
   $CurrentLocation = "Unknown"
}
else
{
   $CurrentLocation = $CurrentLocation
}
if([string]::IsNullOrEmpty($LocationCode)) 
{
   $LocationCode = "Unknown"
}
else
{
   $LocationCode = $LocationCode
}

# DeviceOU - AD Computer - Get Computer Parent OU Description
$DeviceOUParent = $DeviceAttr.Parent
$DeviceOUSearch = new-object system.directoryservices.directorysearcher
$DeviceOUSearch.SearchRoot = "$DeviceOUParent" 
$DeviceOUDesc = $DeviceOUSearch.findone()
$DeviceOU = $DeviceOUDesc.Properties.description
if([string]::IsNullOrEmpty($DeviceOU)) 
{
   $DeviceOU = "Unknown"
}
else
{
   $DeviceOU = $DeviceOU
}

$IPAddress = (Get-NetIPAddress | Where-Object {$_.PrefixOrigin -eq "Manual" -or $_.PrefixOrigin -eq "DHCP"-and  $_.AddressFamily -eq "IPv4"}).IPAddress -join "`n"

#Data displayed on wallpaper
$o = ([ordered]@{
"Device Name" = $DeviceName
"Manufacturer" = "HP"
"Model" = "EliteDesk 700 G1"
"Serial Number" = $SerialNUmber
"CPU" = "i3-4130"
"Memory" = "8 GB"
"Free Disk Space" = "C: $FreeSpace GB"
"OS Architecture" = $OSArchitecture
"OS Edition" = $OSEdition
"OS Release ID" = "$DisplayVersion"
"` " = "` "
"Current User" = If ([string]::IsNullOrEmpty($UserAttr.DisplayName)) {$ActiveClient} Else {$UserAttr.DisplayName}
"Domain Name" = $DomainName
"OS Build Version" = $BuildVersion
"Current School" = "$CurrentLocation"
"Current School Code" = "$LocationCode"
"School Code" = $DeviceOU.replace("C", "")
"Device Type" = "$DeviceType"
"UDM Role" = "$($DeviceRole.split(',', 2)[0])"
"Room Allocation" = "$RoomAllocation"
"UDM Comment" = "$($DeviceRole.split(',', 2)[1])"
"IP Address" = "10.214.96.249"
"` ` " = "` "
"Last Updated" = (Get-Date).ToString()
})

# original src: https://p0w3rsh3ll.wordpress.com/2014/08/29/poc-tatoo-the-background-of-your-virtual-machines/
Function New-ImageInfo {
    # src: https://github.com/fabriceleal/Imagify/blob/master/imagify.ps1
    param(  
        [Parameter(Mandatory=$True, Position=1)]
        [object] $data,
        [Parameter(Mandatory=$True)]
        [string] $in="",
        [string] $font="Courier New",
        [float] $size=12.0,
        #[float] $lineHeight = 1.4,
        [float] $textPaddingLeft = 0,
        [float] $textPaddingTop = 0,
        [float] $textItemSpace = 0,
        [string] $out="out.png" 
    )

    [system.reflection.assembly]::loadWithPartialName('system') | out-null
    [system.reflection.assembly]::loadWithPartialName('system.drawing') | out-null
    [system.reflection.assembly]::loadWithPartialName('system.drawing.imaging') | out-null
    [system.reflection.assembly]::loadWithPartialName('system.windows.forms') | out-null

    #foreBrush - change colour of text
    $foreBrush  = [System.Drawing.Brushes]::White
    $backBrush  = new-object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 0, 0, 0))

    # Create font
    $nFont = new-object system.drawing.font($font, $size, [System.Drawing.GraphicsUnit]::Pixel)

    # Create Bitmap
    $SR = [System.Windows.Forms.Screen]::AllScreens | Where Primary | Select -ExpandProperty Bounds | Select Width,Height

    echo $SR >> $logOutput

    $background = new-object system.drawing.bitmap($SR.Width, $SR.Height)
    $bmp = new-object system.drawing.bitmap -ArgumentList $in

    # Create Graphics
    $image = [System.Drawing.Graphics]::FromImage($background)

    # Paint image's background
    $rect = new-object system.drawing.rectanglef(0, 0, $SR.width, $SR.height)
    $image.FillRectangle($backBrush, $rect)

    # add in image
    $topLeft = new-object System.Drawing.RectangleF(0, 0, $SR.Width, $SR.Height)
    $image.DrawImage($bmp, $topLeft)

    # Draw string
    $strFrmt = new-object system.drawing.stringformat
    $strFrmt.Alignment = [system.drawing.StringAlignment]::Near
    $strFrmt.LineAlignment = [system.drawing.StringAlignment]::Near

    $taskbar = [System.Windows.Forms.Screen]::PrimaryScreen
    #Change the value to position BGInfo
    #$taskbarOffset = $taskbar.Bounds.Height - $taskbar.WorkingArea.Height
    $taskbarOffset = $taskbar.WorkingArea.Height - $spaceBetweenHeaderAndInfo #1010 - 460 = 550 pixels

    # first get max key & val widths
    $maxKeyWidth = 0
    $maxValWidth = 0
    $textBgHeight = 0 + $taskbarOffset
    $textBgWidth = 0
    
    # a reversed ordered collection is used since it starts from the bottom
    $reversed = [ordered]@{}

    foreach ($h in $data.GetEnumerator()) {
 
        $valString = "$($h.Value)"
        $valFont = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Regular)
        $valSize = [system.windows.forms.textrenderer]::MeasureText($valString, $valFont)
        $maxValWidth = [math]::Max($maxValWidth, $valSize.Width)

        $keyString = "$($h.Name) "
        $keyFont = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Bold)
        $keySize = [system.windows.forms.textrenderer]::MeasureText($keyString, $keyFont)
        $maxKeyWidth = [math]::Max($maxKeyWidth, $keySize.Width)

        $maxItemHeight = [math]::Max($valSize.Height, $keySize.Height)
        $textBgHeight += ($maxItemHeight + $textItemSpace)
        
        $reversed.Insert(0, $h.Name, $h.Value)      
    }
      
    $textBgWidth = $maxKeyWidth + $maxValWidth + $textPaddingLeft
    $textBgHeight += $textPaddingTop
    $textBgX = $SR.Width - $textBgWidth
    $textBgY = $SR.Height - $textBgHeight

    $textBgRect = New-Object System.Drawing.RectangleF($textBgX, $textBgY, $textBgWidth, $textBgHeight)
    $image.FillRectangle($backBrush, $textBgRect)

    echo $textBgRect >> $logOutput

    $i = 0
    $cumulativeHeight = $SR.Height - $taskbarOffset

    $HeaderFont = New-Object System.Drawing.Font($font, $headerFontSize, ([System.Drawing.FontStyle]::Bold -bor [System.Drawing.FontStyle]::Underline))
    $HeaderSize = [system.windows.forms.textrenderer]::MeasureText($HeaderString, $HeaderFont)
    $image.DrawString($HeaderString,$HeaderFont,$foreBrush,$textBgX+10,$HeaderSize.height)

    foreach ($h in $reversed.GetEnumerator()) {
        $valString = "$($h.Value)"
        $valFont = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Regular)
        $valSize = [system.windows.forms.textrenderer]::MeasureText($valString, $valFont)

        $keyString = "$($h.Name) "
        $keyFont = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Bold)
        $keySize = [system.windows.forms.textrenderer]::MeasureText($keyString, $keyFont)

        echo $valString >> $logOutput
        echo $keyString >> $logOutput

        $maxItemHeight = [math]::Max($valSize.Height, $keySize.Height) + $textItemSpace

        $valX = $SR.Width - $maxValWidth
        $valY = $cumulativeHeight - $maxItemHeight

        $keyX = $valX - $maxKeyWidth
        $keyY = $valY
        
        $valRect = New-Object System.Drawing.RectangleF($valX, $valY, $maxValWidth, $valSize.Height)
        $keyRect = New-Object System.Drawing.RectangleF($keyX, $keyY, $maxKeyWidth, $keySize.Height)

        $cumulativeHeight = $valRect.Top

        
        $image.DrawString($keyString, $keyFont, $foreBrush, $keyRect, $strFrmt)
        $image.DrawString($valString, $valFont, $foreBrush, $valRect, $strFrmt)
        
        $i++
    }
     
    # Close Graphics
    $image.Dispose();

    # Save and close Bitmap
    $background.Save($out, [system.drawing.imaging.imageformat]::Png);
    $background.Dispose();
    $bmp.Dispose();

    # Output file
    Get-Item -Path $out
}

Function Set-Wallpaper {
    # src: http://powershell.com/cs/blogs/tips/archive/2014/01/10/change-desktop-wallpaper.aspx
    param(
        [Parameter(Mandatory=$true)]
        $Path,
        
        [ValidateSet('Center', 'Stretch', 'Fill', 'Tile', 'Fit')]
        $Style = 'Stretch'
    )
    
    #TODO: there in't a better way to do this than inline C#?
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;

namespace Wallpaper
{
    public enum Style : int
    {
        Center, Stretch, Fill, Fit, Tile
    }

    public class Setter {
        public const int SetDesktopWallpaper = 20;
        public const int UpdateIniFile = 0x01;
        public const int SendWinIniChange = 0x02;

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);

        public static void SetWallpaper ( string path, Wallpaper.Style style ) 
        {
            SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
            RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
            switch( style )
            {
                case Style.Tile :
                    key.SetValue(@"WallpaperStyle", "0") ; 
                    key.SetValue(@"TileWallpaper", "1") ; 
                    break;
                case Style.Center :
                    key.SetValue(@"WallpaperStyle", "0") ; 
                    key.SetValue(@"TileWallpaper", "0") ; 
                    break;
                case Style.Stretch :
                    key.SetValue(@"WallpaperStyle", "2") ; 
                    key.SetValue(@"TileWallpaper", "0") ;
                    break;
                case Style.Fill :
                    key.SetValue(@"WallpaperStyle", "10") ; 
                    key.SetValue(@"TileWallpaper", "0") ; 
                    break;
                case Style.Fit :
                    key.SetValue(@"WallpaperStyle", "6") ; 
                    key.SetValue(@"TileWallpaper", "0") ; 
                    break;
            }
            key.Close();
        }
    }
}
"@
    
    [Wallpaper.Setter]::SetWallpaper( $Path, $Style )
}

# execute tasks

echo $o > $logOutput

# get wallpaper from a background image history path

if($wallpaperImagesHistory0 -eq "$env:LOCALAPPDATA\Microsoft\DesktopData\DesktopWallpaper.jpg" -and $wallpaperImagesHistory1 -eq "$env:LOCALAPPDATA\Temp\BGInfo.bmp")
{
    # copy image from history path to users temp folder as current.jpg
    Copy-Item $wallpaperImagesHistory2 -Destination "$wallpaperImageOutput\current.jpg" 
    # create wallpaper image and save it in user profile
    $WallPaper = New-ImageInfo -data $o -in "$wallpaperImageOutput\current.jpg" -out "$wallpaperImageOutput\wallpaper.png" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace #-lineHeight $lineHeight
    #echo $WallPaper.FullName >> $logOutput
    # update wallpaper for logged in user
    Set-Wallpaper -Path $WallPaper.FullName
    "Loop 1 - Copied Image from path history 2 - $wallpaperImagesHistory2" | Add-Content $logOutput
}

elseIf($wallpaperImagesHistory0 -eq "$env:LOCALAPPDATA\Microsoft\DesktopData\DesktopWallpaper.jpg" -and $wallpaperImagesHistory1 -eq "$wallpaperImageOutput\wallpaper.png" -and $wallpaperImagesHistory2 -like "*BGInfo.bmp")
{
    Copy-Item $wallpaperImagesHistory3 -Destination "$wallpaperImageOutput\current.jpg" 
    $WallPaper = New-ImageInfo -data $o -in "$wallpaperImageOutput\current.jpg" -out "$wallpaperImageOutput\wallpaper.png" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace 
    Set-Wallpaper -Path $WallPaper.FullName
    "Loop 2 - Copied Image from path history 3 - $wallpaperImagesHistory3" | Add-Content $logOutput
}

elseif($wallpaperImagesHistory1 -eq "$env:LOCALAPPDATA\Microsoft\DesktopData\DesktopWallpaper.jpg" -and $wallpaperImagesHistory0 -eq "$wallpaperImageOutput\wallpaper.png"-and $wallpaperImagesHistory2 -like "*BGInfo.bmp")
{
    Copy-Item $wallpaperImagesHistory3 -Destination "$wallpaperImageOutput\current.jpg" 
    $WallPaper = New-ImageInfo -data $o -in "$wallpaperImageOutput\current.jpg" -out "$wallpaperImageOutput\wallpaper.png" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace     
    Set-Wallpaper -Path $WallPaper.FullName
    "Loop 3 - Copied Image from path history 3 - $wallpaperImagesHistory3" | Add-Content $logOutput
}

elseif($wallpaperImagesHistory0 -eq "$env:LOCALAPPDATA\Microsoft\DesktopData\DesktopWallpaper.jpg" -and $wallpaperImagesHistory1 -eq "$wallpaperImageOutput\wallpaper.png")
{
    Copy-Item $wallpaperImagesHistory2 -Destination "$wallpaperImageOutput\current.jpg" 
    $WallPaper = New-ImageInfo -data $o -in "$wallpaperImageOutput\current.jpg" -out "$wallpaperImageOutput\wallpaper.png" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace 
    Set-Wallpaper -Path $WallPaper.FullName
    "Loop 4 - Copied Image from path history 2 - $wallpaperImagesHistory2" | Add-Content $logOutput
}

elseif($wallpaperImagesHistory1 -eq "$env:LOCALAPPDATA\Microsoft\DesktopData\DesktopWallpaper.jpg" -and $wallpaperImagesHistory0 -eq "$wallpaperImageOutput\wallpaper.png")
{
    Copy-Item $wallpaperImagesHistory2 -Destination "$wallpaperImageOutput\current.jpg" 
    $WallPaper = New-ImageInfo -data $o -in "$wallpaperImageOutput\current.jpg" -out "$wallpaperImageOutput\wallpaper.png" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace     
    Set-Wallpaper -Path $WallPaper.FullName
    "Loop 5 - Copied Image from path history 2 - $wallpaperImagesHistory2" | Add-Content $logOutput
}

elseif($wallpaperImagesHistory0 -ne "$wallpaperImageOutput\wallpaper.png" -or $wallpaperImagesHistory0 -eq "$env:LOCALAPPDATA\Microsoft\DesktopData\DesktopWallpaper.jpg")
{
    if($wallpaperImagesHistory0 -eq "$env:LOCALAPPDATA\Temp\BGInfo.bmp")
    {
        Copy-Item $wallpaperImagesHistory1 -Destination "$wallpaperImageOutput\current.jpg" 
        $WallPaper = New-ImageInfo -data $o -in "$wallpaperImageOutput\current.jpg" -out "$wallpaperImageOutput\wallpaper.png" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace        
        Set-Wallpaper -Path $WallPaper.FullName
        "Loop 6 - Copied Image from path history 1 - $wallpaperImagesHistory1" | Add-Content $logOutput
    
    }
    else
    {
        Copy-Item $wallpaperImagesHistory0 -Destination "$wallpaperImageOutput\current.jpg" 
        $WallPaper = New-ImageInfo -data $o -in "$wallpaperImageOutput\current.jpg" -out "$wallpaperImageOutput\wallpaper.png" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace
        Set-Wallpaper -Path $WallPaper.FullName
        "Loop 6.1 - Copied Image from path history 0 - $wallpaperImagesHistory0"
    }
}

elseif($wallpaperImagesHistory1 -eq "$env:LOCALAPPDATA\Temp\BGInfo.bmp")
{
    Copy-Item $wallpaperImagesHistory2 -Destination "$wallpaperImageOutput\current.jpg" 
    $WallPaper = New-ImageInfo -data $o -in "$wallpaperImageOutput\current.jpg" -out "$wallpaperImageOutput\wallpaper.png" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace 
    Set-Wallpaper -Path $WallPaper.FullName
    "Loop 7 - Copied Image from path history 2 - $wallpaperImagesHistory2" | Add-Content $logOutput
}

elseif($wallpaperImagesHistory1 -ne "$wallpaperImageOutput\wallpaper.png")
{
    Copy-Item $wallpaperImagesHistory1 -Destination "$wallpaperImageOutput\current.jpg" 
    $WallPaper = New-ImageInfo -data $o -in "$wallpaperImageOutput\current.jpg" -out "$wallpaperImageOutput\wallpaper.png" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace 
    Set-Wallpaper -Path $WallPaper.FullName
    "Loop 8 - Copied Image from path history 1 - $wallpaperImagesHistory1" | Add-Content $logOutput
}

else
{
    Copy-Item $wallpaperImagesHistory2 -Destination "$wallpaperImageOutput\current.jpg" 
    $WallPaper = New-ImageInfo -data $o -in "$wallpaperImageOutput\current.jpg" -out "$wallpaperImageOutput\wallpaper.png" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace
    Set-Wallpaper -Path $WallPaper.FullName
    "Loop 9 - Copied Image from path history 2 - $wallpaperImagesHistory2" | Add-Content $logOutput
}

New-ImageInfo -data $o -in "C:/Windows/Web/Screen/DoELockScreen.jpg.old" -out "C:/Windows/Web/Screen/DoELockScreen.jpg" -font $font -size $size -textPaddingLeft $textPaddingLeft -textPaddingTop $textPaddingTop -textItemSpace $textItemSpace