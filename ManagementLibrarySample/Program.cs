using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Azure;
using Microsoft.Azure.Common.Authentication.Models;
using Microsoft.Azure.Management.Resources;
using Microsoft.Azure.Management.Resources.Models;
using Microsoft.Azure.Management.WebSites;
using Microsoft.Azure.Management.WebSites.Models;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Microsoft.Rest;

namespace ManagementLibrarySample
{
    class Program
    {
        private static ResourceManagementClient _resourceGroupClient;
        private static WebSiteManagementClient _websiteClient;
        private static AzureEnvironment _environment;

        static void Main(string[] args)
        {
            try
            {
                MainAsync().Wait();
            }
            catch (Exception e)
            {
                Console.WriteLine(e.GetBaseException().Message);
            }
        }

        static async Task MainAsync()
        {
            // Set Environment - Choose between Azure public cloud, china cloud and US govt. cloud
            _environment = AzureEnvironment.PublicEnvironments[EnvironmentName.AzureCloud];

            // Get the credentials
            TokenCloudCredentials cloudCreds = GetCredsFromServicePrincipal();
            
            var tokenCreds = new TokenCredentials(cloudCreds.Token);

            var loggingHandler = new LoggingHandler(new HttpClientHandler());

            // Create our own HttpClient so we can do logging
            var httpClient = new HttpClient(loggingHandler);

            // Use the creds to create the clients we need
            _resourceGroupClient = new ResourceManagementClient(cloudCreds, _environment.GetEndpointAsUri(AzureEnvironment.Endpoint.ResourceManager), httpClient);
            _websiteClient = new WebSiteManagementClient(_environment.GetEndpointAsUri(AzureEnvironment.Endpoint.ResourceManager), tokenCreds, loggingHandler);
            _websiteClient.SubscriptionId = cloudCreds.SubscriptionId;

            await ListResourceGroupsAndSites();

            // Note: site names are globally unique, so you may need to change it to avoid conflicts
            await CreateSite("MyResourceGroup", "MyAppServicePlan", "SampleSiteFromAPI", "West US");

            // Upload certificate to resource group
            await UpdateLoadCertificate("MyResourceGroup", "CertificateName", "West US", "PathToPfxFile", "CertificatePassword");
        }

        private static Task UpdateLoadCertificate(string resourceGroupName, string certificateName, string location, string pathToPfxFile, string certificatePassword)
        {
            var pfxAsBytes = File.ReadAllBytes(pathToPfxFile);
            var pfxBlob = Convert.ToBase64String(pfxAsBytes);
            var certificate = new Certificate
            {
                Location = location,
                Password = certificatePassword,
                PfxBlob = pfxBlob
            };

            return _websiteClient.Certificates.CreateOrUpdateCertificateAsync(resourceGroupName, certificateName, certificate);
        }

        private static TokenCloudCredentials GetCredsFromServicePrincipal()
        {
            string subscription = ConfigurationManager.AppSettings["AzureSubscription"];
            string tenantId = ConfigurationManager.AppSettings["AzureTenantId"];
            string clientId = ConfigurationManager.AppSettings["AzureClientId"];
            string clientSecret = ConfigurationManager.AppSettings["AzureClientSecret"];

            // Quick check to make sure we're not running with the default app.config
            if (subscription[0] == '[')
            {
                throw new Exception("You need to enter your appSettings in app.config to run this sample");
            }

            var authority = String.Format("{0}{1}", _environment.Endpoints[AzureEnvironment.Endpoint.ActiveDirectory], tenantId);
            var authContext = new AuthenticationContext(authority);
            var credential = new ClientCredential(clientId, clientSecret);
            var authResult = authContext.AcquireToken(_environment.Endpoints[AzureEnvironment.Endpoint.ActiveDirectoryServiceEndpointResourceId], credential);
            return new TokenCloudCredentials(subscription, authResult.AccessToken);
        }

        static async Task ListResourceGroupsAndSites()
        {
            // Go through all the resource groups in the subscription
            var rgListResult = await _resourceGroupClient.ResourceGroups.ListAsync(new ResourceGroupListParameters());
            foreach (var rg in rgListResult.ResourceGroups)
            {
                Console.WriteLine(rg.Name);

                // Go through all the Websites in the resource group
                var siteListResult = await _websiteClient.Sites.GetSitesAsync(rg.Name, null);
                foreach (var site in siteListResult.Value)
                {
                    Console.WriteLine("    " + site.Name);
                }
            }
        }

        static async Task CreateSite(string rgName, string appServicePlanName, string siteName, string location)
        {
            // Create/Update the resource group
            var rgCreateResult = await _resourceGroupClient.ResourceGroups.CreateOrUpdateAsync(rgName, new ResourceGroup { Location = location });

            // Create/Update the App Service Plan
            var serverFarmWithRichSku = new ServerFarmWithRichSku
            {
                Location = location,
                Sku = new SkuDescription
                {
                    Name = "F1",
                    Tier = "Free"
                }
            };
            serverFarmWithRichSku = await _websiteClient.ServerFarms.CreateOrUpdateServerFarmAsync(rgName, appServicePlanName, serverFarmWithRichSku);

            // Create/Update the Website
            var site = new Site
            {
                Location = location,
                ServerFarmId = appServicePlanName
            };
            site = await _websiteClient.Sites.CreateOrUpdateSiteAsync(rgName, siteName, site);

            // Create/Update the Website configuration
            var siteConfig = new SiteConfig
            {
                Location = location,
                PhpVersion = "5.6"
            };
            siteConfig = await _websiteClient.Sites.CreateOrUpdateSiteConfigAsync(rgName, siteName, siteConfig);

            // Create/Update some App Settings
            var appSettings = new StringDictionary
            {
                Location = location,
                Properties = new Dictionary<string, string>
                {
                    { "MyFirstKey", "My first value" },
                    { "MySecondKey", "My second value" }
                }
            };
            await _websiteClient.Sites.UpdateSiteAppSettingsAsync(rgName, siteName, appSettings);

            // Create/Update some Connection Strings
            var connStrings = new ConnectionStringDictionary
            {
                Location = location,
                Properties = new Dictionary<string, ConnStringValueTypePair>
                {
                    { "MyFirstConnString", new ConnStringValueTypePair { Value = "My SQL conn string", Type = DatabaseServerType.SQLAzure }},
                    { "MySecondConnString", new ConnStringValueTypePair { Value = "My custom conn string", Type = DatabaseServerType.Custom }}
                }
            };
            await _websiteClient.Sites.UpdateSiteConnectionStringsAsync(rgName, siteName, connStrings);

            // Restart the site
            await _websiteClient.Sites.RestartSiteAsync(rgName, siteName, softRestart: true);
        }
    }
}
