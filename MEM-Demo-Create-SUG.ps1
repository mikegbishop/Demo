<#	
	.NOTES
	===========================================================================

	 Created on:   	12/15/2020
	 Created by:   	Mike Bishop
	 Organization: 	
	 Filename:  MEM-Demo-Create-SUG.ps1   	
	===========================================================================
	.DESCRIPTION
    Connects to the specified SiteCode and SMSProvider supplied below.  Then gathers a list of updates based on the selected critera and creates a MEM Software Update Group with those updates.
		

#>

cls
#region MEMConnection

# Site configuration
$SiteCode = "EM1" # Site code 
$ProviderMachineName = "FMM31597MEM001.backyard.corp" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

#endregion 

#Set-CMQueryResultMaximum -Maximum 5000

$NewSUGName = "2020-DECEMBER-REQUIRED"
$DatePostedMin = "11/11/2020"
$DatePostedMax = '12/9/2020'

#$Updates = Get-CMSoftwareUpdate -Fast -DateRevisedMin $DatePostedMin -DateRevisedMax $DatePostedMax | where-object {$_.IsSuperseded -eq $False -and $_.IsExpired -eq $False  -and $_.ISEnabled -eq $True -and $_.IsContentProvisioned -eq $True -and $_.LocalizedDisplayName -notlike "*Windows Malicious Software Removal Tool*" -and $_.LocalizedDisplayName -notlike "*Itanium*" -and $_.LocalizedDisplayName -notlike "*IA64*" -and $_.LocalizedDisplayName -notlike "*2003*" -and $_.LocalizedDisplayName -notlike "*1803*"   -and $_.LocalizedDisplayName -notlike "*1709*"   -and $_.LocalizedDisplayName -notlike "*2000*"  -and $_.LocalizedDisplayName -notlike "*2007*" -and $_.LocalizedDisplayName -notlike "*Skype*" -and $_.LocalizedDisplayName -notlike "*Office*" -and $_.LocalizedDisplayName -notlike "*Visio*" -and $_.LocalizedDisplayName -notlike "*Publisher*" -and $_.LocalizedDisplayName -notlike "*Word*" -and $_.LocalizedDisplayName -notlike "*Project*" -and $_.LocalizedDisplayName -notlike "*Powerpoint*" -and $_.LocalizedDisplayName -notlike "*OneNote*" -and $_.LocalizedDisplayName -notlike "*OneDrive*" -and $_.LocalizedDisplayName -notlike "*Access*" -and $_.LocalizedDisplayName -notlike "*Infopath*" -and $_.LocalizedDisplayName -notlike "*Excel*" -and $_.LocalizedDisplayName -notlike "*Microsoft SQL Server* Service Pack*"}| select BulletinID,CI_ID,ISContentProvisioned,Title,LocalizedDisplayName,IsSuperseded,category
#$Updates = Get-CMSoftwareUpdate -Fast -DateRevisedMin $DatePostedMin -DateRevisedMax $DatePostedMax | where-object {$_.IsSuperseded -eq $False -and $_.IsExpired -eq $False -and $_.LocalizedDisplayName -notlike "*Windows Malicious Software Removal Tool*" -and $_.LocalizedDisplayName -notlike "*Itanium*" -and $_.LocalizedDisplayName -notlike "*IA64*" -and $_.LocalizedDisplayName -notlike "*2003*" -and $_.LocalizedDisplayName -notlike "*1803*"   -and $_.LocalizedDisplayName -notlike "*1709*"   -and $_.LocalizedDisplayName -notlike "*2000*"  -and $_.LocalizedDisplayName -notlike "*2007*" -and $_.LocalizedDisplayName -notlike "*Skype*" -and $_.LocalizedDisplayName -notlike "*Office*" -and $_.LocalizedDisplayName -notlike "*Visio*" -and $_.LocalizedDisplayName -notlike "*Publisher*" -and $_.LocalizedDisplayName -notlike "*Word*" -and $_.LocalizedDisplayName -notlike "*Project*" -and $_.LocalizedDisplayName -notlike "*Powerpoint*" -and $_.LocalizedDisplayName -notlike "*OneNote*" -and $_.LocalizedDisplayName -notlike "*OneDrive*" -and $_.LocalizedDisplayName -notlike "*Access*" -and $_.LocalizedDisplayName -notlike "*Infopath*" -and $_.LocalizedDisplayName -notlike "*Excel*" -and $_.LocalizedDisplayName -notlike "*Microsoft SQL Server* Service Pack* " -and $_.LocalizedDisplayName -notlike "*Exchange*"}| select BulletinID,CI_ID,ISContentProvisioned,Title,LocalizedDisplayName,IsSuperseded,category
$Updates = Get-CMSoftwareUpdate -Fast -DateRevisedMin $DatePostedMin -DateRevisedMax $DatePostedMax | where-object {$_.IsSuperseded -eq $False -and $_.IsExpired -eq $False -and $_.LocalizedDisplayName -notlike "*Itanium*" -and $_.LocalizedDisplayName -notlike "*IA64*"}| select BulletinID,CI_ID,ISContentProvisioned,Title,LocalizedDisplayName,IsSuperseded,category

#$Updates = Get-CMSoftwareUpdate -Fast -DateRevisedMin $DatePostedMin -DateRevisedMax $DatePostedMax | where-object {$_.NumMissing -gt 0}

If($Updates.count -lt 1000)
{
    write-host "Found $($Updates.count) that match expected criteria."
    $UG = New-CMSoftwareUpdateGroup -Name $NewSUGName  -UpdateId $Updates.CI_ID 
}
Else
{
    write-host "More than one thousand ($($Updates.count)) ,need to further define the critera."
}


$Updates.LocalizedDisplayName
