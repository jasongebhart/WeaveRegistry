
InModuleScope "WeaveRegistry" {

    Describe "Get-CurrentUser" {
        Context "Modify Path " {
            It "Get Hive" {
                $parameters = @{
                "Name" = "HKEY_USERS\S-1-5-21-1940666338-227100268-1349548132-94132\Volatile Environment"
                }
                Mock -CommandName Get-ChildItem -MockWith {[PSCustomObject]$parameters}
                Mock -CommandName Get-ItemProperty -MockWith {[PSCustomObject]@{UserName = "jgebhart"}}
                $Result = Get-CurrentUser
                $Result.Hive | Should -Be "HKEY_USERS\S-1-5-21-1940666338-227100268-1349548132-94132"
                $Result.Username | Should -Be "jgebhart"
            }
        }
    }
}