<#
.Synopsis 
Windows Registry module. 

.Description
This PowerShell script provides functions for managing Windows Registry settings. 
It includes functions for setting, getting, and comparing registry values.

#>

function Expand-String {
    <#
    .SYNOPSIS
    Expands environment variables and PowerShell variables in a given string.

    .DESCRIPTION
    This function takes a string as input and expands any environment variables or
    PowerShell variables present in the string. It provides an option to expand only
    environment variables using the -ExpandEnvironmentVariables switch.

    .PARAMETER Value
    Specifies the string to be expanded.

    .PARAMETER ExpandEnvironmentVariables
    Indicates whether to expand only environment variables. By default, both
    environment and PowerShell variables are expanded.

    .EXAMPLE
    Expand-String -Value "Hello, $env:USERNAME!"
    Expands the username environment variable in the string.

    .EXAMPLE
    Expand-String -Value "Hello, $env:USERNAME!" -ExpandEnvironmentVariables
    Expands only the environment variable in the string.

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]  
        [string]$Value,

        [Parameter()]
        [switch]$ExpandEnvironmentVariables
    )

    try {
        if ($ExpandEnvironmentVariables) {
            $expandedValue = [Environment]::ExpandEnvironmentVariables($Value)
            Write-Verbose "[$($MyInvocation.MyCommand)] - Expanded Environment Value: $expandedValue"
        }
        else {
            $expandedValue = $ExecutionContext.InvokeCommand.ExpandString($Value)
            Write-Verbose "[$($MyInvocation.MyCommand)] - Expanded Value: $expandedValue"
        }

        $expandedValue
    } catch {
        Write-Error "An error occurred while expanding the string: $_"
        throw $_
    }
}

