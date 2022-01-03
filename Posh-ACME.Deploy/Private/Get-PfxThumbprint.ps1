function Get-PfxThumbprint {
    [OutputType('System.String')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$PfxFile,
        [Parameter(Position=1)]
        [securestring]$PfxPass
    )

    # The PowerShell native Get-PfxCertificate function that exists in 5.1 doesn't
    # have a parameter to supply the PFX password and only prompts for it. So we'll
    # use the native function if it's new enough and supports the param, but
    # otherwise falls back to the .NET cert libraries to read the file. Both methods
    # return a standard X509Certificate2 object that should be disposed.

    if (-not $PfxPass) {
        # create an empty secure string
        $PfxPass = New-Object Security.SecureString
    }

    try {

        if ('Password' -in (Get-Command Get-PfxCertificate).Parameters.Keys) {

            # use the native function
            $cert = Get-PfxCertificate -FilePath $PfxFile -Password $PfxPass

        } else {

            # .NET needs the password in plain text
            $passPlain = [pscredential]::new('a',$PfxPass).GetNetworkCredential().Password

            # read the file
            $cert = [Security.Cryptography.X509Certificates.X509Certificate2]::new()
            $cert.Import($PfxFile, $passPlain, 'DefaultKeySet')
        }

        return $cert.Thumbprint

    } finally {
        if ($null -ne $cert) { $cert.Dispose() }
    }

}
