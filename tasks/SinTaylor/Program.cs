using System;
using System.Diagnostics;

var ts = new TraceSource("SinTaylor", SourceLevels.All);
ts.Listeners.Add(new ConsoleTraceListener());

Console.Write("Введи x (радианы): ");
if (!double.TryParse(Console.ReadLine(), out double x) || double.IsNaN(x))
{
    ts.TraceEvent(TraceEventType.Error, 1, "Аргумент x равен NaN или не распознан.");
    return;
}

Console.Write("Введи точность eps (0 < eps < 1): ");
double eps = double.Parse(Console.ReadLine()!);

Debug.Assert(Math.Abs(x) <= 2 * Math.PI, "х вне разумного диапазона");
Debug.Assert(eps > 0 && eps < 1);

var sw = Stopwatch.StartNew();
double sum = 0.0, term;
int n = 0;

double Factorial(int k)
{
    Debug.Indent();
    double f = 1.0;
    for (int i = 2; i <= k; i++) f *= i;
    Debug.Unindent();
    return f;
}

while (true)
{
    term = Math.Pow(-1, n) * Math.Pow(x, 2 * n + 1) / Factorial(2 * n + 1);
    sum += term;
    Debug.WriteLine($"n={n}, term={term}, sum={sum}");
    ts.TraceEvent(TraceEventType.Verbose, 2, $"n={n}, term={term}");

    if (Math.Abs(term) <= eps) break;
    if (++n > 100)
    {
        ts.TraceEvent(TraceEventType.Warning, 3, "После 100 итераций точность не достигнута");
        break;
    }
}
sw.Stop();

var res = new TaylorResult(x, eps, n + 1, sum);
Console.WriteLine($"\nРезультат: {res.Value:F8}\nИтераций: {res.Iterations}\nMath.Sin(x): {Math.Sin(x):F8}\nРазница: {Math.Abs(res.Value - Math.Sin(x)):E3}\nВремя: {sw.Elapsed.TotalMilliseconds:F4} мс");

[DebuggerDisplay("x={X}, ε={Epsilon}, N={Iterations}")]
record TaylorResult(double X, double Epsilon, int Iterations, double Value);

//*
// 1,570796   0,000001
// 10         0,001
// 35         0,0000001
//*/
