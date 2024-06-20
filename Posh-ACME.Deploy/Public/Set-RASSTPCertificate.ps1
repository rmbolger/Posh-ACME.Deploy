function Set-RASSTPCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,
        [switch]$RemoveOldCert
    )

    Begin {

        # make sure the Remote Access module is available
        if (!(Get-Module -ListAvailable RemoteAccess -Verbose:$false)) {
            throw "The RemoteAccess module is required to use this function."
        } else {
            Import-Module RemoteAccess -Verbose:$false
        }
    }

    Process {

        # surface exceptions without terminating the whole pipeline
        trap { $PSCmdlet.WriteError($PSItem); return }

        $CertThumbprint = Confirm-CertInstall @PSBoundParameters

        $Cert = Get-ChildItem -Path "Cert:\LocalMachine\My\$CertThumbprint"

        # check the old thumbprint value
        $oldThumb = (Get-RemoteAccess).SslCertificate.Thumbprint

        if ($oldThumb -ne $CertThumbprint) {

            try {

                # set the new value
                Write-Verbose "Setting new Remote Access SSTP thumbprint value"
                Stop-Service RemoteAccess
                Set-RemoteAccess -SslCertificate $Cert
                Start-Service RemoteAccess

                # remove the old cert if specified
                if ($RemoveOldCert) { Remove-OldCert $oldThumb }

            } catch { throw }

        } else {
            Write-Warning "Specified certificate is already configured for the Remote Access SSTP Service"
        }

    }

}
