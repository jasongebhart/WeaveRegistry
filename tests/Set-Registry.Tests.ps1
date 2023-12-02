
InModuleScope "WeaveRegistry" {
    
    Describe "Set-Registry" {
        BeforeAll {
            $RegSettings = @{
                "RegPath" = "HKLM:\SOFTWARE\weave"
                "RegProperty" = "test"
                "RegValue" = "00000000"
                "RegType" = "DWORD"
            }
        }
    
        Context "Test Writing to Registry - Registry Path Exists" {
            It "Calls New-ItemProperty" {
                Mock 'Test-Path' -MockWith {$true}
                Mock 'Set-ItemProperty' -MockWith {}
    
                $Result = Set-Registry @RegSettings -Verbose
    
                Assert-MockCalled 'Set-ItemProperty' -Exactly 1 -Scope It
            }
        }
    
        Context "Test Writing to Registry - Registry Path Does Not Exist" {
            It "Calls New-Item" {
                Mock 'Test-Path' -MockWith {$false}
                Mock 'New-Item' -MockWith {}
                Mock 'Set-ItemProperty' -MockWith {}
    
                $Result = Set-Registry @RegSettings -Verbose
    
                Assert-MockCalled 'Set-ItemProperty' -Exactly 1 -Scope It
                Assert-MockCalled 'New-Item' -Exactly 1 -Scope It
            }
        }
    }
    
}