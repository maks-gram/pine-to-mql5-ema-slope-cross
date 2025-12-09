//+------------------------------------------------------------------+
//|                                                trade_executor.mqh|
//|                        Trade Execution Module                    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.00"

//+------------------------------------------------------------------+
//| Trade Executor Class                                             |
//| Implements "always in market" logic                              |
//+------------------------------------------------------------------+
class CTradeExecutor
{
private:
    ulong    m_magic_number;     // Magic number
    string   m_symbol;           // Symbol
    double   m_lot_size;         // Lot size
    uint     m_last_retcode;     // Last OrderSend retcode
    string   m_last_comment;     // Last OrderSend comment
    
    // Check if trading session is open for symbol
    bool     IsMarketOpen();
    
public:
    CTradeExecutor();
    CTradeExecutor(ulong magic_number, string symbol, double lot_size = 0.01);
    
    // Initialize (for reinitialization after default construction)
    void Initialize(ulong magic_number, string symbol, double lot_size);
    
    // Open/switch to LONG position
    bool OpenLong(string comment = "Long");
    
    // Open/switch to SHORT position
    bool OpenShort(string comment = "Short");
    
    // Check if position is open
    bool HasPosition();
    
    // Get current position type (0 = none, 1 = LONG, -1 = SHORT)
    int GetPositionType();
    
    // Close all positions
    bool CloseAllPositions();
    
    // Get last retcode (for diagnostics)
    uint GetLastRetcode() { return m_last_retcode; }
    string GetLastComment() { return m_last_comment; }
};

//+------------------------------------------------------------------+
//| Default constructor                                              |
//+------------------------------------------------------------------+
CTradeExecutor::CTradeExecutor()
{
    m_magic_number = 0;
    m_symbol = "";
    m_lot_size = 0.01;
    m_last_retcode = 0;
    m_last_comment = "";
}

//+------------------------------------------------------------------+
//| Constructor with parameters                                       |
//+------------------------------------------------------------------+
CTradeExecutor::CTradeExecutor(ulong magic_number, string symbol, double lot_size = 0.01)
{
    m_magic_number = magic_number;
    m_symbol = symbol;
    m_lot_size = lot_size;
    m_last_retcode = 0;
    m_last_comment = "";
}

//+------------------------------------------------------------------+
//| Initialize (for reinitialization after default construction)    |
//+------------------------------------------------------------------+
void CTradeExecutor::Initialize(ulong magic_number, string symbol, double lot_size)
{
    m_magic_number = magic_number;
    m_symbol = symbol;
    m_lot_size = lot_size;
    m_last_retcode = 0;
    m_last_comment = "";
}

