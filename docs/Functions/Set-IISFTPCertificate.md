---
external help file: Posh-ACME.Deploy-help.xml
Module Name: Posh-ACME.Deploy
online version: https://docs.dvolve.net/Posh-ACME.Deploy/v2/Functions/Set-IISFTPCertificate/
schema: 2.0.0
---

# Set-IISFTPCertificate

## Synopsis

Configure RD Session Host service to use the specified certificate.

## Syntax

```powershell
Set-IISFTPCertificate [[-CertThumbprint] <String>] [[-PfxFile] <String>] [[-PfxPass] <SecureString>]
 -SiteName <String> [-ControlChannelPolicy <String>] [-DataChannelPolicy <String>] [-Use128BitEncryption]
 [-RemoveOldCert] [<CommonParameters>]
```

## Description

Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

## Examples

### EXAMPLE 1
```
New-PACertificate site1.example.com | Set-IISFTPCertificate -SiteName "My FTP"
```

Create a new certificate and add it to the specified IIS FTP site.

### EXAMPLE 2
```
Submit-Renewal site1.example.com | Set-IISFTPCertificate -SiteName "My FTP"
```

Renew a certificate and and add it to the specified IIS FTP site.

## Parameters

### -CertThumbprint
Thumbprint/Fingerprint for the certificate to configure.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Thumbprint

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ControlChannelPolicy
The control channel policy that should be configured for the FTP site: SslRequire, SslAllow, or SslRequireCredentialsOnly.
See https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/ftpserver/security/ssl for details.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DataChannelPolicy
The data channel policy that should be configured for the FTP site: SslRequire, SslAllow, or SslDeny.
See https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/ftpserver/security/ssl for details.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
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
Position: 2
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
Position: 3
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

### -SiteName
The IIS FTP site name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Use128BitEncryption
If specified, enable 128-bit encryption for SSL connections to the FTP site.

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

[FTP over SSL Documentation](https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/ftpserver/security/ssl)
