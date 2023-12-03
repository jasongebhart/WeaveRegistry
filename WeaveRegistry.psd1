@{

    # Script module name
    RootModule = 'WeaveRegistry.psm1'
    
    # Version number 
    ModuleVersion = '1.0'
    
    # ID to uniquely identify module 
    GUID = 'c64ecc4e-f3a3-4ae2-bd22-08d93609ee18'  
    
    # Author
    Author = 'Jason Gebhart'
    
    # Company or vendor  
    CompanyName = 'Vivika'
    
    # Copyright statement
    Copyright = '(c) 2023 MyCompany. All rights reserved.'
    
    # Module description
    Description = 'Custom module for working with the registry.'
    
    # Minimum PowerShell version required
    PowerShellVersion = '5.0'
    
    # Functions to export from the module
    FunctionsToExport = @(
        'ConvertFrom-GPPreferenceXML',
        'Compare-RegistryObject',
        'Set-RegistryPropertyByObject',
        'Set-Registry',
        'Mount-RegistryHive',
        'Dismount-RegistryHive'
        #'Test-RegistryHiveMounted' 
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess  
    PrivateData = @{
    
        PSData = @{
            # Tags to apply to the module 
            Tags = @('Registry', 'String')
    
            # License URI for the module
            LicenseUri = 'https://license.com/MIT'
    
            # URI to latest version 
            ProjectUri = 'https://github.com/jasongebhart/weave/tree/main/WeaveRegistry/' 
    
            # Icon URI         
            IconUri = 'https://github.com/jasongebhart/weave/icon.png'
        } 
    }
    
    }