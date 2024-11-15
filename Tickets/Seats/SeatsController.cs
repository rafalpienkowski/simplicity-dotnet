using System.Data;
using Dapper;
using Microsoft.AspNetCore.Mvc;

namespace Tickets.Seats;

[Route("seats")]
public class SeatsController(
    IDbConnection dbConnection, 
    ILogger<SeatsController> logger) 
    : Controller
{
    
    [HttpGet("{eventId:int}")]
    public async Task<IActionResult> GetSeatsPartial(int eventId)
    {
        logger.LogInformation("Getting seats for event {EventId}", eventId);
        
        const string query = "SELECT * FROM tickets.events WHERE event_id = @EventId";
        var seats = await dbConnection.QueryAsync<SeatModel>(query, new { EventId = eventId });
        
        return PartialView("_SeatsPartial", seats);
    }
}

public class SeatModel
{
    public int Ticket_Id { get; set; }
    public int EventId { get; set; }
    public string Sector { get; set; }
    public int Row { get; set; }
    public int Seat { get; set; }
    public bool Is_Available { get; set; }
    public DateTime Last_Changed { get; set; }
}