## 1.5.0 (2022-03-07)

* Set-NPSCertificate now supports both PEAP and EAP-TLS (Thanks @amorrowbellarmine)

## 1.4.0 (2022-01-06)

* Added `Set-IISCertificateNew` which was actually added in 1.3.0 but missed in the release notes. This should functions the same as the existing `Set-IISCertificate` function but is dependent on the IISAdministration module instead of the legacy WebAdministration module and should work on PowerShell 6+. However, it requires at least version 1.1.0.0 of the IISAdministration module which is distributed from powershellgallery.com.
  * Using this function will also work around issue #8 which involves errors for sites with uncommon characters in their names.
* Added `Set-RASSTPCertificate` which can be used to set the certificate for the Remote Access SSTP service. (Thanks @markpizz)
* The `CertThumbprint` parameter is no longer mandatory in the various public functions when `PfxFile` is specified. The thumprint will be read directly from the cert in the PFX if necessary. (#13)
* Improvements and fixes for `Set-ExchangeCertificate` involving old cert removal and cert replacement on renewal. (#19) (Thanks @markpizz)
* Fixed regression in `Set-ExchangeCertificate` from (#16) (Thanks @markpizz)
* Added support in private functions for cert management in locations/stores other than LocalMachine\My.

## 1.3.0 (2021-07-26)

* Added Set-NPSCertificate

## 1.2.0 (2020-10-15)

* Added Set-IISFTPCertificate

## 1.1.0 (2020-06-24)

* Added Set-ExchangeCertificate

## 1.0.0 (2019-12-13)

* Initial Release
* Added functions
  * Set-IISCertificate
  * Set-RDGWCertificate
  * Set-RDSHCertificate
  * Set-WinRMCertificate
