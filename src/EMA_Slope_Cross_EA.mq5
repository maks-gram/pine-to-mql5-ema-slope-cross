//+------------------------------------------------------------------+
//|                                    EMA_Slope_Cross_EA.mq5        |
//|           Port of "EMA Slope + EMA Cross Strategy" (ChartArt)     |
//|           Compact MT5 EA with visuals and optional alerts         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.00"

// Modules
#include "modules/ema_calc.mqh"
#include "modules/slope_calc.mqh"
#include "modules/trade_executor.mqh"
#include "modules/DrawEMA.mqh"
#include "modules/DrawBar.mqh"
#include "modules/alerts.mqh"

//--- Inputs (aligned with the original Pine strategy)
input group "=== EMA Settings ==="
input int      MA1_Length = 2;          // Fast EMA length
input int      MA2_Length = 4;          // Mid EMA length
input int      MA3_Length = 20;         // Slow EMA length

input group "=== Trading ==="
input ENUM_TIMEFRAMES  Timeframe = 0;  // 0 = chart TF, 16385 = H1, 16408 = D1
input ulong    MagicNumber = 123456;   // Magic number
input double   LotSize = 0.1;         // Lot size

input group "=== Visualization ==="
input bool     ShowBarColor = true;    // Color bars by EMA slopes
input bool     ShowMovingAverages = true; // Plot EMAs
input bool     ShowFillArea = true;    // Fill area between EMA2 and EMA3
input group "=== Alerts ==="
input bool     SendAlerts = false;     // Send alerts on open/close

//--- State
CEMACalculator    g_ema_calc;           
CTradeExecutor    g_trade_executor;     
CSlopeCalculator  g_slope_calc;         
CDrawEMA          g_draw_ema;           
CDrawBar          g_draw_bar;           
CAlerts           g_alerts;             