Function Compare-RegistryPropertyByObject {
    <#
    .SYNOPSIS
    Compares registry properties based on the provided settings.

    .DESCRIPTION
    This function compares registry properties using settings provided through the pipeline. 
    It standardizes registry hive and key path names, retrieves the actual and reference values, and performs a comparison.

    .PARAMETER RegSettings
    Specifies the registry settings to be compared. This parameter accepts an object with properties
    such as Hive, Name, Path, Type, Value, and Code.

    .OUTPUTS
    Returns an array of custom objects with properties: Name, Code, Type, ActualValue, TargetValue, and RegistryPath.

    .EXAMPLE
    # Custom PSObject example
    $Settings = @{
        Name = 'TestProperty'
        Path = 'HKLM:\SOFTWARE\Test'
        Type = 'REG_SZ'
        Value = 'TestValue'
        Code = 'Info'
    }

    # GPP Object from XML example
    $Settings = @{
        Hive = 'HKEY_LOCAL_MACHINE'
        Name = 'TestProperty'
        Path = 'Software\Test'
        Type = 'REG_SZ'
        Value = 'TestValue'
        Code = 'Injfo'
    }

    $Settings | Compare-RegistryPropertyByObject
    # Compares the specified registry property using the provided settings.

    .NOTES
    This code handles custom PowerShell objects and accommodates XML objects created by exporting a GPO preference. 

    GPO preference XML Objects 
    may have a HIVE value that requires conversion to short format (e.g., HKEY_LOCAL_MACHINE to HKLM:).
    The key path is defined separately from the hive and needs to be joined. 

    Other registry objects already use short naming (HKLM:) with the key Path already merged, requiring no conversion.
    #>
  [Cmdletbinding()]
    param (
    [Parameter(Position=0,Mandatory=$true,ValueFromPipeline = $true)]
        $RegSettings
    )
    Begin 
    { 
         $Results = @()
    }
    
    Process {
        foreach ($setting in $RegSettings) {
            $Hive = $setting.hive
            $RegProperty = $setting.name
            $RegPath = $setting.path
            $RegType = $setting.type
            $RegValue = $setting.Value
            $CodeSeverity = $setting.code

            If ($Hive) {
                $Shorthive = Convert-RegistryHive -HiveFullName $hive
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Hive: $hive"
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] - short Hive $Shorthive"

                switch ($Shorthive) {
                    "HKU:"
                     {
                        $PSHiveName = "HKU"
                        If (-not(Get-PSDrive -Name $PSHiveName -ea SilentlyContinue)) {
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Drive $PSHiveName does not exist"
                            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Mapping Drive $hive"
                            New-PSDrive -PSProvider Registry -Name $PSHiveName -Root $hive | Out-null
                            If (-not(Test-Path -Path $Shorthive)) {
                                Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Drive $Shorthive still does not exist"
                            }
                        }
                     }
                    "HKCR:"
                     {
                        $PSHiveName = "HKCR"
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Mapping Drive to $hive"
                        If (-not(Test-Path -Path $Shorthive)) {
                            New-PSDrive -PSProvider Registry -Name $PSHiveName -Root $hive | Out-Null
                        }
                     }
                    Default 
                    {
                    }
                }             
                If(Test-Path -Path $Shorthive) {
                    $RegPath = Join-path -path $Shorthive -ChildPath $setting.key
                } else {
                    Write-Verbose -Message "[$($MyInvocation.MyCommand)] - path is unavailable $Shorthive"
                }
            } 

            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Registry Set Start-------------"
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Property: $RegProperty"
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Value: $RegValue"
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Hive: $Hive"
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Registry Path: $RegPath"
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Getting Current registry value" 
            $RegistrySettings = @{
                "RegPath" = $RegPath
                "RegProperty" = $RegProperty
                "RegValue" = $RegValue
                "RegType" = $RegType
            }
            $ActualValue = Get-RegistryActualValue @RegistrySettings
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Convert and Return Reference value"
            $RegistrySettings = @{
                "RegType" = $RegType
                "RegValue" = $RegValue
            }
            $ReferenceValue = Get-RegistryReferenceValue @RegistrySettings

            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Compare Actual and Reference Values"
            $CompareLookup = @{
                ActualValue = $ActualValue
                ReferenceValue = $ReferenceValue
                RegType = $RegType
            }
            $Code = Assert-RegistryValuesEqual @CompareLookup -Verbose

            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Lookup Definition of Code Severity and Translate comparison"
            $ConvertedCode = Convert-ReturnCode -CodeSeverity $CodeSeverity -Code $Code
            $Results += [pscustomobject]@{ 
                Name = $RegProperty
                Code = $ConvertedCode | Out-String
                Type = $RegType
                ActualValue = $ActualValue
                TargetValue = $ReferenceValue
                RegistryPath = $RegPath
            }
       }
    }
    end 
    {            
        $Results
    }
}
Function Assert-RegistryValuesEqual {
    <#
    .SYNOPSIS
    Compares the actual registry value to a reference value, considering the registry data type.

    .DESCRIPTION
    This function compares the actual registry value to a reference value, taking into account the registry data type.
    It can handle different registry data types and convert values if necessary.

    .PARAMETER ActualValue
    Specifies the actual registry value to be compared. This parameter accepts any valid registry value.

    .PARAMETER ReferenceValue
    Specifies the reference value for comparison. If not provided or set to 0, it defaults to "Blank."

    .PARAMETER RegType
    Specifies the registry data type. If not provided, it defaults to "Null."

    .OUTPUTS
    Returns a code indicating the result of the comparison: "OK" if the values match, "Error" otherwise.

    .EXAMPLE
    Assert-RegistryValuesEqual -ActualValue "123" -ReferenceValue "123" -RegType "REG_SZ"
    # Compares the specified registry values with the given data type.

    .NOTES
    This function handles different registry data types, including REG_DWORD, and performs conversions if necessary.
    #>
    [cmdletbinding()]
    param (
        [Parameter(Position=0, Mandatory=$false, ValueFromPipeline = $true, HelpMessage = "Specifies the actual registry value.")]
        $ActualValue = $null,

        [Parameter(Position=1, Mandatory=$false, ValueFromPipeline = $true, HelpMessage = "Specifies the reference value for comparison.")]
        $ReferenceValue = $null,

        [Parameter(Position=2, Mandatory=$false, ValueFromPipeline = $true, HelpMessage = "Specifies the registry data type.")]
        $RegType = $null
    )
    Begin 
    {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Actual Registry Value: $($ActualValue ?? 'Null')"
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Reference Value: $($ReferenceValue ?? 'Null')"
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - RegType: $($RegType ?? 'Null')"
    }
    Process 
    {
        $ReferenceValue = if (-not $ReferenceValue -and $ReferenceValue -ne 0) { "Blank" } else { $ReferenceValue }
        $ActualValue = if (-not $ActualValue -and $ActualValue -ne 0) { "Blank" } else { $ActualValue }

        if ($RegType -eq 'REG_DWORD' -and $ReferenceValue -ne "Blank") {
            $ReferenceValue = [Convert]::ToInt32($ReferenceValue, 16)
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Lookup Value Converted (ToInt32(16)): $ReferenceValue"
        }

        $Code = if ($ActualValue -eq $ReferenceValue) { "OK" } else { "Error" }
    }
    end 
    {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Code: $Code"
        $Code
    }
}


