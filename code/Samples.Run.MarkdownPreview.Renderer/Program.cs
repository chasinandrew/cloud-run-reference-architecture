// Copyright 2022 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var port = Environment.GetEnvironmentVariable("PORT");
if (port != null)
{
    app.Urls.Add($"http://0.0.0.0:{port}");
}

app.MapPost("/", async (HttpRequest request) =>
{
    using var reader = new StreamReader(request.Body);
    var bodyString = await reader.ReadToEndAsync();
    return Markdig.Markdown.ToHtml(bodyString); 
});

app.Run();


// Expose Program class for unit tests //
public partial class Program  { }
