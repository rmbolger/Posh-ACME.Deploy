function Test-CertInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1)]
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]$StoreLocation = 'LocalMachine',
        [Parameter(Position=2)]
        [string]$StoreName = 'My'
    )

    $allCerts = Get-ChildItem Cert:\$StoreLocation\$StoreName

    if ($allCerts | Where-Object {$_.Thumbprint -eq $CertThumbprint}) {
        return $true
    } else {
        return $false
    }

}
