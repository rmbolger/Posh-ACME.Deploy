function Set-RDGWCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,
        [switch]$NoRestartService,
        [switch]$RemoveOldCert
    )

    Begin {
        # make sure the RDS module is available
        if (-not (Get-Module -ListAvailable RemoteDesktopServices -Verbose:$false)) {
            try { throw "The RemoteDesktopServices module is required to use this function." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        } else {
            Import-Module RemoteDesktopServices -Verbose:$false
        }
    }

    Process {

        # surface exceptions without terminating the whole pipeline
        trap { $PSCmdlet.WriteError($PSItem); return }

        $CertThumbprint = Confirm-CertInstall @PSBoundParameters

        # check the old thumbprint value
        $oldThumb = (Get-Item RDS:\GatewayServer\SSLCertificate\Thumbprint).CurrentValue

        if ($oldThumb -ne $CertThumbprint) {

            # set the new value
            Write-Verbose "Setting new RDGW thumbprint value"
            Set-Item RDS:\GatewayServer\SSLCertificate\Thumbprint -Value $CertThumbprint -EA Stop -Verbose:$false

            # restart the service unless specified
            if (-not $NoRestartService) {
                Write-Verbose "Restarting TSGateway service"
                Restart-Service TSGateway
            }

            # remove the old cert if specified
            if ($RemoveOldCert) { Remove-OldCert $oldThumb }

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
