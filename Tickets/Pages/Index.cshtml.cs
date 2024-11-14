using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Tickets.Pages;

public class IndexModel(ILogger<IndexModel> logger) : PageModel
{
    public void OnGet()
    {
        logger.LogInformation("Main page requested");
    }
}