# Posh-ACME.Deploy

A Collection of certificate deployment functions intended for use with [Posh-ACME](https://github.com/rmbolger/Posh-ACME). But the functions should be generic enough to work with any certificate.

## Supported Deployment Targets

- IIS 7.0+
- IIS FTP services
- Remote Desktop Session Host / Remote Desktop listener
- Remote Desktop Gateway
- WinRM
- Exchange (tested on 2019)
- [Network Policy Server (NPS)](https://docs.microsoft.com/en-us/windows-server/networking/technologies/nps/nps-top)
- Remote Access SSTP
- Active Directory (LDAPS)
- PowerBI Reporting Services

## Installation (Stable)

The latest release version can found in the [PowerShell Gallery](https://www.powershellgallery.com/packages/Posh-ACME.Deploy/) or the [GitHub releases page](https://github.com/rmbolger/Posh-ACME.Deploy/releases). Installing from the gallery is easiest using `Install-Module` from the PowerShellGet module. See [Installing PowerShellGet](https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget) if you don't already have it installed.

```powershell
# install for all users (requires elevated privs)
Install-Module -Name Posh-ACME.Deploy -Scope AllUsers

# install for current user
Install-Module -Name Posh-ACME.Deploy -Scope CurrentUser
```

*NOTE: If you use PowerShell 5.1 or earlier, `Install-Module` may throw an error depending on your Windows and .NET version due to a change PowerShell Gallery made to their TLS settings. For more info and a workaround, see the [official blog post](https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/).*

## Installation (Development)

To install the latest *development* version from the git main branch, use the following PowerShell command. This method assumes a default [`PSModulePath`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath) environment variable.

```powershell
# install latest dev version
iex (irm https://raw.githubusercontent.com/rmbolger/Posh-ACME.Deploy/main/instdev.ps1)
```

## Quick Start

An IIS website tends to be the most common certificate target for this module. We'll assume you have already created a cert using [Posh-ACME](https://github.com/rmbolger/Posh-ACME) and want to deploy it to the default site in IIS and bound to all IPs and port 443 with no host header or [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) requirement. *(SNI and host headers for TLS require IIS 8.0+)*

First, make sure your PowerShell session is running as admin. For the initial deployment, you can do something like this which will import the cert into the `LocalMachine\My` certificate store and add/update the site's https binding with the selected certificate. The `-Verbose` flag is optional but can be a nice way to see what's happening. If you need to customize the binding parameters, check the function's help with `Get-Help Set-IISCertificate`.

```powershell
Set-PAOrder example.com
Get-PACertificate | Set-IISCertificate -SiteName 'Default Web Site' -Verbose
```

Your Posh-ACME renewal script might look something like this.

```powershell
Set-PAOrder example.com
if ($cert = Submit-Renewal) {
    $cert | Set-IISCertificate -SiteName 'Default Web Site' -RemoveOldCert
}
```

`Submit-Renewal` only returns a certificate object when it successfully renews the certificate. So you generally run it 1-2 times per day and it doesn't do anything until the renewal window has been reached. The `-RemoveOldCert` parameter will delete the previous certificate from the Windows certificate store after it successfully imports and configures the new one.

The rest of the functions in this module work very similarly. Check the associated parameters using `Get-Help <function>` for details. Additional documentation can be found [here](https://docs.dvolve.net/Posh-ACME.Deploy/)

## Requirements and Platform Support

All of the currently included functions are tied to Windows services and related modules. Generally, you should have Windows PowerShell 5.1 with .NET Framework 4.7.1 or later which are the same minimum requirements as Posh-ACME.

PowerShell 7+ support will be dependent on the specific function you're using and whether any dependent modules (WebAdministration, RemoteDesktopServices, etc) are compatible.

## Changelog

See [CHANGELOG.md](https://github.com/rmbolger/Posh-ACME.Deploy/blob/main/CHANGELOG.md)
