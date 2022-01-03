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

    <#
    .SYNOPSIS
        Configure Remote Access SSTP service to use the specified certificate.

    .DESCRIPTION
        Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

    .PARAMETER CertThumbprint
        Thumbprint/Fingerprint for the certificate to configure.

    .PARAMETER PfxFile
        Path to a PFX containing a certificate and private key. Not required if the certificate is already in the local system's Personal certificate store.

    .PARAMETER PfxPass
        The export password for the specified PfxFile parameter. Not required if the Pfx does not require an export password.

    .PARAMETER RemoveOldCert
        If specified, the old certificate associated with Remote Access SSTP will be deleted from the local system's Personal certificate store. Ignored if the old certificate has already been removed or otherwise can't be found.

    .EXAMPLE
        New-PACertificate vpn.example.com | Set-RASSTPCertificate

        Create a new certificate and configure it for Remote Access SSTP on this system.

    .EXAMPLE
        Submit-Renewal vpn.example.com | Set-RASSTPCertificate

        Renew a certificate and configure it for Remote Access SSTP on this system.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME.Deploy

    #>
}
