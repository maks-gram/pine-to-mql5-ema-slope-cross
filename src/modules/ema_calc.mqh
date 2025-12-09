//+------------------------------------------------------------------+
//|                                                  ema_calc.mqh    |
//|                        Exponential Moving Average Calculator     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| EMA Calculator Class                                             |
//+------------------------------------------------------------------+
class CEMACalculator
{
private:
    int      m_handle_ema1;      // EMA1 indicator handle
    int      m_handle_ema2;      // EMA2 indicator handle
    int      m_handle_ema3;      // EMA3 indicator handle
    string   m_symbol;           // Symbol
    ENUM_TIMEFRAMES m_period;     // Timeframe
    
public:
    CEMACalculator();
    ~CEMACalculator();
    
    // Initialize EMA indicators
    bool Initialize(string symbol, ENUM_TIMEFRAMES period, int ma1_length, int ma2_length, int ma3_length);
    
    // Get EMA values
    double GetEMA1(int shift = 0);
    double GetEMA2(int shift = 0);
    double GetEMA3(int shift = 0);
    
    // Release resources
    void Release();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CEMACalculator::CEMACalculator()
{
    m_handle_ema1 = INVALID_HANDLE;
    m_handle_ema2 = INVALID_HANDLE;
    m_handle_ema3 = INVALID_HANDLE;
    m_symbol = "";
    m_period = PERIOD_CURRENT;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CEMACalculator::~CEMACalculator()
{
    Release();
}

//+------------------------------------------------------------------+
//| Initialize EMA indicators                                        |
//+------------------------------------------------------------------+
bool CEMACalculator::Initialize(string symbol, ENUM_TIMEFRAMES period, int ma1_length, int ma2_length, int ma3_length)
{
    m_symbol = symbol;
    m_period = period;
    
    // Create handles for three EMAs
    m_handle_ema1 = iMA(m_symbol, m_period, ma1_length, 0, MODE_EMA, PRICE_CLOSE);
    m_handle_ema2 = iMA(m_symbol, m_period, ma2_length, 0, MODE_EMA, PRICE_CLOSE);
    m_handle_ema3 = iMA(m_symbol, m_period, ma3_length, 0, MODE_EMA, PRICE_CLOSE);
    
    // Check if handles are valid
    if(m_handle_ema1 == INVALID_HANDLE || m_handle_ema2 == INVALID_HANDLE || m_handle_ema3 == INVALID_HANDLE)
    {
        Print("Failed to create EMA indicators. Error code: ", GetLastError());
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get EMA1 value at specified bar                                 |
//+------------------------------------------------------------------+
double CEMACalculator::GetEMA1(int shift = 0)
{
    if(m_handle_ema1 == INVALID_HANDLE)
        return 0.0;
    
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if(CopyBuffer(m_handle_ema1, 0, shift, 1, buffer) <= 0)
        return 0.0;
    
    return buffer[0];
}

//+------------------------------------------------------------------+
//| Get EMA2 value                                                   |
//+------------------------------------------------------------------+
double CEMACalculator::GetEMA2(int shift = 0)
{
    if(m_handle_ema2 == INVALID_HANDLE)
        return 0.0;
    
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if(CopyBuffer(m_handle_ema2, 0, shift, 1, buffer) <= 0)
        return 0.0;
    
    return buffer[0];
}

//+------------------------------------------------------------------+
//| Get EMA3 value                                                   |
//+------------------------------------------------------------------+
double CEMACalculator::GetEMA3(int shift = 0)
{
    if(m_handle_ema3 == INVALID_HANDLE)
        return 0.0;
    
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if(CopyBuffer(m_handle_ema3, 0, shift, 1, buffer) <= 0)
        return 0.0;
    
    return buffer[0];
}

//+------------------------------------------------------------------+
//| Release resources                                                |
//+------------------------------------------------------------------+
void CEMACalculator::Release()
{
    if(m_handle_ema1 != INVALID_HANDLE)
    {
        IndicatorRelease(m_handle_ema1);
        m_handle_ema1 = INVALID_HANDLE;
    }
    
    if(m_handle_ema2 != INVALID_HANDLE)
    {
        IndicatorRelease(m_handle_ema2);
        m_handle_ema2 = INVALID_HANDLE;
    }
    
    if(m_handle_ema3 != INVALID_HANDLE)
    {
        IndicatorRelease(m_handle_ema3);
        m_handle_ema3 = INVALID_HANDLE;
    }
}

