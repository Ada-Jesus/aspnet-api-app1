# ---------------- BASE RUNTIME ----------------
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

# IMPORTANT: ECS ALB expects this port
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

# ---------------- BUILD ----------------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY . .

RUN dotnet restore
RUN dotnet publish -c Release -o /app/publish

# ---------------- FINAL ----------------
FROM base AS final
WORKDIR /app

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "aspnet-api-app.dll"]
