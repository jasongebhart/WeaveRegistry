If ($PSScriptRoot) {
    $global:projectDirectory = Join-Path $PSScriptRoot "..\"
    Import-Module -Name "$projectDirectory\WeaveRegistry" -Verbose
} else {
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] - PSScriptRoot $PSScriptRoot does not exist"
}

InModuleScope "WeaveRegistry" {
    
}
