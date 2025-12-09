//+------------------------------------------------------------------+
//|                                                  DrawEMA.mqh     |
//|                        EMA Lines Drawing Module for MT5          |
//|                                                                   |
//| Description:                                                     |
//| Provides CDrawEMA class for drawing EMA lines on MT5 charts.   |
//| Supports automatic color determination by value direction,      |
//| object management and cleanup of old elements.                  |
//|                                                                   |
//| Usage:                                                           |
//| 1. Create object: CDrawEMA draw_ema;                              |
//| 2. Initialize: draw_ema.Initialize(...);                         |
//| 3. Draw lines: draw_ema.DrawLineOnBar(...);                      |
//| 4. Clean up: draw_ema.DeleteAllObjects();                        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| EMA Lines Drawing Class                                          |
//+------------------------------------------------------------------+
class CDrawEMA
{
private:
    string      m_symbol;                    // Symbol
    string      m_ema_prefix_1;              // Prefix for first EMA line (e.g., "EMA2_")
    string      m_ema_prefix_2;              // Prefix for second EMA line (e.g., "EMA3_")
    string      m_fill_prefix;               // Prefix for fill between EMA2 and EMA3
    bool        m_enable_fill;               // Enable fill between EMA2 and EMA3
    long        m_chart_id;                  // Chart ID (0 = current chart)
    int         m_ema1_width;                // First EMA line width (in pixels)
    int         m_ema2_width;                // Second EMA line width (in pixels)
    color       m_color_up;                 // Line color when value increases (default: clrLime)
    color       m_color_down;                // Line color when value decreases (default: clrRed)
    color       m_color_neutral;             // Neutral color (default: clrBlue)
    
    // Helper methods
    color       GetColorByChange(double change);      // Determine color by value change
    string      GetObjectName(string prefix, datetime time);  // Generate object name
    
public:
    CDrawEMA();
    
    // Initialize class
    // Parameters:
    //   symbol - symbol (e.g., "EURUSD")
    //   ema_prefix_1 - prefix for first EMA line (e.g., "EMA2_")
    //   ema_prefix_2 - prefix for second EMA line (e.g., "EMA3_")
    //   ema1_width - first line width (default: 2)
    //   ema2_width - second line width (default: 4)
    //   color_up - color when increasing (default: clrLime)
    //   color_down - color when decreasing (default: clrRed)
    //   color_neutral - neutral color (default: clrBlue)
    // Returns: true on success, false on error
    bool        Initialize(string symbol, 
                          string ema_prefix_1, 
                          string ema_prefix_2,
                          string fill_prefix = "EMA_FILL_",
                          bool enable_fill = true,
                          int ema1_width = 2,
                          int ema2_width = 4,
                          color color_up = clrLime,
                          color color_down = clrRed,
                          color color_neutral = clrBlue);
    
    // Drawing methods
    
    // Draw single EMA line between two points
    // Parameters:
    //   prefix - object name prefix
    //   time_prev - previous point time
    //   value_prev - EMA value at previous point
    //   time_curr - current point time
    //   value_curr - EMA value at current point
    //   change - value change (value_curr - value_prev) for color determination
    //   width - line width
    // Returns: true on success, false on error
    bool        DrawLine(string prefix, 
                        datetime time_prev, double value_prev,
                        datetime time_curr, double value_curr,
                        double change, int width);
    
    // Draw EMA lines on current bar (for two EMAs)
    // Parameters:
    //   ema2_curr, ema2_prev - second EMA values (current and previous)
    //   ema3_curr, ema3_prev - third EMA values (current and previous)
    //   change_ema2, change_ema3 - value changes for color determination
    //   timeframe - working timeframe
    // Returns: true on success, false on error
    bool        DrawLineOnBar(double ema2_curr, double ema2_prev,
                         double ema3_curr, double ema3_prev,
                         double change_ema2, double change_ema3,
                         ENUM_TIMEFRAMES timeframe);
    
    // Draw fill between EMA2 and EMA3 on current closed bar
    bool        DrawFillOnBar(double ema2_curr, double ema2_prev,
                              double ema3_curr, double ema3_prev,
                              ENUM_TIMEFRAMES timeframe);
    
