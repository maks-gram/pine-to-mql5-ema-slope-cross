# pine-to-mql5-ema-slope-cross
TradingView-to-MT5 conversion (Pine Script → MQL5). Includes EMA slope/cross logic, ATR stop option, alerts, modular architecture, and MT5 backtest results. 

Pine → MQL5 Conversion: EMA Slope + EMA Cross Strategy

Complete TradingView-to-MT5 Conversion Project (with enhancements)
This repository contains a fully implemented conversion of the public TradingView strategy
“EMA Slope + EMA Cross Strategy (by ChartArt)”
into a structured, feature-rich MQL5 Expert Advisor, including additional improvements:
- Clean modular architecture
- Select a timeframe for the robot;
- Magic number for trading multiple instruments;
- Risk management section taking volatility into account (to be added later);
- Money management section (to be added later);
- Trade standby mode (not always in the market, to be added later).

1. Project Purpose
This project demonstrates how a complete TradingView strategy can be accurately translated into MT5, including:
- indicator logic
- entry conditions
- alert conditions
- visualization
- strategy flow
- market entry/exit behavior
On top of that, several practical trading features were added in the MT5 version which were not available in the original Pine Script.

2. Original TradingView Strategy (Pine Script)
Source:
https://www.tradingview.com/script/…
Author: ChartArt
Script name: “EMA Slope + EMA Cross Strategy”
You can find the original Pine file here:
/tradingview/original_script.pine

Core logic in Pine:
- EMA(2), EMA(4), EMA(20)
- long/short conditions using slope + crossovers
- non-stop (always in the market) behavior
- trend-based coloring
- alertcondition() for signals
Screenshot (TradingView signals):
tradingview/screenshot_tv_signals.png

3. MT5 Conversion — What Was Implemented
✔ EMA calculation
Mapped using built-in MQL5 iMA() function
(or custom EMA module if needed).
✔ Slope detection
Using Close[i] - Close[i+1] and EMA differential.
✔ Cross detection
Translated from Pine crossover/crossunder to MT5 logic.
✔ Position Management
Equivalent of strategy.entry() calls.

4. MT5 Improvements (beyond the original TradingView script)
This is what makes the project stand out.
1️⃣ Selectable Timeframe
Work on any timeframe independently from chart timeframe
Timeframe = 0 (chart TF), 16385 (H1), 16408 (D1), etc.
2️⃣ Signal-Based Trading (not always in market)
Positions open only when LONG or SHORT conditions are met
Automatic position reversal when opposite signal appears
3️⃣ Configurable Alerts
- MT5 Alert() notifications (optional)
- Alerts sent on position open/close events
4️⃣ Enhanced Visualization
EMA(4) & EMA(20) with trend-based colors (green/red/blue)
Optional fill area between EMA2 and EMA3
Bar coloring based on EMA slopes
5️⃣ Modular Architecture
Located under /src/modules:
- ema_calc.mqh - EMA calculations
- slope_calc.mqh - Slope and crossover detection
- DrawBar.mqh - Bar coloring module
- DrawEMA.mqh - EMA lines drawing module
- alerts.mqh - Alert management
- trade_executor.mqh - Trade execution and position management
6️⃣ Market Closed Handling
Automatic retry mechanism when market is closed (error 10018)
Pending direction tracking for delayed entries

5. MT5 Strategy Behavior
The logic mirrors TradingView:
Long conditions (either A or B):
A) price crosses below EMA3 (crossunder(price, EMA3))
OR
B) All of:
   - change(price) < 0 (price slope down)
   - change(EMA1) < 0 (EMA1 slope down)
   - crossunder(price, EMA1) (price crosses under EMA1)
   - change(EMA2) > 0 (EMA2 slope up)

Short conditions (either A or B):
A) price crosses above EMA3 (crossover(price, EMA3))
OR
B) All of:
   - change(price) > 0 (price slope up)
   - change(EMA1) > 0 (EMA1 slope up)
   - crossover(price, EMA1) (price crosses over EMA1)
   - change(EMA2) < 0 (EMA2 slope down)

Position Management:
- Positions open only when LONG or SHORT condition is met
- If opposite signal appears, current position is closed and new one is opened

6. Backtest Results
Example backtest (MT5 Tester):
- comparison_of_results_Pine_MT5.png
- tester's_work_MT5.png
- tester's_work_MT5_with_results.png
real-time test:
- mt5_chart_real_with_alerts.png
- mt5_chart_real_EURUSD_1m.png
- mt5_chart_real_GBPUSD_1m.png

7. File Structure
/src/EMA_Slope_Cross_EA.mq5         → main EA file  
/src/modules/…                      → calculation & trading modules  
/tradingview/original_script.pine   → original Pine Script  
/docs/…                             → logic diagrams  
/mt5/…                              → screenshots & backtests  

8. How to Use
1) Copy the folder into:
MQL5/Experts/pine_to_mql5_ema_slope_cross/
2) Compile EA inside MetaEditor.
3) Attach to chart.
4) Configure input parameters:
- EMA Settings:
  - MA1_Length (Fast EMA, default: 2)
  - MA2_Length (Mid EMA, default: 4)
  - MA3_Length (Slow EMA, default: 20)
- Trading:
  - Timeframe (0 = chart TF, 16385 = H1, 16408 = D1)
  - MagicNumber (default: 123456)
  - LotSize (default: 0.1)
- Visualization:
  - ShowBarColor (color bars by EMA slopes)
  - ShowMovingAverages (plot EMA lines)
  - ShowFillArea (fill between EMA2 and EMA3)
- Alerts:
  - SendAlerts (enable/disable MT5 alerts)
5) Run backtest or forward test.

9. Roadmap — Planned for v2.0
- Risk management section - Customizable exit rules (TP/SL via EMA or volatility filters)
- Money management section - Dynamic lot sizing based on risk percentage
- ATR-based stop loss
- Multi-symbol support
- Python module for automated reporting

10. License & Attribution
This project is for educational and demonstration purposes.
Original idea and Pine Script belong to ChartArt (TradingView).
The MT5 code is written from scratch as a clean-room implementation.

11. Author
Maxime
FinTech Developer · MT5 Automation · Trading Strategy Engineer

💬 Want to convert your TradingView script to MT5?
Feel free to contact me — this project shows exactly what I can build.


===============================
Project structure

/pine-to-mql5-ema-slope-cross/
│
├── src/
│   ├── EMA_Slope_Cross_EA.mq5
│   └── modules/
│       ├── ema_calc.mqh
│       ├── slope_calc.mqh
│       ├── alerts.mqh
│       ├── DrawBar.mqh
│       ├── DrawEMA.mqh
│       ├── trade_executor.mqh
│
├── tradingview/
│   ├── original_script.pine
│
├── screenshot/
│   ├── comparison_of_results_Pine_MT5.png
│   ├── mt5_chart_real_with_alerts.png
│   ├── tester's_work_MT5.png
│   ├── tester's_work_MT5_with_results.png
│   ├── mt5_chart_real_EURUSD_1m.png
│   ├── mt5_chart_real_GBPUSD_1m.png
│   ├── TrView_chart_real_GBPUSD_1m.png
│
├── docs/
│   ├── logic_diagram.md
│   ├── architecture_overview.md
│
└── README.md
