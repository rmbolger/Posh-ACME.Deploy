function Remove-OldCert {
    [CmdletBinding()]
    param(
        [string]$OldCertThumb,
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]$StoreLocation = 'LocalMachine',
        [string]$StoreName = 'My'
    )

    if ($null -eq $OldCertThumb) { return }

    Get-ChildItem Cert:\$StoreLocation\$StoreName |
    Where-Object {
        $_.Thumbprint -eq $OldCertThumb
    } |
    ForEach-Object {
        Write-Verbose "Deleting old cert with thumbprint $OldCertThumb"
        $_ | Remove-Item
    }

}