//+------------------------------------------------------------------+
//| Check if trading session is open                                 |
//+------------------------------------------------------------------+
bool CTradeExecutor::IsMarketOpen()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    ENUM_DAY_OF_WEEK day = (ENUM_DAY_OF_WEEK)dt.day_of_week; // 0=Sunday
    
    // Current time in seconds from start of day
    int seconds_now = dt.hour * 3600 + dt.min * 60 + dt.sec;
    
    // Iterate through sessions for current day
    datetime session_from = 0;
    datetime session_to   = 0;
    for(int i = 0; SymbolInfoSessionTrade(m_symbol, day, i, session_from, session_to); i++)
    {
        int from_s = (int)(session_from % 86400);
        int to_s   = (int)(session_to % 86400);
        
        if(from_s == 0 && to_s == 0)
            continue;
        
        // Session without crossing midnight
        if(to_s > from_s)
        {
            if(seconds_now >= from_s && seconds_now < to_s)
                return true;
        }
        else // Session crossing midnight (rare for FX, but handle it)
        {
            if(seconds_now >= from_s || seconds_now < to_s)
                return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Open/switch to LONG position                                    |
//| If SHORT exists - closes it and opens LONG                       |
//| If LONG already exists - does nothing                            |
//+------------------------------------------------------------------+
bool CTradeExecutor::OpenLong(string comment = "Long")
{
    int pos_type = GetPositionType();
    
    m_last_retcode = 0;
    m_last_comment = "";
    
    // If already LONG - do nothing
    if(pos_type == 1)
        return true;
    
    // If SHORT exists - close it
    if(pos_type == -1)
    {
        CloseAllPositions();
        Sleep(100);  // Small delay to ensure closure
    }
    
    // If market is closed - don't send order, try later
    if(!IsMarketOpen())
    {
        m_last_retcode = 10018;
        m_last_comment = "Market closed (session check)";
        return false;
    }
    
    // Open LONG position
    MqlTradeRequest request = {};
    MqlTradeResult  result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = m_symbol;
    request.volume = m_lot_size;
    request.type = ORDER_TYPE_BUY;
    request.price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
    request.deviation = 10;
    request.magic = m_magic_number;
    request.comment = comment;
    
    // Determine supported filling mode
    int filling = (int)SymbolInfoInteger(m_symbol, SYMBOL_FILLING_MODE);
    if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
        request.type_filling = ORDER_FILLING_FOK;
    else if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
        request.type_filling = ORDER_FILLING_IOC;
    else
        request.type_filling = ORDER_FILLING_RETURN;
    
    if(!OrderSend(request, result))
    {
        m_last_retcode = result.retcode;
        m_last_comment = result.comment;
        Print("Failed to open LONG position. Error code: ", result.retcode, ", description: ", result.comment);
        return false;
    }
    
    m_last_retcode = result.retcode;
    m_last_comment = result.comment;
    
    return true;
}

//+------------------------------------------------------------------+
//| Open/switch to SHORT position                                   |
//| If LONG exists - closes it and opens SHORT                      |
//| If SHORT already exists - does nothing                           |
//+------------------------------------------------------------------+
bool CTradeExecutor::OpenShort(string comment = "Short")
{
    int pos_type = GetPositionType();
    
    m_last_retcode = 0;
    m_last_comment = "";
    
    // If already SHORT - do nothing
    if(pos_type == -1)
        return true;
    
    // If LONG exists - close it
    if(pos_type == 1)
    {
        CloseAllPositions();
        Sleep(100);  // Small delay to ensure closure
    }
    
    // If market is closed - don't send order, try later
    if(!IsMarketOpen())
    {
        m_last_retcode = 10018;
        m_last_comment = "Market closed (session check)";
        return false;
    }
    
    // Open SHORT position
    MqlTradeRequest request = {};
    MqlTradeResult  result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = m_symbol;
    request.volume = m_lot_size;
    request.type = ORDER_TYPE_SELL;
    request.price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    request.deviation = 10;
    request.magic = m_magic_number;
    request.comment = comment;
    
    // Determine supported filling mode
    int filling = (int)SymbolInfoInteger(m_symbol, SYMBOL_FILLING_MODE);
    if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
        request.type_filling = ORDER_FILLING_FOK;
    else if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
        request.type_filling = ORDER_FILLING_IOC;
    else
        request.type_filling = ORDER_FILLING_RETURN;
    
    if(!OrderSend(request, result))
    {
        m_last_retcode = result.retcode;
        m_last_comment = result.comment;
        Print("Failed to open SHORT position. Error code: ", result.retcode, ", description: ", result.comment);
        return false;
    }
    
    m_last_retcode = result.retcode;
    m_last_comment = result.comment;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if position is open                                        |
//+------------------------------------------------------------------+
bool CTradeExecutor::HasPosition()
{
    return (GetPositionType() != 0);
}

//+------------------------------------------------------------------+
//| Get current position type                                       |
//| Returns: 0 = none, 1 = LONG, -1 = SHORT                         |
//+------------------------------------------------------------------+
int CTradeExecutor::GetPositionType()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);  // Select position by index
        if(ticket > 0)
        {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol && 
               PositionGetInteger(POSITION_MAGIC) == m_magic_number)
            {
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                    return 1;  // LONG
                else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                    return -1; // SHORT
            }
        }
    }
    
    return 0; // No position
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
bool CTradeExecutor::CloseAllPositions()
{
    bool closed = false;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)
        {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol && 
               PositionGetInteger(POSITION_MAGIC) == m_magic_number)
            {
                MqlTradeRequest request = {};
                MqlTradeResult  result = {};
                
                request.action = TRADE_ACTION_DEAL;
                request.position = ticket;
                request.symbol = m_symbol;
                request.volume = PositionGetDouble(POSITION_VOLUME);
                request.deviation = 10;
                request.magic = m_magic_number;
                
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                {
                    request.type = ORDER_TYPE_SELL;
                    request.price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
                }
                else
                {
                    request.type = ORDER_TYPE_BUY;
                    request.price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
                }
                
                // Determine supported filling mode
                int filling = (int)SymbolInfoInteger(m_symbol, SYMBOL_FILLING_MODE);
                if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
                    request.type_filling = ORDER_FILLING_FOK;
                else if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
                    request.type_filling = ORDER_FILLING_IOC;
                else
                    request.type_filling = ORDER_FILLING_RETURN;
                
                if(!OrderSend(request, result))
                {
                    Print("Failed to close position. Error code: ", result.retcode, ", description: ", result.comment);
                    continue;
                }
                
                closed = true;
            }
        }
    }
    
    return closed;
}
