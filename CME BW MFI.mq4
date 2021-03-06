//+------------------------------------------------------------------+
//|                                    CME Accumulation Distribution |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+

/*
  Accumulation/Distribution Technical Indicator is determined by the changes in price and volume.
  The volume acts as a weighting coefficient at the change of price — the higher the coefficient
  (the volume) is, the greater the contribution of the price change (for this period of time)
  will be in the value of the indicator.
*/
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots 5

#property indicator_type1 DRAW_HISTOGRAM
#property indicator_color1 clrNONE

#property indicator_type2 DRAW_HISTOGRAM
#property indicator_color2 clrLime

#property indicator_type3 DRAW_HISTOGRAM
#property indicator_color3 clrBlue

#property indicator_type4 DRAW_HISTOGRAM
#property indicator_color4 clrPink

#property indicator_type5 DRAW_HISTOGRAM
#property indicator_color5 clrSaddleBrown

#include "ICmeProvider.mqh"
#ifdef __MQL4__
   #include "CmeProviderMT4.mqh"
#else 
   #include "CmeProviderMT5.mqh"
#endif

input ENUM_CME_VOL_TYPE VolType = CME_GLOBEX_VOLUME;     // Volume Type
input bool           AutoDetect = true;                  // Auto Detect Report Name 
input string         ReportName = "EURODOLLAR FUTURE (ED)"; // Report Name

double               buffer[];
double               buffer1[];
double               buffer2[];
double               buffer3[];
double               buffer4[];
double               prev_v;
double               prev_mfi;
ICmeProvider*        CmeProvider = new CCmeProvider();   // CME Data Provider
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!CmeProvider.InitProvider(Symbol(), Period(), VolType, AutoDetect, ReportName))
      return INIT_FAILED;
   string type_vol = CmeProvider.CmeVolumeToString(VolType);
   IndicatorSetString(INDICATOR_SHORTNAME, "CME MFI " + type_vol);
   SetIndexBuffer(0, buffer, INDICATOR_DATA);
   SetIndexBuffer(1, buffer1, INDICATOR_DATA);
   SetIndexBuffer(2, buffer2, INDICATOR_DATA);
   SetIndexBuffer(3, buffer3, INDICATOR_DATA);
   SetIndexBuffer(4, buffer4, INDICATOR_DATA);
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
   if(prev_calculated == 0.0)
   {
      prev_v = 0.0;
      prev_mfi = 0.0;
   }
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
            SetPrevValue(bar);
            continue;
         }
      }
      //-- calculate MFI
      double value = 0.0;
      if(cme_volume != 0.0)
         value = (high[bar]-low[bar])/Point()/cme_volume;
      else
         value = EMPTY_VALUE;
      SetValue(bar, value, cme_volume);
      prev_mfi = buffer[bar];
      prev_v = cme_volume;
   }
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Set value of indicators                                          |
//+------------------------------------------------------------------+
void SetValue(int index, double mfi, double vol)
{
   buffer[index] = mfi;
   buffer1[index] = EMPTY_VALUE;
   buffer2[index] = EMPTY_VALUE;
   buffer3[index] = EMPTY_VALUE;
   buffer4[index] = EMPTY_VALUE;
   if(mfi > prev_mfi)
   {
      if(vol > prev_v)
         buffer1[index] = buffer[index];
      else
         buffer2[index] = buffer[index];
   }
   else
   {
      if(vol > prev_v)
         buffer3[index] = buffer[index];
      else
         buffer4[index] = buffer[index];
   }
}

void SetPrevValue(int index)
{
   buffer[index] = buffer[index+1];
   buffer1[index] = buffer1[index+1];
   buffer2[index] = buffer2[index+1];
   buffer3[index] = buffer3[index+1];
   buffer4[index] = buffer4[index+1];
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
