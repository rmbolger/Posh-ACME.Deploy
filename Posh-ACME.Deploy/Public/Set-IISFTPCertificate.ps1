function Set-IISFTPCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,
        [Parameter(Mandatory)]
        [string]$SiteName,
        [ValidateSet('SslRequire','SslAllow','SslRequireCredentialsOnly')]
        [string]$ControlChannelPolicy,
        [ValidateSet('SslRequire','SslAllow','SslDeny')]
        [string]$DataChannelPolicy,
        [switch]$Use128BitEncryption,
        [switch]$RemoveOldCert
    )

    Begin {
        # make sure the WebAdministration module is available
        if (!(Get-Module -ListAvailable WebAdministration -Verbose:$false)) {
            try { throw "The WebAdministration module is required to use this function." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        } else {
            Import-Module WebAdministration -Verbose:$false
        }
    }

    Process {

        # surface individual errors without terminating the whole pipeline
        trap { $PSCmdlet.WriteError($PSItem); return }

        $CertThumbprint = Confirm-CertInstall @PSBoundParameters

        # verify the site exists
        $sitePath = "IIS:\Sites\$SiteName"
        if (-not (Get-Item $sitePath -EA SilentlyContinue)) {
            throw "Site $SiteName not found."
        }

        # check existing settings and update if necessary
        $configPath = 'ftpServer.security.ssl'
        $siteConfig = Get-ItemProperty $sitePath -Name $configPath

        if ($ControlChannelPolicy -and $ControlChannelPolicy -ne $siteConfig.controlChannelPolicy) {
            Write-Verbose "Updating $SiteName controlChannelPolicy to $ControlChannelPolicy"
            Set-ItemProperty $sitePath -Name "$configPath.controlChannelPolicy" -Value $ControlChannelPolicy
        }
        if ($DataChannelPolicy -and $DataChannelPolicy -ne $siteConfig.dataChannelPolicy) {
            Write-Verbose "Updating $SiteName dataChannelPolicy to $DataChannelPolicy"
            Set-ItemProperty $sitePath -Name "$configPath.dataChannelPolicy" -Value $DataChannelPolicy
        }
        if ('Use128BitEncryption' -in $PSBoundParameters.Keys -and $Use128BitEncryption -ne $siteConfig.ssl128) {
            Write-Verbose "Updating $SiteName ssl128 to $Use128BitEncryption"
            Set-ItemProperty $sitePath -Name "$configPath.ssl128" -Value $Use128BitEncryption.IsPresent
        }
        if ('My' -ne $siteConfig.serverCertStoreName) {
            Write-Verbose "Updating $SiteName serverCertStoreName to My"
            Set-ItemProperty $sitePath -Name "$configPath.serverCertStoreName" -Value 'My'
        }

        if ($CertThumbprint -ne $siteConfig.serverCertHash) {

            $oldThumb = $siteConfig.serverCertHash

            Write-Verbose "Updating $SiteName serverCertHash to $CertThumbprint"
            Set-ItemProperty $sitePath -Name "$configPath.serverCertHash" -Value $CertThumbprint

            if ($RemoveOldCert) { Remove-OldCert $oldThumb }
        }

    }

}
