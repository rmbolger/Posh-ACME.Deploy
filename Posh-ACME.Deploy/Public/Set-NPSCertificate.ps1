function Set-NPSCertificate {
    [CmdletBinding(DefaultParameterSetName='ByName')]
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,
        [string]$IASConfigPath = '%SystemRoot%\System32\ias\ias.xml',
        [Parameter(ParameterSetName='ByName', Mandatory)]
        [string]$PolicyName,
        [Parameter(ParameterSetName='ByXPath', Mandatory)]
        [string]$PolicyXPath,
        [switch]$RemoveOldCert
    )

    Process {

        # surface individual errors without terminating the whole pipeline
        trap { $PSCmdlet.WriteError($PSItem); return }

        $CertThumbprint = Confirm-CertInstall @PSBoundParameters

        $configPath = [Environment]::ExpandEnvironmentVariables($IASConfigPath)
        $configPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($configPath)

        [xml]$IASConfig = Get-Content $configPath

        if ('ByName' -eq $PSCmdlet.ParameterSetName) {
            $policies = $IASConfig.SelectSingleNode("//RadiusProfiles//*[@name='$PolicyName']")
            # verify the policy exists
            if (-not ($policies)) {
                throw "Policy $PolicyName not found."
            }
        } else {
            $policies = $IASConfig.SelectNodes($PolicyXPath)
            if ($policies.Count -eq 0) {
                throw "No policy elements returned using PolicyXPath $PolicyXPath"
            }
        }

        $oldThumbs = @()
        $saverestart = $false

        foreach ($policy in $policies) {
            foreach ($eapconfig in $policy.Properties.msEAPConfiguration) {

                if ($eapconfig.innerText.substring(0,32) -eq "0d000000000000000000000000000000") {
                    #EAP TLS
                    $substringstart = 80
                    $eaptype = "Microsoft: Smart Card or other certificate"
                } elseif ($eapconfig.innerText.substring(0,32) -eq "19000000000000000000000000000000") {
                    #PEAP
                    $substringstart = 72
                    $eaptype = "Microsoft: Protected EAP (PEAP)"
                } else {
                    Write-Warning "Unidentified EAP configuration security method. Skipping for now"
                    continue;
                }

                $currentThumb = $eapconfig.InnerText.Substring($substringstart,40)

                # update the cert thumbprint if it's different
                if ($CertThumbprint -ne $currentThumb) {
                    $saverestart = $true

                    # save the old thumbprints
                    $oldThumbs += $currentThumb

                    # set the new one
                    Write-Verbose "Setting NPS policy '$($policy.name)' certificate thumbprint to $CertThumbprint for EAP type '$eaptype'"
                    $eapconfig.InnerText = $eapconfig.InnerText.Replace($currentThumb,$CertThumbprint.ToLower())

                } else {
                    Write-Warning "Specified certificate is already configured for EAP type '$eaptype' in NPS Policy '$($policy.name)'"
                }
            }
        }

        if ($saverestart) {
            $IASConfig.Save($configPath)

            Restart-Service 'IAS'

            # remove the old cert if specified
            if ($RemoveOldCert) {
                $oldThumbs | Sort-Object -Unique | ForEach-Object {Remove-OldCert $_ }
            }
        }
    }

<#
.SYNOPSIS
    Configure a NPS Network Policy to use the specified certificate for MS PEAP.

.DESCRIPTION
    Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

.PARAMETER CertThumbprint
    Thumbprint/Fingerprint for the certificate to configure.

.PARAMETER PfxFile
    Path to a PFX containing a certificate and private key. Not required if the certificate is already in the local system's Personal certificate store.

.PARAMETER PfxPass
    The export password for the specified PfxFile parameter. Not required if the Pfx does not require an export password.

.PARAMETER IASConfigPath
    The path to the NPS config file you want to edit. Default: %SystemRoot%\System32\ias\ias.xml

.PARAMETER PolicyName
    The name of the Network Policy.

.PARAMETER PolicyXPath
    An XPath expression that returns one or more Network Policies with an msEAPConfiguration element. An example that would return all policies might be '//RadiusProfiles//Children/*[descendant::msEAPConfiguration]'. This is for advanced usage where you are updating multiple policies with the same certificate.

.PARAMETER RemoveOldCert
    If specified, the old certificate associated with the service will be deleted from the local system's Personal certificate store. Ignored if the old certificate has already been removed or otherwise can't be found.

.EXAMPLE
    New-PACertificate site1.example.com | Set-NPSCertificate -PolicyName "Secure Wireless Connections"

    Create a new certificate and add it to the specified NPS Network Policy.

.EXAMPLE
    Submit-Renewal site1.example.com | Set-NPSCertificate -PolicyName "Secure Wireless Connections"

    Renew a certificate and and add it to the specified NPS Network Policy.

.LINK
    Project: https://github.com/rmbolger/Posh-ACME.Deploy

#>
}
