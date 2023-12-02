
InModuleScope "WeaveRegistry" {
    
    Describe "Get-RegistryActualValue" {
        BeforeAll {
            $RegSettings = @{
                "RegPath"     = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
                "RegProperty" = "ActiveSetupDisabled"
                "RegValue"    = "00000000"
                "RegType"     = "REG_DWORD"
            }

            $ExpandStringSettings = @{
                "RegPath"     = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
                "RegProperty" = "Common Desktop"
                "RegValue"    = "%PUBLIC%\Desktop"
                "RegType"     = "REG_EXPAND_SZ"
            }

            $BinaryValue = "240000003f28000000000000000000000000000001000000130000000000000062000000"

            $BinarySettings = @{
                "RegPath"     = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
                "RegProperty" = "ShellState"
                "RegValue"    = $BinaryValue
                "RegType"     = "REG_BINARY"
            }
        }

        Context " Test Registry Conversion" {
            It "DWORD Get-RegistryActualValue" {
                $Result = Get-RegistryActualValue @RegSettings
                $Result | Should -Be 0
            }

            It " Expand String Get-RegistryActualValue" {
                $Result = Get-RegistryActualValue @ExpandStringSettings
                $Result | Should -Be "%PUBLIC%\Desktop"
            }

            It " Binary Get-RegistryActualValue" {
                $Result = Get-RegistryActualValue @BinarySettings
                $Result | Should -Be $BinaryValue
            }
            
        }
    } 
}
