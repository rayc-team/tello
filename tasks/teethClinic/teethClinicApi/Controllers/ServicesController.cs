using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using teethClinicApi.Models;

namespace teethClinicApi.Controllers;

public record ServiceDto(string Name, decimal Price);
public record RecordProcedureDto(int AppointmentId, int ServiceId, int Quantity = 1);

[ApiController]
[Route("api/[controller]")]
public class ServicesController : BaseController
{
    // GET: api/services
    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await Db.Services.Select(s => new { s.Id, s.Name, s.Price }).ToListAsync());

    // POST: api/services
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] ServiceDto dto)
    {
        var service = new Service { Name = dto.Name, Price = dto.Price };
        Db.Services.Add(service);
        await Db.SaveChangesAsync();
        return Ok(new { service.Id, service.Name, service.Price });
    }

    // POST: api/services/record
    [HttpPost("record")]
    public async Task<IActionResult> RecordProcedure([FromBody] RecordProcedureDto dto)
    {
        if (!await Db.Appointments.AnyAsync(a => a.Id == dto.AppointmentId))
            return BadRequest($"Приём с ID {dto.AppointmentId} не найден");

        if (!await Db.Services.AnyAsync(s => s.Id == dto.ServiceId))
            return BadRequest($"Услуга с ID {dto.ServiceId} не найдена");

        var item = new AppliedService
        {
            AppointmentId = dto.AppointmentId,
            ServiceId = dto.ServiceId,
            Quantity = dto.Quantity > 0 ? dto.Quantity : 1
        };

        Db.AppliedServices.Add(item);
        await Db.SaveChangesAsync();

        return Ok(new
        {
            item.Id,
            item.AppointmentId,
            item.ServiceId,
            item.Quantity
        });
    }

    // DELETE: api/services/record/1
    [HttpDelete("record/{id:int}")]
    public async Task<IActionResult> DeleteRecordedProcedure(int id)
    {
        var item = await Db.AppliedServices.FindAsync(id);
        if (item == null) return NotFound("Запись об оказанной услуге не найдена");

        Db.AppliedServices.Remove(item);
        await Db.SaveChangesAsync();
        return NoContent();
    }
}
