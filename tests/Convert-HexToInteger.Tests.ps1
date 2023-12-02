
InModuleScope "WeaveRegistry" {
    
    Describe "Convert-HexToInteger" {
        Context "Test Registry Conversion" {
            It "0 Convert-HexToInteger" {
                $Result = Convert-HexToInteger -HexValue 0
                $Result | Should -Be 0
            }
            It "06000000 Convert-HexToInteger" {
                $Result = Convert-HexToInteger -HexValue "06000000"
                $Result | Should -Be "100663296"
            }
            It "00000002 Convert-HexToInteger" {
                $Result = Convert-HexToInteger -HexValue "00000002"
                $Result | Should -Be 2
            }

        }
    } 
}