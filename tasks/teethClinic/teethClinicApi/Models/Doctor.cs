using System;
using System.Collections.Generic;

namespace teethClinicApi.Models;

public partial class Doctor
{
    public int Id { get; set; }

    public string FullName { get; set; } = null!;

    public string Specialty { get; set; } = null!;

    public virtual ICollection<Schedule> Schedules { get; set; } = new List<Schedule>();

    public virtual ICollection<User> Users { get; set; } = new List<User>();
}
