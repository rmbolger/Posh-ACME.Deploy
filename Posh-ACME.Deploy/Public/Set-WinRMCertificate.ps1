function Set-WinRMCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName)]
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

        # surface exceptions without terminating the whole pipeline
        trap { $PSCmdlet.WriteError($PSItem); return }

        $CertThumbprint = Confirm-CertInstall @PSBoundParameters

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

            # Set-WSManInstance fails if the existing hostname on the listener doesn't match
            # the CN value of the certificate's subject (which seems broken to me, but *shrug*).
            # So we're going to parse the hostname from the subject and make sure we set it
            # at the same time as the thumbprint.
            $subject = (Get-Item "Cert:\LocalMachine\My\$CertThumbprint").Subject
            if ($subject -match 'CN=(?<host>[^,]+)') {
                $certHost = $matches['host']
                Write-Verbose "Parsed hostname $certHost from cert subject."
            }

            # set the new thumbprint
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

}
