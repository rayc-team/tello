using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using teethClinicApi.Models;

namespace teethClinicApi.Controllers;

public record DoctorDto(string FullName, string Specialty);

[ApiController]
[Route("api/[controller]")]
public class DoctorsController : BaseController
{
    // GET: api/doctors
    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await Db.Doctors.Select(d => new { d.Id, d.FullName, d.Specialty }).ToListAsync());

    // POST: api/doctors
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] DoctorDto dto)
    {
        var doctor = new Doctor
        {
            FullName = dto.FullName,
            Specialty = dto.Specialty
        };

        Db.Doctors.Add(doctor);
        await Db.SaveChangesAsync();
        return Ok(new { doctor.Id, doctor.FullName, doctor.Specialty });
    }

    // PUT: api/doctors/1
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] DoctorDto dto)
    {
        var doctor = await Db.Doctors.FindAsync(id);
        if (doctor == null) return NotFound("Врач не найден");

        doctor.FullName = dto.FullName;
        doctor.Specialty = dto.Specialty;
        await Db.SaveChangesAsync();

        return Ok(new { doctor.Id, doctor.FullName, doctor.Specialty });
    }

    // DELETE: api/doctors/1
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var doctor = await Db.Doctors.FindAsync(id);
        if (doctor == null) return NotFound("Врач не найден");

        Db.Doctors.Remove(doctor);
        await Db.SaveChangesAsync();
        return NoContent();
    }
}
