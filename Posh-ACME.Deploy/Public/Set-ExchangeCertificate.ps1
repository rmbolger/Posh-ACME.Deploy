function Set-ExchangeCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,
        [string]$ExchangeServices='IIS,SMTP',
        [switch]$RemoveOldCert
    )

    Process {

        # make sure the Exchange snapin is available
        if (!(Get-PSSnapin | Where-Object { $_.Name -match "Microsoft.Exchange.Management.PowerShell" })) {
            throw "The Microsoft.Exchange.Management.PowerShell snapin is required to use this function."
        } else {
            Get-PSSnapin -Registered | Where-Object {
                $_.Name -match "Microsoft.Exchange.Management.PowerShell" -and (
                    $_.Name -match "Admin" -or
                    $_.Name -match "E2010" -or
                    $_.Name -match "SnapIn"
                )
            } | Add-PSSnapin -EA SilentlyContinue
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
        $oldThumb = (Get-ExchangeCertificate).Thumbprint

        if ($oldThumb -notcontains $CertThumbprint) {

            try {

                # set the new value
                Write-Verbose "Setting new Exchange thumbprint value"
                Enable-ExchangeCertificate -Services $ExchangeServices -Thumbprint $CertThumbprint -Force -EA Stop -Verbose:$false

                # remove the old cert if specified
                if ($RemoveOldCert) { Remove-OldCert $oldThumb }

            } catch { throw }

        } else {
            Write-Warning "Specified certificate is already configured for Exchange"
        }

    }





    <#
    .SYNOPSIS
        Configure Exchange service to use the specified certificate.

    .DESCRIPTION
        Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

    .PARAMETER CertThumbprint
        Thumbprint/Fingerprint for the certificate to configure.

    .PARAMETER PfxFile
        Path to a PFX containing a certificate and private key. Not required if the certificate is already in the local system's Personal certificate store.

    .PARAMETER PfxPass
        The export password for the specified PfxFile parameter. Not required if the Pfx does not require an export password.

    .PARAMETER ExchangeServices
        The name of the Exchange services to configure. Defaults to 'IIS,SMTP'.

    .PARAMETER RemoveOldCert
        If specified, the old certificate associated with RDP will be deleted from the local system's Personal certificate store. Ignored if the old certificate has already been removed or otherwise can't be found.

    .EXAMPLE
        New-PACertificate site1.example.com | Set-ExchangeCertificate

        Create a new certificate and configure it for Exchange on this system.

    .EXAMPLE
        Submit-Renewal site1.example.com | Set-ExchangeCertificate

        Renew a certificate and configure it for Exchange on this system.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME.Deploy

    #>
}
