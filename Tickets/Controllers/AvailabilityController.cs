using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Npgsql;

namespace Tickets.Controllers;

[Microsoft.AspNetCore.Components.Route("availability")]
public class AvailabilityController(
    NpgsqlDataSource datasource
) : Controller
{
    [HttpPost("")]
    public async Task<IActionResult> Reserve([FromBody] Request request)
    {
        var jsonbData = JsonSerializer.Serialize(request.resources.Select(x =>
            new { external_id = x.id, last_changed = DateTime.Parse(x.last_changed), owner = x.owner }));

        const string query = "SELECT availability.reserve(@Data::jsonb);";

        await using var command = datasource.CreateCommand(query);
        command.Parameters.AddWithValue("@Data", NpgsqlTypes.NpgsqlDbType.Jsonb, jsonbData);

        var result = (int)(await command.ExecuteScalarAsync() ?? -1);

        if (result == 0)
        {
            return Ok("Resource reserved");
        }

        return BadRequest("Unable to reserve resource");
    }
}

public record Request(Resource[] resources);

public record Resource(int id, string last_changed, string owner);
