function Confirm-CertInstall {
    param(
        [Parameter(Position=0)]
        [string]$CertThumbprint,
        [Parameter(Position=1)]
        [string]$PfxFile,
        [Parameter(Position=2)]
        [securestring]$PfxPass,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Process {

        # validate we have at least one of our cert related parameters
        if (-not $CertThumbprint -and -not $PfxFile) {
            throw "CertThumbprint and PfxFile were not provided. You must specify one or both of them."
        }

        # grab the cert thumbprint from the PFX file if it wasn't specified
        if (-not $CertThumbprint) {
            Write-Verbose "Attempting to read Pfx thumbprint"
            $CertThumbprint = Get-PfxThumbprint -PfxFile $PfxFile -PfxPass $PfxPass
        }

        # install the cert if necessary
        if (-not (Test-CertInstalled $CertThumbprint)) {
            if ($PfxFile) {
                $PfxFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PfxFile)
                Import-PfxCertInternal $PfxFile -PfxPass $PfxPass
            } else {
                throw "Certificate thumbprint not found and no PfxFile file specified to import."
            }
        }

        # return the potentially expanded PfxFile path
        return $CertThumbprint

    }
}
