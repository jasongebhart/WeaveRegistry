
InModuleScope "WeaveRegistry" {
    Describe "Mount-RegistryHive" {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {$true}
            Mock -CommandName Start-Process -MockWith {'The operation completed successfully.'}
            $mountArgs = @{
                Path = 'C:\Users\Default\NTUSER.DAT'
                Name = 'TestHive'
            }   
        }

        Context "Mounting Registry Hive" {
            It "Calls reg.exe to mount hive" {
                $result = Mount-RegistryHive @mountArgs
                $result.Result | Should -Be 'The operation completed successfully.'
                Write-Host "Actual Result: $($result.Result)"
                Should -Invoke Start-Process -Exactly -Times 1 
            }
        }
        

        Context "Parameter Validation" {
            It "Validates hive path parameter before mounting" {
                Mock Test-Path {$false}  
                { Mount-RegistryHive -Path 'InvalidPath' } | Should -Throw
                Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter {
                    $Path -eq 'InvalidPath'
                }
            }
            It "Throws error if registry exe not found" {
                $registryExe = "$env:SystemRoot\system32\reg.exe"
                Mock Test-Path {$false} -ParameterFilter {$Path -eq $registryExe}          
                { Mount-RegistryHive } | Should -Throw
            
            }
        }
        Context " Check Return " {
            It "Returns expected result object" {
               $result = Mount-RegistryHive @mountArgs
                $result.PSObject.TypeNames[0] | Should -Be 'WeaveRegistry.MountResult'       
                $result | Get-Member -MemberType NoteProperty | 
                    Select-Object -ExpandProperty Name | 
                        Should -BeIn 'Command', 'Result', 'Mounted'             
            }
        }
    }
}