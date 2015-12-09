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
        static string _subscription = ConfigurationManager.AppSettings["AzureSubscription"];

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

            object body = new
            {
                location = Location
            };

            using (var response = await client.PutAsJsonAsync(
                $"/subscriptions/{_subscription}/resourceGroups/{ResourceGroup}?api-version=2015-11-01",
                body))
            {
                response.EnsureSuccessStatusCode();
            }

            // Create the App Service Plan

            body = new
            {
                location = Location,
                Sku = new
                {
                    Name = "F1"
                }
            };

            using (var response = await client.PutAsJsonAsync(
                $"/subscriptions/{_subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/serverfarms/{AppServicePlan}?api-version=2015-08-01",
                body))
            {
                response.EnsureSuccessStatusCode();
            }

            // Create the Web App

            body = new
            {
                location = Location,
                properties = new
                {
                    serverFarmId = AppServicePlan
                }
            };

            using (var response = await client.PutAsJsonAsync(
                $"/subscriptions/{_subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{WebApp}?api-version=2015-08-01",
                body))
            {
                response.EnsureSuccessStatusCode();
            }

            // List the Web Apps and their host names

            using (var response = await client.GetAsync(
                $"/subscriptions/{_subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites?api-version=2015-08-01"))
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

            body = new
            {
                properties = new
                {
                    Foo = "Hello",
                    Bar = "Bye",
                }
            };

            using (var response = await client.PutAsJsonAsync(
                $"/subscriptions/{_subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{WebApp}/config/appsettings?api-version=2015-08-01",
                body))
            {
                response.EnsureSuccessStatusCode();
            }

            // Turn on http logging

            body = new
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
            };

            using (var response = await client.PutAsJsonAsync(
                $"/subscriptions/{_subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{WebApp}/config/logs?api-version=2015-08-01",
                body))
            {
                response.EnsureSuccessStatusCode();
            }

            // Stop the app

            using (var response = await client.PostAsync(
                $"/subscriptions/{_subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{WebApp}/stop?api-version=2015-08-01",
                null))
            {
                response.EnsureSuccessStatusCode();
            }

            // Delete the Web App

            using (var response = await client.DeleteAsync(
                $"/subscriptions/{_subscription}/resourceGroups/{ResourceGroup}/providers/Microsoft.Web/sites/{WebApp}?api-version=2015-08-01"))
            {
                response.EnsureSuccessStatusCode();
            }
        }
    }
}
