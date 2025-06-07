function Set-IISCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,
        [string]$SiteName='Default Web Site',
        [uint32]$Port=443,
        [string]$IPAddress='*',
        [string[]]$HostHeader=@(''),
        [switch]$RequireSNI,
        [switch]$DisableHTTP2,
        [switch]$DisableOCSPStapling,
        [switch]$DisableQUIC,
        [switch]$DisableTLS13,
        [switch]$DisableLegacyTLS,
        [switch]$RemoveOldCert,
        [switch]$Force
    )

    Begin {
        # Make sure we have the New-IISSiteBinding function available from
        # the IISAdministration module. It needs at least version 1.1.0.0 of
        # the module.
        if (-not (Get-Command New-IISSiteBinding -EA Ignore)) {

            $module = Get-Module -ListAvailable IISAdministration -All -Verbose:$false |
                Where-Object { $_.Version -ge [version]'1.1.0.0' } |
                Sort-Object -Descending Version |
                Select-Object -First 1

            if (-not $module) {
                try { throw "The IISAdministration module version 1.1.0.0 or newer is required to use this function. https://blogs.iis.net/iisteam/introducing-iisadministration-in-the-powershell-gallery" }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            } else {
                # This module seems to have weird caching issues with the state of
                # IIS bindings. So make sure we Force import to prevent making decisions
                # based on stale data.
                if (-not $PSEdition -or $PSEdition -eq 'Desktop') {
                    $module | Import-Module -Verbose:$false -Force
                } else {
                    $module | Import-Module -UseWindowsPowerShell -Verbose:$false -Force
                }
            }
        }

        # The Microsoft.Web.Administration.SslFlags enum is not loaded until we actually
        # make a function call from the module. So do that.
        $null = Get-IISSite | Get-IISSiteBinding

        # build a map of switches to their corresponding SslFlags enum value
        $switchMap = @{
            'RequireSNI' = [Microsoft.Web.Administration.SslFlags]::Sni
            'DisableHTTP2' = [Microsoft.Web.Administration.SslFlags]::DisableHTTP2
            'DisableOCSPStapling' = [Microsoft.Web.Administration.SslFlags]::DisableOCSPStp
            'DisableQUIC' = [Microsoft.Web.Administration.SslFlags]::DisableQUIC
            'DisableTLS13' = [Microsoft.Web.Administration.SslFlags]::DisableTLS13
            'DisableLegacyTLS' = [Microsoft.Web.Administration.SslFlags]::DisableLegacyTLS
        }

        # Different versions of Windows/IIS have different supported flags. So older OSes
        # might have fewer flags in the enum than newer ones. We're going to remove any
        # that got set to $null because they don't exist for the current OS.
        foreach ($key in @($switchMap.Keys)) {
            if (-not $switchMap[$key]) {
                Write-Debug "$key removed from supported SslFlags map because it had no matching value in the enum on this OS"
                $switchMap.Remove($key)
            }
        }

        $psb = $PSBoundParameters
    }

    Process {

        # surface exceptions without terminating the whole pipeline
        trap { $PSCmdlet.WriteError($PSItem); return }

        $CertThumbprint = Confirm-CertInstall @PSBoundParameters
        Write-Debug "new thumbprint $CertThumbprint"

        # verify the site exists
        if (-not (Get-IISSite -Name $SiteName)) {
            throw "Site $SiteName not found."
        }

        # multiple host headers require multiple bindings
        [string[]]$oldThumbPrints = foreach ($hh in $HostHeader) {

            # check for an existing site binding
            $bindMatch = "$($IPAddress):$($Port):$($hh)"
            $binding = (Get-IISSiteBinding -Name $SiteName -Protocol 'https' -WarningAction 'Ignore') | Where-Object {
                $_.bindingInformation -eq $bindMatch
            }

            # The IISAdministration module combines the creation of web binding and SSL binding
            # into New-IISSiteBinding, but there's no Set-IISSiteBinding equivalent that would
            # allow us to update the certificate thumbprint or tweak things like the SslFlags
            # value on the binding. So if we find a binding that is not exactly what we want,
            # we have to delete and re-create it.
            if ($binding) {

                # grab the old/current thumbprint
                $oldThumb = ''
                try {
                    $oldThumb = [BitConverter]::ToString($binding.CertificateHash).Replace('-','')
                } catch {}
                Write-Debug "old thumbprint $oldThumb for $SiteName"

                # sslFlags is a bitwise combination of values from the [Microsoft.Web.Administration.SslFlags]
                # enum. It has added new feature flags over the years between Server 2016/2019/2022 and will
                # likely continue to do so. To avoid overwriting future flags this function may not yet know
                # about, we need to check for each option's flag individually in the current binding value
                # instead of just comparing the calculated sum of the specified switches.

                # adjust the flags based on the specified switches
                $newFlags = $binding.sslFlags
                foreach ($switchName in $switchMap.Keys) {
                    if ($psb.ContainsKey($switchName)) {
                        if ($psb[$switchName]) { $newFlags = $newFlags -bor $switchMap[$switchName] }   # Ensure Set
                        else                   { $newFlags = $newFlags -bxor $switchMap[$switchName] }  # Ensure Unset
                    }
                }

                # remove the binding if flags or thumbprint are different
                if ($binding.sslFlags -ne $newFlags -or $oldThumb -ne $CertThumbprint) {

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

                    # save the old thumbprint for potential deletion later
                    if ($oldThumb -ne $CertThumbprint) {
                        Write-Output $oldThumb
                    }
                }
            } else {
                # no existing binding means we have to build the sslFlags value from scratch
                $newFlags = [Microsoft.Web.Administration.SslFlags]::None
                foreach ($switchName in $switchMap.Keys) {
                    if ($psb.ContainsKey($switchName)) {
                        if ($psb[$switchName]) { $newFlags = $newFlags -bor $switchMap[$switchName] }   # Ensure Set
                        else                   { $newFlags = $newFlags -bxor $switchMap[$switchName] }  # Ensure Unset
                    }
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
                    SslFlag = $newFlags
                    CertificateThumbprint = $CertThumbprint
                    CertStoreLocation = 'Cert:\LocalMachine\My'
                }
                if ($Force) {
                    $newBindingParams.Force = $true
                }
                Write-Verbose "Adding IIS site binding for $bindMatch"
                New-IISSiteBinding @newBindingParams

            }

        }

        # remove the old cert(s) if specified
        if ($RemoveOldCert) {
            $oldThumbprints | Sort-Object -Unique | ForEach-Object {
                Remove-OldCert $_
            }
        }

    }

}
