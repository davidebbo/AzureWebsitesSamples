## WebHostingPlan operations

# Example call: ListWebHostingPlans MyResourceGroup
Function ListWebHostingPlans($ResourceGroupName)
{
    Get-AzureResource –ResourceGroupName $ResourceGroupName –ResourceType Microsoft.Web/serverfarms
}

# Example call: GetWebHostingPlan MyResourceGroup MyWHP
Function GetWebHostingPlan($ResourceGroupName, $PlanName)
{
    Get-AzureResource –ResourceGroupName $ResourceGroupName –ResourceType Microsoft.Web/serverfarms –Name $PlanName -ApiVersion 2014-11-01
}


## Site operations


# Example call: ListSites MyResourceGroup
Function ListSites($ResourceGroupName)
{
    Get-AzureResource –ResourceGroupName $ResourceGroupName –ResourceType Microsoft.Web/sites
}

# Example call: GetSite MyResourceGroup MySite
Function GetSite($ResourceGroupName, $SiteName)
{
    Get-AzureResource –ResourceGroupName $ResourceGroupName –ResourceType Microsoft.Web/sites –Name $SiteName -ApiVersion 2014-11-01
}

# Example call: CreateSite MyResourceGroup "North Europe" MySite DefaultServerFarm
Function CreateSite($ResourceGroupName, $Location, $SiteName, $PlanName)
{
    New-AzureResource –ResourceGroupName $ResourceGroupName -Location $Location –ResourceType Microsoft.Web/sites –Name $SiteName -PropertyObject @{ "webHostingPlan" = $PlanName } -ApiVersion 2014-11-01
}

# Example call: DeleteSite MyResourceGroup MySite
Function DeleteSite($ResourceGroupName, $SiteName)
{
    Remove-AzureResource –ResourceGroupName $ResourceGroupName –ResourceType Microsoft.Web/sites –Name $SiteName -ApiVersion 2014-11-01
}

# Example call: $webHostingPlan = GetSiteWebHostingPlan MyResourceGroup MySite
Function GetSiteWebHostingPlan($ResourceGroupName, $SiteName)
{
    $site = GetSite $ResourceGroupName $SiteName
    $site.Properties.webHostingPlan
}

## Site config operations

# Example call: GetSiteConfig MyResourceGroup MySite
Function GetSiteConfig($ResourceGroupName, $SiteName)
{
    Get-AzureResource –ResourceGroupName $ResourceGroupName –ResourceType Microsoft.Web/sites/Config –Name web –ParentResource sites/$SiteName -ApiVersion 2014-11-01
}

# Example call: SetSiteConfig MyResourceGroup MySite $ConfigObject
Function SetSiteConfig($ResourceGroupName, $SiteName, $ConfigObject)
{
    Set-AzureResource –ResourceGroupName $ResourceGroupName –ResourceType Microsoft.Web/sites/Config –Name web –ParentResource sites/$SiteName -PropertyObject $ConfigObject -ApiVersion 2014-11-01
}

# Example call: $phpVersion = GetPHPVersion MyResourceGroup MySite
Function GetPHPVersion($ResourceGroupName, $SiteName)
{
    $config = GetSiteConfig $ResourceGroupName $SiteName
    $config.Properties.phpVersion
}

# Example call: SetPHPVersion MyResourceGroup MySite 5.6
Function SetPHPVersion($ResourceGroupName, $SiteName, $PHPVersion)
{
    SetSiteConfig $ResourceGroupName $SiteName @{ "phpVersion" = $PHPVersion }
}


## Certificate operations

# Example call: UploadCert MyResourceGroup "North Europe" foo.pfx "MyPassword!" MyTestCert
Function UploadCert($ResourceGroupName, $Location, $PfxPath, $PfxPassword, $CertName)
{
    # Read the raw bytes of the pfx file
    $pfxBytes = get-content $PfxPath -Encoding Byte

    $props = @{
        "PfxBlob" = [System.Convert]::ToBase64String($pfxBytes)
        "Password" = $PfxPassword
    }

    New-AzureResource -Location $Location -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/certificates -Name $CertName -PropertyObject $props -ApiVersion 2014-11-01
}

# Example call: DeleteCert MyResourceGroup MyCert
Function DeleteCert($ResourceGroupName, $CertName)
{
    Remove-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/certificates -Name $CertName -ApiVersion 2014-11-01
}
