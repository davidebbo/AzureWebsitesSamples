$ErrorActionPreference = "Stop"

## WebHostingPlan operations

# Example call: ListAppServicePlans MyResourceGroup
Function ListAppServicePlans($ResourceGroupName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/serverfarms -OutputObjectFormat New -IsCollection
}

# Example call: GetAppServicePlan MyResourceGroup MyWHP
Function GetAppServicePlan($ResourceGroupName, $PlanName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/serverfarms -Name $PlanName -OutputObjectFormat New -ApiVersion 2015-08-01
}

# Example call: CreateAppServicePlan MyResourceGroup "North Europe" MyHostingPlan
Function CreateAppServicePlan($ResourceGroupName, $Location, $PlanName, $SkuName = "F1", $SkuTier = "Free")
{
    $fullObject = @{
        location = $Location
        sku = @{
            name = $SkuName
            tier = $SkuTier
        }
    }

    New-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/serverfarms -Name $PlanName -IsFullObject -PropertyObject $fullObject -OutputObjectFormat New -ApiVersion 2015-08-01 -Force
}

# Example call: DeleteWebApp MyResourceGroup MySite
Function DeleteAppServicePlan($ResourceGroupName, $PlanName)
{
    Remove-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/serverfarms -Name $PlanName -ApiVersion 2015-08-01 -Force
}



## Site operations

# Example call: ListWebApps MyResourceGroup
Function ListWebApps($ResourceGroupName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites -OutputObjectFormat New
}

# Example call: GetWebApp MyResourceGroup MySite
Function GetWebApp($ResourceGroupName, $SiteName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites -Name $SiteName -OutputObjectFormat New -ApiVersion 2015-08-01
}

# Example call: CreateWebApp MyResourceGroup "North Europe" MySite DefaultServerFarm
Function CreateWebApp($ResourceGroupName, $Location, $SiteName, $PlanName)
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -Location $Location -ResourceType Microsoft.Web/sites -Name $SiteName -PropertyObject @{ webHostingPlan = $PlanName } -OutputObjectFormat New -ApiVersion 2015-08-01 -Force
}

# Example call: DeleteWebApp MyResourceGroup MySite
Function DeleteWebApp($ResourceGroupName, $SiteName)
{
    Remove-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites -Name $SiteName -ApiVersion 2015-08-01 -Force
}

# Example call: $planId = GetSiteAppServicePlanId MyResourceGroup MySite
Function GetSiteAppServicePlanId($ResourceGroupName, $SiteName)
{
    $site = GetWebApp $ResourceGroupName $SiteName
    $site.Properties.serverFarmId
}


## Site config operations

# Example call: GetWebAppConfig MyResourceGroup MySite
Function GetWebAppConfig($ResourceGroupName, $SiteName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/web -OutputObjectFormat New -ApiVersion 2015-08-01
}

# Example call: SetWebAppConfig MyResourceGroup MySite $ConfigObject
Function SetWebAppConfig($ResourceGroupName, $SiteName, $ConfigObject)
{
    Set-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/web -PropertyObject $ConfigObject -OutputObjectFormat New -ApiVersion 2015-08-01 -Force
}

# Example call: $phpVersion = GetPHPVersion MyResourceGroup MySite
Function GetPHPVersion($ResourceGroupName, $SiteName)
{
    $config = GetWebAppConfig $ResourceGroupName $SiteName
    $config.Properties.phpVersion
}

# Example call: SetPHPVersion MyResourceGroup MySite 5.6
Function SetPHPVersion($ResourceGroupName, $SiteName, $PHPVersion)
{
    SetWebAppConfig $ResourceGroupName $SiteName @{ "phpVersion" = $PHPVersion }
}


## App Settings

# Example call: GetWebAppAppSettings MyResourceGroup MySite
Function GetWebAppAppSettings($ResourceGroupName, $SiteName)
{
    $res = Invoke-AzureResourceAction -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/appsettings -Action list -ApiVersion 2015-08-01 -Force
    $res.Properties
}

# Example call: SetWebAppAppSettings MyResourceGroup MySite @{ key1 = "val1"; key2 = "val2" }
Function SetWebAppAppSettings($ResourceGroupName, $SiteName, $AppSettingsObject)
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/appsettings -PropertyObject $AppSettingsObject -OutputObjectFormat New -ApiVersion 2015-08-01 -Force
}


## Connection Strings

# Example call: GetWebAppConnectionStrings MyResourceGroup MySite
Function GetWebAppConnectionStrings($ResourceGroupName, $SiteName)
{
    $res = Invoke-AzureResourceAction -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/connectionstrings -Action list -ApiVersion 2015-08-01 -Force
    $res.Properties
}

# Example call: SetWebAppConnectionStrings MyResourceGroup MySite @{ conn1 = @{ Value = "Some connection string"; Type = 2  } }
Function SetWebAppConnectionStrings($ResourceGroupName, $SiteName, $ConnectionStringsObject)
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/connectionstrings -PropertyObject $ConnectionStringsObject -OutputObjectFormat New -ApiVersion 2015-08-01 -Force
}


## Deployment related operations

# Example call: DeployCloudHostedPackage MyResourceGroup "West US" MySite https://auxmktplceprod.blob.core.windows.net/packages/Bakery.zip
Function DeployCloudHostedPackage($ResourceGroupName, $Location, $SiteName, $packageUrl)
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -Location $Location -ResourceType Microsoft.Web/sites/Extensions -Name MSDeploy -ParentResource sites/$SiteName -PropertyObject @{ "packageUri" = $packageUrl } -ApiVersion 2015-08-01 -Force
}

# Deploy from an external git repo
Function HookupExternalGitRepo($ResourceGroupName, $SiteName, $repoUrl)
{
    $props = @{
        RepoUrl = $repoUrl
        Branch = "master"
        IsManualIntegration = true
    }

    New-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/SourceControls -Name $SiteName/Web -PropertyObject $props -OutputObjectFormat New -ApiVersion 2015-08-01 -Force
}

# Deploy from an external git repo
Function GetGitDeployments($ResourceGroupName, $SiteName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Deployments -Name $SiteName -OutputObjectFormat New -ApiVersion 2015-08-01
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

    New-AzureResource -Location $Location -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/certificates -Name $CertName -PropertyObject $props -ApiVersion 2015-08-01 -Force
}

# Example call: DeleteCert MyResourceGroup MyCert
Function DeleteCert($ResourceGroupName, $CertName)
{
    Remove-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/certificates -Name $CertName -ApiVersion 2015-08-01 -Force
}


## Premium Add-Ons

Function GetWebAppAddons($ResourceGroupName, $SiteName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/premieraddons -Name $SiteName -OutputObjectFormat New -ApiVersion 2015-08-01 -IsCollection
}

Function AddZrayAddon($ResourceGroupName, $Location, $SiteName, $Name, $PlanName)
{
    $plan = @{
        name = $PlanName
        publisher = "zend-technologies"
        product = "z-ray"
    }

    New-AzureResource -ResourceGroupName $ResourceGroupName -Location $Location -ResourceType Microsoft.Web/sites/premieraddons -Name $SiteName/$Name -Properties @{} -PlanObject $plan -OutputObjectFormat New -ApiVersion 2015-08-01 -Force
}

Function RemoveWebAppAddon($ResourceGroupName, $SiteName, $Name)
{
    Remove-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/premieraddons -Name $SiteName/$Name -ApiVersion 2015-08-01 -Force
}
