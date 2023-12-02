
InModuleScope "WeaveRegistry" {

    Describe "Expand-String" {

        BeforeAll {
            $ExpandStringValue = '%USERPROFILE%\Documents'
            $TestVariable = "TestVariable" 
        }

        Context "Environment Variable %userProfile%" {
            
            It "Expands Strings with environment variable" {
                Expand-String -Value $ExpandStringValue -ExpandEnvironmentVariables | Should -Be "$env:USERPROFILE\Documents"  
            }
        }

        Context "No Environment Variable Expansion Required" {
            
            It "Does not expand string without variables" {
                Expand-String -Value "No Expansion Required" -ExpandEnvironmentVariables | Should -Be "No Expansion Required"
            }
        }

        Context "Variable Expansion" {
            
            It "Expands regular PowerShell variable" {
                Expand-String -Value $TestVariable | Should -Be "TestVariable"
            }
        }
    }
}