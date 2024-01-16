@{

RootModule = 'Posh-ACME.Deploy.psm1'
ModuleVersion = '1.6.0'
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
## 1.6.0 (2023-01-23)

* Set-IISCertificateNew now accepts a string array for the `-HostHeader` param which will create bindings for each value instead of needing to call the function multiple times. (#23)
* Set-NPSCertificate now has a `-PolicyXPath` parameter which can be used instead of `-PolicyName` to apply the certificate to all matching policies in the XPath statement. (#24)
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

}
