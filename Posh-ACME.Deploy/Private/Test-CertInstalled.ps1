function Test-CertInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [AllowEmptyString()]
        [string]$CertThumbprint,
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]$StoreLocation = 'LocalMachine',
        [string]$StoreName = 'My'
    )

    Process {

        if (-not $CertThumbprint) {
            return $false
        }

        $allCerts = Get-ChildItem Cert:\$StoreLocation\$StoreName

        if ($allCerts | Where-Object {$_.Thumbprint -eq $CertThumbprint}) {
            return $true
        } else {
            return $false
        }

    }
}
