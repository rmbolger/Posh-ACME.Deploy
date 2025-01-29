function Set-PBIRSCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName)]
        [Alias('Thumbprint')]
        [string]$CertThumbprint,
        [Parameter(Position=1,ValueFromPipelineByPropertyName)]
        [string]$PfxFile,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [securestring]$PfxPass,
        [string[]]$WebApplicationsToEdit=@('ReportServerWebApp','PowerBIWebApp','OfficeWebApp','ReportServerWebService'),
        [switch]$RemoveOldCert
    )

    Process {

        # surface exceptions without terminating the whole pipeline
        trap { $PSCmdlet.WriteError($PSItem); return }

        $CertThumbprint = Confirm-CertInstall @PSBoundParameters

        # Get the name of the PBIRS server
        $PBIRSServerName = (Get-WmiObject -Namespace root\Microsoft\SqlServer\ReportServer -Class __Namespace).Name
        # Get the version of the PBIRS server
        $PBIRSVersion = (Get-WmiObject -Namespace root\Microsoft\SqlServer\ReportServer\$PBIRSServerName -Class __Namespace).Name
        # Get the configuration of the PBIRS server
        $PBIRSConfig = Get-WmiObject -Namespace "root\Microsoft\SqlServer\ReportServer\$PBIRSServerName\$PBIRSVersion\Admin" -Class MSReportServer_ConfigurationSetting
        
		# Get the system locale ID
		$lcid = [System.Globalization.CultureInfo]::GetCultureInfo("de-DE").LCID
		
        # Get all configured web applications
        $WebApplications = $PBIRSConfig.ListSSLCertificateBindings($lcid).Application
        Write-Verbose "WebApplications: $WebApplications"
        # Get all configured thumbprints
        $oldCertThumbprints = $PBIRSConfig.ListSSLCertificateBindings($lcid).CertificateHash
        Write-Verbose "OldCertThumbprints: $oldCertThumbprints"
        # Get all configured IPAddresses
        $Addresses = $PBIRSConfig.ListSSLCertificateBindings($lcid).IPAddress
        Write-Verbose "Addresses: $Addresses"
        # Get All configured ports
        $Ports = $PBIRSConfig.ListSSLCertificateBindings($lcid).Port
        Write-Verbose "Ports: $Ports"

        # Remove the old bindings
        for ($i = 0; $i -lt $WebApplications.Count; $i++) {
            
            # Get the actual web application binding details
            $WebApplication = $WebApplications[$i]
            $oldCertThumbprint = $oldCertThumbprints[$i]
            $Address = $Addresses[$i]
            $Port = $Ports[$i]

            # if the certificate thumbprint for the binding is different and the web application is in the list of web applications to be set the certificate for
            if ( "$oldCertThumbprint" -ne "$CertThumbprint" -and $WebApplicationsToEdit.Contains("$WebApplication") ){

                Write-Verbose "Deleting WebApplication $WebApplication, Thumbprint $oldCertThumbprint, Address $Address and Port $Port"
                
                # Remove old binding
                $result = $PBIRSConfig.RemoveSSLCertificateBindings("$WebApplication", $oldCertThumbprint, $Address, $Port, $lcid)
				if (!($result.HRESULT -eq 0)) { write-error $result.Error }
            } else {
                Write-Verbose "Not deleting WebApplication $WebApplication, Thumbprint $OldCertThumbprint, Address $Address and Port $Port"
            }
        }
		
		# Add a binding with the new certificate for every web application
		for ($i = 0; $i -lt $WebApplications.Count; $i++) {
            
            # Get the actual web application binding details
            $WebApplication = $WebApplications[$i]
            $oldCertThumbprint = $oldCertThumbprints[$i]
            $Address = $Addresses[$i]
            $Port = $Ports[$i]

            # if the certificate thumbprint for the binding is different and the web application is in the list of web applications to be set the certificate for
            if ( "$oldCertThumbprint" -ne "$CertThumbprint" -and $WebApplicationsToEdit.Contains("$WebApplication") ){

                Write-Verbose "Adding WebApplication $WebApplication, Thumbprint $oldCertThumbprint, Address $Address and Port $Port"
                
                # Add binding with the new certificate thumbprint
                $result = $PBIRSConfig.CreateSSLCertificateBinding("$WebApplication", $CertThumbprint, $Address, $Port, $lcid)
				if (!($result.HRESULT -eq 0)) { write-error $result.Error }
            } else {
                Write-Verbose "Not adding WebApplication $WebApplication, Thumbprint $OldCertThumbprint, Address $Address and Port $Port"
            }
        }

        # remove the old cert if specified
        if ($RemoveOldCert) { Remove-OldCert $OldCertThumbprint }
    }

    <#
    .SYNOPSIS
        Configure the PowerBI Reporting Services to use the specified certificate.

    .DESCRIPTION
        Intended to be used with the output from Posh-ACME's New-PACertificate or Submit-Renewal.

    .PARAMETER CertThumbprint
        Thumbprint/Fingerprint for the certificate to configure.

    .PARAMETER PfxFile
        Path to a PFX containing a certificate and private key. Not required if the certificate is already in the local system's Personal certificate store.

    .PARAMETER PfxPass
        The export password for the specified PfxFile parameter. Not required if the Pfx does not require an export password.

    .PARAMETER WebApplications
        The PBIRS WebApplications the certificate should be replaced for. Defaults to 'ReportServerWebApp','PowerBIWebApp','OfficeWebApp','ReportServerWebService'.

    .EXAMPLE
        New-PACertificate site1.example.com | Set-PBIRSCertificate

        Create a new certificate and configure it for the PowerBI Reporting Services on this system.

    .EXAMPLE
        Submit-Renewal site1.example.com | Set-PBIRSCertificate

        Renew a certificate and configure it for the PowerBI Reporting Services on this system.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME.Deploy

    #>
}
