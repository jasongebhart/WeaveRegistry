
InModuleScope "WeaveRegistry" {
    
    Describe "Test-RegistryHiveMounted" {
        Context "Test Registry Path" {
            It "Registry Path Exists" {
                Mock -CommandName Test-Path -MockWith {$true}
                $Result = Test-RegistryHiveMounted
                $Result.Mounted  | Should -Be $true
            }
        }
        Context "Test Registry Path" {
            It "Registry Path Exists" {
                Mock -CommandName Test-Path -MockWith {$false}
                $Result = Test-RegistryHiveMounted
                $Result.Mounted  | Should -Be $false
            }
        }
    }
}