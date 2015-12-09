using System;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace HttpClientSample
{
    public static class AuthenticationHelpers
    {
        const string ARMResource = "https://management.core.windows.net/";
        const string TokenEndpoint = "https://login.windows.net/{0}/oauth2/token";
        const string SPNPayload = "resource={0}&client_id={1}&grant_type=client_credentials&client_secret={2}";

        public static async Task<string> AcquireTokenBySPN(string tenantId, string clientId, string clientSecret)
        {
            var payload = String.Format(SPNPayload,
                                        WebUtility.UrlEncode(ARMResource),
                                        WebUtility.UrlEncode(clientId),
                                        WebUtility.UrlEncode(clientSecret));

            var body = await HttpPost(tenantId, payload);
            return body.access_token;
        }

        static async Task<dynamic> HttpPost(string tenantId, string payload)
        {
            using (var client = new HttpClient())
            {
                var address = String.Format(TokenEndpoint, tenantId);
                var content = new StringContent(payload, Encoding.UTF8, "application/x-www-form-urlencoded");
                using (var response = await client.PostAsync(address, content))
                {
                    if (!response.IsSuccessStatusCode)
                    {
                        Console.WriteLine("Status:  {0}", response.StatusCode);
                        Console.WriteLine("Content: {0}", await response.Content.ReadAsStringAsync());
                    }

                    response.EnsureSuccessStatusCode();

                    return await response.Content.ReadAsAsync<dynamic>();
                }
            }
        }
    }
}
