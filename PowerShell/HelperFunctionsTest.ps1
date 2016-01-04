$ResourceGroupName = "TestRG"
$Location = "East US 2"
$SiteName = "PSTest7775"
$PlanName = "MyPlan"

Write-Host "Creating Resource Group"
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Force

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

Write-Host "Hooking up site to an external git repo"
HookupExternalGitRepo $ResourceGroupName $SiteName https://github.com/davidebbo-test/TrivialAppAndWebJob

Write-Host "Waiting until the deployment is done"
While ($true)
{
    Start-Sleep -s 1
    Write-Host "Getting the deployment list"
    $deployments = GetGitDeployments $ResourceGroupName $SiteName
    if ($deployments)
    {
        $latestDeployment = $deployments[0].Properties
        Write-Host "Progress: " $latestDeployment.Progress

        if ($latestDeployment.Complete) { break }
    }
}

Write-Host "Getting a specific Wep App and sending a GET request to its hostname"
$site = GetWebApp $ResourceGroupName $SiteName
$hostName = $site.Properties.enabledHostNames[0]
$response = Invoke-WebRequest $hostName
Write-Host $response.StatusCode
Write-Host $response.Content

$WebJobName = "SomeWebJob"
Write-Host Displaying triggered WebJob details
GetTriggeredWebJob $ResourceGroupName $SiteName $WebJobName

Write-Host Running the triggered WebJob
RunTriggeredWebJob $ResourceGroupName $SiteName $WebJobName

Write-Host "Deploying bakery sample using msdeploy"
DeployCloudHostedPackage $ResourceGroupName $Location $SiteName https://auxmktplceprod.blob.core.windows.net/packages/Bakery.zip

Write-Host "Getting the publishing profile XML"
GetPublishingProfile $ResourceGroupName $SiteName

Write-Host "Getting the publishing credentials"
GetPublishingCredentials $ResourceGroupName $SiteName

Write-Host "Setting some app settings"
SetWebAppAppSettings $ResourceGroupName $SiteName @{ key1 = "val1"; key2 = "val2" }

Write-Host "Reading the app settings"
GetWebAppAppSettings $ResourceGroupName $SiteName

Write-Host "Setting some connnection strings"
$props=@{
    MyConn = @{ Value = "Some connection string"; Type = "SqlAzure"  }
    MyConn2 = @{ Value = "Some other connection string"; Type = "Custom"  }
}
SetWebAppConnectionStrings $ResourceGroupName $SiteName $props

Write-Host "Reading the connection strings"
GetWebAppConnectionStrings $ResourceGroupName $SiteName

SetSlotSettings $ResourceGroupName $SiteName @{ appSettingNames = @("key1"); connectionStringNames = "MyConn","MyConn2" }
GetSlotSettings $ResourceGroupName $SiteName

Write-Host "Setting the PHP version and reading it back"
SetPHPVersion $ResourceGroupName $SiteName 5.6
GetPHPVersion $ResourceGroupName $SiteName

Write-Host "Installing site extension"
InstallSiteExtension $ResourceGroupName $SiteName filecounter
Write-Host "Listing installed site extensions"
ListWebAppSiteExtensions $ResourceGroupName $SiteName
Write-Host "Uninstalling site extension"
UninstallSiteExtension $ResourceGroupName $SiteName filecounter

Write-Host "Enabling the ZRay addon"
AddZrayAddon $ResourceGroupName $Location $SiteName MyZray "free"

Write-Host "Listing installed addons"
GetWebAppAddons $ResourceGroupName $SiteName

Write-Host "Removing the ZRay addon"
RemoveWebAppAddon $ResourceGroupName $SiteName MyZray

Write-Host "Deleting the Web App"
DeleteWebApp $ResourceGroupName $SiteName

Write-Host "Deleting the App Service Plan"
DeleteAppServicePlan $ResourceGroupName $PlanName