    // Draw all EMA lines on history (for initialization)
    // Parameters:
    //   ema_calc - pointer to CEMACalculator object to get EMA values
    //   ema1_length, ema2_length - EMA lengths (used for validation)
    //   bars_count - number of bars to draw
    //   timeframe - working timeframe
    // Returns: true on success, false on error
    bool        DrawAllLines(CEMACalculator* ema_calc,
                            int ema1_length, int ema2_length,
                            int bars_count,
                            ENUM_TIMEFRAMES timeframe);
    
    // Cleanup methods
    
    // Remove old EMA objects (keeps only last N bars)
    // Parameters:
    //   bars_to_keep - number of bars to keep
    //   timeframe - working timeframe
    void        CleanOldObjects(int bars_to_keep, ENUM_TIMEFRAMES timeframe);
    
    // Delete all EMA objects (by both prefixes)
    void        DeleteAllObjects();
    
    // Delete all objects by specified prefix
    // Parameters:
    //   prefix - prefix to search for objects
    void        DeleteObjectsByPrefix(string prefix);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//| Initializes all variables with default values                   |
//+------------------------------------------------------------------+
CDrawEMA::CDrawEMA()
{
    m_symbol = "";
    m_ema_prefix_1 = "";
    m_ema_prefix_2 = "";
    m_fill_prefix = "EMA_FILL_";
    m_chart_id = 0;
    m_ema1_width = 2;
    m_ema2_width = 4;
    m_color_up = clrLime;
    m_color_down = clrRed;
    m_color_neutral = clrBlue;
}

//+------------------------------------------------------------------+
//| Initialize class                                                 |
//| Sets working parameters and gets chart ID                        |
//+------------------------------------------------------------------+
bool CDrawEMA::Initialize(string symbol,
                         string ema_prefix_1,
                         string ema_prefix_2,
                         string fill_prefix /*= "EMA_FILL_"*/,
                         bool enable_fill /*= true*/,
                         int ema1_width /*= 2*/,
                         int ema2_width /*= 4*/,
                         color color_up /*= clrLime*/,
                         color color_down /*= clrRed*/,
                         color color_neutral /*= clrBlue*/)
{
    // Validate input parameters
    if(symbol == "" || ema_prefix_1 == "" || ema_prefix_2 == "")
    {
        Print("CDrawEMA::Initialize: Error! Empty initialization parameters.");
        return false;
    }
    
    m_symbol = symbol;
    m_ema_prefix_1 = ema_prefix_1;
    m_ema_prefix_2 = ema_prefix_2;
    m_fill_prefix = fill_prefix;
    m_enable_fill = enable_fill;
    m_chart_id = ChartID();
    m_ema1_width = ema1_width;
    m_ema2_width = ema2_width;
    m_color_up = color_up;
    m_color_down = color_down;
    m_color_neutral = color_neutral;
    
    if(m_chart_id <= 0)
    {
        Print("CDrawEMA::Initialize: Error! Failed to get chart ID.");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Determine color by value change                                  |
//| Positive change -> growth color, negative -> decline color      |
//+------------------------------------------------------------------+
color CDrawEMA::GetColorByChange(double change)
{
    if(change > 0)
        return m_color_up;
    else if(change < 0)
        return m_color_down;
    else
        return m_color_neutral;
}

//+------------------------------------------------------------------+
//| Get object name                                                  |
//| Generates unique object name based on prefix and time           |
//+------------------------------------------------------------------+
string CDrawEMA::GetObjectName(string prefix, datetime time)
{
    return prefix + TimeToString(time, TIME_DATE|TIME_MINUTES);
}

//+------------------------------------------------------------------+
//| Draw single EMA line                                             |
//| Creates or updates OBJ_TREND object to display line              |
//+------------------------------------------------------------------+
bool CDrawEMA::DrawLine(string prefix,
                       datetime time_prev, double value_prev,
                       datetime time_curr, double value_curr,
                       double change, int width)
{
    if(m_chart_id <= 0)
        return false;
    
    if(value_prev <= 0 || value_curr <= 0)
        return false;
    
    string obj_name = GetObjectName(prefix, time_curr);
    color line_color = GetColorByChange(change);
    
    if(ObjectFind(m_chart_id, obj_name) < 0)
    {
        if(ObjectCreate(m_chart_id, obj_name, OBJ_TREND, 0, time_prev, value_prev, time_curr, value_curr))
        {
            ObjectSetInteger(m_chart_id, obj_name, OBJPROP_COLOR, line_color);
            ObjectSetInteger(m_chart_id, obj_name, OBJPROP_WIDTH, width);
            ObjectSetInteger(m_chart_id, obj_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(m_chart_id, obj_name, OBJPROP_RAY_RIGHT, false);
            ObjectSetInteger(m_chart_id, obj_name, OBJPROP_RAY_LEFT, false);
            ObjectSetInteger(m_chart_id, obj_name, OBJPROP_BACK, false);
            ObjectSetInteger(m_chart_id, obj_name, OBJPROP_SELECTABLE, false);
            return true;
        }
        else
        {
            return false;
        }
    }
    else
    {
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_TIME, 0, time_prev);
        ObjectSetDouble(m_chart_id, obj_name, OBJPROP_PRICE, 0, value_prev);
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_TIME, 1, time_curr);
        ObjectSetDouble(m_chart_id, obj_name, OBJPROP_PRICE, 1, value_curr);
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_COLOR, line_color);
        return true;
    }
}

//+------------------------------------------------------------------+
//| Draw EMA lines on current bar                                   |
//| Draws two lines (EMA2 and EMA3) for last closed bar             |
//+------------------------------------------------------------------+
bool CDrawEMA::DrawLineOnBar(double ema2_curr, double ema2_prev,
                             double ema3_curr, double ema3_prev,
                             double change_ema2, double change_ema3,
                             ENUM_TIMEFRAMES timeframe)
{
    if(m_chart_id <= 0)
        return false;
    
    datetime time0 = iTime(m_symbol, timeframe, 0);
    datetime time1 = iTime(m_symbol, timeframe, 1);
    
    if(time0 == 0 || time1 == 0)
        return false;
    
    if(!DrawLine(m_ema_prefix_1, time1, ema2_prev, time0, ema2_curr, change_ema2, m_ema1_width))
        return false;
    
    if(!DrawLine(m_ema_prefix_2, time1, ema3_prev, time0, ema3_curr, change_ema3, m_ema2_width))
        return false;
    
    if(m_enable_fill)
        DrawFillOnBar(ema2_curr, ema2_prev, ema3_curr, ema3_prev, timeframe);
    
    CleanOldObjects(500, timeframe);
    
    ChartRedraw(m_chart_id);
    
    return true;
}

//+------------------------------------------------------------------+
//| Draw fill between EMA2 and EMA3                                 |
//| Creates/updates rectangle on closed bar                         |
//+------------------------------------------------------------------+
bool CDrawEMA::DrawFillOnBar(double ema2_curr, double ema2_prev,
                             double ema3_curr, double ema3_prev,
                             ENUM_TIMEFRAMES timeframe)
{
    if(m_chart_id <= 0)
        return false;
    
    datetime time0 = iTime(m_symbol, timeframe, 0);
    datetime time1 = iTime(m_symbol, timeframe, 1);
    
    if(time0 == 0 || time1 == 0)
        return false;
    
    double top_curr = MathMax(ema2_curr, ema3_curr);
    double bottom_curr = MathMin(ema2_curr, ema3_curr);
    double top_prev = MathMax(ema2_prev, ema3_prev);
    double bottom_prev = MathMin(ema2_prev, ema3_prev);
    
    // Pine equivalent: color=silver, transp=50 -> semi-transparent silver (ARGB:127,192,192,192)
    color fill_color = (color)0x7FC0C0C0;
    
    string obj_name = m_fill_prefix + TimeToString(time0, TIME_DATE|TIME_MINUTES);
    
    if(ObjectFind(m_chart_id, obj_name) < 0)
    {
        if(!ObjectCreate(m_chart_id, obj_name, OBJ_RECTANGLE, 0, time1, top_prev, time0, bottom_curr))
        {
            return false;
        }
        
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_COLOR, fill_color);
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_BACK, true);
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_FILL, true);
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_BGCOLOR, fill_color);
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_SELECTABLE, false);
    }
    else
    {
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_TIME, 0, time1);
        ObjectSetDouble(m_chart_id, obj_name, OBJPROP_PRICE, 0, top_prev);
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_TIME, 1, time0);
        ObjectSetDouble(m_chart_id, obj_name, OBJPROP_PRICE, 1, bottom_curr);
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_COLOR, fill_color);
        ObjectSetInteger(m_chart_id, obj_name, OBJPROP_BGCOLOR, fill_color);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Draw all EMA lines on history                                   |
