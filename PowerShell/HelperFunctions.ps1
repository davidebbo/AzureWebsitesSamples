## WebHostingPlan operations

# Example call: ListAppServicePlans MyResourceGroup
Function ListAppServicePlans($ResourceGroupName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/serverfarms -OutputObjectFormat New
}

# Example call: GetAppServicePlan MyResourceGroup MyWHP
Function GetAppServicePlan($ResourceGroupName, $PlanName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/serverfarms -Name $PlanName -OutputObjectFormat New -ApiVersion 2015-04-01
}

# Example call: CreateAppServicePlan MyResourceGroup "North Europe" MyHostingPlan
Function CreateAppServicePlan($ResourceGroupName, $Location, $PlanName, $Sku = "Free")
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -Location $Location -ResourceType Microsoft.Web/serverfarms -Name $PlanName -PropertyObject @{ sku = $Sku } -OutputObjectFormat New -ApiVersion 2015-04-01 -Force
}

# Example call: DeleteSite MyResourceGroup MySite
Function DeleteAppServicePlan($ResourceGroupName, $PlanName)
{
    Remove-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/serverfarms -Name $PlanName -ApiVersion 2015-04-01 -Force
}



## Site operations

# Example call: ListSites MyResourceGroup
Function ListSites($ResourceGroupName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites -OutputObjectFormat New
}

# Example call: GetSite MyResourceGroup MySite
Function GetSite($ResourceGroupName, $SiteName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites -Name $SiteName -OutputObjectFormat New -ApiVersion 2015-04-01
}

# Example call: CreateSite MyResourceGroup "North Europe" MySite DefaultServerFarm
Function CreateSite($ResourceGroupName, $Location, $SiteName, $PlanName)
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -Location $Location -ResourceType Microsoft.Web/sites -Name $SiteName -PropertyObject @{ webHostingPlan = $PlanName } -OutputObjectFormat New -ApiVersion 2015-04-01 -Force
}

# Example call: DeleteSite MyResourceGroup MySite
Function DeleteSite($ResourceGroupName, $SiteName)
{
    Remove-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites -Name $SiteName -ApiVersion 2015-04-01 -Force
}

# Example call: $planId = GetSiteAppServicePlanId MyResourceGroup MySite
Function GetSiteAppServicePlanId($ResourceGroupName, $SiteName)
{
    $site = GetSite $ResourceGroupName $SiteName
    $site.Properties.serverFarmId
}


## Site config operations

# Example call: GetSiteConfig MyResourceGroup MySite
Function GetSiteConfig($ResourceGroupName, $SiteName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/web -OutputObjectFormat New -ApiVersion 2015-04-01
}

# Example call: SetSiteConfig MyResourceGroup MySite $ConfigObject
Function SetSiteConfig($ResourceGroupName, $SiteName, $ConfigObject)
{
    Set-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/web -PropertyObject $ConfigObject -OutputObjectFormat New -ApiVersion 2015-04-01 -Force
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


## App Settings

# Example call: GetSiteAppSettings MyResourceGroup MySite
Function GetSiteAppSettings($ResourceGroupName, $SiteName)
{
    $res = Invoke-AzureResourceAction -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/appsettings -Action list -ApiVersion 2015-04-01 -Force
    $res.Properties
}

# Example call: SetSiteAppSettings MyResourceGroup MySite @{ key1 = "val1"; key2 = "val2" }
Function SetSiteAppSettings($ResourceGroupName, $SiteName, $AppSettingsObject)
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/appsettings -PropertyObject $AppSettingsObject -OutputObjectFormat New -ApiVersion 2015-04-01 -Force
}


## Connection Strings

# Example call: GetSiteConnectionStrings MyResourceGroup MySite
Function GetSiteConnectionStrings($ResourceGroupName, $SiteName)
{
    $res = Invoke-AzureResourceAction -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/connectionstrings -Action list -ApiVersion 2015-04-01 -Force
    $res.Properties
}

# Example call: SetSiteConnectionStrings MyResourceGroup MySite @{ conn1 = { Value = "Some connection string"; Type = 2  } }
# NOTE: broken, need to fix!
Function SetSiteConnectionStrings($ResourceGroupName, $SiteName, $ConnectionStringsObject)
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/connectionstrings -PropertyObject $ConnectionStringsObject -OutputObjectFormat New -ApiVersion 2015-04-01 -Force
}


## Deployment related operations

# Example call: DeployCloudHostedPackage MyResourceGroup "West US" MySite https://auxmktplceprod.blob.core.windows.net/packages/Bakery.zip
Function DeployCloudHostedPackage($ResourceGroupName, $Location, $SiteName, $packageUrl)
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -Location $Location -ResourceType Microsoft.Web/sites/Extensions -Name MSDeploy -ParentResource sites/$SiteName -PropertyObject @{ "packageUri" = $packageUrl } -ApiVersion 2014-04-01 -Force
}


## Certificate operations

# Example call: UploadCert MyResourceGroup "North Europe" foo.pfx "MyPassword!" MyTestCert
Function UploadCert($ResourceGroupName, $Location, $PfxPath, $PfxPassword, $CertName)
{
    # Read the raw bytes of the pfx file
    $pfxBytes = get-content $PfxPath -Encoding Byte

    $props = @{
        PfxBlob = [System.Convert]::ToBase64String($pfxBytes)
        Password = $PfxPassword
    }

    New-AzureResource -Location $Location -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/certificates -Name $CertName -PropertyObject $props -ApiVersion 2014-11-01 -Force
}

# Example call: DeleteCert MyResourceGroup MyCert
Function DeleteCert($ResourceGroupName, $CertName)
{
    Remove-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/certificates -Name $CertName -ApiVersion 2014-11-01 -Force
}


## Tests

Function TestHelpers($ResourceGroupName, $Location, $SiteName, $PlanName = "MyPlan")
{
    CreateAppServicePlan $ResourceGroupName $Location $PlanName

    ListAppServicePlans $ResourceGroupName

    GetAppServicePlan $ResourceGroupName $PlanName

    CreateSite $ResourceGroupName $Location $SiteName $PlanName

    ListSites $ResourceGroupName

    $site = GetSite $ResourceGroupName $SiteName
    Write-Host $site.Properties.enabledHostNames[0]

    DeleteAppServicePlan $ResourceGroupName $PlanName
}


