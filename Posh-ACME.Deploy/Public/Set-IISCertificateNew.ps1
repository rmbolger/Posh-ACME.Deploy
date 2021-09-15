function Set-IISCertificateNew {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,
        [string]$SiteName='Default Web Site',
        [uint32]$Port=443,
        [string]$IPAddress='*',
        [string]$HostHeader,
        [switch]$RequireSNI,
        [switch]$RemoveOldCert
    )

    Process {

        trap { $PSCmdlet.ThrowTerminatingError($PSItem) }

        # Make sure we have the New-IISSiteBinding function available from
        # the IISAdministration module. It needs at least version 1.1.0.0 of
        # the module.
        if (-not (Get-Command New-IISSiteBinding -EA Ignore)) {

            $module = Get-Module -ListAvailable IISAdministration -All -Verbose:$false |
                Where-Object { $_.Version -ge [version]'1.1.0.0' } |
                Sort-Object -Descending Version |
                Select-Object -First 1

            if (-not $module) {
                throw "The IISAdministration module version 1.1.0.0 or newer is required to use this function. https://blogs.iis.net/iisteam/introducing-iisadministration-in-the-powershell-gallery"
            } else {
                if (-not $PSEdition -or $PSEdition -eq 'Desktop') {
                    $module | Import-Module -Verbose:$false
                } else {
                    $module | Import-Module -UseWindowsPowerShell -Verbose:$false
                }
            }
        }

        # install the cert if necessary
        if (-not (Test-CertInstalled $CertThumbprint)) {
            if ($PfxFile) {
                $PfxFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PfxFile)
                Import-PfxCertInternal $PfxFile -PfxPass $PfxPass
            } else {
                throw "Certificate thumbprint not found and PfxFile not specified."
            }
        }

        # verify the site exists
        if (-not (Get-IISSite -Name $SiteName)) {
            throw "Site $SiteName not found."
        }

        $sslFlags = 'None'
        if ($RequireSNI) { $sslFlags = 'Sni' }

        # check for an existing site binding
        $bindMatch = "$($IPAddress):$($Port):$($HostHeader)"
        $binding = (Get-IISSiteBinding -Name $SiteName -Protocol 'https' -WarningAction 'Ignore') | Where-Object {
            $_.bindingInformation -eq $bindMatch
        }

        # The IISAdministration module combines the creation of web binding and SSL binding
        # into New-IISSiteBinding, but there's no Set-IISSiteBinding equivalent that would
        # allow us to update the certificate thumbprint or tweak things like the SslFlags
        # value on the binding. So if we find a binding that is not exactly what we want,
        # we have to delete and re-create it.
        if ($binding) {

            # save the old thumbprint for potential deleting later
            $oldThumb = [BitConverter]::ToString($binding.CertificateHash).Replace('-','')

            if ($binding.sslFlags -ne $sslFlags -or $oldThumb -ne $CertThumbprint) {

                $removeBindingParams = @{
                    Name = $SiteName
                    BindingInformation = $bindMatch
                    Protocol = 'https'
                    RemoveConfigOnly = $true
                    Confirm = $false
                }
                Write-Verbose "Deleting IIS site binding for $bindMatch"
                Remove-IISSiteBinding @removeBindingParams
                $binding = $null
            }
        }

        # create the new binding if necessary
        if ($binding) {
            Write-Verbose "IIS site binding already exists for $bindMatch"
        } else {

            $newBindingParams = @{
                Name = $SiteName
                Protocol = 'https'
                BindingInformation = $bindMatch
                SslFlag = $sslFlags
                CertificateThumbprint = $CertThumbprint
                CertStoreLocation = 'Cert:\LocalMachine\My'
            }
            Write-Verbose "Adding IIS site binding for $bindMatch"
            New-IISSiteBinding @newBindingParams

            # remove the old cert if specified
            if ($RemoveOldCert) { Remove-OldCert $oldThumb }
        }

    }





    <#
    .SYNOPSIS
        Configure RD Session Host service to use the specified certificate.

    .DESCRIPTION
        Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

        This function is dependent on the IISAdministration module version 1.1.0.0 or greater which
        can be installed from the PowerShell Gallery.
        https://blogs.iis.net/iisteam/introducing-iisadministration-in-the-powershell-gallery

    .PARAMETER CertThumbprint
        Thumbprint/Fingerprint for the certificate to configure.

    .PARAMETER PfxFile
        Path to a PFX containing a certificate and private key. Not required if the certificate is already in the local system's Personal certificate store.

    .PARAMETER PfxPass
        The export password for the specified PfxFile parameter. Not required if the Pfx does not require an export password.

    .PARAMETER SiteName
        The IIS web site name to modify bindings on. Defaults to "Default Web Site".

    .PARAMETER Port
        The listening TCP port for the site binding. Defaults to 443.

    .PARAMETER IPAddress
        The listening IP Address for the site binding. Defaults to '*' which is "All Unassigned" in the IIS management console.

    .PARAMETER HostHeader
        The "Host name" value for the site binding. If empty, this binding will respond to all names.

    .PARAMETER RequireSNI
        If specified, the "Require Server Name Indication" box will be checked for the site binding.

    .PARAMETER RemoveOldCert
        If specified, the old certificate associated with RDP will be deleted from the local system's Personal certificate store. Ignored if the old certificate has already been removed or otherwise can't be found.

    .EXAMPLE
        New-PACertificate site1.example.com | Set-IISCertificateNew -SiteName "My Website"

        Create a new certificate and add it to the specified IIS website on the default port.

    .EXAMPLE
        Submit-Renewal site1.example.com | Set-IISCertificateNew -SiteName "My Website"

        Renew a certificate and and add it to the specified IIS website on the default port.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME.Deploy

    #>
}
