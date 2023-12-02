
InModuleScope "WeaveRegistry" {

    Describe "ConvertFrom-GPPreferenceXML" {
        BeforeAll {
$TestXML = @"
<?xml version="1.0" encoding="utf-8"?>
<Collection clsid="{ed0507d7-6a55-4b63-8641-48d1083864c3}" name="HKEY_LOCAL_MACHINE">
<Collection clsid="{ed0507d7-6a55-4b63-8641-48d1083864c3}" name="SOFTWARE">
    <Collection clsid="{ed0507d7-6a55-4b63-8641-48d1083864c3}" name="Microsoft">
    <Collection clsid="{ed0507d7-6a55-4b63-8641-48d1083864c3}" name="Windows">
        <Collection clsid="{ed0507d7-6a55-4b63-8641-48d1083864c3}" name="CurrentVersion">
        <Collection clsid="{ed0507d7-6a55-4b63-8641-48d1083864c3}" name="Policies">
            <Collection clsid="{ed0507d7-6a55-4b63-8641-48d1083864c3}" name="Explorer">
            <Registry clsid="{f5716fb9-3627-4119-a8ee-8360b8e85b43}" name="NoClose" descr="Imported Reg File" image="17">
                <Properties action="U" hive="HKEY_LOCAL_MACHINE" key="SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" name="NoClose" default="0" type="REG_DWORD" displayDecimal="0" value="00000000" />
            </Registry>
            </Collection>
        </Collection>
        </Collection>
    </Collection>
    </Collection>
</Collection>
</Collection>
"@
        }

        Context "Read XML" { 
            It "Create Object from XML" {
                Mock -CommandName 'Get-Content' -MockWith {$TestXML}
                $properties = ConvertFrom-GPPreferenceXML $TestXML
                Foreach ($result in $properties) {
                    $result.action | Should -Be "U"
                    $result.hive | Should -Be "HKEY_LOCAL_MACHINE"
                    $result.key | Should -Be "SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
                    $result.name | Should -Be "NoClose"
                    $result.default | Should -Be 0
                    $result.type | Should -Be "REG_DWORD" 
                    $result.method | Should -Be $null
                    $result.displayDecimal | Should -Be 0                                                           
                    $result.value | Should -Be "00000000"
                }
            }
        }
    }
}