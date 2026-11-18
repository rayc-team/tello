using System;
using System.Collections.Generic;

namespace teethClinicApi.Models;

public partial class Schedule
{
    public int Id { get; set; }

    public int DoctorId { get; set; }

    public DateOnly WorkDate { get; set; }

    public TimeOnly StartTime { get; set; }

    public TimeOnly EndTime { get; set; }

    public string Cabinet { get; set; } = null!;

    public virtual ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();

    public virtual Doctor Doctor { get; set; } = null!;
}
