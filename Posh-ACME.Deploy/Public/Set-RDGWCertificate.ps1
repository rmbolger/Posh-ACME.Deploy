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

}
