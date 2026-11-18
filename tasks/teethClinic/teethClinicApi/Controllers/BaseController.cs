using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using teethClinicApi.Models;

namespace teethClinicApi.Controllers;

[ApiController]
public abstract class BaseController : ControllerBase
{
    private AppDbContext? _db;

    protected AppDbContext Db => _db ??= HttpContext.RequestServices.GetRequiredService<AppDbContext>();
}
