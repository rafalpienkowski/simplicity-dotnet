using Npgsql;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();
builder.Services.AddControllers();
builder.Services.AddResponseCaching();
builder.Services.AddResponseCompression();

builder.Services.AddSingleton<NpgsqlDataSource>(_ =>
    new NpgsqlDataSourceBuilder(builder.Configuration.GetConnectionString("PostgresConnection")).Build());

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.MapControllers();
app.UseResponseCompression();
app.UseResponseCaching();
app.MapRazorPages();

await app.RunAsync();