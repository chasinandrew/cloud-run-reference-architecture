# Use Microsoft's official build .NET image.
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-env
WORKDIR /

# Copy csproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /
COPY --from=build-env /out .

ENV PORT=8080
# Run the web service on container startup.
ENTRYPOINT ["dotnet", "helloworld.dll"]
