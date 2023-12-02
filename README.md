# PowerShell Registry Management Script

## Overview
This PowerShell script provides functions for managing Windows Registry settings. It includes functions for setting, getting, and comparing registry values.

## Functions

### Expand-String
Expands environment variables in a given string.

### Compare-RegistryPropertyByObject
Compares registry settings based on the provided object.

### Convert-RegistryType
Converts registry value types to human-readable formats.

### Convert-RegistryHive
Converts registry hive names to short format.

### Convert-HexToInteger
Converts registry values based on their types.

### Convert-ReturnCode
Converts return codes based on severity.

### Get-RegistryReferenceValue
Gets the reference value for a registry setting.

### Get-RegistryActualValue
Gets the actual registry value for a given path and property.

### Get-CurrentUser
Retrieves information about the currently logged-in user.

### Set-RegistryPropertyByObject
Sets registry properties based on the provided object.

### Set-Registry
Sets a specific registry property.

### Mount-RegistryHive
Mounts a registry hive from a file to a specified name in the Windows Registry.

### Dismount-RegistryHive
Dismounts a registry hive from the Windows Registry.

### Test-RegistryHiveMounted
Checks if a registry hive is mounted in the Windows Registry.

## Usage
1. Clone the repository.
2. Open a PowerShell console.
3. Import the script using `Import-Module`.

```powershell
Import-Module path\to\RegistryManagementScript.ps1

# Example: Set a registry property
$RegSettings = @{
    "RegPath" = "HKLM:\Software\MyApp"
    "RegProperty" = "Version"
    "RegValue" = "1.0"
    "RegType" = "REG_SZ"
}

Set-Registry @RegSettings
