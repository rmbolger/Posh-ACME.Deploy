function Set-RDSHCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,
        [string]$TerminalName='RDP-tcp',
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

        # get a reference to the RDP config
        $ts = Get-WmiObject -class 'Win32_TSGeneralSetting' -Namespace 'root\cimv2\terminalservices' -Filter "TerminalName='$TerminalName'"

        # update the cert thumbprint if it's different
        if ($CertThumbprint -ne $ts.SSLCertificateSHA1Hash) {

            # save the old thumbprint
            $oldThumb = $ts.SSLCertificateSHA1Hash

            # set the new one
            Write-Verbose "Setting $TerminalName certificate thumbprint to $CertThumbprint"
            Set-WmiInstance -Path $ts.__path -Argument @{SSLCertificateSHA1Hash='$CertThumbprint'} | Out-Null

            # remove the old cert if specified
            if ($RemoveOldCert) {
                $oldCert = $allCerts | Where-Object {$_.Thumbprint -eq $oldThumb}
                if ($oldCert) { $oldCert | Remove-Item }
            }
        } else {
            Write-Warning "Specified certificate is already configured for RDP terminal $TerminalName"
        }

    }





    <#
    .SYNOPSIS
        Configure RD Session Host service to use the specified certificate.

    .DESCRIPTION
        Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

    .PARAMETER CertThumbprint
        Thumbprint/Fingerprint for the certificate to configure.

    .PARAMETER PfxFile
        Path to a PFX containing a certificate and private key. Not required if the certificate is already in the local system's Personal certificate store.

    .PARAMETER PfxPass
        The export password for the specified PfxFile parameter. Not required if the Pfx does not require an export password.

    .PARAMETER TerminalName
        The name of the RDP terminal to configure. Defaults to 'RDP-Tcp'.

    .PARAMETER RemoveOldCert
        If specified, the old certificate associated with RDP will be deleted from the local system's Personal certificate store. Ignored if the old certificate has already been removed or otherwise can't be found.

    .EXAMPLE
        New-PACertificate site1.example.com | Set-RDSHCertificate

        Create a new certificate and configure it for RD Session Host on this system.

    .EXAMPLE
        Submit-Renewal site1.example.com | Set-RDSHCertificate

        Renew a certificate and configure it for RD Session Host on this system.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME.Deploy

    #>
}
