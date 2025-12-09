//+------------------------------------------------------------------+
//|                                                  slope_calc.mqh  |
//|                        Slope Calculator and Crossover Detection  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| Slope Calculator Class                                           |
//+------------------------------------------------------------------+
class CSlopeCalculator
{
public:
    // Calculate change - equivalent to change() in Pine Script
    static double Change(double current, double previous);
    
    // Check crossover (crossing from below) - equivalent to crossover() in Pine
    // Returns true if current1 > current2 AND previous1 <= previous2
    static bool Crossover(double current1, double previous1, double current2, double previous2);
    
    // Check crossunder (crossing from above) - equivalent to crossunder() in Pine
    // Returns true if current1 < current2 AND previous1 >= previous2
    static bool Crossunder(double current1, double previous1, double current2, double previous2);
};

//+------------------------------------------------------------------+
//| Calculate change - equivalent to change() in Pine Script        |
//| Pine: change(x) = x - x[1]                                      |
//+------------------------------------------------------------------+
double CSlopeCalculator::Change(double current, double previous)
{
    return current - previous;
}

//+------------------------------------------------------------------+
//| Check crossover (crossing from below)                            |
//| Pine: crossover(a, b) = a > b and a[1] <= b[1]                  |
//+------------------------------------------------------------------+
bool CSlopeCalculator::Crossover(double current1, double previous1, double current2, double previous2)
{
    return (current1 > current2) && (previous1 <= previous2);
}

//+------------------------------------------------------------------+
//| Check crossunder (crossing from above)                           |
//| Pine: crossunder(a, b) = a < b and a[1] >= b[1]                  |
//+------------------------------------------------------------------+
bool CSlopeCalculator::Crossunder(double current1, double previous1, double current2, double previous2)
{
    return (current1 < current2) && (previous1 >= previous2);
}

