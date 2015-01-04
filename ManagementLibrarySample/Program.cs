using System;
using System.Configuration;
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
                Console.WriteLine(e);
            }
        }

        static async Task MainAsync()
        {
            // Get the credentials
            SubscriptionCloudCredentials cloudCreds = GetCredsFromServicePrincipal();

            // Use them to create the clients we need
            _resourceGroupClient = new ResourceManagementClient(cloudCreds);
            _websiteClient = new WebSiteManagementClient(cloudCreds);

            await ListResourceGroupsAndSites();

            await CreateSite("MyResourceGroup", "MyWebHostingPlan", "MySite777", "West US");
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
            ResourceGroupListResult res = await _resourceGroupClient.ResourceGroups.ListAsync(new ResourceGroupListParameters());
            foreach (var rg in res.ResourceGroups)
            {
                Console.WriteLine(rg.Name);

                // Go through all the Websites in the resource group
                WebSiteListResponse sites = await _websiteClient.WebSites.ListAsync(rg.Name, null, new WebSiteListParameters());
                foreach (var site in sites)
                {
                    Console.WriteLine("    " + site.Name);
                }
            }
        }

        static async Task CreateSite(string rgName, string whpName, string siteName, string location)
        {
            var res2 = await _resourceGroupClient.ResourceGroups.CreateOrUpdateAsync(rgName, new BasicResourceGroup { Location = location });

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

            WebHostingPlanCreateOrUpdateResponse whpCreateRes = await _websiteClient.WebHostingPlans.CreateOrUpdateAsync(rgName, whpCreateParams);

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

            var siteCreateRes = await _websiteClient.WebSites.CreateOrUpdateAsync(rgName, siteName, null /*slot*/, createParams);

            var siteUpdateParams = new WebSiteUpdateConfigurationParameters
            {
                Location = location,
                Properties = new WebSiteUpdateConfigurationDetails
                {
                    PhpVersion = "5.6",
                }
            };

            var updateRes = await _websiteClient.WebSites.UpdateConfigurationAsync(rgName, siteName, null /*slot*/, siteUpdateParams);
        }
    }
}
