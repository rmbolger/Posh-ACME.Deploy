function Set-RDSHCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName)]
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

        # surface exceptions without terminating the whole pipeline
        trap { $PSCmdlet.WriteError($PSItem); return }

        $CertThumbprint = Confirm-CertInstall @PSBoundParameters

        # get a reference to the RDP config
        $cimParams = @{
            ClassName = 'Win32_TSGeneralSetting'
            Namespace = 'root\cimv2\terminalservices'
            Filter = "TerminalName='$TerminalName'"
        }
        $ts = Get-CimInstance @cimParams

        # update the cert thumbprint if it's different
        if ($CertThumbprint -ne $ts.SSLCertificateSHA1Hash) {

            # save the old thumbprint
            $oldThumb = $ts.SSLCertificateSHA1Hash

            # set the new one
            Write-Verbose "Setting $TerminalName certificate thumbprint to $CertThumbprint"
            $ts.SSLCertificateSHA1Hash = $CertThumbprint
            $ts | Set-CimInstance -EA Stop

            # remove the old cert if specified
            if ($RemoveOldCert) { Remove-OldCert $oldThumb }

        } else {
            Write-Warning "Specified certificate is already configured for RDP terminal $TerminalName"
        }

    }

}
