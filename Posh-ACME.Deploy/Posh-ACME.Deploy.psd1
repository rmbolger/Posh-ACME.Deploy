@{

RootModule = 'Posh-ACME.Deploy.psm1'
ModuleVersion = '2.0.1'
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
    'Set-IISCertificateOld'
    'Set-IISFTPCertificate'
    'Set-PBIRSCertificate'
    'Set-RASSTPCertificate'
    'Set-RDGWCertificate'
    'Set-RDSHCertificate'
    'Set-WinRMCertificate'
    'Set-NPSCertificate'
)
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @(
    'Set-IISCertificateNew'
)

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
## 2.0.1 (2025-02-19)

* Fix TypeNotFound error in Set-IISCertificate for SslFlags enum (#31)
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

}
