using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using teethClinicApi.Models;

namespace teethClinicApi.Controllers;

public record CreateAppointmentDto(int PatientId, int ScheduleId, TimeOnly AppointmentTime);
public record UpdateAppointmentDto(int? PatientId, int? ScheduleId, TimeOnly? AppointmentTime, string? Status, string? Result);

[ApiController]
[Route("api/[controller]")]
public class AppointmentsController : BaseController
{
    // GET: api/appointments или api/appointments?doctorId=1
    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int? doctorId)
    {
        var query = Db.Appointments.AsQueryable();

        if (doctorId.HasValue)
            query = query.Where(a => a.Schedule.DoctorId == doctorId.Value);

        var list = await query
            .Select(a => new
            {
                a.Id,
                a.PatientId,
                PatientName = a.Patient.FullName,
                PatientPhone = a.Patient.Phone,
                a.ScheduleId,
                DoctorId = a.Schedule.DoctorId,
                DoctorName = a.Schedule.Doctor.FullName,
                WorkDate = a.Schedule.WorkDate,
                Cabinet = a.Schedule.Cabinet,
                a.AppointmentTime,
                a.Status,
                a.Result,
                AppliedServices = a.AppliedServices.Select(ap => new
                {
                    ap.Id,
                    ap.ServiceId,
                    ServiceName = ap.Service.Name,
                    ap.Service.Price,
                    ap.Quantity,
                    Total = ap.Service.Price * ap.Quantity
                })
            })
            .ToListAsync();

        return Ok(list);
    }

    // POST: api/appointments
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateAppointmentDto dto)
    {
        var patientExists = await Db.Patients.AnyAsync(p => p.Id == dto.PatientId);
        if (!patientExists)
            return BadRequest($"Пациент с ID {dto.PatientId} не найден");

        var schedule = await Db.Schedules.FindAsync(dto.ScheduleId);
        if (schedule == null)
            return BadRequest($"Смена расписания с ID {dto.ScheduleId} не найдена");

        if (dto.AppointmentTime < schedule.StartTime || dto.AppointmentTime >= schedule.EndTime)
            return BadRequest($"Время приёма ({dto.AppointmentTime}) должно быть внутри смены врача ({schedule.StartTime} - {schedule.EndTime})");

        var appt = new Appointment
        {
            PatientId = dto.PatientId,
            ScheduleId = dto.ScheduleId,
            AppointmentTime = dto.AppointmentTime,
            Status = "Запланирован"
        };

        Db.Appointments.Add(appt);
        await Db.SaveChangesAsync();

        return Ok(new
        {
            appt.Id,
            appt.PatientId,
            appt.ScheduleId,
            appt.AppointmentTime,
            appt.Status
        });
    }

    // PUT: api/appointments/1
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateAppointmentDto dto)
    {
        var appt = await Db.Appointments.FindAsync(id);
        if (appt == null) return NotFound("Запись на приём не найдена");

        if (dto.PatientId.HasValue)
        {
            if (!await Db.Patients.AnyAsync(p => p.Id == dto.PatientId.Value))
                return BadRequest($"Пациент с ID {dto.PatientId.Value} не найден");
            appt.PatientId = dto.PatientId.Value;
        }

        if (dto.ScheduleId.HasValue)
        {
            if (!await Db.Schedules.AnyAsync(s => s.Id == dto.ScheduleId.Value))
                return BadRequest($"Расписание с ID {dto.ScheduleId.Value} не найдено");
            appt.ScheduleId = dto.ScheduleId.Value;
        }

        if (dto.AppointmentTime.HasValue) appt.AppointmentTime = dto.AppointmentTime.Value;
        if (!string.IsNullOrEmpty(dto.Status)) appt.Status = dto.Status;
        if (dto.Result != null) appt.Result = dto.Result;

        await Db.SaveChangesAsync();

        return Ok(new
        {
            appt.Id,
            appt.PatientId,
            appt.ScheduleId,
            appt.AppointmentTime,
            appt.Status,
            appt.Result
        });
    }

    // DELETE: api/appointments/1
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var appt = await Db.Appointments.FindAsync(id);
        if (appt == null) return NotFound("Запись на приём не найдена");

        Db.Appointments.Remove(appt);
        await Db.SaveChangesAsync();
        return NoContent();
    }
}