//| Used during initialization to draw all lines at once           |
//+------------------------------------------------------------------+
bool CDrawEMA::DrawAllLines(CEMACalculator* ema_calc,
                            int ema1_length, int ema2_length,
                            int bars_count,
                            ENUM_TIMEFRAMES timeframe)
{
    if(m_chart_id <= 0 || ema_calc == NULL)
        return false;
    
    if(bars_count < 2)
        return false;
    
    int drawn_count = 0;
    
    // Draw from oldest to current (need previous bar for each line)
    for(int i = bars_count - 1; i >= 1; i--)
    {
        double ema2_curr = ema_calc.GetEMA2(i);
        double ema2_prev = ema_calc.GetEMA2(i + 1);
        double ema3_curr = ema_calc.GetEMA3(i);
        double ema3_prev = ema_calc.GetEMA3(i + 1);
        
        if(ema2_curr <= 0 || ema2_prev <= 0 || ema3_curr <= 0 || ema3_prev <= 0)
            continue;
        
        double change_ema2 = ema2_curr - ema2_prev;
        double change_ema3 = ema3_curr - ema3_prev;
        
        datetime time_curr = iTime(m_symbol, timeframe, i);
        datetime time_prev = iTime(m_symbol, timeframe, i + 1);
        
        if(time_curr == 0 || time_prev == 0)
            continue;
        
        if(DrawLine(m_ema_prefix_1, time_prev, ema2_prev, time_curr, ema2_curr, change_ema2, m_ema1_width))
            drawn_count++;
        if(DrawLine(m_ema_prefix_2, time_prev, ema3_prev, time_curr, ema3_curr, change_ema3, m_ema2_width))
            drawn_count++;
    }
    
    ChartRedraw(m_chart_id);
    
    return true;
}

