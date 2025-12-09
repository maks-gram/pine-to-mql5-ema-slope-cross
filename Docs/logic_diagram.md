## Logic diagram (Long / Short)

+---------------------------------------------------+
|        Signal logic (on bar close only)           |
+---------------------------------------------------+

Inputs:
  - price (Close)
  - EMA1 (fast), EMA2 (medium), EMA3 (slow)
  - slope(price), slope(EMA1), slope(EMA2), slope(EMA3)

                 +----------------------+
                 |   Start evaluation   |
                 +----------+-----------+
                            |
                            v
                +------------------------+
                | Check LONG condition   |
                +------------------------+
                  long_condition is TRUE if:

                  A) price crosses UNDER EMA3
                     (crossunder(price, EMA3))
                  OR
                  B) All of:
                     - change(price) < 0        (price slope down)
                     - change(EMA1) < 0         (EMA1 slope down)
                     - crossunder(price, EMA1)  (price under EMA1)
                     - change(EMA2) > 0         (EMA2 slope up)

                            |
            +---------------+----------------+
            |                                |
       (long_condition)                 (no long)
            |                                v
            v                        +-------------------+
 +-------------------+              | Check SHORT cond. |
 |  Generate LONG    |              +-------------------+
 |  signal           |                short_condition is TRUE if:
 +---------+---------+
           |                         A) price crosses OVER EMA3
           |                            (crossover(price, EMA3))
           v                         OR
+---------------------------+        B) All of:
| Position management:      |           - change(price) > 0        (price up)
| - Open / reverse to LONG  |           - change(EMA1) > 0         (EMA1 up)
| - Send alert if enabled  |           - crossover(price, EMA1)   (price over EMA1)
+---------------------------+           - change(EMA2) < 0         (EMA2 down)
                                     
                                     
                                     
                            |
                +-----------+------------+
                |                        |
          (short_condition)        (no short)
                |                        |
                v                        v
      +-------------------+       +-------------------+
      | Generate SHORT    |       |   No signal       |
      | signal            |       | (no action, keep  |
      +---------+---------+       |  current position) |
                |                 +-------------------+
                v
      +---------------------------+
      | Position management:      |
      | - Open / reverse to SHORT |
      | - Send alert if enabled  |
      +---------------------------+
