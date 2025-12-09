//+------------------------------------------------------------------+
//|                                                  DrawBar.mqh     |
//|                        Bar Coloring Module for MT5               |
//|                                                                   |
//| Description:                                                     |
//| Provides CDrawBar class for coloring bars on MT5 charts.       |
//| Supports automatic color determination by EMA changes,         |
//| object management and cleanup of old elements.                  |
//|                                                                   |
//| Usage:                                                           |
//| 1. Create object: CDrawBar draw_bar;                             |
//| 2. Initialize: draw_bar.Initialize(...);                         |
//| 3. Color bars: draw_bar.ColorBar(...);                           |
//| 4. Clean up: draw_bar.DeleteAllObjects();                         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.00"

// Semi-transparent default colors for bar coloring
// Base bar colors (light and semi-transparent): up=light green, down=light red, neutral=blue
// In MQL color is stored in 0xAABBGGRR format, so we use predefined values
#define BAR_COLOR_UP_DEF      ((color)0x8090EE90)   // light green
#define BAR_COLOR_DOWN_DEF    ((color)0x800000FF)   // light red
#define BAR_COLOR_NEUTRAL_DEF ((color)0x80FFA0A0)   // blue

//+------------------------------------------------------------------+
//| Bar Coloring Class                                               |
//+------------------------------------------------------------------+
class CDrawBar
{
private:
    string      m_symbol;                    // Symbol
    string      m_bar_prefix;                // Prefix for bar objects (e.g., "BarColor_")
    long        m_chart_id;                  // Chart ID (0 = current chart)
    color       m_color_up;                 // Color when EMA increases (default: muted green)
    color       m_color_down;                // Color when EMA decreases (default: muted red)
    color       m_color_neutral;             // Neutral color (default: muted blue)
    
    // Helper methods
    color       GetBarColor(double change_ema2, double change_ema3);  // Determine color by EMA changes
    string      GetObjectName(datetime time);  // Generate object name
    
public:
    CDrawBar();
    
    // Initialize class
    // Parameters:
    //   symbol - symbol (e.g., "EURUSD")
    //   bar_prefix - prefix for bar objects (default: "BarColor_")
    //   color_up - color when EMA increases (default: clrGreen)
    //   color_down - color when EMA decreases (default: clrRed)
    //   color_neutral - neutral color (default: clrBlue)
    // Returns: true on success, false on error
    bool        Initialize(string symbol,
                         string bar_prefix = "BarColor_",
                         color color_up = BAR_COLOR_UP_DEF,
                         color color_down = BAR_COLOR_DOWN_DEF,
                         color color_neutral = BAR_COLOR_NEUTRAL_DEF);
    
    // Drawing methods
    
    // Color current bar (bar with index 0)
    // Parameters:
    //   change_ema2, change_ema3 - EMA changes for color determination
    //   timeframe - working timeframe
    // Returns: true on success, false on error
    bool        ColorBar(double change_ema2, double change_ema3, ENUM_TIMEFRAMES timeframe);
    
    // Color bar by index
    // Parameters:
    //   bar_index - bar index (0 = current, 1 = previous, etc.)
    //   change_ema2, change_ema3 - EMA changes for color determination
    //   timeframe - working timeframe
    // Returns: true on success, false on error
    bool        ColorBarByIndex(int bar_index, double change_ema2, double change_ema3, ENUM_TIMEFRAMES timeframe);
    
    // Color bar with custom parameters
    // Parameters:
    //   time_prev, time_curr - bar start and end time
    //   high_price, low_price - bar maximum and minimum price
    //   bar_color - color for coloring
    // Returns: true on success, false on error
    bool        ColorBarCustom(datetime time_prev, datetime time_curr,
                              double high_price, double low_price,
                              color bar_color);
    
    // Cleanup methods
    
    // Remove old bar objects (keeps only last N bars)
    // Parameters:
    //   bars_to_keep - number of bars to keep
    //   timeframe - working timeframe
    void        CleanOldObjects(int bars_to_keep, ENUM_TIMEFRAMES timeframe);
    
