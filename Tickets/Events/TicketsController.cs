using System.Data;
using Dapper;
using Microsoft.AspNetCore.Mvc;

namespace Tickets.Events;

[Route("tickets")]
public class TicketsController(
    IDbConnection dbConnection,
    ILogger<TicketsController> logger)
    : Controller
{
    [HttpGet("events")]
    public async Task<IActionResult> GetEventsPartial()
    {
        logger.LogInformation("Getting events");

        const string query = "SELECT * FROM reservations.events;";
        var events = await dbConnection.QueryAsync<EventModel>(query);

        return PartialView("_EventsPartial", events);
    }

    [HttpGet("events/{eventId:int}/sectors")]
    public async Task<IActionResult> GetSectorsPartial(int eventId)
    {
        const string query = "SELECT DISTINCT sector FROM reservations.tickets WHERE event_id = @EventId ORDER BY sector;";
        var sectors = await dbConnection.QueryAsync<string>(query, param: new { EventId = eventId });

        ViewData["eventId"] = eventId;
        return PartialView("_SectorsPartial", sectors);
    }

    [HttpGet("events/{eventId:int}/sectors/{sector}")]
    public async Task<IActionResult> GetSeatsPartial(int eventId, string sector)
    {
        logger.LogInformation("Getting seats for event {EventId} and sector {Sector}", eventId, sector);

        const string query = "SELECT * FROM reservations.tickets WHERE event_id = @EventId AND sector = @Sector;";
        var seats = await dbConnection.QueryAsync<SeatModel>(query, new { EventId = eventId, Sector = sector });

        return PartialView("_SeatsPartial", seats);
    }

    [HttpPost("{ticketId:int}")]
    public IActionResult Reserve(int ticketId)
    {
        logger.LogInformation("Reserving ticket {TicketId}", ticketId);
        
        return Ok("O");
    }
}

public class EventModel
{
    public int Event_Id { get; set; }
    public string Event_Name { get; set; }
    public DateTime Event_Date { get; set; }
}

public class SeatModel
{
    public int Ticket_Id { get; set; }
    public int Row { get; set; }
    public int Seat { get; set; }
    public bool Is_Available { get; set; }
}