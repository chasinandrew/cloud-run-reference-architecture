FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-env
WORKDIR /app

COPY *.csproj ./
RUN dotnet restore

COPY . ./
RUN dotnet publish -r linux-x64 --no-self-contained -p:PublishReadyToRun=true -c Release -o out

# Copy to runtime image
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
COPY --from=build-env /app/out .

# Port passed in by Cloud Run via environment variable PORT.  Default 8080.
ENV PORT=8080

# Run the web service on container startup.
ENTRYPOINT ["dotnet", "helloworld.dll"]
