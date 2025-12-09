==================================
## Architecture (ASCII diagram)

+-----------------------------------------------------------+
|                    EMA Slope + Cross EA                   |
+-----------------------------------------------------------+

                (every new tick / OnTick)

        +--------------------------------------+
        | 1. Read inputs & market data         |
        |--------------------------------------|
        | - Symbol / Timeframe (resolved)      |
        | - Price (Close from closed bars)      |
        | - User inputs (EMA lengths, LotSize) |
        +----------------------+---------------+
                               |
                               v
        +--------------------------------------+
        | 2. Check for new bar                 |
        |--------------------------------------|
        | - Process only on bar close          |
        | - Handle pending retry (market closed)|
        +----------------------+---------------+
                               |
                               v
        +--------------------------------------+
        | 3. Indicator calculations            |
        |--------------------------------------|
        | - EMA1 (Fast, length=2)              |
        | - EMA2 (Medium, length=4)            |
        | - EMA3 (Slow, length=20)             |
        | - Changes (price, EMA1, EMA2, EMA3)  |
        +----------------------+---------------+
                               |
                               v
        +--------------------------------------+
        | 4. Signal detection                  |
        |--------------------------------------|
        | - long_condition =                  |
        |   A: crossunder(price, EMA3) OR      |
        |   B: (price↓ & EMA1↓ & crossunder    |
        |       price/EMA1 & EMA2↑)            |
        | - short_condition =                 |
        |   A: crossover(price, EMA3) OR       |
        |   B: (price↑ & EMA1↑ & crossover    |
        |       price/EMA1 & EMA2↓)           |
        +----------------------+---------------+
                               |
                               v
        +--------------------------------------+
        | 5. Position management               |
        |--------------------------------------|
        | - If long_condition:                 |
        |   * Close SHORT if exists            |
        |   * Open LONG position              |
        | - If short_condition:                |
        |   * Close LONG if exists             |
        |   * Open SHORT position             |
        | - Handle market closed (retry)      |
        +----------------------+---------------+
                               |
                               v
        +--------------------------------------+
        | 6. Alerts                            |
        |--------------------------------------|
        | - MT5 Alert() (if SendAlerts=true)   |
        | - Notify on position open/close      |
        +----------------------+---------------+
                               |
                               v
        +--------------------------------------+
        | 7. Visual updates                    |
        |--------------------------------------|
        | - Draw EMA lines (trend-colored)     |
        | - Color bars by EMA slopes           |
        | - Optional fill between EMA2/EMA3   |
        +--------------------------------------+
