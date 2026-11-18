using System;
using System.Collections.Generic;

namespace teethClinicApi.Models;

public partial class Appointment
{
    public int Id { get; set; }

    public int ScheduleId { get; set; }

    public int PatientId { get; set; }

    public TimeOnly AppointmentTime { get; set; }

    public string? Status { get; set; }

    public string? Result { get; set; }

    public virtual ICollection<AppliedService> AppliedServices { get; set; } = new List<AppliedService>();

    public virtual Patient Patient { get; set; } = null!;

    public virtual Schedule Schedule { get; set; } = null!;
}
