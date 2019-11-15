@{

RootModule = 'Posh-ACME.Deploy.psm1'
ModuleVersion = '1.0'
GUID = '79819e0a-30db-4742-bcc4-0c956273db51'
Author = 'Ryan Bolger'
Copyright = '(c) 2018 Ryan Bolger. All rights reserved.'
Description = 'Deployment helper functions for Posh-ACME'
CompatiblePSEditions = 'Desktop'
PowerShellVersion = '5.1'
DotNetFrameworkVersion = '4.7.1'

FunctionsToExport = @(
    'Set-IISCertificate'
    'Set-RDGWCertificate'
    'Set-RDSHCertificate'
    'Set-WinRMCertificate'
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
        LicenseUri = 'https://github.com/rmbolger/Posh-ACME.Deploy/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rmbolger/Posh-ACME.Deploy'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @'
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

}
