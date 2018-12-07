function Set-RDGWCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,
        [switch]$NoRestartService,
        [switch]$RemoveOldCert
    )

    Process {

        # make sure the RDS module is available
        if (!(Get-Module -ListAvailable RemoteDesktopServices -Verbose:$false)) {
            throw "The RemoteDesktopServices module is required to use this function."
        } else {
            Import-Module RemoteDesktopServices -Verbose:$false
        }

        # install the cert if necessary
        if (!(Test-CertInstalled $CertThumbprint)) {
            if ($PfxFile) {
                $PfxFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PfxFile)
                Import-PfxCertInternal $PfxFile -PfxPass $PfxPass -EA Stop
            } else {
                throw "Certificate thumbprint not found and PfxFile not specified."
            }
        }

        # check the old thumbprint value
        $oldThumb = (Get-Item RDS:\GatewayServer\SSLCertificate\Thumbprint).CurrentValue

        if ($oldThumb -ne $CertThumbprint) {

            try {

                # set the new value
                Write-Verbose "Setting new RDGW thumbprint value"
                Set-Item RDS:\GatewayServer\SSLCertificate\Thumbprint -Value $CertThumbprint -EA Stop -Verbose:$false

                # restart the service unless specified
                if (!$NoRestartService) {
                    Write-Verbose "Restarting TSGateway service"
                    Restart-Service TSGateway
                }

                # remove the old cert if specified
                if ($RemoveOldCert) { Remove-OldCert $oldThumb }

            } catch { throw }

        } else {
            Write-Warning "Specified certificate is already configured for RDP Gateway"
        }

    }





    <#
    .SYNOPSIS
        Configure RD Gateway service to use the specified certificate.

    .DESCRIPTION
        Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

    .PARAMETER CertThumbprint
        Thumbprint/Fingerprint for the certificate to configure.

    .PARAMETER PfxFile
        Path to a PFX containing a certificate and private key. Not required if the certificate is already in the local system's Personal certificate store.

    .PARAMETER PfxPass
        The export password for the specified PfxFile parameter. Not required if the Pfx does not require an export password.

    .PARAMETER NoRestartService
        If specified, the Remote Desktop Gateway service will not be restarted after changing the certificate.

    .PARAMETER RemoveOldCert
        If specified, the old certificate associated with RDP will be deleted from the local system's Personal certificate store. Ignored if the old certificate has already been removed or otherwise can't be found.

    .EXAMPLE
        New-PACertificate site1.example.com | Set-RDGWCertificate

        Create a new certificate and configure it for RD Gateway on this system.

    .EXAMPLE
        Submit-Renewal site1.example.com | Set-RDGWCertificate

        Renew a certificate and configure it for RD Gateway on this system.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME.Deploy

    #>
}
