$ErrorActionPreference = "Stop"

## WebHostingPlan operations

# Example call: ListAppServicePlans MyResourceGroup
Function ListAppServicePlans($ResourceGroupName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/serverfarms -OutputObjectFormat New
}

# Example call: GetAppServicePlan MyResourceGroup MyWHP
Function GetAppServicePlan($ResourceGroupName, $PlanName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/serverfarms -Name $PlanName -OutputObjectFormat New -ApiVersion 2015-06-01
}

# Example call: CreateAppServicePlan MyResourceGroup "North Europe" MyHostingPlan
Function CreateAppServicePlan($ResourceGroupName, $Location, $PlanName, $Sku = "Free")
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -Location $Location -ResourceType Microsoft.Web/serverfarms -Name $PlanName -PropertyObject @{ sku = $Sku } -OutputObjectFormat New -ApiVersion 2015-04-01 -Force
}

# Example call: DeleteWebApp MyResourceGroup MySite
Function DeleteAppServicePlan($ResourceGroupName, $PlanName)
{
    Remove-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/serverfarms -Name $PlanName -ApiVersion 2015-06-01 -Force
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
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites -Name $SiteName -OutputObjectFormat New -ApiVersion 2015-06-01
}

# Example call: CreateWebApp MyResourceGroup "North Europe" MySite DefaultServerFarm
Function CreateWebApp($ResourceGroupName, $Location, $SiteName, $PlanName)
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -Location $Location -ResourceType Microsoft.Web/sites -Name $SiteName -PropertyObject @{ webHostingPlan = $PlanName } -OutputObjectFormat New -ApiVersion 2015-06-01 -Force
}

# Example call: DeleteWebApp MyResourceGroup MySite
Function DeleteWebApp($ResourceGroupName, $SiteName)
{
    Remove-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites -Name $SiteName -ApiVersion 2015-06-01 -Force
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
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/web -OutputObjectFormat New -ApiVersion 2015-06-01
}

# Example call: SetWebAppConfig MyResourceGroup MySite $ConfigObject
Function SetWebAppConfig($ResourceGroupName, $SiteName, $ConfigObject)
{
    Set-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/web -PropertyObject $ConfigObject -OutputObjectFormat New -ApiVersion 2015-06-01 -Force
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
    $res = Invoke-AzureResourceAction -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/appsettings -Action list -ApiVersion 2015-06-01 -Force
    $res.Properties
}

# Example call: SetWebAppAppSettings MyResourceGroup MySite @{ key1 = "val1"; key2 = "val2" }
Function SetWebAppAppSettings($ResourceGroupName, $SiteName, $AppSettingsObject)
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/appsettings -PropertyObject $AppSettingsObject -OutputObjectFormat New -ApiVersion 2015-06-01 -Force
}


## Connection Strings

# Example call: GetWebAppConnectionStrings MyResourceGroup MySite
Function GetWebAppConnectionStrings($ResourceGroupName, $SiteName)
{
    $res = Invoke-AzureResourceAction -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/connectionstrings -Action list -ApiVersion 2015-06-01 -Force
    $res.Properties
}

# Example call: SetWebAppConnectionStrings MyResourceGroup MySite @{ conn1 = { Value = "Some connection string"; Type = 2  } }
# NOTE: broken, need to fix!
Function SetWebAppConnectionStrings($ResourceGroupName, $SiteName, $ConnectionStringsObject)
{
    New-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/Config -Name $SiteName/connectionstrings -PropertyObject $ConnectionStringsObject -OutputObjectFormat New -ApiVersion 2015-06-01 -Force
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


## Premium Add-Ons

Function GetWebAppAddons($ResourceGroupName, $SiteName)
{
    Get-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/premieraddons -Name $SiteName -OutputObjectFormat New -ApiVersion 2015-06-01 -IsCollection
}

Function AddZrayAddon($ResourceGroupName, $Location, $SiteName, $Name, $PlanName)
{
    $plan = @{
        name = $PlanName
        publisher = "zend-technologies"
        product = "z-ray"
    }

    New-AzureResource -ResourceGroupName $ResourceGroupName -Location $Location -ResourceType Microsoft.Web/sites/premieraddons -Name $SiteName/$Name -Properties @{} -PlanObject $plan -OutputObjectFormat New -ApiVersion 2015-06-01 -Force
}

Function RemoveWebAppAddon($ResourceGroupName, $SiteName, $Name)
{
    Remove-AzureResource -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/premieraddons -Name $SiteName/$Name -ApiVersion 2015-06-01 -Force
}



## Tests

Function TestHelpers($ResourceGroupName, $Location, $SiteName, $PlanName = "MyPlan")
{
    Write-Host "Creating Resource Group"
    New-AzureResourceGroup -Name $ResourceGroupName -Location $Location -Force

    Write-Host "Creating App Service Plan"
    CreateAppServicePlan $ResourceGroupName $Location $PlanName

    Write-Host "Listing App Service Plans"
    ListAppServicePlans $ResourceGroupName

    Write-Host "Getting a specific App Service Plan"
    GetAppServicePlan $ResourceGroupName $PlanName

    Write-Host "Creating Web App"
    CreateWebApp $ResourceGroupName $Location $SiteName $PlanName

    Write-Host "Listing all Web Apps in the Resource Group"
    ListWebApps $ResourceGroupName

    Write-Host "Getting a specific Wep App and sending a GET request to its hostname"
    $site = GetWebApp $ResourceGroupName $SiteName
    $hostName = $site.Properties.enabledHostNames[0]
    $response = Invoke-WebRequest $hostName
    Write-Host $response.StatusCode

    Write-Host "Setting some app settings"
    SetWebAppAppSettings $ResourceGroupName $SiteName @{ key1 = "val1"; key2 = "val2" }

    Write-Host "Reading the app settings"
    GetWebAppAppSettings $ResourceGroupName $SiteName

    Write-Host "Setting the PHP version and reading it back"
    SetPHPVersion $ResourceGroupName $SiteName 5.6
    GetPHPVersion $ResourceGroupName $SiteName

    Write-Host "Enabling the ZRay addon"
    AddZrayAddon $ResourceGroupName $Location $SiteName MyZray "free"

    Write-Host "Listing installed addons"
    GetWebAppAddons $ResourceGroupName $SiteName

    Write-Host "Removing the ZRay addon"
    RemoveWebAppAddon $ResourceGroupName $SiteName MyZray

    Write-Host "Deleting the Web App"
    DeleteWebApp $ResourceGroupName $SiteName

    Write-Host "Deleting the App Servce Plan"
    DeleteAppServicePlan $ResourceGroupName $PlanName
}
