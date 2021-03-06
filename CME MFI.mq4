//+------------------------------------------------------------------+
//|                           CME Daily Bulletin Indicators Pack.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots 1
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrBlueViolet

#include "ICmeProvider.mqh"
#ifdef __MQL4__
   #include "CmeProviderMT4.mqh"
#else 
   #include "CmeProviderMT5.mqh"
#endif

input int            MfiPeriod = 14;                     // MFI Period
input ENUM_CME_VOL_TYPE VolType = CME_GLOBEX_VOLUME;     // Volume Type
input bool           AutoDetect = true;                  // Auto Detect Report Name 
input string         ReportName = "EURODOLLAR FUTURE (ED)"; // Report Name

double               buffer[];
ICmeProvider*        CmeProvider = new CCmeProvider();   // CME Data Provider
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   
   if(!CmeProvider.InitProvider(Symbol(), Period(), VolType, AutoDetect, ReportName))
      return INIT_FAILED;
   string type_vol = CmeProvider.CmeVolumeToString(VolType);
   IndicatorSetString(INDICATOR_SHORTNAME, "CME MFI " + type_vol + " (" + (string)MfiPeriod + ")");
   SetIndexBuffer(0, buffer, INDICATOR_DATA);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Deinit and free CmeProvider                                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(CheckPointer(CmeProvider) == POINTER_DYNAMIC)
   {
      CmeProvider.IndicatorRelease();
      delete CmeProvider;
   }
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   ArraySetAsSeries(buffer, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(tick_volume, true);
   
   for(int i = prev_calculated; i < rates_total && !IsStopped(); i++)
   {
      int bar = rates_total-i-1;
      //-- get cme daily volume or stundart tick volume
      double cme_volume = CmeProvider.GetValue(bar);
      if(cme_volume == EMPTY_VALUE || i == 0)
      {
         buffer[bar] = EMPTY_VALUE;
         continue;
      }
      //-- Syncronize calculations on period less D1
      if(Period() < PERIOD_D1 && VolType <= CME_OPEN_INTEREST)
      {
         if(!NewDay(time[bar+1], time[bar]))
         {
            buffer[bar] = buffer[bar+1];
            continue;
         }
      }
      //-- calculate typing price
      double curr_tp = TP(high[bar], low[bar], close[bar]);
      int limit = MathMin(MfiPeriod, i);
      double pos_mf = 0.0;
      double neg_mf = 0.0;
      //-- calculate sum positive and sum negative money flow values for period
      for(int p = 1; p <= limit; p++)
      {
         double prev_tp = TP(high[p+bar], low[p+bar], close[p+bar]);
         if(curr_tp > prev_tp)
            pos_mf += MF(curr_tp, CmeProvider.GetValue(p+bar-1));
         else
            neg_mf += MF(curr_tp, CmeProvider.GetValue(p+bar-1));
         curr_tp = prev_tp;
      }
      if(neg_mf != 0.0)
      {
         double mr = pos_mf/neg_mf;
         buffer[bar] = 100 - (100 / (1 + mr));
      }
      else
         buffer[bar] = 100.0;
   }
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Calculate typing price                                           |
//+------------------------------------------------------------------+
double TP(double max, double min, double close)
{
   return (max + min + close)/3.0;
}
//+------------------------------------------------------------------+
//| Money flow value: typing price * volume                          |
//+------------------------------------------------------------------+
double MF(double tp, double volume)
{
   return tp*volume;
}
//+------------------------------------------------------------------+
//| Return true if new day detected, otherwise false                 |
//+------------------------------------------------------------------+
bool NewDay(datetime prev_time, datetime curr_time)
{
   MqlDateTime pt, ct;
   TimeToStruct(prev_time, pt);
   TimeToStruct(curr_time, ct);
   return pt.day != ct.day;
}
//+------------------------------------------------------------------+