Function Convert-RegistryType {
    <#
    .SYNOPSIS
    Converts and normalizes registry types.

    .DESCRIPTION
    This function takes a registry type as input and converts it to a normalized type. 
    Supported registry types include REG_SZ, REG_EXPAND_SZ, and REG_DWORD.

    DWORD: Stands for "Double Word." It is a data type that represents a 32-bit unsigned integer in computing.
    In the Windows registry, DWORD values are often used to store numerical data, such as configuration settings or parameters.

    REG_DWORD: Stands for "Registry Double Word." This is the naming convention used in the Windows registry itself.
    When you see "REG_DWORD" in the context of registry entries, it indicates a 32-bit numeric value.

    .PARAMETER RegType
    Specifies the registry type to be converted.

    .PARAMETER RegValue
    Specifies the registry to be converted.

    .EXAMPLE
    Convert-RegistryValueType -RegType REG_SZ
    Converts REG_SZ registry type to 'String'.

    .EXAMPLE
    Convert-RegistryValueType -RegType REG_EXPAND_SZ
    Converts REG_EXPAND_SZ registry type to 'ExpandString'.

    .EXAMPLE
    Convert-RegistryValueType -RegType REG_DWORD
    Converts REG_DWORD registry type to 'DWORD'.

    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('REG_SZ', 'REG_EXPAND_SZ', 'REG_DWORD', 'REG_BINARY', 'REG_MULTI_SZ', 'REG_QWORD')]
        $RegType
    )

    Process {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Registry Type: $RegType"

        $TypeMapping = @{
            'REG_SZ'        = 'String'
            'REG_EXPAND_SZ' = 'ExpandString'
            'REG_DWORD'     = 'DWORD'
        }

        $NormalizedType = $TypeMapping[$RegType]
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Converted Registry Type: $NormalizedType"

        $NormalizedType
    }
}
Function Convert-RegistryHive {
    <#
    .SYNOPSIS
    Converts a registry hive full name to its abbreviated form.

    .DESCRIPTION
    Convert-RegistryHive converts a registry hive full name to its abbreviated form.

    .PARAMETER HiveFullName
    Specifies the full name of the registry hive. Valid values are "HKEY_CURRENT_USER", "HKEY_LOCAL_MACHINE", "HKEY_USERS", and "HKEY_CLASSES_ROOT".

    .EXAMPLE
    Convert-RegistryHive -HiveFullName "HKEY_LOCAL_MACHINE"
    Returns "HKLM:"

    .NOTES

    #>

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$false, ValueFromPipeline = $true)]
        [ValidateSet("HKEY_CURRENT_USER", "HKEY_LOCAL_MACHINE", "HKEY_USERS", "HKEY_CLASSES_ROOT")]
        $HiveFullName = "HKEY_LOCAL_MACHINE"
    )

    Begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Registry Hive from XML entry: $HiveFullName"
    }

    Process {
        switch ($HiveFullName) {
            HKEY_CURRENT_USER {
                $hive = "HKCU:"
            }
            HKEY_LOCAL_MACHINE {
                $hive = "HKLM:"
            }
            HKEY_USERS {
                $hive = "HKU:"
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] - $hive"
            }
            HKEY_CLASSES_ROOT {
                $hive = "HKCR:"
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] - $hive"
            }
            Default {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Hive not found"
                $hive = $null
            }
        }
    }

    End {
        $hive
    }
}


