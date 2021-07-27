function Set-NPSCertificate {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
      [Alias('Thumbprint')]
      [string]$CertThumbprint,
      [Parameter(Position=1,ValueFromPipelineByPropertyName)]
      [string]$PfxFile,
      [Parameter(Position=2,ValueFromPipelineByPropertyName)]
      [securestring]$PfxPass,
      [string]$IASConfigPath = '%SystemRoot%\System32\ias\ias.xml',
      [Parameter(Mandatory=$true)]
      [string]$PolicyName,
      [switch]$RemoveOldCert
  )

  Process {

      # install the cert if necessary
      if (-not (Test-CertInstalled $CertThumbprint)) {
          if ($PfxFile) {
              $PfxFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PfxFile)
              Import-PfxCertInternal $PfxFile -PfxPass $PfxPass
          } else {
              throw "Certificate thumbprint not found and PfxFile not specified."
          }
      }

      [xml]$IASConfig = Get-Content ([Environment]::ExpandEnvironmentVariables($IASConfigPath))

      $policy = $IASConfig.SelectSingleNode("//RadiusProfiles//*[@name='$PolicyName']")
      
      # verify the policy exists
      if (-not ($policy)) {
          throw "Policy $PolicyName not found."
      }

      $currentThumb = $policy.Properties.msEAPConfiguration.InnerText.Substring(72,40)
      
      # update the cert thumbprint if it's different
      if ($CertThumbprint -ne $currentThumb) {

        # save the old thumbprint
        $oldThumb = $currentThumb

        # set the new one
        Write-Verbose "Setting $PolicyName certificate thumbprint to $CertThumbprint"
        $policy.Properties.msEAPConfiguration.InnerText = $policy.Properties.msEAPConfiguration.InnerText.SubString(0,72) + $CertThumbprint.ToLower() + $policy.Properties.msEAPConfiguration.InnerText.SubString(112)
        
        $IASConfig.Save([Environment]::ExpandEnvironmentVariables($IASConfigPath))

        Restart-Service 'IAS'
        
        # remove the old cert if specified
        if ($RemoveOldCert) { Remove-OldCert $oldThumb }

      } else {
          Write-Warning "Specified certificate is already configured for NPS Policy $PolicyName"
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

  .PARAMETER RemoveOldCert
      If specified, the old certificate associated with RDP will be deleted from the local system's Personal certificate store. Ignored if the old certificate has already been removed or otherwise can't be found.

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
