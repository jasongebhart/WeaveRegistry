
InModuleScope "WeaveRegistry" {
    Describe "Dismount-RegistryHive" {
        BeforeAll {
            $MountTest = [pscustomobject] @{
                Name = "DefaultUser"
                Mounted = $true
            }
            Mock -ModuleName WeaveRegistry -CommandName Test-RegistryHiveMounted -MockWith {$MountTest}
        }
        Context "Call reg.exe" {
            It "Test when Hive is mounted into HKLM" {
                Mock -ModuleName WeaveRegistry -CommandName Test-Path -MockWith {$true}
                Mock -ModuleName WeaveRegistry -CommandName 'reg.exe' -MockWith {"successfully"}
                $Result = Dismount-RegistryHive
                $Result.Mounted | Should -Be $true
                Assert-MockCalled 'reg.exe' -Exactly 1
            }
        }
        Context "No Call to Reg.exe" {
            It "Test when Hive is not mounted into HKLM" {
                $HiveNotMounted = [pscustomobject] @{
                    Name = "DefaultUser"
                    Mounted = $false
                }
                Mock -ModuleName WeaveRegistry -CommandName Test-Path -MockWith {$false}
                Mock -ModuleName WeaveRegistry -CommandName Test-RegistryHiveMounted -MockWith {$HiveNotMounted}
                if (Test-Path -Path "HKLM:\$($HiveNotMounted.Name)"){
                    # If Test-Path is true, assert call to reg.exe
                    Assert-MockCalled 'reg.exe' -Exactly 0
                }
                $Result = Dismount-RegistryHive
                $Result.Mounted | Should -Be $false
            }
        }
    }
}