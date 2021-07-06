function Set-IISCertificate {
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

        # make sure the WebAdministration module is available
        if (-not (Get-Module -ListAvailable WebAdministration -Verbose:$false)) {
            throw "The WebAdministration module is required to use this function."
        } else {
            Import-Module WebAdministration -Verbose:$false
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

        # HostHeader with SSL is only supported on IIS versions with SNI support which is IIS 8+. So throw an error
        # if they specified one and we can't use it.
        $SupportSNI = ((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\InetStp).MajorVersion -ge 8)
        if (-not ([string]::IsNullOrWhiteSpace($HostHeader))) {
            if (-not $SupportSNI) {
                throw "Host Headers for SSL/TLS bindings are only supported on IIS 8.0 or higher."
            }
        } elseif ($RequireSNI) {
            # HostHeader is empty but they used -RequireSNI, so throw an error
            throw "RequireSNI specified, but HostHeader is missing."
        }

        # verify the site exists
        if (-not (Get-WebSite -Name $SiteName)) {
            throw "Site $SiteName not found."
        }

        $sslFlags = 0
        if ($RequireSNI) { $sslFlags = 1 }

        # check for an existing site binding
        $bindMatch = "$($IPAddress):$($Port):$($HostHeader)"
        $binding = Get-WebBinding -Name $SiteName -Protocol 'https' | Where-Object {
            $_.bindingInformation -eq $bindMatch
        }
        if ($binding) {

            # we've got a match on the binding string, but now we have to make sure the sslFlags value
            # also matches. But sslFlags only exists on IIS 8+, so don't bother checking on earlier versions
            if ($SupportSNI) {

                # update the value if it doesn't match
                if ($binding.sslFlags -ne $sslFlags) {
                    Write-Verbose "Updating sslFlags on binding $bindMatch"
                    Set-WebBinding -Name $SiteName -BindingInformation $bindMatch -PropertyName sslFlags -Value $sslFlags
                } else {
                    Write-Verbose "IIS Binding already exists for $bindMatch"
                }

            } else {
                Write-Verbose "IIS Binding already exists for $bindMatch"
            }

        } else {
            # no match

            # build the param splat we'll use with New-WebBinding
            $newBindingParams = @{
                Name = $SiteName
                Protocol = 'https'
                IPAddress = $IPAddress
                Port = $Port
            }
            if ($HostHeader) {
                $newBindingParams.HostHeader = $HostHeader
            }
            if ($SupportSNI) {
                $newBindingParams.SslFlags = $sslFlags
            }

            Write-Verbose "Adding new site binding for $bindMatch"
            New-WebBinding @newBindingParams
        }

        # get a reference to the cert
        $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $CertThumbprint }

        # get the current ssl binding list
        $sslBindings = Get-ChildItem IIS:\SslBindings | Where-Object { $_.Sites.Value -eq $SiteName }

        # Matching the SSL binding is weird because it changes depending on whether you have the
        # SNI required flag enabled on the web binding or not. If yes, the IP is stripped so the string
        # starts with '!' and ends with '!<hostname>'. If not, the IP is included (0.0.0.0 for *) but the
        # hostname and it's '!' are stripped. So:
        #
        #           *:443:                 + No SNI =     0.0.0.0!443
        # 10.10.10.10:443:                 + No SNI = 10.10.10.10!443
        #           *:443:test.example.com + No SNI =     0.0.0.0!443
        # 10.10.10.10:443:test.example.com + No SNI = 10.10.10.10!443
        #           *:443:                 +    SNI = (not possible)
        # 10.10.10.10:443:                 +    SNI = (not possible)
        #           *:443:test.example.com +    SNI =            !443!test.example.com
        # 10.10.10.10:443:test.example.com +    SNI =            !443!test.example.com
        #
        # This means it's possible to have multiple web bindings that basically share an SSL binding
        # so if you change the thumbprint on one, it changes both.

        $sslMatch = $bindMatch.Replace(':','!').Replace('*','0.0.0.0')
        if ($sslMatch[-1] -eq '!') {
            # remove the ending '!'
            $sslMatch = $sslMatch.Substring(0,$sslMatch.Length-1)
        } elseif ($RequireSNI) {
            # remove the IP in front
            $sslMatch = $sslMatch.Substring($sslMatch.IndexOf('!'))
        } else {
            # remove the '!<hostname>' at the end
            $sslMatch = $sslMatch.Substring(0,$sslMatch.LastIndexOf('!'))
        }
        Write-Verbose "Checking SSL binding $sslMatch"

        # check if ssl binding already exists
        if ($binding = $sslBindings | Where-Object { $_.PSChildName -eq $sslMatch }) {

            # save the old thumbprint for potential deleting later
            $oldThumb = $binding.Thumbprint

            if ($oldThumb -eq $CertThumbprint) {
                Write-Verbose "SSL binding already exists for $sslMatch"
            } else {
                Write-Verbose "Removing old thumbprint from $sslMatch SSL binding"
                # Could never get Set-Item to work directly, always kept throwing param errors
                # So instead, we'll delete and re-create
                Get-Item IIS:\SslBindings\$sslMatch | Remove-Item
                $addNew = $true
            }

        } else { $addNew = $true }

        if ($addNew) {

            Write-Verbose "Adding certificate thumbprint $CertThumbprint"
            if ($SupportSNI) {
                $cert | New-Item IIS:\SslBindings\$sslMatch -SslFlags $sslFlags | Out-Null
            } else {
                $cert | New-Item IIS:\SslBindings\$sslMatch | Out-Null
            }

            # remove the old cert if specified
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
        The IIS web site name to modify bindings on. Defaults to "Default Web Site".

    .PARAMETER Port
        The listening TCP port for the site binding. Defaults to 443.

    .PARAMETER IPAddress
        The listening IP Address for the site binding. Defaults to '*' which is "All Unassigned" in the IIS management console.

    .PARAMETER HostHeader
        The "Host name" value for the site binding. If empty, this binding will respond to all names. Supported only on IIS 8.0 or higher.

    .PARAMETER RequireSNI
        If specified, the "Require Server Name Indication" box will be checked for the site binding. Supported only on IIS 8.0 or higher.

    .PARAMETER RemoveOldCert
        If specified, the old certificate associated with RDP will be deleted from the local system's Personal certificate store. Ignored if the old certificate has already been removed or otherwise can't be found.

    .EXAMPLE
        New-PACertificate site1.example.com | Set-IISCertificate -SiteName "My Website"

        Create a new certificate and add it to the specified IIS website on the default port.

    .EXAMPLE
        Submit-Renewal site1.example.com | Set-IISCertificate -SiteName "My Website"

        Renew a certificate and and add it to the specified IIS website on the default port.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME.Deploy

    #>
}
