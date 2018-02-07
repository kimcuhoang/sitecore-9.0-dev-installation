#####################################################
# 
#  Uninstall Sitecore
# 
#####################################################
$ErrorActionPreference = "Stop"
. $PSScriptRoot\settings.ps1

Write-Host "*******************************************************" -ForegroundColor Green
Write-Host " UN Installing Sitecore $SitecoreVersion" -ForegroundColor Green
Write-Host " Sitecore: $SitecoreSiteName" -ForegroundColor Green
Write-Host " xConnect: $XConnectSiteName" -ForegroundColor Green
Write-Host "*******************************************************" -ForegroundColor Green

if (Get-Module("uninstall")) {
    Remove-Module "uninstall"
}

# $carbon = Get-Module Carbon
# if (-not $carbon) {
#     write-host "Installing Carbon..." -ForegroundColor Green
#     Install-Module -Name 'Carbon' -AllowClobber -Scope CurrentUser
#     Import-Module Carbon
# }

Import-Module "$PSScriptRoot\build\uninstall\uninstall.psm1"



$database = Get-SitecoreDatabase -SqlServer $SqlServer -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminPassword

# Unregister xconnect services
Remove-SitecoreWindowsService "$XConnectSiteName-MarketingAutomationService"
Remove-SitecoreWindowsService "$XConnectSiteName-IndexWorker"

# Delete xconnect site
Remove-SitecoreIisSite $XConnectSiteName

# Drop xconnect databases
Remove-SitecoreDatabase -Name "${SolutionPrefix}_Xdb.Collection.Shard0" -Server $database
Remove-SitecoreDatabase -Name "${SolutionPrefix}_Xdb.Collection.Shard1" -Server $database
Remove-SitecoreDatabase -Name "${SolutionPrefix}_Xdb.Collection.ShardMapManager" -Server $database
Remove-SitecoreDatabase -Name "${SolutionPrefix}_MarketingAutomation" -Server $database
Remove-SitecoreDatabase -Name "${SolutionPrefix}_Processing.Pools" -Server $database
Remove-SitecoreDatabase -Name "${SolutionPrefix}_Processing.Tasks" -Server $database
Remove-SitecoreDatabase -Name "${SolutionPrefix}_ReferenceData" -Server $database
Remove-SitecoreDatabase -Name "${SolutionPrefix}_Reporting" -Server $database

# Delete xconnect files
Remove-SitecoreFiles $XConnectSiteRoot

# Delete xconnect server certificate
Remove-SitecoreCertificate $XConnectSiteName
# Delete xconnect client certificate
Remove-SitecoreCertificate $XConnectCert

# Delete sitecore site
Remove-SitecoreIisSite $SitecoreSiteName

# Drop sitecore databases
Remove-SitecoreDatabase -Name "${SolutionPrefix}_Core" -Server $database
Remove-SitecoreDatabase -Name "${SolutionPrefix}_ExperienceForms" -Server $database
Remove-SitecoreDatabase -Name "${SolutionPrefix}_Master" -Server $database
Remove-SitecoreDatabase -Name "${SolutionPrefix}_Web" -Server $database

# Delete sitecore files
Remove-SitecoreFiles $SitecoreSiteRoot

# Delete sitecore certificate
Remove-SitecoreCertificate $SitecoreSiteName

# Delete Solr Cores
if (Get-Module("solr")) {
    Remove-Module "solr"
}
Import-Module "$SolrDockerPath\solr.psm1"
Remove-SitecoreSolrCore -SolrUrl $SolrUrl -SolutionPrefix $SolutionPrefix
Uninstall-Solr -DockerComposeFile $DockerComposeFile `
                -SolrDataRoot $SolrRoot `
                -P12KeystoreFile $P12KeystoreFile `
                -KeystorePassword $KeystorePassword

#Remove log files
get-childitem .\ -include *.log -recurse | foreach ($_) {Remove-Item $_.fullname}
