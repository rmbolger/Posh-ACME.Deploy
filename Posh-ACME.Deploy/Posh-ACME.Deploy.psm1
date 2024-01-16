#Requires -Version 5.1

# Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the files
Foreach($import in @($Public + $Private))
{
    Try { . $import.fullname }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Set-IISCertificateNew was renamed to Set-IISCertificate in 2.x. But we'll add
# an alias to the old name to reduce script breakage until the next major version.
Set-Alias Set-IISCertificateNew -Value Set-IISCertificate