Function Convert-HexToInteger {
    <#
    .SYNOPSIS
        Converts hexadecimal values to integer format.

    .DESCRIPTION
        This function is designed to convert hexadecimal values to their integer equivalents.

    .PARAMETER HexValue
        Specifies the hexadecimal value to be converted.

    .NOTES
        File Name      : Convert-HexToInteger.ps1
        Prerequisite   : PowerShell V2

        A leading "0x" is often used to indicate that a number is in hexadecimal (base-16) format. 
        However, when reading the value from the regitry the response may omit the "0x" prefix.

    .EXAMPLE
        Convert-HexToInteger -HexValue "0x06000000"
        Converts the hexadecimal value "0x06000000" to its integer equivalent.

        Convert-HexToInteger -HexValue "06000000"
        Converts the hexadecimal value "06000000" to its integer equivalent.

    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("HexRegistryValue")]
        $HexValue
    )
    Begin {
    }
    Process {
        Write-Verbose "[$($MyInvocation.MyCommand)] - Converting hexadecimal value to integer."     
        try {
            $IntegerValue = [Convert]::ToInt32($HexValue, 16)
            Write-Verbose "[$($MyInvocation.MyCommand)] - Converted Integer Value: $IntegerValue"
        } catch {
            Write-Warning "Failed to convert the hexadecimal value to integer: $_"
        }
    }

    End {
        $IntegerValue
    }
}

Function Convert-ReturnCode {
    <#
    .SYNOPSIS
    Converts a raw return code into a more meaningful format based on severity levels.

    .DESCRIPTION
    This function converts raw return codes into more meaningful and actionable content, 
    allowing for better interpretation of the severity of an error or informational message.

    .PARAMETER CodeSeverity
    Specifies the severity level for interpreting the return code. 
    Acceptable values are "OK," "Error," "Info," or any custom code.

    .PARAMETER Code
    Specifies the raw return code that needs to be converted.

    .OUTPUTS
    Returns a converted code indicating the severity level: "OK" for success, "Error" for errors, "Info" for informational messages, 
    or the original code for custom scenarios.

    .EXAMPLE
    Convert-ReturnCode -CodeSeverity "Error" -Code "OK"
    # Converts the raw return code "OK" with severity level "Error" into a more meaningful format.

    .NOTES
    This function is useful for standardizing return codes and providing a clearer understanding of the result's severity level.
    Code severity is defined on some objects to determine the severity of the error message.
    If "OK" is defined, then any result is considered OK.
    If "Error" is defined, it reports either "Error" or "OK" based on the code.
    "Info" is defined; any errors are considered informational only.
    If the code is not defined, it reports the error with no filtering.
    #>
    [cmdletbinding()]
    param (
        [Parameter(Position=0, Mandatory=$false, ValueFromPipeline = $true, HelpMessage = "Specifies the severity level for interpreting the return code.")]
        [ValidateSet("Error", "Info")]
        $CodeSeverity = "Error",

        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline = $true, HelpMessage = "Specifies the raw return code that needs to be converted.")]
        [ValidateSet("OK", "Error")]
        $Code
    )
    Begin {}
    Process 
    {
        switch ($CodeSeverity) {
            "Info" {
                $ConvertedCode = if ($Code -eq "OK") { "OK" } else { "Info" }
            }
            default {
                $ConvertedCode = $Code
            }
        }
    }
    end 
    {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Converted Code: $ConvertedCode"
        $ConvertedCode
    }
}

