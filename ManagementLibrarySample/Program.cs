using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Azure;
using Microsoft.Azure.Common.Authentication.Models;
using Microsoft.Azure.Management.ResourceManager;
using Microsoft.Azure.Management.ResourceManager.Models;
using Microsoft.Azure.Management.WebSites;
using Microsoft.Azure.Management.WebSites.Models;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Microsoft.Rest;
using Microsoft.Rest.Azure;
using Microsoft.Azure.Management.Dns;
using Microsoft.Azure.Management.Dns.Models;

namespace ManagementLibrarySample
{
    class Program
    {
        private static ResourceManagementClient _resourceGroupClient;
        private static WebSiteManagementClient _websiteClient;
        private static AzureEnvironment _environment;
        private static DnsManagementClient _dnsClient;

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
            _resourceGroupClient = new ResourceManagementClient(_environment.GetEndpointAsUri(AzureEnvironment.Endpoint.ResourceManager), tokenCreds, loggingHandler);
            _resourceGroupClient.SubscriptionId = cloudCreds.SubscriptionId;
            _websiteClient = new WebSiteManagementClient(_environment.GetEndpointAsUri(AzureEnvironment.Endpoint.ResourceManager), tokenCreds, loggingHandler);
            _websiteClient.SubscriptionId = cloudCreds.SubscriptionId;
            _dnsClient = new DnsManagementClient(cloudCreds);

            await ListResourceGroupsAndSites();

            // Note: site names are globally unique, so you may need to change it to avoid conflicts
            await CreateSite("MyResourceGroup", "MyAppServicePlan", "SampleSiteFromAPI7", "West US");

            // NOTE: uncomment lines below and change parameters as appropriate

            // if you have a configured  Azure DNS Zone you can add subdomains (i.e. subdomain.mydomain.com )
            //await CreateOrUpdateCNAME("MyResourceGroup", "My DNS Zone", "subdomain", "mywebsite.azurewebsites.net");

            // Upload certificate to resource group
            //await UpdateLoadCertificate("MyResourceGroup", "CertificateName", "West US", "PathToPfxFile", "CertificatePassword");

            // Bind certificate to resource group
            //await BindCertificateToSite("MyResourceGroup", "SiteName", "CertificateName", "hostName");
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="resourceGroupName"></param>
        /// <param name="dnsZoneName"></param>
        /// <param name="cNAME">subdomain</param>
        /// <param name="alias">i.e. MYWEBSITE.azurewebsites.net</param>
        /// <returns></returns>
        private async static Task<Boolean> CreateOrUpdateCNAME(string resourceGroupName, string dnsZoneName, string cNAME, string alias)
        {

            var item = _dnsClient.Zones;
            var myzone = _dnsClient.Zones.Get("cofire", "cofire.test");
            cNAME = (cNAME.IndexOf('.') == -1) ? cNAME : cNAME.Substring(0, cNAME.IndexOf('.'));

            try
            {
                RecordSet newCName1 = new RecordSet("global");
                newCName1.Properties = new RecordSetProperties();
                newCName1.Properties.Ttl = 10800;
                newCName1.Properties.CnameRecord = new CnameRecord($"{alias}.");
                newCName1.Type = "CNAME";
                newCName1.Location = "global";
                newCName1.Name = cNAME;


                var responseETagUpdate =
                    await _dnsClient.RecordSets.CreateOrUpdateAsync(resourceGroupName, dnsZoneName, cNAME, RecordType.CNAME,
                    new RecordSetCreateOrUpdateParameters(newCName1), null, null);

                if (responseETagUpdate.StatusCode == System.Net.HttpStatusCode.Created || responseETagUpdate.StatusCode == System.Net.HttpStatusCode.OK)
                    return true;
                else
                    return false;

            }
            catch (Hyak.Common.CloudException e)
            {
                //  check if the precondition failed
                if (e.Response.StatusCode == System.Net.HttpStatusCode.PreconditionFailed)
                {
                    Console.WriteLine("The ETag precondition failed");
                }
                else
                {
                    throw e;
                }
            }
            return false;

        }

        private static Task UpdateLoadCertificate(string resourceGroupName, string certificateName, string location, string pathToPfxFile, string certificatePassword)
        {
            var pfxAsBytes = File.ReadAllBytes(pathToPfxFile);
            var certificate = new Certificate
            {
                Location = location,
                Password = certificatePassword,
                PfxBlob = pfxAsBytes
            };

            return _websiteClient.Certificates.CreateOrUpdateWithHttpMessagesAsync(resourceGroupName, certificateName, certificate);
        }

