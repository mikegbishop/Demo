<#	
	.NOTES
	===========================================================================

	 Created on:   	12/15/2020
	 Created by:   	Mike Bishop
	 Organization: 	
	 Filename:  MEM-Add-Boundary-Subnet.ps1   	
	===========================================================================
	.DESCRIPTION
    Reads the Boundary subnet and boundary group name from the input CSV file(s) located in the .\Current-Configs directory and creates the objects and assigns to the 
    apprpriate boundary group.  Safe to rerun to verify they all exist.
		
Example Input CSV File:

BoundarySubnet,BoundaryGroupMember,Active
192.168.6.0/24,Houston Office,Yes
192.168.7.0/24,,Yes
192.168.8.0/24,Dallas Office,Yes
192.168.9.0/24,Dallas Office,Yes
192.168.10.0/24,Paris Office,Yes
#>

#region FixedVariables
cls
$Error.Clear()
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$LogPathRoot = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent
$LogPath = $($LogPathRoot + "\Logs")
$ConfigPath = $($LogPathRoot + "\Current-Configs")
if(!(Test-Path $LogPath)){New-Item -ItemType directory $LogPath}
if(!(Test-Path $ConfigPath)){New-Item -ItemType directory $ConfigPath}
$Logfile = $($LogPath + "\$env:COMPUTERNAME.MEM-Add-Boundary-Subnet." + $(Get-Date -format MM.dd.yyyy.HH.mm.ss) + ".log")
$Global:Test = $null

# The following line pulls the AdminConsole file path from the registry.
$SCCMModulePath = $($(Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\SMS\Setup")."UI Installation Directory" + "\bin\ConfigurationManager.psd1")

#The following line declares an explicit path to the ConfigurationManager PowerShell module.
#$SCCMModulePath = "E:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

    $Color = [PSCustomObject]@{
            Blue = 'Blue'
            Red = 'Red'
            Yellow = 'Yellow'
            Green = 'Green'
            Magenta = 'Magenta'
            DarkBlue = 'DarkBlue'
            DarkGreen = 'DarkGreen'
            DarkRed = 'DarkRed'
            DarkMagenta = 'DarkMagenta'
            DarkYellow = 'DarkYellow'}
#endregion FixedVariables

#region Functions
Function LogWrite
{
   Param ([string]$logstring,[ValidateSet('Yes','No')][string]$DisplayConsole="No",[ValidateSet('Blue', 'Red','Yellow','Green','DarkBlue','DarkRed','DarkYellow','DarkGreen','White')][string]$TextColor="White")
   $DateStamp = Get-Date -Format MM.dd.yyyy.HH.mm.ss
   if ($DisplayConsole -eq "Yes" -or $Debug -eq $true)
       {
        Write-Host $logstring -ForegroundColor $TextColor 
       }

   $logstring = $logstring + "     " + $DateStamp
   #$DisplayConsole = 1
   Add-content $Logfile -value $logstring

}

function Check-Boundary-Exists
{
	[CmdletBinding()]
	param
	(
		[Parameter() ]
		[string]$BoundaryName = 'Bogus-Boundary'
    )
		
    $CurBoundary = Get-CMBoundary -BoundaryName $BoundaryName
    if($CurBoundary.DisplayName -eq $BoundaryName)
        {
            Return $true
        }
    else
        {
            Return $false
        }
}

function Create-Subnet-Boundary
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[string]$BoundaryName
	)

    if(Check-Boundary-Exists -BoundaryName $BoundaryName)
        {
            LogWrite "Boundary $BoundaryName already exists." -DisplayConsole Yes -TextColor Yellow
            Return $true
        }
    else
        {   
            New-CMBoundary -DisplayName $BoundaryName -BoundaryType IPSubNet -Value $BoundaryName -OutVariable NewBoundaryResult | Write-Verbose
            #Write-Host $NewBoundaryResult
            if($NewBoundaryResult.DisplayName -eq $BoundaryName)
                {
                    LogWrite "$BoundaryName successfully created." -DisplayConsole Yes -TextColor Green
                    Return $true
                }
            else
                {
                    LogWrite "Failed to create $BoundaryName" -DisplayConsole Yes -TextColor Red
                    Return $false
                }
        }
}

function Check-Boundary-Group-Exists
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[string]$BoundaryGroupName		
	)

    $CurBoundaryGroup = Get-CMBoundaryGroup -Name $BoundaryGroupName
    if($CurBoundaryGroup.Name -eq $BoundaryGroupName)
        {
            Return $true
        }
    else
        {
            Return $false
        }
}

function Create-Boundary-Group
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[string]$BoundaryGroupName	
	)

    $CurBoundaryGroup = New-CMBoundaryGroup -Name $BoundaryGroupName
    if($CurBoundaryGroup.Name -eq $BoundaryGroupName)
        {
            LogWrite $("Succesfully created boundary group: " + $CurBoundaryGroup.Name )
            Return $true
        }
    else
        {
            Return $false
        }
}