Function Get-RegistryReferenceValue {
    <#
    .SYNOPSIS
    This function retrieves a registry value based on the specified registry type.

    .DESCRIPTION
    Get-RegistryReferenceValue retrieves a registry value based on the specified registry type.
    
    .PARAMETER RegType
    Specifies the registry type.

    .PARAMETER RegValue
    Specifies the registry value.

    .EXAMPLE
    Get-RegistryReferenceValue -RegType 'REG_SZ' -RegValue 'SampleValue'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$false, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('REG_SZ', 'REG_EXPAND_SZ', 'REG_DWORD', 'REG_BINARY')]
        [string]$RegType = $null,

        [Parameter(Position=1, Mandatory=$false, ValueFromPipelineByPropertyName = $true)]
        [string]$RegValue = $null
    )

    Begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Registry Type: $RegType"
        if ($RegValue) {
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Lookup Value Type: $($RegValue.GetType())"
        } else {
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Value Type: Null"
        }
    }

    Process {
        try {
            $ReferenceValue = switch ($RegType) {
                ('REG_SZ', 'REG_DWORD', 'REG_BINARY') {
                    $RegValue
                }
                'REG_EXPAND_SZ' {
                    if ($RegValue -like '*%*') {
                        Expand-String $RegValue -ExpandEnvironmentVariables
                    } else {
                        Expand-String $RegValue
                    }
                }
                default {
                    $RegValue
                }
            }
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Lookup Value: $ReferenceValue"
        } catch {
            Write-Error -Message "Error retrieving registry value: $_"
            $ReferenceValue = $null
        }
    }

    End {
        $ReferenceValue
    }
}
function Get-RegistryActualValue {
    <#
    .SYNOPSIS
        Retrieves the actual value of a registry entry.

    .DESCRIPTION
        The Get-RegistryActualValue function retrieves the actual value of a registry entry based on the specified registry path, property, value, and type.
        It supports different registry value types, including REG_SZ, REG_EXPAND_SZ, REG_DWORD, and REG_BINARY.

    .PARAMETER RegPath
        Specifies the path of the registry entry.

    .PARAMETER RegProperty
        Specifies the name of the registry property to retrieve.

    .PARAMETER RegValue
        Specifies an optional registry value to consider.

    .PARAMETER RegType
        Specifies the type of the registry value.

    .EXAMPLE
        Get-RegistryActualValue -RegPath "HKLM:\Software\MyApp" -RegProperty "Version" -RegType "REG_SZ"
        Retrieves the actual value of the "Version" registry property in the "HKLM:\Software\MyApp" registry path.

    #>
    [cmdletbinding()]
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName = $true)]
        [string]$RegPath,

        [Parameter(Position=1, Mandatory=$true, ValueFromPipelineByPropertyName = $true)]
        [string]$RegProperty,

        [Parameter(Position=2, Mandatory=$false, ValueFromPipelineByPropertyName = $true)]
        [string]$RegValue = $null,

        [Parameter(Position=3, Mandatory=$false, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("REG_SZ", "REG_EXPAND_SZ", "REG_DWORD", "REG_BINARY")]
        [string]$RegType = $null
    )

    Begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Registry Type: $RegType"
        If ($RegValue) {
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Lookup Value Type: $($RegValue.GetType())"
        }
    }

    Process {
        Switch ($RegType) {
            REG_SZ {
                $ActualValue = (Get-ItemProperty -Path $RegPath -name $RegProperty -ErrorAction SilentlyContinue).$RegProperty
            }
            REG_EXPAND_SZ {
                $key = Get-Item -Path $RegPath
                $ActualValue = $key.GetValue($RegProperty, $null, 'DoNotExpandEnvironmentNames')
            }
            REG_DWORD {
                $ActualValue = (Get-ItemProperty -Path $RegPath -name $RegProperty -ErrorAction SilentlyContinue).$RegProperty
            }
            REG_BINARY {
                $ActualArray = (Get-ItemProperty -Path $RegPath -name $RegProperty -ErrorAction SilentlyContinue).$RegProperty
                $valuelist = ""
                Foreach ($item in $ActualArray) {
                    If ((measure-object -InputObject $item -Character).Characters -lt 2) {
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - (measure-object -InputObject $item -Character).Characters"
                        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Adding preceding zero"
                        $valuelist += "0"
                    }
                    $valuelist += '{0:x}' -f $item
                }
                $ActualValue = $valuelist
            }
            Default {
                $ActualValue = (Get-ItemProperty -Path $RegPath -name $RegProperty -ErrorAction SilentlyContinue).$RegProperty
            }
        }
    }

    end {
        $ActualValue
    }
}


