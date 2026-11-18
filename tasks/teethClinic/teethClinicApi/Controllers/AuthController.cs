using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using teethClinicApi.Models;

namespace teethClinicApi.Controllers;

public record LoginDto(string Username, string Password);

public record RegisterUserDto(string Username, string Password, string Role, int? DoctorId);

[ApiController]
[Route("api/[controller]")]
public class AuthController : BaseController
{
    // GET: api/auth/users
    [HttpGet("users")]
    public async Task<IActionResult> GetAllUsers()
    {
        var users = await Db.Users
            .Select(u => new
            {
                u.Id,
                u.Username,
                u.Role,
                u.DoctorId,
                DoctorName = u.Doctor != null ? u.Doctor.FullName : null
            })
            .ToListAsync();

        return Ok(users);
    }

    // POST: api/auth/login
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto request)
    {
        var user = await Db.Users
            .FirstOrDefaultAsync(u => u.Username == request.Username && u.Password == request.Password);

        if (user == null)
            return Unauthorized(new { message = "Неверный логин или пароль" });

        return Ok(new
        {
            user.Id,
            user.Username,
            user.Role,
            user.DoctorId,
            message = $"Успешный вход под ролью: {user.Role}"
        });
    }

    // POST: api/auth/register
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterUserDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Username) || string.IsNullOrWhiteSpace(dto.Password))
            return BadRequest("Логин и пароль не могут быть пустыми");

        if (await Db.Users.AnyAsync(u => u.Username == dto.Username))
            return BadRequest($"Пользователь с логином '{dto.Username}' уже существует");

        if (dto.Role != "Администратор" && dto.Role != "Врач")
            return BadRequest("Роль должна быть 'Администратор' или 'Врач'");

        int? finalDoctorId = null;

        // Если роль "Врач" — проверяем, что указан существующий DoctorId из таблицы doctors:
        if (dto.Role == "Врач")
        {
            if (!dto.DoctorId.HasValue || dto.DoctorId.Value <= 0)
                return BadRequest("Для роли 'Врач' необходимо указать существующий doctorId из таблицы врачей");

            var doctorExists = await Db.Doctors.AnyAsync(d => d.Id == dto.DoctorId.Value);
            if (!doctorExists)
                return BadRequest($"Врач с ID {dto.DoctorId.Value} не найден в таблице doctors");

            finalDoctorId = dto.DoctorId.Value;
        }

        var newUser = new User
        {
            Username = dto.Username,
            Password = dto.Password,
            Role = dto.Role,
            DoctorId = finalDoctorId
        };

        Db.Users.Add(newUser);
        await Db.SaveChangesAsync();

        return Ok(new
        {
            newUser.Id,
            newUser.Username,
            newUser.Role,
            newUser.DoctorId
        });
    }

    // DELETE: api/auth/users/1
    [HttpDelete("users/{id:int}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        var user = await Db.Users.FindAsync(id);
        if (user == null) return NotFound("Пользователь не найден");

        Db.Users.Remove(user);
        await Db.SaveChangesAsync();
        return NoContent();
    }
}
