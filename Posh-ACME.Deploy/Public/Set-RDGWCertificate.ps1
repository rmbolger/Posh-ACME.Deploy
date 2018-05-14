#Requires -Module RemoteDesktopServices

function Set-RDGWCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2)]
        [securestring]$PfxPass,
        [switch]$NoRestartService,
        [switch]$RemoveOldCert
    )

    Process {

        # install the cert if necessary
        if (!(Test-CertInstalled $CertThumbprint)) {
            if ($PfxFile) {
                $PfxFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PfxFile)
                Import-PfxCertInternal $PfxFile -PfxPass $PfxPass
            } else {
                throw "Certificate thumbprint not found and PfxFile not specified."
            }
        }

        # check the old thumbprint value
        $oldThumb = (Get-Item RDS:\GatewayServer\SSLCertificate\Thumbprint).CurrentValue

        if ($oldThumb -ne $CertThumbprint) {

            # set the new value
            Set-Item RDS:\GatewayServer\SSLCertificate\Thumbprint -Value $CertThumbprint

            # restart the service unless specified
            if (!$NoRestartService) {
                Restart-Service TSGateway
            }

            # remove the old cert if specified
            if ($RemoveOldCert) {
                $oldCert = $allCerts | Where-Object {$_.Thumbprint -eq $oldThumb}
                if ($oldCert) { $oldCert | Remove-Item }
            }

        } else {
            Write-Warning "Specified certificate is already configured for RDP Gateway"
        }

    }

}
