# Stage 1: Build Backend & Frontend
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn

# Copy csproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore

# Copy the remaining project files
COPY . .

# Build frontend assets
RUN yarn install
RUN yarn run build:prod

# Publish the .NET application
RUN dotnet publish -c Release -o /app/publish

# Stage 2: Runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime

# Install cultures to support ICU
RUN apk add --no-cache icu-libs
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

WORKDIR /app
COPY --from=build /app/publish .

# Configure ASP.NET Core
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "AspnetCoreMvcFull.dll"]
