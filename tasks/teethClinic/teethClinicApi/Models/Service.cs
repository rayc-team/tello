using System;
using System.Collections.Generic;

namespace teethClinicApi.Models;

public partial class Service
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public decimal Price { get; set; }

    public virtual ICollection<AppliedService> AppliedServices { get; set; } = new List<AppliedService>();
}
