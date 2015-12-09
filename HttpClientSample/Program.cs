using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace HttpClientSample
{
    class Program
    {
        static string Subscription = ConfigurationManager.AppSettings["AzureSubscription"];

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
            string tenantId = ConfigurationManager.AppSettings["AzureTenantId"];
            string clientId = ConfigurationManager.AppSettings["AzureClientId"];
            string clientSecret = ConfigurationManager.AppSettings["AzureClientSecret"];

            string token = await AuthenticationHelpers.AcquireTokenBySPN(tenantId, clientId, clientSecret);

            using (var client = new HttpClient(new LoggingHandler(new HttpClientHandler())))
            {
                client.DefaultRequestHeaders.Add("Authorization", "Bearer " + token);
                client.BaseAddress = new Uri("https://management.azure.com/");

                await MakeARMRequests(client);
            }
        }

        static async Task MakeARMRequests(HttpClient client)
        {
            const string ResourceGroup = "MyResourceGroup";
            const string AppServicePlan = "MyAppServicePlan";
            const string WebApp = "SampleSiteFromAPI";
            const string Location = "West US";

            // Create the resource group

            using (var response = await client.PutAsJsonAsync(
                $"/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}?api-version=2015-11-01",
                new
                {
                    location = Location
                }))
            {
                response.EnsureSuccessStatusCode();
            }

            // Create the App Service Plan

            using (var response = await client.PutAsJsonAsync(
                $"/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/serverfarms/{AppServicePlan}?api-version=2015-08-01",
                new
                {
                    location = Location,
                    Sku = new
                    {
                        Name = "F1"
                    }
                }))
            {
                response.EnsureSuccessStatusCode();
            }

            // Create the Web App

            using (var response = await client.PutAsJsonAsync(
                $"/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{WebApp}?api-version=2015-08-01",
                new
                {
                    location = Location,
                    properties = new
                    {
                        serverFarmId = AppServicePlan
                    }
                }))
            {
                response.EnsureSuccessStatusCode();
            }

            // List the Web Apps and their host names

            using (var response = await client.GetAsync(
                $"/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites?api-version=2015-08-01"))
            {
                response.EnsureSuccessStatusCode();

                var json = await response.Content.ReadAsAsync<dynamic>();
                foreach (var app in json.value)
                {
                    Console.WriteLine(app.name);
                    foreach (var hostname in app.properties.enabledHostNames)
                    {
                        Console.WriteLine("  " + hostname);
                    }
                }
            }

            // Set some app settings

            using (var response = await client.PutAsJsonAsync(
                $"/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{WebApp}/config/appsettings?api-version=2015-08-01",
                new
                {
                    properties = new
                    {
                        Foo = "Hello",
                        Bar = "Bye",
                    }
                }))
            {
                response.EnsureSuccessStatusCode();
            }

            // Turn on http logging

            using (var response = await client.PutAsJsonAsync(
                $"/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{WebApp}/config/logs?api-version=2015-08-01",
                new
                {
                    properties = new
                    {
                        httpLogs = new
                        {
                            fileSystem = new
                            {
                                enabled = true
                            }
                        }
                    }
                }))
            {
                response.EnsureSuccessStatusCode();
            }

            // Stop the app

            using (var response = await client.PostAsync(
                $"/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{WebApp}/stop?api-version=2015-08-01",
                null))
            {
                response.EnsureSuccessStatusCode();
            }

            // Delete the Web App

            using (var response = await client.DeleteAsync(
                $"/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{WebApp}?api-version=2015-08-01"))
            {
                response.EnsureSuccessStatusCode();
            }
        }
    }
}
