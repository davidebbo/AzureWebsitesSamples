using System;
using System.Configuration;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Azure.Management.Resources;
using Microsoft.Azure.Management.Resources.Models;
using Microsoft.Azure.Management.WebSites;
using Microsoft.Azure.Management.WebSites.Models;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Microsoft.WindowsAzure;

namespace ManagementLibrarySample
{
    class Program
    {
        private static ResourceManagementClient _resourceGroupClient;
        private static WebSiteManagementClient _websiteClient;

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
            // Get the credentials
            SubscriptionCloudCredentials cloudCreds = GetCredsFromServicePrincipal();

            // Create our own HttpClient so we can do logging
            HttpClient httpClient = new HttpClient(new LoggingHandler(new HttpClientHandler()));

            // Use the creds to create the clients we need
            _resourceGroupClient = new ResourceManagementClient(cloudCreds, httpClient);
            _websiteClient = new WebSiteManagementClient(cloudCreds, httpClient);

            await ListResourceGroupsAndSites();

            // Note: site names are globally unique, so you may need to change it to avoid conflicts
            await CreateSite("MyResourceGroup", "MyWebHostingPlan", "SampleSiteFromAPI", "West US");
        }

        private static SubscriptionCloudCredentials GetCredsFromServicePrincipal()
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

            var authority = String.Format("{0}/{1}", "https://login.windows.net", tenantId);
            var authContext = new AuthenticationContext(authority);
            var credential = new ClientCredential(clientId, clientSecret);
            var authResult = authContext.AcquireToken("https://management.core.windows.net/", credential);

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
                var siteListResult = await _websiteClient.WebSites.ListAsync(rg.Name, null, new WebSiteListParameters());
                foreach (var site in siteListResult)
                {
                    Console.WriteLine("    " + site.Name);
                }
            }
        }

        static async Task CreateSite(string rgName, string whpName, string siteName, string location)
        {
            // Create/Update the resource group
            var rgCreateResult = await _resourceGroupClient.ResourceGroups.CreateOrUpdateAsync(rgName, new BasicResourceGroup { Location = location });

            // Create/Update the Web Hosting Plan
            var whpCreateParams = new WebHostingPlanCreateOrUpdateParameters
            {
                WebHostingPlan = new WebHostingPlan
                {
                    Name = whpName,
                    Location = location,
                    Properties = new WebHostingPlanProperties
                    {
                        Sku = SkuOptions.Free
                    }
                }
            };
            var whpCreateResult = await _websiteClient.WebHostingPlans.CreateOrUpdateAsync(rgName, whpCreateParams);

            // Create/Update the Website
            var createParams = new WebSiteCreateOrUpdateParameters
            {
                WebSite = new WebSiteBase
                {
                    Name = siteName,
                    Location = location,
                    Properties = new WebSiteBaseProperties
                    {
                        ServerFarm = whpName
                    }
                }
            };
            var siteCreateResult = await _websiteClient.WebSites.CreateOrUpdateAsync(rgName, siteName, null /*slot*/, createParams);

            // Create/Update the Website configuration
            var siteUpdateParams = new WebSiteUpdateConfigurationParameters
            {
                Location = location,
                Properties = new WebSiteUpdateConfigurationDetails
                {
                    PhpVersion = "5.6",
                }
            };
            var siteUpdateRes = await _websiteClient.WebSites.UpdateConfigurationAsync(rgName, siteName, null /*slot*/, siteUpdateParams);
        }
    }
}
