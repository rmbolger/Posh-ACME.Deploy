function Set-WinRMCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,
        [string]$Address='*',
        [string]$Transport='HTTPS',
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

        # get a reference to the existing listener
        $listener = Get-WSManInstance -ResourceURI 'winrm/config/Listener' -Enumerate |
            Where-Object { $_.Address -eq $Address -and $_.Transport -eq $Transport }
        if (-not $listener) {
            throw "Listener with Transport $Transport and Address $Address not found."
        }

        # update the cert thumbprint if it's different
        if ($CertThumbprint -ne $listener.CertificateThumbprint) {

            # save the old thumbprint
            $oldThumb = $listener.CertificateThumbprint

            # get the hostname from the cert subject
            $subject = (Get-Item "Cert:\LocalMachine\My\$CertThumbprint").Subject
            if ($subject -match 'CN=(?<host>[^,]+)') {
                $certHost = $matches['host']
                Write-Verbose "Parsed hostname $certHost"
            }

            # set the new one
            Write-Verbose "Setting Listener with Transport $Transport and Address $Address to certificate thumbprint $CertThumbprint and hostname $certHost."
            $setParams = @{
                ResourceURI = 'winrm/config/Listener'
                SelectorSet = @{
                    Address = $Address
                    Transport = $Transport
                }
                ValueSet = @{
                    Hostname = $certHost
                    CertificateThumbprint = $CertThumbprint
                }
            }
            Set-WSManInstance @setParams -EA Stop | Out-Null

            # remove the old cert if specified
            if ($RemoveOldCert) { Remove-OldCert $oldThumb }

        } else {
            Write-Warning "Specified certificate is already configured for Listener with Transport $Transport and Address $Address."
        }

    }





    <#
    .SYNOPSIS
        Configure a WinRM HTTPS listener to use the specified certificate.

    .DESCRIPTION
        Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

    .PARAMETER CertThumbprint
        Thumbprint/Fingerprint for the certificate to configure.

    .PARAMETER PfxFile
        Path to a PFX containing a certificate and private key. Not required if the certificate is already in the local system's Personal certificate store.

    .PARAMETER PfxPass
        The export password for the specified PfxFile parameter. Not required if the Pfx does not require an export password.

    .PARAMETER Address
        The address value of the WinRM listener. Defaults to '*'.

    .PARAMETER Transport
        The transport of the WinRM listener. Defaults to 'HTTPS'.

    .EXAMPLE
        New-PACertificate site1.example.com | Set-WinRMCertificate

        Create a new certificate and configure it for the listener on this system.

    .EXAMPLE
        Submit-Renewal site1.example.com | Set-RDSHCertificate

        Renew a certificate and configure it for the listener on this system.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME.Deploy

    #>
}
