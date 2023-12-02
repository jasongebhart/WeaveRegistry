
InModuleScope "WeaveRegistry" {
    
    Describe "Assert-RegistryValuesEqual" {
        BeforeAll {

            $stringCompare = @{
                ActualValue = "Hello"
                ReferenceValue = "Hello"
                RegType = "REG_SZ" 
            }

            $dwordSameValues = @{
                ActualValue = "00000000"
                ReferenceValue = "00000000" 
                RegType = "REG_DWORD"
            }

            $dwordDifferentValues = @{
                ActualValue = 0
                ReferenceValue = "00000000"
                RegType = "REG_DWORD"
            } 

        }
        Context "Compare Registry to Reference" {
            It "Compare String Values" {
                $Result = Assert-RegistryValuesEqual @StringCompare
                $Result | Should -Be "OK"
            }
        }
        Context "Compare Registry to Reference" {
            It "Compare String Values" {
                $Result = Assert-RegistryValuesEqual @dwordSameValues 
                $Result | Should -Be "Error"
            }


            It "Returns OK when DWORD actual value is 0 and matches reference" {
                $Result = Assert-RegistryValuesEqual @dwordDifferentValues 
                $Result | Should -Be "OK"
            }
        }
    }
}