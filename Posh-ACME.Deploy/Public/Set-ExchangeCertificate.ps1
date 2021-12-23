function Set-ExchangeCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,
        [string[]]$ExchangeServices=@('IMAP', 'POP', 'IIS','SMTP'),
        [switch]$RemoveOldCert
    )

    Begin {
    
        # make sure the Exchange snapin is available on the local system
        if (!(Get-PSSnapin -Registered | Where-Object { $_.Name -match "Microsoft.Exchange.Management.PowerShell" })) {
            throw "The Microsoft.Exchange.Management.PowerShell snapin is required to use this function."
        } else {
            if (!(Get-PSSnapin | Where-Object {
                  $_.Name -match "Microsoft.Exchange.Management.PowerShell" -and (
                      $_.Name -match "Admin" -or
                      $_.Name -match "E2010" -or
                      $_.Name -match "SnapIn"
                  )
            })) {
                 Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
                 }
        }
    }

    Process {

        # surface individual errors without terminating the whole pipeline
        trap { $PSCmdlet.WriteError($PSItem); return }

        $CertThumbprint = Confirm-CertInstall @PSBoundParameters

        $Cert = Get-ChildItem -Path "Cert:\LocalMachine\My\$CertThumbprint"
        $CertExpire = $Cert.NotBefore

        # find the old thumbprint value for the specified services
        $OldCertThumbprint = ''
        $OldCertSubject = ''
        $OldCertExpire = ''
        $ExchangeCerts = Get-ExchangeCertificate 
        $ExchangeCerts | ForEach-Object {
            $CertServices = $_.Services -split ', '
            $ServicesDiff = Compare-Object -ReferenceObject $ExchangeServices -DifferenceObject $CertServices
            if ($ServicesDiff.Length -eq 0) { # No differences? means same services
                $OldCertThumbprint = $_.Thumbprint.ToString()
                $OldCertSubject = $_.Subject.ToString()
                $OldCertExpire = $_.NotAfter
            }
        }

        $NewCertInstalled = $false

        if ($OldCertThumbprint -eq $CertThumbprint) { # Already registered in Exchange?

            Write-Host "Specified certificate ($OldCertSubject, Expiring: $OldCertExpire) is already configured for Exchange services: $ExchangeServices."

        } else {

            try {

                # set the new value
                Write-Host "Setting new Exchange thumbprint: $CertThumbprint value Expiring: $CertExpire"
                Enable-ExchangeCertificate -Services $ExchangeServices -Thumbprint $CertThumbprint -Force -EA Stop -Verbose:$false

                $NewCertInstalled = $true

            } catch { throw }

        }

        # automatically unconfigure old certs for the current service list from Exchange
        $ExchangeCerts | ForEach-Object {
            $ThisServices = $_.Services -split ', '
            $ThisSubject = $_.Subject
            $ThisNotAfter = $_.NotAfter
            $ThisThumbprint = $_.Thumbprint
            $ServicesDiff = Compare-Object -ReferenceObject $ExchangeServices -DifferenceObject $ThisServices
            if (($ServicesDiff.Length -eq 0) -and ($_.Thumbprint.ToString() -ne $CertThumbprint)) { # Same Services but not just installed
                Write-Host "Removing certificate ($ThisSubject Expiring: $ThisNotAfter) from the Exchange Configuration. Thumbprint: $ThisThumbprint"
                Remove-ExchangeCertificate -Thumbprint $_.Thumbprint -Confirm:$false
                # remove old cert if specified
                if ($RemoveOldCert) {
                    Remove-OldCert $_.Thumbprint.ToString()
                }
            }
        }

        if (($NewCertInstalled) -and ('IIS' -in $ExchangeServices)) {
            $TempFile = New-TemporaryFile
            $IISCommand = (Get-Command 'iisreset.exe').Path
            Start-Process -FilePath $IISCommand -ArgumentList '/RESTART' -NoNewWindow -RedirectStandardOutput $TempFile -Wait 
            Get-Content $TempFile | Write-Host
            Remove-Item $TempFile
        }

    }





    <#
    .SYNOPSIS
        Configure Exchange service to use the specified certificate.

    .DESCRIPTION
        Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

    .PARAMETER CertThumbprint
        Thumbprint/Fingerprint for the certificate to configure.

    .PARAMETER PfxFile
        Path to a PFX containing a certificate and private key. Not required if the certificate is already in the local system's Personal certificate store.

    .PARAMETER PfxPass
        The export password for the specified PfxFile parameter. Not required if the Pfx does not require an export password.

    .PARAMETER ExchangeServices
        The name of the Exchange services to configure. Defaults to 'IIS,SMTP'.

    .PARAMETER RemoveOldCert
        If specified, the old certificate associated with RDP will be deleted from the local system's Personal certificate store. Ignored if the old certificate has already been removed or otherwise can't be found.

    .EXAMPLE
        New-PACertificate site1.example.com | Set-ExchangeCertificate

        Create a new certificate and configure it for Exchange on this system.

    .EXAMPLE
        Submit-Renewal site1.example.com | Set-ExchangeCertificate

        Renew a certificate and configure it for Exchange on this system.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME.Deploy

    #>
}