datetime g_last_bar_time = 0;           
ENUM_TIMEFRAMES g_current_timeframe = 0; 
int g_pending_direction = 0;            // 1 = pending long, -1 = pending short

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Resolve working timeframe
    ENUM_TIMEFRAMES work_timeframe = Timeframe;
    if(work_timeframe == 0)
    {
        work_timeframe = _Period;
    }
    
    g_current_timeframe = work_timeframe;
    
    if(!g_ema_calc.Initialize(Symbol(), work_timeframe, MA1_Length, MA2_Length, MA3_Length))
    {
        Print("EMA calculator init failed");
        return INIT_FAILED;
    }
    
    // Initialize trade executor
    g_trade_executor.Initialize(MagicNumber, Symbol(), LotSize);
    
    // Initialize drawing modules
    if(!g_draw_ema.Initialize(Symbol(), "EMA2_", "EMA3_", "EMA_FILL_", ShowFillArea, 2, 4))
    {
        Print("EMA drawing init failed");
        return INIT_FAILED;
    }
    
    if(!g_draw_bar.Initialize(Symbol(), "BarColor_"))
    {
        Print("Bar drawing init failed");
        return INIT_FAILED;
    }

    // Initialize alerts
    g_alerts.Initialize(SendAlerts);
    
    Print("EMA Slope Cross EA initialized. TF: ", EnumToString(work_timeframe),
          ", EMA lengths: ", MA1_Length, "/", MA2_Length, "/", MA3_Length);
    
    // Initial drawing on history
    if(ShowMovingAverages)
    {
        int bars_to_draw = MathMax(MA3_Length + 50, 100);
        int total_bars = iBars(Symbol(), work_timeframe);
        int bars_count = MathMin(bars_to_draw, total_bars - 1);
        g_draw_ema.DrawAllLines(&g_ema_calc, MA2_Length, MA3_Length, bars_count, work_timeframe);
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up graphical objects
    g_draw_ema.DeleteAllObjects();
    g_draw_bar.DeleteAllObjects();
    
    // Release resources
    g_ema_calc.Release();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Resolve working timeframe
    ENUM_TIMEFRAMES work_timeframe = Timeframe;
    if(work_timeframe == 0)
    {
        work_timeframe = _Period;  // Use chart timeframe if 0
    }
    
    // Check if timeframe changed in settings
    if(work_timeframe != g_current_timeframe)
    {
        // Close all open positions
        if(g_trade_executor.HasPosition())
        {
            if(g_trade_executor.CloseAllPositions())
                g_alerts.Send("EMA Slope + EMA Cross: Closed positions (timeframe change)");
            Sleep(500);
        }
        
        // Release old timeframe resources
        g_ema_calc.Release();
        
        // Delete all graphical objects
        g_draw_ema.DeleteAllObjects();
        g_draw_bar.DeleteAllObjects();
        
        // Reset state
        g_last_bar_time = 0;
        
        // Reinitialize with new timeframe
        g_current_timeframe = work_timeframe;
        
        if(!g_ema_calc.Initialize(Symbol(), work_timeframe, MA1_Length, MA2_Length, MA3_Length))
        {
            Print("Failed to reinitialize EMA calculator with new timeframe");
            return;
        }
        
        // Redraw all EMA lines on new timeframe
        if(ShowMovingAverages)
        {
            int bars_to_draw = MathMax(MA3_Length + 50, 100);
            int total_bars = iBars(Symbol(), work_timeframe);
            int bars_count = MathMin(bars_to_draw, total_bars - 1);
            g_draw_ema.DrawAllLines(&g_ema_calc, MA2_Length, MA3_Length, bars_count, work_timeframe);
        }
    }
    
    // Check for new bar (process only on bar close, like Pine Script)
    datetime current_bar_time = iTime(Symbol(), work_timeframe, 0);
    
    bool is_new_bar = (current_bar_time != g_last_bar_time);
    bool has_pending = (g_pending_direction != 0);
    
    // Exit if no new bar and no pending orders
    if(!is_new_bar && !has_pending)
        return;
    
    // Retry pending entry if market was closed
    if(has_pending && !is_new_bar)
    {
        if(g_pending_direction == 1)
        {
            if(g_trade_executor.OpenLong("Long (retry)"))
            {
                g_pending_direction = 0;
            }
            else if(g_trade_executor.GetLastRetcode() != 10018)
            {
                g_pending_direction = 0;
            }
        }
        else if(g_pending_direction == -1)
        {
            if(g_trade_executor.OpenShort("Short (retry)"))
            {
                g_pending_direction = 0;
            }
            else if(g_trade_executor.GetLastRetcode() != 10018)
            {
                g_pending_direction = 0;
            }
        }
        
        return;
    }
    
    g_last_bar_time = current_bar_time;
    
    // Use closed bars: shift=1 = last closed, shift=2 = previous
    double price_curr = iClose(Symbol(), work_timeframe, 1);
    double price_prev = iClose(Symbol(), work_timeframe, 2);
    
    // Validate price data
    if(price_curr <= 0 || price_prev <= 0)
        return;
    
    // Get EMA values (shift=1 for current closed bar, shift=2 for previous)
    double ema1_curr = g_ema_calc.GetEMA1(1);
    double ema1_prev = g_ema_calc.GetEMA1(2);
    double ema2_curr = g_ema_calc.GetEMA2(1);
    double ema2_prev = g_ema_calc.GetEMA2(2);
    double ema3_curr = g_ema_calc.GetEMA3(1);
    double ema3_prev = g_ema_calc.GetEMA3(2);
   
    // Validate EMA data
    if(ema1_curr <= 0 || ema1_prev <= 0 || ema2_curr <= 0 || ema2_prev <= 0 || ema3_curr <= 0 || ema3_prev <= 0)
        return;
    
    // Calculate changes for all EMAs
    double change_price = g_slope_calc.Change(price_curr, price_prev);
    double change_ema1 = g_slope_calc.Change(ema1_curr, ema1_prev);
    double change_ema2 = g_slope_calc.Change(ema2_curr, ema2_prev);
    double change_ema3 = g_slope_calc.Change(ema3_curr, ema3_prev);
    
    // Get values for previous bar for visualization
    double ema2_prev_prev = g_ema_calc.GetEMA2(3);
    double ema3_prev_prev = g_ema_calc.GetEMA3(3);
    double change_ema2_prev = g_slope_calc.Change(ema2_prev, ema2_prev_prev);
    double change_ema3_prev = g_slope_calc.Change(ema3_prev, ema3_prev_prev);
    
    // Check LONG conditions
    // Pine: long = crossunder(price, MA3) or (change(price)<0 and change(MA1)<0 and crossunder(price,MA1) and change(MA2)>0)
    bool condition_a = g_slope_calc.Crossunder(price_curr, price_prev, ema3_curr, ema3_prev);
    bool condition_b = (change_price < 0) && 
                       (change_ema1 < 0) && 
                       g_slope_calc.Crossunder(price_curr, price_prev, ema1_curr, ema1_prev) && 
                       (change_ema2 > 0);
    bool long_condition = condition_a || condition_b;
    
    // Check SHORT conditions
    // Pine: short = crossover(price, MA3) or (change(price)>0 and change(MA1)>0 and crossover(price,MA1) and change(MA2)<0)
    bool condition_a_short = g_slope_calc.Crossover(price_curr, price_prev, ema3_curr, ema3_prev);
    bool condition_b_short = (change_price > 0) && 
                             (change_ema1 > 0) && 
                             g_slope_calc.Crossover(price_curr, price_prev, ema1_curr, ema1_prev) && 
                             (change_ema2 < 0);
    bool short_condition = condition_a_short || condition_b_short;
    
    // Execute trades (position opens only when LONG or SHORT condition is met)
    if(long_condition)
    {
        int prev_pos = g_trade_executor.GetPositionType();
        if(g_trade_executor.OpenLong("Long"))
        {
            if(prev_pos == -1)
                g_alerts.Send("EMA Slope + EMA Cross: Closed SHORT");
            g_alerts.Send("EMA Slope + EMA Cross: Opened LONG");
        }
        else if(g_trade_executor.GetLastRetcode() == 10018)
        {
            g_pending_direction = 1;
        }
    }
    
    if(short_condition)
    {
        int prev_pos_short = g_trade_executor.GetPositionType();
        if(g_trade_executor.OpenShort("Short"))
        {
            if(prev_pos_short == 1)
                g_alerts.Send("EMA Slope + EMA Cross: Closed LONG");
            g_alerts.Send("EMA Slope + EMA Cross: Opened SHORT");
        }
        else if(g_trade_executor.GetLastRetcode() == 10018)
        {
            g_pending_direction = -1;
        }
    }
    
    // Draw EMA lines on chart
    if(ShowMovingAverages && ema2_curr > 0 && ema3_curr > 0)
    {
        g_draw_ema.DrawLineOnBar(ema2_curr, ema2_prev, ema3_curr, ema3_prev, change_ema2, change_ema3, work_timeframe);
    }
    
    // Color bars
    if(ShowBarColor)
    {
        g_draw_bar.ColorBarByIndex(1, change_ema2, change_ema3, work_timeframe);
    }
}
