<#
Using Visual Studio Code

Open your Pester test project in Visual Studio Code.
Locate the Pester test script you want to run.
Right-click on the test script file and select "Run Pester" from the context menu.
This will execute the selected test script and display the results in the Visual Studio Code output panel.
#$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
#. "$here\$sut"
#>