        private static async Task BindCertificateToSite(string resourceGroupName, string siteName, string certificateName, string hostName)
        {
            var certificateResponse = await _websiteClient.Certificates.GetWithHttpMessagesAsync(resourceGroupName, certificateName);
            var certificate = certificateResponse.Body;
            var siteResponse = await _websiteClient.WebApps.GetWithHttpMessagesAsync(resourceGroupName, siteName);
            var site = siteResponse.Body;

            var hst = new HostNameBinding();
            hst.Name = siteName;
            hst.Name = $"{siteName}/{hostName}";
            hst.Location = site.Location;

            var doms3 = await _websiteClient.WebApps.CreateOrUpdateHostNameBindingWithHttpMessagesAsync(resourceGroupName, siteName, hostName, hst);


            if (!site.HostNames.Any(h => string.Equals(h, hostName, StringComparison.OrdinalIgnoreCase)))
            {
                site.HostNames.Add(hostName);
            }

            if (site.HostNameSslStates == null)
            {
                site.HostNameSslStates = new List<HostNameSslState>();
            }

            if (!site.HostNameSslStates.Any(s => string.Equals(s.Name, hostName, StringComparison.OrdinalIgnoreCase)))
            {
                site.HostNameSslStates.Add(new HostNameSslState
                {
                    Name = hostName, 
                    Thumbprint = certificate.Thumbprint,
                    SslState = SslState.SniEnabled,
                    ToUpdate = true
                });
            }

            await _websiteClient.WebApps.CreateOrUpdateAsync(resourceGroupName, siteName, site);
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
            IPage<ResourceGroup> rgListResult = await _resourceGroupClient.ResourceGroups.ListAsync();
            foreach (var rg in rgListResult)
            {
                Console.WriteLine(rg.Name);

                // Go through all the Websites in the resource group
                var siteListResult = await _websiteClient.WebApps.ListByResourceGroupWithHttpMessagesAsync(rg.Name);
                foreach (var site in siteListResult.Body)
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
            var serverFarmWithRichSku = new AppServicePlan
            {
                Location = location,
                Sku = new SkuDescription
                {
                    Name = "F1",
                    Tier = "Free"
                }
            };
            serverFarmWithRichSku = await _websiteClient.AppServicePlans.CreateOrUpdateAsync(rgName, appServicePlanName, serverFarmWithRichSku);

            // Create/Update the Website
            var site = new Site
            {
                Location = location,
                ServerFarmId = appServicePlanName
            };
            site = await _websiteClient.WebApps.CreateOrUpdateAsync(rgName, siteName, site);

            Console.WriteLine($"Site outbound IP addresses: {site.OutboundIpAddresses}");

            // Create/Update the Website configuration
            var siteConfig = new SiteConfig
            {
                Location = location,
                PhpVersion = "5.6"
            };
            siteConfig = await _websiteClient.WebApps.CreateOrUpdateConfigurationAsync(rgName, siteName, siteConfig);

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
            await _websiteClient.WebApps.UpdateApplicationSettingsAsync(rgName, siteName, appSettings);

            // Create/Update some Connection Strings
            var connStrings = new ConnectionStringDictionary
            {
                Location = location,
                Properties = new Dictionary<string, ConnStringValueTypePair>
                {
                    { "MyFirstConnString", new ConnStringValueTypePair { Value = "My SQL conn string", Type = ConnectionStringType.SQLAzure }},
                    { "MySecondConnString", new ConnStringValueTypePair { Value = "My custom conn string", Type = ConnectionStringType.Custom }}
                }
            };
            await _websiteClient.WebApps.UpdateConnectionStringsAsync(rgName, siteName, connStrings);

            // List the site quotas
            Console.WriteLine("Site quotas:");
            var quotas = await _websiteClient.WebApps.ListUsagesAsync(rgName, siteName);
            foreach (var quota in quotas)
            {
                Console.WriteLine($"    {quota.Name.Value}: {quota.CurrentValue} {quota.Unit}");
            }

            // Get the publishing profile xml file
            using (var stream = await _websiteClient.WebApps.ListPublishingProfileXmlWithSecretsAsync(rgName, siteName, new CsmPublishingProfileOptions()))
            {
                string profileXml = await (new StreamReader(stream)).ReadToEndAsync();
                Console.WriteLine(profileXml);
            }

            // Restart the site
            await _websiteClient.WebApps.RestartAsync(rgName, siteName, softRestart: true);
        }
    }
}