    // Delete all bar objects (by prefix)
    void        DeleteAllObjects();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//| Initializes all variables with default values                   |
//+------------------------------------------------------------------+
CDrawBar::CDrawBar()
{
    m_symbol = "";
    m_bar_prefix = "BarColor_";
    m_chart_id = 0;
    m_color_up = BAR_COLOR_UP_DEF;
    m_color_down = BAR_COLOR_DOWN_DEF;
    m_color_neutral = BAR_COLOR_NEUTRAL_DEF;
}

//+------------------------------------------------------------------+
//| Initialize class                                                 |
//| Sets working parameters and gets chart ID                        |
//+------------------------------------------------------------------+
bool CDrawBar::Initialize(string symbol,
                         string bar_prefix,
                         color color_up,
                         color color_down,
                         color color_neutral)
{
    // Validate input parameters
    if(symbol == "")
    {
        Print("CDrawBar::Initialize: Error! Empty symbol.");
        return false;
    }
    
    m_symbol = symbol;
    m_bar_prefix = bar_prefix;
    m_chart_id = ChartID();
    m_color_up = color_up;
    m_color_down = color_down;
    m_color_neutral = color_neutral;
    
    if(m_chart_id <= 0)
    {
        Print("CDrawBar::Initialize: Error! Failed to get chart ID.");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Determine bar color by EMA changes                              |
//| Logic:                                                           |
//|   - If both EMAs increase (change > 0) -> green color            |
//|   - If both EMAs decrease (change < 0) -> red color             |
//|   - Otherwise -> blue color (neutral)                           |
//+------------------------------------------------------------------+
color CDrawBar::GetBarColor(double change_ema2, double change_ema3)
{
    bool up = (change_ema2 > 0) && (change_ema3 > 0);
    bool dn = (change_ema2 < 0) && (change_ema3 < 0);
    
    if(up)
        return m_color_up;
    else if(dn)
        return m_color_down;
    else
        return m_color_neutral;
}

//+------------------------------------------------------------------+
//| Get object name                                                  |
//| Generates unique object name based on prefix and time            |
//+------------------------------------------------------------------+
string CDrawBar::GetObjectName(datetime time)
{
    return m_bar_prefix + TimeToString(time, TIME_DATE|TIME_MINUTES);
}

//+------------------------------------------------------------------+
//| Color current bar                                                |
//| Wrapper over ColorBarByIndex for convenience                    |
//+------------------------------------------------------------------+
bool CDrawBar::ColorBar(double change_ema2, double change_ema3, ENUM_TIMEFRAMES timeframe)
{
    return ColorBarByIndex(0, change_ema2, change_ema3, timeframe);
}

//+------------------------------------------------------------------+
//| Color bar by index                                               |
//| Gets bar data and calls ColorBarCustom                           |
//+------------------------------------------------------------------+
bool CDrawBar::ColorBarByIndex(int bar_index, double change_ema2, double change_ema3, ENUM_TIMEFRAMES timeframe)
{
    if(m_chart_id <= 0)
        return false;
    
    datetime time_curr = iTime(m_symbol, timeframe, bar_index);
    datetime time_prev = iTime(m_symbol, timeframe, bar_index + 1);
    double high_price = iHigh(m_symbol, timeframe, bar_index);
    double low_price = iLow(m_symbol, timeframe, bar_index);
    
    if(time_curr == 0 || time_prev == 0 || high_price <= 0 || low_price <= 0)
        return false;
    
    color bar_color = GetBarColor(change_ema2, change_ema3);
    
    return ColorBarCustom(time_prev, time_curr, high_price, low_price, bar_color);
}

//+------------------------------------------------------------------+
//| Color bar with custom parameters                                 |
//| Creates or updates OBJ_RECTANGLE object to color bar             |
//+------------------------------------------------------------------+
bool CDrawBar::ColorBarCustom(datetime time_prev, datetime time_curr,
                              double high_price, double low_price,
                              color bar_color)
{
    if(m_chart_id <= 0)
        return false;
    
    if(time_curr == 0 || time_prev == 0 || high_price <= low_price)
        return false;
    
    string bar_name = GetObjectName(time_curr);
    
    if(ObjectFind(m_chart_id, bar_name) < 0)
    {
        if(ObjectCreate(m_chart_id, bar_name, OBJ_RECTANGLE, 0, time_prev, high_price, time_curr, low_price))
        {
            ObjectSetInteger(m_chart_id, bar_name, OBJPROP_COLOR, bar_color);
            ObjectSetInteger(m_chart_id, bar_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(m_chart_id, bar_name, OBJPROP_WIDTH, 1);
            // Draw above EMA fill so bar color doesn't change from background
            ObjectSetInteger(m_chart_id, bar_name, OBJPROP_BACK, false);
            ObjectSetInteger(m_chart_id, bar_name, OBJPROP_FILL, true);
            ObjectSetInteger(m_chart_id, bar_name, OBJPROP_BGCOLOR, bar_color);
            ObjectSetInteger(m_chart_id, bar_name, OBJPROP_SELECTABLE, false);
            return true;
        }
        else
        {
            return false;
        }
    }
    else
    {
        ObjectSetInteger(m_chart_id, bar_name, OBJPROP_COLOR, bar_color);
        ObjectSetInteger(m_chart_id, bar_name, OBJPROP_BGCOLOR, bar_color);
        return true;
    }
}

//+------------------------------------------------------------------+
//| Remove old bar objects                                            |
//| Removes objects older than specified number of bars              |
//+------------------------------------------------------------------+
void CDrawBar::CleanOldObjects(int bars_to_keep, ENUM_TIMEFRAMES timeframe)
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
        
        if(StringFind(name, m_bar_prefix) == 0)
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
//| Delete all bar objects                                            |
//| Removes all objects created by this module                       |
//+------------------------------------------------------------------+
void CDrawBar::DeleteAllObjects()
{
    if(m_chart_id <= 0)
        return;
    
    int total = ObjectsTotal(m_chart_id);
    
    for(int i = total - 1; i >= 0; i--)
    {
        string name = ObjectName(m_chart_id, i);
        
        if(StringFind(name, m_bar_prefix) == 0)
        {
            ObjectDelete(m_chart_id, name);
        }
    }
    
    ChartRedraw(m_chart_id);
}
