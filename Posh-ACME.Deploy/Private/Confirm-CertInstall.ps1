function Confirm-CertInstall {
    param(
        [Parameter(Position=0)]
        [AllowEmptyString()]
        [string]$CertThumbprint,
        [Parameter(Position=1)]
        [AllowEmptyString()]
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

        # install the cert if necessary
        if (-not (Test-CertInstalled $CertThumbprint)) {
            if ($PfxFile) {# grab the cert thumbprint from the PFX file if it wasn't valid/installed
                $PfxFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PfxFile)
                $CertThumbprint = Import-PfxCertInternal $PfxFile -PfxPass $PfxPass
            } else {
                throw "Certificate thumbprint not found and no PfxFile file specified to import."
            }
        }

        # return the potentially expanded PfxFile path
        return $CertThumbprint

    }
}
