using System;
using System.Collections.Generic;

namespace teethClinicApi.Models;

public partial class User
{
    public int Id { get; set; }

    public string Username { get; set; } = null!;

    public string Password { get; set; } = null!;

    public string Role { get; set; } = null!;

    public int? DoctorId { get; set; }

    public virtual Doctor? Doctor { get; set; }
}
