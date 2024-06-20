#Requires -Modules platyPS

[CmdletBinding()]
param()

# Generate new MAML from the markdown
New-ExternalHelp .\docs\Functions\ -OutputPath .\Posh-ACME.Deploy\en-US\ -Force | Out-Null

# Fix the spacing on examples
$maml = Get-Content .\Posh-ACME.Deploy\en-US\Posh-ACME.Deploy-help.xml
$maml | ForEach-Object {
    # insert a blank paragraph before the end of the example "remarks"
    if ($_ -like '*</dev:remarks>') {
        '          <maml:para></maml:para>'
    }
    $_
} | Out-File .\Posh-ACME.Deploy\en-US\Posh-ACME.Deploy-help.xml -Encoding utf8 -Force
