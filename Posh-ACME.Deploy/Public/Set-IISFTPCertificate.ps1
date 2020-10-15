function Set-IISFTPCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
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

    Process {

        # make sure the WebAdministration module is available
        if (!(Get-Module -ListAvailable WebAdministration -Verbose:$false)) {
            try { throw "The WebAdministration module is required to use this function." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        } else {
            Import-Module WebAdministration -Verbose:$false
        }

        # install the cert if necessary
        if (!(Test-CertInstalled $CertThumbprint)) {
            if ($PfxFile) {
                $PfxFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PfxFile)
                Import-PfxCertInternal $PfxFile -PfxPass $PfxPass
            } else {
                try { throw "Certificate thumbprint not found and PfxFile not specified." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        }

        # verify the site exists
        $sitePath = "IIS:\Sites\$SiteName"
        if (-not (Get-Item $sitePath -EA SilentlyContinue)) {
            try { throw "Site $SiteName not found." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
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

    .PARAMETER SiteName
        The IIS FTP site name.

    .PARAMETER ControlChannelPolicy
        The control channel policy that should be configured for the FTP site: SslRequire, SslAllow, or SslRequireCredentialsOnly. See https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/ftpserver/security/ssl for details.

    .PARAMETER DataChannelPolicy
        The data channel policy that should be configured for the FTP site: SslRequire, SslAllow, or SslDeny. See https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/ftpserver/security/ssl for details.

    .PARAMETER Use128BitEncryption
        If specified, enable 128-bit encryption for SSL connections to the FTP site.

    .EXAMPLE
        New-PACertificate site1.example.com | Set-IISFTPCertificate -SiteName "My FTP"

        Create a new certificate and add it to the specified IIS FTP site.

    .EXAMPLE
        Submit-Renewal site1.example.com | Set-IISFTPCertificate -SiteName "My FTP"

        Renew a certificate and and add it to the specified IIS FTP site.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME.Deploy

    .LINK
        https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/ftpserver/security/ssl

    #>
}
