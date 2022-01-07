@{

RootModule = 'Posh-ACME.Deploy.psm1'
ModuleVersion = '1.4.0'
GUID = '79819e0a-30db-4742-bcc4-0c956273db51'
Author = 'Ryan Bolger'
Copyright = '(c) 2018 Ryan Bolger. All rights reserved.'
Description = 'Deployment helper functions for Posh-ACME'
CompatiblePSEditions = 'Desktop'
PowerShellVersion = '5.1'
DotNetFrameworkVersion = '4.7.1'

FunctionsToExport = @(
    'Set-ExchangeCertificate'
    'Set-IISCertificate'
    'Set-IISCertificateNew'
    'Set-IISFTPCertificate'
    'Set-RASSTPCertificate'
    'Set-RDGWCertificate'
    'Set-RDSHCertificate'
    'Set-WinRMCertificate'
    'Set-NPSCertificate'
)
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'LetsEncrypt','ssl','tls','certificates','acme','powershell','posh-acme'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/rmbolger/Posh-ACME.Deploy/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rmbolger/Posh-ACME.Deploy'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @'
## 1.4.0 (2022-01-06)

* Added `Set-IISCertificateNew` which was actually added in 1.3.0 but missed in the release notes. This should functions the same as the existing `Set-IISCertificate` function but is dependent on the IISAdministration module instead of the legacy WebAdministration module and should work on PowerShell 6+. However, it requires at least version 1.1.0.0 of the IISAdministration module which is distributed from powershellgallery.com.
  * Using this function will also work around issue #8 which involves errors for sites with uncommon characters in their names.
* Added `Set-RASSTPCertificate` which can be used to set the certificate for the Remote Access SSTP service. (Thanks @markpizz)
* The `CertThumbprint` parameter is no longer mandatory in the various public functions when `PfxFile` is specified. The thumprint will be read directly from the cert in the PFX if necessary. (#13)
* Improvements and fixes for `Set-ExchangeCertificate` involving old cert removal and cert replacement on renewal. (#19) (Thanks @markpizz)
* Fixed regression in `Set-ExchangeCertificate` from (#16) (Thanks @markpizz)
* Added support in private functions for cert management in locations/stores other than LocalMachine\My.
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

}
