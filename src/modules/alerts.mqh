//+------------------------------------------------------------------+
//|                                                  alerts.mqh      |
//|                        Alert                 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      ""
#property version   "1.00"

class CAlerts
{
private:
    bool m_enabled;

public:
    CAlerts() : m_enabled(false) {}

    void Initialize(bool enabled)
    {
        m_enabled = enabled;
    }

    void SetEnabled(bool enabled)
    {
        m_enabled = enabled;
    }

    bool Enabled() const
    {
        return m_enabled;
    }

    void Send(string message)
    {
        if(!m_enabled)
            return;
        Alert(message);
    }
};
