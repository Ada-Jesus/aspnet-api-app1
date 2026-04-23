var builder = WebApplication.CreateBuilder(args);

// ---------------- IMPORTANT: ECS NETWORK BINDING ----------------
// Ensures the app listens on the correct interface + port for ALB
builder.WebHost.UseUrls("http://0.0.0.0:8080");

// ---------------- SERVICES ----------------
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();


// ---------------- HEALTH CHECK (CRITICAL FOR ALB) ----------------
app.MapGet("/health", () => Results.Ok("healthy"));


// ---------------- SWAGGER ----------------
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();


// ---------------- API ----------------
var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild",
    "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();

    return forecast;
})
.WithName("GetWeatherForecast")
.WithOpenApi();


// ---------------- START APP ----------------
app.Run();


// ---------------- MODEL ----------------
record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}