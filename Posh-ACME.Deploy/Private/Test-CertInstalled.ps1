function Test-CertInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1)]
        [string]$StoreName = 'LocalMachine',
        [Parameter(Position=2)]
        [string]$StoreLoc = 'My'
    )

    $allCerts = Get-ChildItem Cert:\$StoreName\$StoreLoc

    if ($allCerts | Where-Object {$_.Thumbprint -eq $CertThumbprint}) {
        return $true
    } else {
        return $false
    }

}
