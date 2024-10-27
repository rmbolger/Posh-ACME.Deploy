function Set-ActiveDirectoryLDAPS {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,       
        [switch]$RemoveOldCert
    )

    Process {

        # surface exceptions without terminating the whole pipeline
        trap { $PSCmdlet.WriteError($PSItem); return }

        $CertThumbprint = Confirm-CertInstall @PSBoundParameters
        
        # Copy cert from local store to NTDS Store
        $LocalCertStore = 'HKLM:/Software/Microsoft/SystemCertificates/My/Certificates'
        $NtdsCertStore = 'HKLM:/Software/Microsoft/Cryptography/Services/NTDS/SystemCertificates/My/Certificates'
        if (-Not (Test-Path $NtdsCertStore)) {
	        New-Item $NtdsCertStore -Force
        }
        Copy-Item -Path "$LocalCertStore/$CertThumbprint" -Destination $NtdsCertStore
        
        # Command AD to update.
        $dse = [adsi]'LDAP://localhost/rootDSE'
        [void]$dse.Properties['renewServerCertificate'].Add(1)
        $dse.CommitChanges()        
    
        if ($RemoveOldCert) {
            Get-ChildItem $NtdsCertStore | Select -Expand Name | ForEach-Object {
                if ($_ -notlike "*$CertThumbprint*") {
                    Remove-Item Registry::$_
                }
            }
        }
    }
}
