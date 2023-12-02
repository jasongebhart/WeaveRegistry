
InModuleScope "WeaveRegistry" {
    
    Describe "Get-RegistryReferenceValue" {
        BeforeAll {
            $RegSettings = @{
                "RegType" = "REG_DWORD"
                "RegValue" = "00000000"
            }

            $ExpandStringSettings = @{
                "RegType" = "REG_EXPAND_SZ"
                "RegValue" = "%PUBLIC%\Desktop"
           }
        $BinaryValue = "24,00,00,00,33,28,00,00,00,00,00,00,00,00,00,00,00,00,00,00,01,00,00,00,13,00,00,00,00,00,00,00,62,00,00,00"
           $BinarySettings = @{
                "RegType" = "REG_BINARY"
                "RegValue" = $BinaryValue
            }
        }
        Context "Test Registry Conversion" {
            It "DWORD Get-RegistryReferenceValue " {
                $Result = Get-RegistryReferenceValue @RegSettings
                $Result | Should -Be 0
            }

            It "Expand String Get-RegistryReferenceValue " {
                $Result = Get-RegistryReferenceValue  @ExpandStringSettings
                $Result | Should -Be "C:\Users\Public\Desktop"
            }

            It "Binary Get-RegistryReferenceValue " {
                $BinaryValue = "24,00,00,00,33,28,00,00,00,00,00,00,00,00,00,00,00,00,00,00,01,00,00,00,13,00,00,00,00,00,00,00,62,00,00,00"
                $Result = Get-RegistryReferenceValue  @BinarySettings
                $Result | Should -Be $BinaryValue
            }
        }
    }  
}