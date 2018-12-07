function Remove-OldCert {
    [CmdletBinding()]
    param(
        [string]$OldCertThumb
    )

    if ($null -eq $OldCertThumb) { return }

    $oldCert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Thumbprint -eq $OldCertThumb}
    if ($oldCert) {
        Write-Verbose "Deleting old certificate with thumbprint $OldCertThumb"
        $oldCert | Remove-Item
    }

}
