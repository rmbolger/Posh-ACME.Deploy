# Posh-ACME.Deploy

A Collection of certificate deployment functions intended for use with [Posh-ACME](https://github.com/rmbolger/Posh-ACME). But the functions should be generic enough to work with any certificate.

# Supported Deployment Targets

- IIS 7.0+
- Remote Desktop Session Host
- Remote Desktop Gateway
- WinRM

# Install

## Release

*(When released)* The [latest release version](https://www.powershellgallery.com/packages/Posh-ACME.Deploy) can found in the PowerShell Gallery. Installing from the gallery requires the PowerShellGet module which is installed by default on Windows 10 or later and all versions of PowerShell Core. See [Getting Started with the Gallery](https://www.powershellgallery.com/) for instructions on earlier OSes. Zip/Tar versions can also be downloaded from the [GitHub releases page](https://github.com/rmbolger/Posh-ACME.Deploy/releases).


```powershell
# install for all users (requires elevated privs)
Install-Module Posh-ACME.Deploy -Scope AllUsers

# install for current user
Install-Module Posh-ACME.Deploy -Scope CurrentUser
```

## Development

To install the latest *development* version from the git master branch, use the following PowerShell command. This method assumes a default PowerShell environment that includes the [`PSModulePath`](https://msdn.microsoft.com/en-us/library/dd878326.aspx) environment variable. You must also make sure `Get-ExecutionPolicy` does not return `Restricted` or `AllSigned`.

```powershell
# (optional) set less restrictive execution policy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# install latest dev version
iex (irm https://raw.githubusercontent.com/rmbolger/Posh-ACME.Deploy/master/instdev.ps1)
```

# Quick Start

TODO

# Requirements and Platform Support

* Supports Windows PowerShell 5.1 or later (Desktop edition) **with .NET Framework 4.7.1** or later

# Changelog

See [CHANGELOG.md](/CHANGELOG.md)