function ConvertFrom-GPPreferenceXML {
    <#
    .SYNOPSIS
    Retrieves registry settings from an XML file.

    .DESCRIPTION
    This function parses an XML file containing registry settings and returns the settings as objects.

    .PARAMETER XML
    Specifies the path to the XML file containing registry settings.

    .EXAMPLE
    PS C:\> ConvertFrom-GPPreferenceXML -XML "Path\To\Your\Custom.xml"
    Retrieves registry settings from the specified XML file.

    .NOTES
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline = $true)]
        [string]$XML
    )    
    try {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - XML: $XML"
        $XMLDoc = [xml](Get-Content -Path $XML)
        $Registry = $XMLDoc.SelectNodes('//Collection/Registry/Properties')

        $Results = foreach ($prop in $Registry) {
            $value = $prop.value

            [PSCustomObject]@{
                Action         = $prop.action
                Hive           = $prop.hive
                Key            = $prop.key
                Name           = $prop.name
                Default        = $prop.default
                Type           = $prop.type
                Method         = $prop.method
                DisplayDecimal = $prop.displayDecimal
                Value          = $value
            }
        }

        $Results
    } catch {
        Write-Error -Message "Failed to parse XML: $_"
    }
}

function Get-CurrentUser {
    <#
    .SYNOPSIS
    Retrieves information about the currently logged-in user.

    .DESCRIPTION
    This function queries the registry to obtain information about the currently logged-in user,
    including the username and registry hive associated with the user.

    .OUTPUTS
    Returns a custom object with properties UserName and Hive.

    .EXAMPLE
    PS C:\> Get-CurrentUser
    Retrieves information about the currently logged-in user.

    .NOTES

    #>
    [Cmdletbinding()]
    param() 
    $Path = 'registry::hkey_users\*\Volatile*'
    $Hive = Split-Path -Parent (Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | 
            Select-Object -ExpandProperty Name)
    $UserName = (Get-ItemProperty -Path $Path -Name Username -ErrorAction SilentlyContinue).Username

    if ($Hive) {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Current User: $UserName"
        $Result = [pscustomobject]@{
            UserName = $UserName
            Hive = $Hive
        }
    } else {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Current User: Not Found"
        $Result = [pscustomobject]@{
            UserName = "Not Found"
            Hive = $null
        }
    }
    $Result
}

function Set-RegistryPropertyByObject {
    <#
    .SYNOPSIS
        Sets registry properties based on a collection of registry settings.

    .DESCRIPTION
        The Set-RegistryPropertyByObject function allows you to set registry properties based on a collection of registry settings.
        The registry settings are provided as objects containing information such as hive, registry key path, property name, value, and type.
        This function is useful for bulk registry configuration tasks.

    .PARAMETER RegSettings
        Specifies a collection of objects containing registry settings. Each object should have properties such as hive, key, name, value, and type.

    .EXAMPLE
        $RegistrySettings = @(
            [PSCustomObject]@{
                hive      = "HKEY_LOCAL_MACHINE"
                key       = "Software\MyApp"
                name      = "Version"
                value     = "1.0"
                type      = "REG_SZ"
            },
            [PSCustomObject]@{
                hive      = "HKCU:"
                key       = "Software\MyApp"
                name      = "Settings"
                value     = "Enabled"
                type      = "REG_SZ"
            }
        )

        Set-RegistryPropertyByObject -RegSettings $RegistrySettings
        Sets registry properties based on the specified registry settings.

    .NOTES

    .LINK
    #>
    [cmdletbinding()]
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)]
        [array]$RegSettings
    )

    Begin {}

    Process {
        foreach ($setting in $RegSettings) {
            $hive = $setting.hive
            $RegProperty = $setting.name
            $RegPath = $setting.path
            $RegType = $setting.type
            $RegValue = $setting.Value

            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Registry Set Start-------------"

            # Standardize Hive and Key Path 
            # ... (rest of your code)

            If ($RegType -eq 'REG_DWORD'){
                $RegValue = Convert-HexToInteger -HexValue $RegValue
            } 
            $RegType = Convert-RegistryType -RegType $RegType

            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - RegValue: $RegValue"
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - RegType: $RegType"             

            $RegSettings = @{
                "RegPath" = $RegPath
                "RegProperty" = $RegProperty
                "RegValue" = $RegValue
                "RegType" = $RegType
            }
            Set-Registry @RegSettings
        }
    }
    end {}
}

