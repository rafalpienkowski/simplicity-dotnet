using System.Data;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Dapper;
using Microsoft.AspNetCore.Mvc;

namespace Tickets.Pages;

public class IndexModel(IDbConnection dbConnection, ILogger<IndexModel> logger) : PageModel
{
    public void OnGet()
    {
        logger.LogInformation("Main page requested");
    }
    
    public async Task<IActionResult> OnGetRowCountAsync()
    {
        logger.LogInformation("Row count requested");

        const string query = "SELECT COUNT(*) FROM tickets.events";
        var result = await dbConnection.ExecuteScalarAsync<int>(query);
        return Content(result.ToString());
    }
}