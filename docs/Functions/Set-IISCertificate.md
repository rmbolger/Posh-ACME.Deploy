---
external help file: Posh-ACME.Deploy-help.xml
Module Name: Posh-ACME.Deploy
online version: https://docs.dvolve.net/Posh-ACME.Deploy/v2/Functions/Set-IISCertificate/
schema: 2.0.0
---

# Set-IISCertificate

## Synopsis

Configure RD Session Host service to use the specified certificate.

## Syntax

```powershell
Set-IISCertificate [[-CertThumbprint] <String>] [[-PfxFile] <String>] [[-PfxPass] <SecureString>]
 [-SiteName <String>] [-Port <UInt32>] [-IPAddress <String>] [-HostHeader <String[]>] [-RequireSNI]
 [-DisableHTTP2] [-DisableOCSPStapling] [-DisableQUIC] [-DisableTLS13] [-DisableLegacyTLS] [-RemoveOldCert]
 [-Force] [<CommonParameters>]
```

## Description

Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

This function is dependent on the IISAdministration module version 1.1.0.0 or greater which
can be installed from the PowerShell Gallery.
https://blogs.iis.net/iisteam/introducing-iisadministration-in-the-powershell-gallery

Some of the SSL binding flags like DisableTLS13 might not be supported on older versions of IIS.

## Examples

### EXAMPLE 1
```
New-PACertificate site1.example.com | Set-IISCertificateNew -SiteName "My Website"
```

Create a new certificate and add it to the specified IIS website on the default port.

### EXAMPLE 2
```
Submit-Renewal site1.example.com | Set-IISCertificateNew -SiteName "My Website"
```

Renew a certificate and and add it to the specified IIS website on the default port.

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

### -DisableHTTP2
If specified, the "Disable HTTP/2" box will be checked for the site binding.

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

### -DisableLegacyTLS
If specified, the "Disable Legacy TLS" box will be checked for the site binding.

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

### -DisableOCSPStapling
If specified, the "Disable OCSP Stapling" box will be checked for the site binding.

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

### -DisableQUIC
If specified, the "Disable QUIC" box will be checked for the site binding.

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

### -DisableTLS13
If specified, the "Disable TLS 1.3 over TCP" box will be checked for the site binding.

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

### -Force
If specified, the -Force switch will be passed through to New-IISSiteBinding which should only be necessary if there are multiple Sites using the same binding.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HostHeader
The "Host name" value for the site binding.
If empty, this binding will respond to all names.
You can also pass an array of names to create a binding for each name in the array.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: @('')
Accept pipeline input: False
Accept wildcard characters: False
```

### -IPAddress
The listening IP Address for the site binding.
Defaults to '*' which is "All Unassigned" in the IIS management console.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: *
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

### -Port
The listening TCP port for the site binding.
Defaults to 443.

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 443
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

### -RequireSNI
If specified, the "Require Server Name Indication" box will be checked for the site binding.

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
The IIS web site name to modify bindings on.
Defaults to "Default Web Site".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Default Web Site
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links