Function Set-Registry {
    <#
    .SYNOPSIS
    Sets a value in the Windows Registry.

    .DESCRIPTION
    Set-Registry sets a value in the Windows Registry.

    .PARAMETER RegPath
    Specifies the registry path where the value will be set.

    .PARAMETER RegProperty
    Specifies the name of the registry property to set.

    .PARAMETER RegValue
    Specifies the value to set in the registry. This parameter is optional.

    .PARAMETER RegType
    Specifies the type of the registry value.

    .EXAMPLE
    Set-Registry -RegPath "HKLM:\Software\MyApp" -RegProperty "Version" -RegValue "1.0" -RegType "String"
    Sets the registry value "Version" to "1.0" in the "HKLM:\Software\MyApp" registry path.

    .NOTES
    .LINK
    #>
    [cmdletbinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName = $true)]
        [string]$RegPath,

        [Parameter(Position=1, Mandatory=$true, ValueFromPipelineByPropertyName = $true)]
        [string]$RegProperty,

        [Parameter(Position=2, Mandatory=$false, ValueFromPipelineByPropertyName = $true)]
        [string]$RegValue,

        [Parameter(Position=3, Mandatory=$true, ValueFromPipelineByPropertyName = $true)]
        [string]$RegType
    )

    Begin {}

    Process {
        Write-Verbose "[$($MyInvocation.MyCommand)] - Registry Set Start-------------"
        Write-Verbose "[$($MyInvocation.MyCommand)] - Registry Path: $RegPath"
        Write-Verbose "[$($MyInvocation.MyCommand)] - Registry Property: $RegProperty"
        Write-Verbose "[$($MyInvocation.MyCommand)] - Registry Value: $RegValue"
        Write-Verbose "[$($MyInvocation.MyCommand)] - Registry Type: $RegType"

        If (-not(Test-Path -Path $RegPath)) {
            Write-Verbose "[$($MyInvocation.MyCommand)] - Creating registry path: $RegPath"
            New-Item -Path $RegPath -Force
        } else {
            Write-Verbose "[$($MyInvocation.MyCommand)] - Path already exists: $RegPath"
        }

        If ($PSCmdlet.ShouldProcess("Setting $RegProperty in the Registry")) {
            $parameters = @{
                Path        = $RegPath
                Name        = $RegProperty
                Value       = $RegValue
                Type        = $RegType
                ErrorAction = "Stop" # Change to "Stop" for more detailed error messages
            }
            try {
                Write-Verbose "[$($MyInvocation.MyCommand)] - Setting registry property: $RegProperty"
                Set-ItemProperty @parameters
            } catch {
                Write-Error "Failed to set registry property: $_"
                throw $_
            }
        } else {
            Write-Verbose "[$($MyInvocation.MyCommand)] - Setting $RegProperty in the Registry skipped."
        }
    }

    End {}
}

