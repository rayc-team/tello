using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using teethClinicApi.Models;

namespace teethClinicApi.Controllers;

public record CreateScheduleDto(int DoctorId, DateOnly WorkDate, TimeOnly StartTime, TimeOnly EndTime, string Cabinet);
public record UpdateScheduleDto(int? DoctorId, DateOnly? WorkDate, TimeOnly? StartTime, TimeOnly? EndTime, string? Cabinet);

[ApiController]
[Route("api/[controller]")]
public class SchedulesController : BaseController
{
    // GET: api/schedules or api/schedules?doctorId=1
    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int? doctorId)
    {
        var query = Db.Schedules.AsQueryable();

        if (doctorId.HasValue)
            query = query.Where(s => s.DoctorId == doctorId.Value);

        var list = await query
            .Select(s => new
            {
                s.Id,
                s.DoctorId,
                DoctorName = s.Doctor.FullName,
                DoctorSpecialty = s.Doctor.Specialty,
                s.WorkDate,
                s.StartTime,
                s.EndTime,
                s.Cabinet
            })
            .ToListAsync();

        return Ok(list);
    }

    // POST: api/schedules
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateScheduleDto dto)
    {
        var doctorExists = await Db.Doctors.AnyAsync(d => d.Id == dto.DoctorId);
        if (!doctorExists)
            return BadRequest($"Врач с ID {dto.DoctorId} не найден");

        if (dto.StartTime >= dto.EndTime)
            return BadRequest("Время начала смены должно быть раньше времени окончания");

        var schedule = new Schedule
        {
            DoctorId = dto.DoctorId,
            WorkDate = dto.WorkDate,
            StartTime = dto.StartTime,
            EndTime = dto.EndTime,
            Cabinet = dto.Cabinet
        };

        Db.Schedules.Add(schedule);
        await Db.SaveChangesAsync();

        return Ok(new
        {
            schedule.Id,
            schedule.DoctorId,
            schedule.WorkDate,
            schedule.StartTime,
            schedule.EndTime,
            schedule.Cabinet
        });
    }

    // PUT: api/schedules/1
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateScheduleDto dto)
    {
        var schedule = await Db.Schedules.FindAsync(id);
        if (schedule == null) return NotFound("Смена в расписании не найдена");

        if (dto.DoctorId.HasValue)
        {
            var doctorExists = await Db.Doctors.AnyAsync(d => d.Id == dto.DoctorId.Value);
            if (!doctorExists) return BadRequest($"Врач с ID {dto.DoctorId.Value} не найден");
            schedule.DoctorId = dto.DoctorId.Value;
        }

        if (dto.WorkDate.HasValue) schedule.WorkDate = dto.WorkDate.Value;
        if (dto.StartTime.HasValue) schedule.StartTime = dto.StartTime.Value;
        if (dto.EndTime.HasValue) schedule.EndTime = dto.EndTime.Value;
        if (!string.IsNullOrEmpty(dto.Cabinet)) schedule.Cabinet = dto.Cabinet;

        await Db.SaveChangesAsync();

        return Ok(new
        {
            schedule.Id,
            schedule.DoctorId,
            schedule.WorkDate,
            schedule.StartTime,
            schedule.EndTime,
            schedule.Cabinet
        });
    }

    // DELETE: api/schedules/1
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var schedule = await Db.Schedules.FindAsync(id);
        if (schedule == null) return NotFound("Смена в расписании не найдена");

        Db.Schedules.Remove(schedule);
        await Db.SaveChangesAsync();
        return NoContent();
    }
}
