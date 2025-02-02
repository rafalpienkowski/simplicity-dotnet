using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.OutputCaching;
using Npgsql;

namespace Tickets.Controllers;

[Route("tickets")]
public class TicketsController(
    NpgsqlDataSource datasource,
    ILogger<TicketsController> logger)
    : Controller
{
    [HttpGet("events")]
    public async Task<IActionResult> GetEventsPartial()
    {
        logger.LogInformation("Getting events");

        const string query = "SELECT event_id, event_date, event_name FROM tickets.events;";
        await using var command = datasource.CreateCommand(query);
        await using var reader = await command.ExecuteReaderAsync();
        var events = new List<EventModel>();
        while (await reader.ReadAsync())
        {
            var eventModel = new EventModel(
                reader.GetInt32(reader.GetOrdinal("event_id")),
                reader.GetString(reader.GetOrdinal("event_name")),
                reader.GetDateTime(reader.GetOrdinal("event_date")));

            events.Add(eventModel);
        }

        return PartialView("_EventsPartial", events);
    }

    [HttpGet("events/{eventId:int}/sectors")]
    public async Task<IActionResult> GetSectorsPartial(int eventId)
    {
        const string query =
            "SELECT DISTINCT sector FROM tickets.seats WHERE event_id = @EventId ORDER BY sector;";

        var sectors = new List<string>();
        await using var command = datasource.CreateCommand(query);
        command.Parameters.AddWithValue("@EventId", eventId);

        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            sectors.Add(reader.GetString(reader.GetOrdinal("sector")));
        }

        ViewData["eventId"] = eventId;
        return PartialView("_SectorsPartial", sectors);
    }

    [HttpGet("events/{eventId:int}/sectors/{sector}")]
    [OutputCache(Duration = 30)]
    public async Task<IActionResult> GetSeatsPartial(int eventId, string sector, [FromQuery] string data)
    {
        const string query =
            "SELECT seat_id, row, seat, is_available, last_changed FROM tickets.available_seats WHERE event_id = @EventId AND sector = @Sector;";

        var seats = new List<SeatModel>();

        await using var command = datasource.CreateCommand(query);
        command.Parameters.AddWithValue("@EventId", eventId);
        command.Parameters.AddWithValue("@Sector", sector);

        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var seat = new SeatModel(
                reader.GetInt32(reader.GetOrdinal("seat_id")),
                reader.GetInt32(reader.GetOrdinal("row")),
                reader.GetInt32(reader.GetOrdinal("seat")),
                reader.GetBoolean(reader.GetOrdinal("is_available")),
                reader.GetDateTime(reader.GetOrdinal("last_changed")));

            seats.Add(seat);
        }

        if (!string.IsNullOrEmpty(data))
        {
            return Ok(seats);
        }

        return PartialView("_SeatsPartial", seats);
    }

}

public record EventModel(int Event_Id, string Event_Name, DateTime Event_Date);

public record SeatModel(int Seat_Id, int Row, int Seat, bool Is_Available, DateTime Last_Changed);
