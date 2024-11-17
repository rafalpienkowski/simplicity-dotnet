using System.Data;
using Dapper;
using Microsoft.AspNetCore.Mvc;
using Npgsql;

namespace Tickets.Tickets;

[Route("tickets")]
public class TicketsController(
    NpgsqlConnection dbConnection,
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
        const string query =
            "SELECT DISTINCT sector FROM reservations.tickets WHERE event_id = @EventId ORDER BY sector;";
        var sectors = await dbConnection.QueryAsync<string>(query, param: new { EventId = eventId });

        ViewData["eventId"] = eventId;
        return PartialView("_SectorsPartial", sectors);
    }

    [HttpGet("events/{eventId:int}/sectors/{sector}")]
    public async Task<IActionResult> GetSeatsPartial(int eventId, string sector)
    {
        logger.LogInformation("Getting seats for event {EventId} and sector {Sector}", eventId, sector);

        const string query =
            "SELECT seat_id, row, seat, is_available FROM reservations.tickets WHERE event_id = @EventId AND sector = @Sector;";
        var seats = await dbConnection.QueryAsync<SeatModel>(query, new { EventId = eventId, Sector = sector });

        return PartialView("_SeatsPartial", seats);
    }

    [HttpPost("")]
    public async Task<IActionResult> Reserve([FromBody] ReserveSeats reserveSeats, CancellationToken ct)
    {
        logger.LogInformation("Reserving seats {ReserveSeats}",
            reserveSeats.SeatIds.Select(id => id.ToString()));

        if (dbConnection.State != ConnectionState.Open)
        {
            await dbConnection.OpenAsync(ct);
        }
        
        await using var transaction = await dbConnection.BeginTransactionAsync(ct);
        try
        {
            const string selectQuery = @"
                    SELECT seat_id
                    FROM reservations.tickets
                    WHERE seat_id = ANY(@SeatIds) AND is_available = TRUE
                    FOR UPDATE;
                ";

            var selectedSeats = await dbConnection.QueryAsync<int>(
                selectQuery,
                new { reserveSeats.SeatIds },
                transaction: transaction
            );

            if (selectedSeats.Any())
            {
                const string updateQuery = @"
                        UPDATE reservations.tickets
                        SET is_available = FALSE, last_changed = CURRENT_TIMESTAMP
                        WHERE seat_id = ANY(@SeatIds) AND is_available = TRUE;
                    ";

                await dbConnection.ExecuteAsync(
                    updateQuery,
                    new { reserveSeats.SeatIds },
                    transaction: transaction
                );

                await transaction.CommitAsync(ct);
                return Ok();
            }
            else
            {
                await transaction.RollbackAsync(ct);
                return BadRequest("Unable to reserve seats.");
            }
        }
        catch (Exception)
        {
            await transaction.RollbackAsync(ct);
            throw;
        }
    }
}

public record EventModel(int Event_Id, string Event_Name, DateTime Event_Date);

public record SeatModel(int Seat_Id, int Row, int Seat, bool Is_Available);

public record ReserveSeats(int[] SeatIds);