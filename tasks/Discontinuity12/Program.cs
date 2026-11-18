using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;

using var logFile = new StreamWriter("analyzer.log", append: true);
var ts = new TraceSource("DiscontinuityAnalyzer", SourceLevels.All);
ts.Listeners.Add(new TextWriterTraceListener(logFile));
Trace.AutoFlush = true;

IDiscontinuousFunction[] funcs = [new HyperbolaFunction(), new RemovableFunction(), new SignumFunction(), new SqrtBoundaryFunction()];
var sessionSw = Stopwatch.StartNew();

while (true)
{
    Debug.Indent();
    Console.Write("\n1. 1/x\n2. (x^2-1)/(x-1)\n3. sign(x)\n4. sqrt(x^2-1)\n5. Отчёт [-3, 3]\n0. Выход\nВыбор: ");
    string? choice = Console.ReadLine();
    Debug.Unindent();

    if (choice == "0") break;
    if (choice == "5")
    {
        var rep = new FunctionReport();
        foreach (var f in funcs)
        {
            var fSw = Stopwatch.StartNew();
            for (double x = -3; x <= 3.001; x += 0.5)
                if (f.GetDiscontinuityAt(x) is { } dt) rep.Items.Add(new(f.Name, Math.Round(x, 2), dt));
            fSw.Stop();
            Console.WriteLine($"{f.Name} проверена за {fSw.Elapsed.TotalMilliseconds:F3} мс");
        }
        foreach (var i in rep.Items) Console.WriteLine($"{i.FunctionName,-18} | {i.Point,5} | {i.Type}");
        continue;
    }

    if (int.TryParse(choice, out int idx) && idx is >= 1 and <= 4)
    {
        var f = funcs[idx - 1];
        ts.TraceEvent(TraceEventType.Information, 10, $"Вызов {f.Name}");
        Console.Write("Введи x: ");
        if (!double.TryParse(Console.ReadLine(), out double x))
        {
            ts.TraceEvent(TraceEventType.Error, 40, "Некорректный ввод x");
            continue;
        }

        var dt = f.GetDiscontinuityAt(x);
            if (dt.HasValue)
                ts.TraceEvent(TraceEventType.Warning, 20, $"Разрыв {dt.Value} в x={x} для {f.Name}");

            var sw = Stopwatch.StartNew();
            var val = f.Evaluate(x);
            sw.Stop();

            Console.WriteLine(val.HasValue ? $"f({x}) = {val.Value:F4} ({sw.Elapsed.TotalMilliseconds:F4} мс)" : $"Разрыв: {dt}");
#if DEBUG
            Console.WriteLine($"[DEBUG пределы] f({x - 1e-4:F4}) = {f.Evaluate(x - 1e-4)?.ToString("F4") ?? "нет"}; f({x + 1e-4:F4}) = {f.Evaluate(x + 1e-4)?.ToString("F4") ?? "нет"}");
#endif
    }
}

sessionSw.Stop();
Console.WriteLine($"Сеанс завершён за {sessionSw.Elapsed.TotalMilliseconds:F2} мс");

public enum DiscontinuityType { Pole, Removable, Jump, Boundary }

public interface IDiscontinuousFunction
{
    string Name { get; }
    DiscontinuityType DiscontinuityType { get; }
    double DiscontinuityPoint { get; }
    double? Evaluate(double x);
    DiscontinuityType? GetDiscontinuityAt(double x);
}

[DebuggerDisplay("{Name}: разрыв={DiscontinuityType} @ {DiscontinuityPoint}")]
class HyperbolaFunction : IDiscontinuousFunction
{
    public string Name => "1/x";
    public DiscontinuityType DiscontinuityType => DiscontinuityType.Pole;
    public double DiscontinuityPoint => 0.0;
    public double? Evaluate(double x)
    {
        if (Math.Abs(x) < 1e-9) { if (Debugger.IsAttached) Debugger.Break(); Debug.Assert(x != 0, "Деление на ноль в 1/x"); return null; }
        return 1.0 / x;
    }
    public DiscontinuityType? GetDiscontinuityAt(double x) => Math.Abs(x) < 1e-9 ? DiscontinuityType.Pole : null;
}

[DebuggerDisplay("{Name}: разрыв={DiscontinuityType} @ {DiscontinuityPoint}")]
class RemovableFunction : IDiscontinuousFunction
{
    public string Name => "(x^2 - 1)/(x - 1)";
    public DiscontinuityType DiscontinuityType => DiscontinuityType.Removable;
    public double DiscontinuityPoint => 1.0;
    public double? Evaluate(double x)
    {
        if (Math.Abs(x - 1.0) < 1e-9) { if (Debugger.IsAttached) Debugger.Break(); Debug.Assert(Math.Abs(x - 1.0) >= 1e-9, "Устранимый разрыв при x=1"); return null; }
        return (x * x - 1.0) / (x - 1.0);
    }
    public DiscontinuityType? GetDiscontinuityAt(double x) => Math.Abs(x - 1.0) < 1e-9 ? DiscontinuityType.Removable : null;
}

[DebuggerDisplay("{Name}: разрыв={DiscontinuityType} @ {DiscontinuityPoint}")]
class SignumFunction : IDiscontinuousFunction
{
    public string Name => "sign(x)";
    public DiscontinuityType DiscontinuityType => DiscontinuityType.Jump;
    public double DiscontinuityPoint => 0.0;
    public double? Evaluate(double x)
    {
        Debug.Assert(!double.IsNaN(x), "Аргумент NaN");
        if (Math.Abs(x) < 1e-9) { if (Debugger.IsAttached) Debugger.Break(); return 0.0; }
        return Math.Sign(x);
    }
    public DiscontinuityType? GetDiscontinuityAt(double x) => Math.Abs(x) < 1e-9 ? DiscontinuityType.Jump : null;
}

[DebuggerDisplay("{Name}: разрыв={DiscontinuityType} @ {DiscontinuityPoint}")]
class SqrtBoundaryFunction : IDiscontinuousFunction
{
    public string Name => "sqrt(x^2 - 1)";
    public DiscontinuityType DiscontinuityType => DiscontinuityType.Boundary;
    public double DiscontinuityPoint => 1.0;
    public double? Evaluate(double x)
    {
        if (Math.Abs(x) < 1.0) { if (Debugger.IsAttached) Debugger.Break(); Debug.Assert(Math.Abs(x) >= 1.0, "Вне области определения"); return null; }
        return Math.Sqrt(x * x - 1.0);
    }
    public DiscontinuityType? GetDiscontinuityAt(double x) => (Math.Abs(x) < 1.0 || Math.Abs(Math.Abs(x) - 1.0) < 1e-9) ? DiscontinuityType.Boundary : null;
}

record DiscontinuityItem(string FunctionName, double Point, DiscontinuityType Type);

[DebuggerTypeProxy(typeof(FunctionReportDebugView))]
record FunctionReport(List<DiscontinuityItem> Items)
{
    public FunctionReport() : this(new List<DiscontinuityItem>()) { }
}

class FunctionReportDebugView(FunctionReport rep)
{
    public Dictionary<DiscontinuityType, List<DiscontinuityItem>> GroupedByType =>
        rep.Items.GroupBy(i => i.Type).ToDictionary(g => g.Key, g => g.ToList());
}

//*
// 2        0
// 3        1
// -5       0
// 2        0       1 / -1
//*/
