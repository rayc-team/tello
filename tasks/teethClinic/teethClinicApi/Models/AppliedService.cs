using System;
using System.Collections.Generic;

namespace teethClinicApi.Models;

public partial class AppliedService
{
    public int Id { get; set; }

    public int AppointmentId { get; set; }

    public int ServiceId { get; set; }

    public int Quantity { get; set; }

    public virtual Appointment Appointment { get; set; } = null!;

    public virtual Service Service { get; set; } = null!;
}
