# Posh-ACME.Deploy

A Collection of certificate deployment functions intended for use with [Posh-ACME](https://github.com/rmbolger/Posh-ACME). But the functions should be generic enough to work with any certificate.

# Supported Deployment Targets

- Remote Desktop Session Host
- Remote Desktop Gateway

# Install

The [latest release version](https://www.powershellgallery.com/packages/Posh-ACME.Deploy) can found in the PowerShell Gallery. Installing from the gallery requires the PowerShellGet module which is installed by default on Windows 10 or later. See [Getting Started with the Gallery](https://www.powershellgallery.com/) for instructions on earlier OSes. Zip/Tar versions can also be downloaded from the [GitHub releases page](https://github.com/rmbolger/Posh-ACME.Deploy/releases).

```powershell
# install for all users (requires elevated privs)
Install-Module -Name Posh-ACME.Deploy

# install for current user
Install-Module -Name Posh-ACME.Deploy -Scope CurrentUser
```

To install the latest *development* version from the git master branch, use the following command in PowerShell v3 or later. This method assumes a default Windows PowerShell environment that includes the [`PSModulePath`](https://msdn.microsoft.com/en-us/library/dd878326.aspx) environment variable which contains a reference to `$HOME\Documents\WindowsPowerShell\Modules`. You must also make sure `Get-ExecutionPolicy` is not set to `Restricted` or `AllSigned`.

```powershell
# (optional) set less restrictive execution policy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# install latest dev version
iex (invoke-restmethod https://raw.githubusercontent.com/rmbolger/Posh-ACME.Deploy/master/instdev.ps1)
```


# Quick Start

TODO

# Requirements and Platform Support

* Requires Windows PowerShell 5.1 or later (a.k.a. Desktop edition).
* Requires .NET Framework 4.7.1 or later

# Changelog

See [CHANGELOG.md](/CHANGELOG.md)