function Check-Boundary-Members
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[string]$BoundaryGroupName,
		[Parameter(Mandatory)]
		[string]$BoundaryName
	)

    if($(Get-CMBoundary -BoundaryGroupName $BoundaryGroupName).DisplayName -contains $BoundaryName)
        {
            #LogWrite $("Boundary $BoundaryName is already a member of boundary group  $BoundaryGroupName" ) -DisplayConsole Yes
            Return $true
        }
    else
        {
           LogWrite $("Boundary $BoundaryName is not currently a member of boundary group  $BoundaryGroupName" ) -DisplayConsole Yes
            Return $false
        }
}

function Add-Boundary-To-Group
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[string]$BoundaryGroupName,
		[Parameter(Mandatory)]
		[string]$BoundaryName
	)

    Add-CMBoundaryToGroup -BoundaryGroupName $BoundaryGroupName -BoundaryName $BoundaryName -OutVariable $AddSubnettoBoundaryGroupResult
    $Global:Test = $AddSubnettoBoundaryGroupResult
}

#endregion Functions

#region Main

if(!(Get-Module ConfigurationManager))
    {
        Import-module $SCCMModulePath
        LogWrite "Successfully imported the SCCM PS module." -DisplayConsole Yes -TextColor Green
    }
    else
    {
        LogWrite "Configuration Manger Powershell Module already loaded." -DisplayConsole Yes -TextColor Green
    }

$SMSDRV = Get-PSDRive -PSProvider CMSite
CD "$($SMSDRV):"
if($SMSDRV)
{
    LogWrite "Successfully created the PS-Drive SMSDRV." -DisplayConsole Yes -TextColor Green
}
else
{
    LogWrite "Failed to create the PS-Drive SMSDRV." -DisplayConsole Yes -TextColor Red
    throw "Failed to create the PS-Drive SMSDRV."
}

$InputFileList = Get-ChildItem -Path $ConfigPath -Filter *.csv
if($InputFileList.count -gt 0)
    {
        LogWrite $("Found input files: " + $InputFileList.FullName) -DisplayConsole Yes -TextColor Green
    }
else
    {
        LogWrite $("Failed to find *.csv input files in the $ConfigPath directory") -DisplayConsole Yes -TextColor Red
        throw "Failed to find *.csv input files in the $ConfigPath directory"
    }

foreach($InputFile in $InputFileList)
    {
        $BoundaryList = Import-Csv -Path $InputFile.FullName | Where-Object {$_.Active -eq "Yes"}
        #LogWrite $BoundaryList -DisplayConsole Yes
        
        foreach($Boundary in $BoundaryList)
            {
                LogWrite "Processing $Boundary" -DisplayConsole Yes -TextColor Green
                if(Check-Boundary-Exists -BoundaryName $Boundary.BoundarySubnet)
                    {
                        LogWrite $("Boundary " + $Boundary.BoundarySubnet + " already exists.") -DisplayConsole Yes -TextColor Green
                    }
                else
                    {
                        LogWrite $("Boundary " + $Boundary.BoundarySubnet + " does not already exist will create.") -DisplayConsole Yes 
                        Create-Subnet-Boundary -BoundaryName $Boundary.BoundarySubnet -OutVariable CurSubnetCreationStatus | out-null
                    }

                    if($Boundary.BoundaryGroupMember -ne '')
                        {
                            if(Check-Boundary-Group-Exists -BoundaryGroupName $Boundary.BoundaryGroupMember)
                                {
                                    LogWrite $($Boundary.BoundaryGroupMember + " boundary group already exists.") -DisplayConsole Yes -TextColor Green
                                    $CurBoundaryGroupResult = $true
                                }
                            else
                                {
                                    LogWrite $($Boundary.BoundaryGroupMember + " boundary group does NOT already exist.") -DisplayConsole Yes
                                    Create-Boundary-Group -BoundaryGroupName $Boundary.BoundaryGroupMember -OutVariable CurBoundaryGroupResult | Out-Null
                                }

                            if($CurBoundaryGroupResult)
                                {
                                    if(!(Check-Boundary-Members -BoundaryGroupName $Boundary.BoundaryGroupMember -BoundaryName $Boundary.BoundarySubnet))
                                        {
                                            LogWrite $("Adding subnet " + $Boundary.BoundarySubnet + " to boundary group " + $Boundary.BoundaryGroupMember) -DisplayConsole Yes -TextColor Green
                                            Add-CMBoundaryToGroup -BoundaryGroupName $Boundary.BoundaryGroupMember -BoundaryName $Boundary.BoundarySubnet -OutVariable $AddSubnettoBoundaryGroupResult
                                        }
                                    else
                                        {
                                             LogWrite $("Subnet " + $Boundary.BoundarySubnet + " already exists in boundary group " + $Boundary.BoundaryGroupMember) -DisplayConsole Yes -TextColor Green
                                        }                                                           
                                }
                        }
                    else
                        {
                            LogWrite $("No boundary group name provided for subnet " + $Boundary.BoundarySubnet + " , will not add subnet to any boundary group.") -DisplayConsole Yes -TextColor Yellow
                        }
            }
    }
     
   if($error)
    {
        LogWrite "Errors found: $error" -DisplayConsole Yes -TextColor Red
    }
    else
    {
        LogWrite "No Errors found." -DisplayConsole Yes -TextColor Green
    }

#endregion Main
