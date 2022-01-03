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
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]$StoreLocation = 'LocalMachine',
        [string]$StoreName = 'My',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Process {

        # validate we have at least one of our cert related parameters
        if (-not $CertThumbprint -and -not $PfxFile) {
            throw "CertThumbprint and PfxFile were not provided. You must specify one or both of them."
        }

        $commonSplat = @{
            StoreLocation = $StoreLocation
            StoreName = $StoreName
        }

        # install the cert if necessary
        if ($CertThumbprint -and (Test-CertInstalled $CertThumbprint @commonSplat)) {
            return $CertThumbprint
        }
        if ($PfxFile) {
            # grab the cert thumbprint from the output of the import function
            $PfxFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PfxFile)
            $CertThumbprint = Import-PfxCertInternal $PfxFile $PfxPass @commonSplat
        } else {
            throw "Certificate thumbprint not found and no PfxFile file specified to import."
        }

        # return the thumbprint of the installed cert
        return $CertThumbprint
    }
}
