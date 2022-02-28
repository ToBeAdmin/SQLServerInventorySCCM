<#
	.SYNOPSIS
		PowerShell script for SQL Server Instances Inventory.
        Script get informations about MS SQL Instance and save result in custom WMI class
        Output data : ServerName, InstanceName, ProductName, Version, PatchLevel, Edition
	
	.DESCRIPTION
		Script used by SCCM for create a custom hardware inventory for collect MS SQL Instance
        Data will be saved in custom WMI and SCCM will collect this custom WMI class
        Inventory values : 

        ServerName    InstanceName    ProductName               Version     PatchLevel Edition           PrimaryKey
        ----------    ------------    -----------               -------     ---------- -------           ----------
        ServerName    MSSQL$SQLINT02D Microsoft SQL Server 2016 13.2.5026.0 SP2        Developer Edition          1

	.PARAMETER
		No parameters
	
	.EXAMPLE
		PS C:\> .\ScriptName.ps1
	
	.NOTES
		Version : 1.0
        Author  : BEITONE Jérémy
        Company : Capgemini - Covea Finance
        Creation Date : 21/02/2022
        Purpose/Change : Initial script

#>

[CmdletBinding()] param ()

### Functions List ###
# New-WMIClass : Create custom WMI class
Function New-WMIClass {
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	if ($WMITest -ne $null) {
		$Output = "Deleting " + $Class + " WMI class....."
		Remove-WmiObject $Class
		$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
		if ($WMITest -eq $null) { $Output += "success" } 
        else { $Output += "Failed" ; exit 1 }
		Write-Verbose $Output
	}
	$Output = "Creating " + $Class + " WMI class....."
	$newClass = New-Object System.Management.ManagementClass("root\cimv2", [String]::Empty, $null);
	$newClass["__CLASS"] = $Class;
    $newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("PrimaryKey", [System.Management.CimType]::String, $false)
	$newClass.Properties["PrimaryKey"].Qualifiers.Add("key", $true)
	$newClass.Properties["PrimaryKey"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("InstanceName", [System.Management.CimType]::String, $false)
	$newClass.Properties["InstanceName"].Qualifiers.Add("key", $true)
	$newClass.Properties["InstanceName"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("ProductName", [System.Management.CimType]::String, $false)
	$newClass.Properties["ProductName"].Qualifiers.Add("key", $true)
	$newClass.Properties["ProductName"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("Version", [System.Management.CimType]::String, $false)
	$newClass.Properties["Version"].Qualifiers.Add("key", $true)
	$newClass.Properties["Version"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("PatchLevel", [System.Management.CimType]::String, $false)
	$newClass.Properties["PatchLevel"].Qualifiers.Add("key", $true)
	$newClass.Properties["PatchLevel"].Qualifiers.Add("read", $true)
    $newClass.Properties.Add("Edition", [System.Management.CimType]::String, $false)
	$newClass.Properties["Edition"].Qualifiers.Add("key", $true)
	$newClass.Properties["Edition"].Qualifiers.Add("read", $true)

	$newClass.Put() | Out-Null
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	if ($WMITest -eq $null) { $Output += "success" } 
    else { $Output += "Failed" ; exit 1 }
	Write-Verbose $Output
}
# New-WMIInstance : Create values in custom WMI Class
Function New-WMIInstance {
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][Parameter(Mandatory = $true)][array]$Values,
		[Parameter(Mandatory = $true)][string]$Class
	)
	
	foreach ($Value in $Values) {
		try {
            $Output = "Writing" + [char]32 +$Value.InstanceName + [char]32 + "instance to" + [char]32 + $Class + [char]32 + "class....."
		    $Return = Set-WmiInstance -Class $Class -Arguments @{PrimaryKey = $Value.PrimaryKey; 
                                                                 InstanceName = $Value.InstanceName; 
                                                                 ProductName = $Value.ProductName; 
                                                                 Version = $Value.Version; 
                                                                 PatchLevel = $Value.PatchLevel 
                                                                 Edition = $Value.Edition } -ErrorAction Stop

		    if ($Return -like "*" + $Value.InstanceName + "*") { $Output += "Success" } 
            else { $Output += "Failed" }
		    Write-Verbose $Output
        } catch {
            Write-Verbose "Writing to WMI failed $_"
            return 2
        }
	}
}
# Get-RegistryValue : Get values in Windows Registry
Function Get-RegistryValue {
    # Source : https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/getting-registry-values-and-value-types
    param
    (
        [Parameter(Mandatory = $true)]$RegistryKey
    )

    $key = Get-Item -Path "Registry::$RegistryKey" -ErrorAction SilentlyContinue
    if($key) {
        $Output = "$RegistryKey path exist"
        $key.GetValueNames() |
        ForEach-Object {
            $name = $_
            $rv = 1 | Select-Object -Property Name, Type, Value
            $rv.Name = $name
            $rv.Type = $key.GetValueKind($name)
            $rv.Value = $key.GetValue($name)
            $rv
        }
    }
    else { $Output += "$RegistryKey path not exist" }
    Write-Verbose $Output
}

# End Of Functions List #

#############################################
# MAIN SCRIPT #
#############################################

# Call Get-RegistryValue function and get infos about SQL Instances
$GetSQLInstancesName = Get-RegistryValue -RegistryKey 'HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'

try {
    # If a SQL Instance is present on the computer
    if($GetSQLInstancesName){
        Write-Verbose 'SQL Server instances found'
        
        # Declare name of new custom WMI Class
        $InventoryWMIClass = 'DEMO_SQLServerInventory'
        # Reset counter for PrimaryKey
        $i = 0

        ## Get All SQL Instances Infos
        $results = @() # Create array for output results
        Foreach ($GetSQLInfos in $GetSQLInstancesName){
            $i++ # Increment number for PrimaryKey

            # Get Path of registry SQL instance
            $SQLRegistryPath = $GetSQLInfos.Value 
            # Call Get-RegistryValue for get infos about specific SQL Instance
            $SQLInfos = Get-RegistryValue -RegistryKey "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\$SQLRegistryPath\Setup" 
            $SQLVersion = ($SQLInfos | Where { $_.Name -eq "Version" }).Value
    
            # https://sqlserverbuilds.blogspot.com/
            # Define Product Name of SQL Instance from number version
            # Split string to get first number : Ex 13.2.5026.0 = 13 = Microsoft SQL Server 2016
            switch ( $SQLVersion.Split(".")[0] ) {
                8  { $SQLProductName = 'Microsoft SQL Server 2000' }
                9  { $SQLProductName = 'Microsoft SQL Server 2005' }
                10 { $SQLProductName = 'Microsoft SQL Server 2008' }
                11 { $SQLProductName = 'Microsoft SQL Server 2012' }
                12 { $SQLProductName = 'Microsoft SQL Server 2014' }
                13 { $SQLProductName = 'Microsoft SQL Server 2016' }
                14 { $SQLProductName = 'Microsoft SQL Server 2017' }
                15 { $SQLProductName = 'Microsoft SQL Server 2019' }
            }
    
            # Create Properties with values used by WMI custom class ##
            $Properties = @{
                ServerName   = $env:COMPUTERNAME                                       # ServerName = Name of computer
                InstanceName = "MSSQL`${0}" -f $SQLRegistryPath.Split(".")[1]          # InstanceName = "MSSQL$" + "Name of instance"
                ProductName  = $SQLProductName                                         # ProductName = Product Name 
                Version      =  ($SQLInfos | Where { $_.Name -eq "Version"}).Value     # Version = Version of instance
                PatchLevel   = "SP{0}" -f ($SQLInfos | Where {$_.Name -eq "SP"}).Value # PatchLevel = Service Pack of instance
                Edition      = ($SQLInfos | Where {$_.Name -eq "Edition"}).Value       # Edition = Edition of instance (Standard, Dev, Enterprise..)
                PrimaryKey   = $i                                                      # PrimaryKey = Number incremented for WMI 
            }
            # Create PSObject for Results Array
            $Results += New-Object psobject -Property $properties
        }

        # Display Results Table
        #$Results | Select ServerName,InstanceName,ProductName,Version,PatchLevel,Edition,PrimaryKey | Format-Table -AutoSize

        # Create new WMI custom class for SCCM hardware inventory
        New-WMIClass -Class $InventoryWMIClass #-Verbose
        # Add results to new WMI custom class for SCCM hardware inventory
        New-WMIInstance -Class $InventoryWMIClass -Values $results #-Verbose

        Write-Verbose 'Return 0 to SCCM, to notify compliance script succeeded'
        return 0 # Return 0 for compliance    
    }
    else { Write-Verbose "SQL Server instances not found" ; Write-Verbose 'Return 0 to SCCM, to notify compliance script succeeded' ; return 0 }
}

# Error during script
catch {
    $_
    Write-Verbose 'Return 2 to SCCM, to notify compliance script failed'
    return 2 # Return 2 for non compliance
}