
InModuleScope "WeaveRegistry" {
    
    Describe "Convert-ReturnCode" {
        Context "Determine Severity of Error" {
            It "Convert Error for Severity Info" {
                $Result = Convert-ReturnCode -CodeSeverity "Info" -Code "Error"
                $Result | Should -Be "Info"
            }
            It "Convert Ok for Severity OK" {
                $Result = Convert-ReturnCode -CodeSeverity "Info" -Code "OK"
                $Result | Should -Be "OK"
            }
            It "Convert Error for Severity Error" {
                $Result = Convert-ReturnCode -CodeSeverity "Error" -Code "Error"
                $Result | Should -Be "Error"
            }
            It "Convert Ok for Severity OK" {
                $Result = Convert-ReturnCode -CodeSeverity "Error" -Code "OK"
                $Result | Should -Be "OK"
            }
        }
    }
}