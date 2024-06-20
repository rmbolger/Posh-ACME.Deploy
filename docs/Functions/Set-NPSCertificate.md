---
external help file: Posh-ACME.Deploy-help.xml
Module Name: Posh-ACME.Deploy
online version: https://docs.dvolve.net/Posh-ACME.Deploy/v2/Functions/Set-NPSCertificate/
schema: 2.0.0
---

# Set-NPSCertificate

## Synopsis

Configure a NPS Network Policy to use the specified certificate for MS PEAP.

## Syntax

### ByName (Default)
```powershell
Set-NPSCertificate [[-CertThumbprint] <String>] [[-PfxFile] <String>] [[-PfxPass] <SecureString>]
 [-IASConfigPath <String>] -PolicyName <String> [-RemoveOldCert] [<CommonParameters>]
```

### ByXPath
```powershell
Set-NPSCertificate [[-CertThumbprint] <String>] [[-PfxFile] <String>] [[-PfxPass] <SecureString>]
 [-IASConfigPath <String>] -PolicyXPath <String> [-RemoveOldCert] [<CommonParameters>]
```

## Description

Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

## Examples

### EXAMPLE 1
```
New-PACertificate site1.example.com | Set-NPSCertificate -PolicyName "Secure Wireless Connections"
```

Create a new certificate and add it to the specified NPS Network Policy.

### EXAMPLE 2
```
Submit-Renewal site1.example.com | Set-NPSCertificate -PolicyName "Secure Wireless Connections"
```

Renew a certificate and and add it to the specified NPS Network Policy.

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

### -IASConfigPath
The path to the NPS config file you want to edit.
Default: %SystemRoot%\System32\ias\ias.xml

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: %SystemRoot%\System32\ias\ias.xml
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

### -PolicyName
The name of the Network Policy.

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PolicyXPath
An XPath expression that returns one or more Network Policies with an msEAPConfiguration element.
An example that would return all policies might be '//RadiusProfiles//Children/*\[descendant::msEAPConfiguration\]'.
This is for advanced usage where you are updating multiple policies with the same certificate.

```yaml
Type: String
Parameter Sets: ByXPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
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
