
InModuleScope "WeaveRegistry" {
    
    Describe "Convert-RegistryHive" {
        Context "Convert Registry Hive" {
            It "HKEY_LOCAL_MACHINE" {
                $Result = Convert-RegistryHive -HiveFullName HKEY_LOCAL_MACHINE
                $Result | Should -Be "HKLM:"
            }
            It "HKEY_CURRENT_USER" {
                $Result = Convert-RegistryHive -HiveFullName HKEY_CURRENT_USER
                $Result | Should -Be "HKCU:"
            }
            It "HKEY_USERS" {
                $Result = Convert-RegistryHive -HiveFullName HKEY_USERS
                $Result | Should -Be "HKU:"
            }
            It "HKEY_CLASSES_ROOT" {
                $Result = Convert-RegistryHive -HiveFullName HKEY_CLASSES_ROOT
                $Result | Should -Be "HKCR:"
            }
        }
    }
}