using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using teethClinicApi.Models;

namespace teethClinicApi.Controllers;

public record PatientDto(string FullName, string Phone);

[ApiController]
[Route("api/[controller]")]
public class PatientsController : BaseController
{
    // GET: api/patients
    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await Db.Patients.Select(p => new { p.Id, p.FullName, p.Phone }).ToListAsync());

    // POST: api/patients
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] PatientDto dto)
    {
        var patient = new Patient
        {
            FullName = dto.FullName,
            Phone = dto.Phone
        };

        Db.Patients.Add(patient);
        await Db.SaveChangesAsync();
        return Ok(new { patient.Id, patient.FullName, patient.Phone });
    }

    // PUT: api/patients/1
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] PatientDto dto)
    {
        var patient = await Db.Patients.FindAsync(id);
        if (patient == null) return NotFound("Пациент не найден");

        patient.FullName = dto.FullName;
        patient.Phone = dto.Phone;
        await Db.SaveChangesAsync();

        return Ok(new { patient.Id, patient.FullName, patient.Phone });
    }

    // DELETE: api/patients/1
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var patient = await Db.Patients.FindAsync(id);
        if (patient == null) return NotFound("Пациент не найден");

        Db.Patients.Remove(patient);
        await Db.SaveChangesAsync();
        return NoContent();
    }
}
