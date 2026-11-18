using System;
using System.Collections.Generic;

namespace teethClinicApi.Models;

public partial class Patient
{
    public int Id { get; set; }

    public string FullName { get; set; } = null!;

    public string Phone { get; set; } = null!;

    public virtual ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
}
