---
external help file: Posh-ACME.Deploy-help.xml
Module Name: Posh-ACME.Deploy
online version: https://docs.dvolve.net/Posh-ACME.Deploy/v2/Functions/Set-ActiveDirectoryLDAPS/
schema: 2.0.0
---

# Set-ActiveDirectoryLDAPS

## Synopsis

Configure Active Directory Domain Services (ADDS) certificate.

## Syntax

```powershell
Set-ActiveDirectoryLDAPS [[-CertThumbprint] <String>] [[-PfxFile] <String>] [[-PfxPass] <SecureString>]
 [-RemoveOldCert] [<CommonParameters>]
```

## Description

In cases where ADDS does not automatically pick up the LDAPS certificate from the Local Computer cert store, it can be necessary to explicitly import the cert into the NTDS Service store. Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

This requires elevated/admin access on the domain controller.

## Examples

### EXAMPLE 1
```
$dc = Get-ADDomainController -Discover
$domains = $dc.HostName, $dc.Domain
New-PACertificate $domains | Set-ActiveDirectoryLDAPS -RemoveOldCert
```

Create a new certificate for the DC and domain's FQDNs and add configure Active Directory to use it for LDAPS.

## Parameters

### -CertThumbprint
Thumbprint/Fingerprint for the certificate to configure.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Thumbprint

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PfxFile
Path to a PFX containing a certificate and private key.
Not required if the certificate is already in the local system's Personal certificate store.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PfxPass
The export password for the specified PfxFile parameter.
Not required if the Pfx does not require an export password.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -RemoveOldCert
If specified, the old certificate will be deleted from the local system's Personal certificate store.
Ignored if the old certificate has already been removed or otherwise can't be found.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links