//+------------------------------------------------------------------+
//| Remove old EMA objects                                           |
//| Removes objects older than specified number of bars              |
//+------------------------------------------------------------------+
void CDrawEMA::CleanOldObjects(int bars_to_keep, ENUM_TIMEFRAMES timeframe)
{
    if(m_chart_id <= 0)
        return;
    
    datetime oldest_time = iTime(m_symbol, timeframe, bars_to_keep);
    
    if(oldest_time == 0)
        return;
    
    int total = ObjectsTotal(m_chart_id);
    
    // Iterate in reverse order for safe deletion
    for(int i = total - 1; i >= 0; i--)
    {
        string name = ObjectName(m_chart_id, i);
        
        if(StringFind(name, m_ema_prefix_1) == 0 || StringFind(name, m_ema_prefix_2) == 0 || StringFind(name, m_fill_prefix) == 0)
        {
            datetime obj_time = (datetime)ObjectGetInteger(m_chart_id, name, OBJPROP_TIME, 0);
            
            if(obj_time < oldest_time)
            {
                ObjectDelete(m_chart_id, name);
            }
        }
    }
    
    ChartRedraw(m_chart_id);
}

//+------------------------------------------------------------------+
//| Delete all objects by prefix                                     |
//| Universal method to delete objects with specified prefix         |
//+------------------------------------------------------------------+
void CDrawEMA::DeleteObjectsByPrefix(string prefix)
{
    if(m_chart_id <= 0 || prefix == "")
        return;
    
    int total = ObjectsTotal(m_chart_id);
    
    for(int i = total - 1; i >= 0; i--)
    {
        string name = ObjectName(m_chart_id, i);
        
        if(StringFind(name, prefix) == 0)
        {
            ObjectDelete(m_chart_id, name);
        }
    }
    
    ChartRedraw(m_chart_id);
}

//+------------------------------------------------------------------+
//| Delete all EMA objects                                           |
//| Removes all objects created by this module                      |
//+------------------------------------------------------------------+
void CDrawEMA::DeleteAllObjects()
{
    if(m_chart_id <= 0)
        return;
    
    DeleteObjectsByPrefix(m_ema_prefix_1);
    DeleteObjectsByPrefix(m_ema_prefix_2);
    DeleteObjectsByPrefix(m_fill_prefix);
    
    ChartRedraw(m_chart_id);
}
