
InModuleScope "WeaveRegistry" {
    
    Describe "Convert-RegistryType" {
        Context "Test Type Conversion" {
            It "String Convert-RegistryType" {
                $Result = Convert-RegistryType -RegType REG_SZ
                $Result | Should -Be "String"
            }
            It "REG_EXPAND_SZ Convert-RegistryType" {
                $Result = Convert-RegistryType -RegType REG_EXPAND_SZ
                $Result | Should -Be "ExpandString"
            }
            It "REG_DWORD Convert-RegistryType" {
                $Result = Convert-RegistryType -RegType REG_DWORD
                $Result | Should -Be "DWORD"
            }
        }
    }      
}