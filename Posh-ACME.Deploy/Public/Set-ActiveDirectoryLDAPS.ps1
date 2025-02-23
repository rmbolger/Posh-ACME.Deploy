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
            Write-Verbose "Existing NTDS cert store not found. Creating the necessary reg key."
            $null = New-Item $NtdsCertStore -Force
        }

        # Look for the old cert thumbprint
        $oldThumbprint = Get-ChildItem $NtdsCertStore | Select-Object -First 1 | Select-Object -Expand PSChildName

        # Copy cert from local store to NTDS Store
        Write-Verbose "Copying cert with thumbprint $CertThumbprint to NTDS cert store."
        Copy-Item -Path "$LocalCertStore/$CertThumbprint" -Destination $NtdsCertStore

        # Remove all certs except the new one from the NTDS store
        Write-Verbose "Removing certs not matching thumbprint $CertThumbprint from NTDS cert store."
        Get-ChildItem $NtdsCertStore | Where-Object { $_.PSChildName -ne $CertThumbprint } | Remove-Item

        # Command AD to update.
        Write-Verbose "Triggering NTDS cert update."
        $dse = [adsi]'LDAP://localhost/rootDSE'
        [void]$dse.Properties['renewServerCertificate'].Add(1)
        $dse.CommitChanges()

        # Remove the old cert from LocalMachine if asked to
        if ($RemoveOldCert -and $oldThumbprint) {
            Write-Verbose "Removing old cert with thumbprint $oldThumbprint from Local Machine cert store."
            Get-ChildItem $LocalCertStore | Where-Object { $_.PSChildName -eq $oldThumbprint } | Remove-Item
        }
    }
}
