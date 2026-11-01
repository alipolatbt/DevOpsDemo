using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);
builder.Logging.ClearProviders();
builder.Logging.AddJsonConsole();
builder.Services.AddHealthChecks();
builder.Services.AddHttpLogging(_ => { });

var app = builder.Build();
app.UseHttpLogging();

app.MapGet("/", () => Results.Ok(new { app = "DevOpsDemo", status = "running" }));
app.MapGet("/api/info", (IConfiguration cfg) => Results.Ok(new {
    app = "DevOpsDemo",
    environment = cfg["APP_ENV"] ?? app.Environment.EnvironmentName,
    version = typeof(Program).Assembly.GetName().Version?.ToString(),
    machine = Environment.MachineName,
    utc = DateTimeOffset.UtcNow
}));

static Task WriteHealth(HttpContext context, HealthReport report)
{
    context.Response.ContentType = "application/json";
    return context.Response.WriteAsync(JsonSerializer.Serialize(new {
        status = report.Status.ToString(),
        durationMs = report.TotalDuration.TotalMilliseconds
    }));
}

app.MapHealthChecks("/health/live", new HealthCheckOptions {
    Predicate = _ => false,
    ResponseWriter = WriteHealth
});
app.MapHealthChecks("/health/ready", new HealthCheckOptions {
    ResponseWriter = WriteHealth
});

app.Run();
