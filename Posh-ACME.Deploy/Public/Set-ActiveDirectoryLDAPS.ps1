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

        $LocalCertStore = 'HKLM:/Software/Microsoft/SystemCertificates/My/Certificates'

        # Make sure the NTDS store exists
        $NtdsCertStore = 'HKLM:/Software/Microsoft/Cryptography/Services/NTDS/SystemCertificates/My/Certificates'
        if (-Not (Test-Path $NtdsCertStore)) {
	        $null = New-Item $NtdsCertStore -Force
        }

        # Look for the old cert thumbprint
        $oldThumbprint = Get-ChildItem $NtdsCertStore | Select-Object -First 1 | Select-Object -Expand PSChildName

        # Copy cert from local store to NTDS Store
        Copy-Item -Path "$LocalCertStore/$CertThumbprint" -Destination $NtdsCertStore

        # Remove old copies if necessary
        if ($RemoveOldCert -and $oldThumbprint) {
            Get-ChildItem $NtdsCertStore | Where-Object { $_.PSChildName -eq $oldThumbprint } | Remove-Item
            Get-ChildItem $LocalCertStore | Where-Object { $_.PSChildName -eq $oldThumbprint } | Remove-Item
        }

        # Command AD to update.
        $dse = [adsi]'LDAP://localhost/rootDSE'
        [void]$dse.Properties['renewServerCertificate'].Add(1)
        $dse.CommitChanges()
    }
}