Function Test-RegistryHiveMounted {
    <#
    .SYNOPSIS
    Checks if a registry hive is mounted in the Windows Registry.

    .DESCRIPTION
    Test-RegistryHiveMounted checks if a registry hive is mounted in the Windows Registry.

    .PARAMETER Name
    Specifies the name of the registry hive to check. Default is "TestHive".

    .EXAMPLE
    Test-RegistryHiveMounted -Name "CustomHive"
    Checks if the "CustomHive" registry hive is mounted.

    .NOTES
    .LINK

    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Name = "TestHive"
    )

    Process {
        $Mounted = Test-Path -Path "HKLM:\$Name"
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Path: HKLM:\$Name $($('Does Not', 'Exists')[$Mounted])"
        [pscustomobject] @{
            Name    = $Name
            Mounted = $Mounted
        }
    }
}


function Mount-RegistryHive {
    <#
    .SYNOPSIS
    Mounts a registry hive from a file to a specified name in the Windows Registry.

    .DESCRIPTION
    Mount-RegistryHive mounts a registry hive from a file to a specified name in the Windows Registry.

    .PARAMETER Path
    Specifies the path to the registry hive file to mount. Default is "C:\users\Default\NTUSER.DAT".

    .PARAMETER Name
    Specifies the name to use for the mounted registry hive. Default is "TestHive".

    .EXAMPLE
    Mount-RegistryHive -Path "C:\path\to\custom.hive" -Name "CustomHive"
    Mounts the custom hive file at "C:\path\to\custom.hive" with the name "CustomHive" in the Windows Registry.

    .NOTES

    .LINK
    #>
    [Cmdletbinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateScript({Test-Path $_})]
        [string]$Path = "C:\users\Default\NTUSER.DAT",

        [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Name = "TestHive"
    )

    Begin {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Mounting Registry $Path to $Name -------------"
        $RegistryPath = Join-Path -Path "HKLM\" -ChildPath $Name
        $Command = "$env:SystemRoot\system32\reg.exe"
        if (-not (Test-Path $Command)) {
            throw "The 'reg.exe' executable was not found in the expected location."
        }
        $Arguments = "load", $RegistryPath, $Path
    }

    Process {
        if ($PSCmdlet.ShouldProcess("Loading $Path into Registry")) {
            $Result = Start-Process -FilePath $Command -ArgumentList $Arguments
            if ($Result) {
                $Result = ($Result | Select-String -Pattern "successfully")[0]
            }
        }
    }

    End {
        $result = [PSCustomObject]@{
            Command = $Command 
            Result = $Result
            Mounted = (Test-RegistryHiveMounted -Name $Name).Mounted
        }
        $result.PSObject.TypeNames.Insert(0, 'WeaveRegistry.MountResult')
        $result
    }
}

Function Dismount-RegistryHive {
    <#
    .SYNOPSIS
    Dismounts a registry hive from the Windows Registry.

    .DESCRIPTION
    Dismount-RegistryHive dismounts a registry hive from the Windows Registry.

    .PARAMETER Hive
    Specifies the name of the registry hive to dismount. Default is "TestHive".

    .EXAMPLE
    Dismount-RegistryHive -Hive "CustomHive"
    Dismounts the registry hive with the name "CustomHive" from the Windows Registry.

    .NOTES
    #>
    [Cmdletbinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Position=0, Mandatory=$false, ValueFromPipeline = $true)]
        [string]$Hive = "TestHive"
    )

    Begin {
        $Registrypath = "HKLM\$Hive"
        $Command = "$env:SystemRoot\system32\reg.exe"
        $Arguments = @(
            "unload"
            $Registrypath
        )
        $Result = "Reg.exe - Did not run"
    }

    Process {
        If (Test-Path -Path HKLM:\$Hive) {	
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Registry Hive: HKLM:\$Hive EXISTS"
            If (Test-Path -Path $Command) {
                If ($PSCmdlet.ShouldProcess("Unloading $Registrypath from Registry")) {
                    $Result = reg.exe $Arguments | Out-String
                }
            } else { Write-Verbose -Message "[$($MyInvocation.MyCommand)] - $Command - Not Found"}
        } 
    }

    End {
        [pscustomobject] @{
            Command = $Command
            Result = $Result
            Mounted = (Test-RegistryHiveMounted -Name $Hive).Mounted
        }
    }
}