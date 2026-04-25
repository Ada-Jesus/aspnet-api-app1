var builder = WebApplication.CreateBuilder(args);

// ---------------- ECS BINDING ----------------
builder.WebHost.UseUrls("http://0.0.0.0:8080");

// ---------------- SERVICES ----------------
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// ---------------- SWAGGER (SAFE FOR DEV + ECS) ----------------
app.UseSwagger();
app.UseSwaggerUI();

// ---------------- HEALTH CHECK (ALB) ----------------
app.MapGet("/health", () => Results.Ok("OK"));

// ---------------- SAMPLE API ----------------
var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild",
    "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast(
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();

    return forecast;
})
.WithName("GetWeatherForecast")
.WithOpenApi();

app.Run();

// ---------------- MODEL ----------------
record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}