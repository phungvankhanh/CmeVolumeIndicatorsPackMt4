//+------------------------------------------------------------------+
//|                                                  CmeProvider.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
/*
   ICmeProvider - defined global invariants,
*/
//+------------------------------------------------------------------+
//| Тип хранимого объема                                             |
//+------------------------------------------------------------------+
enum ENUM_CME_VOL_TYPE
{
   CME_GLOBEX_VOLUME,      // Globex Volume
   CME_PIT_VOLUME,         // Pit Volume
   CME_EXPIT_VOLUME,       // ExPit Volume
   CME_OTC_VOLUME,         // OTC Volume
   CME_TOTAL_VOLUME,       // Total Volume
   CME_MTD_ADV_VOLUME,     // Avrg Month Volume
   CME_CALL_PUT_RATIO,     // CallPut Ratio
   CME_OPEN_INTEREST       // Open Interest
};
#define TOTAL_CME_GROUP 7
//+------------------------------------------------------------------+
//| Always defined                                                   |
//+------------------------------------------------------------------+
#define PRODUCTION
//+---------------------------------------------------------------------+
//| Cross-platforming interface for CME Provider                        |
//+---------------------------------------------------------------------+
class ICmeProvider
{
protected:
    //-- This abstract class as interface
                     ICmeProvider(void);
public:   
   //-- This methods is invariant by platform, so they implementation in this class
   string            VolumeIndName(void);
   string            OiIndName(void);
   string            CallPutIndName(void);
   datetime          DataSince();
   string            CmeVolumeToString(ENUM_CME_VOL_TYPE vol_type);
   //-- This method has different implimentation in MetaTrader 5 and MetaTrader 4 platforms
   virtual bool      InitProvider(string symbol, int period, ENUM_CME_VOL_TYPE vol_type, bool auto_detect, string report_name){return false;}
   //-- This method has no effect in MetaTrader 4
   virtual void      IndicatorRelease(void){;}
   //-- Abstract get method
   //-- Implementation this method depends by platform, so this method need override in concrete class of provider
   virtual double    GetValue(int index){return EMPTY_VALUE;}
};
//+------------------------------------------------------------------+
//| This abstract class                                              |
//+------------------------------------------------------------------+
ICmeProvider::ICmeProvider(void)
{
   MessageBox("atention please, if you run this indicators without");
}
//+------------------------------------------------------------------+
//| Data since of publication CME data                               |
//+------------------------------------------------------------------+
datetime ICmeProvider::DataSince()
{
   return D'2014.01.01';
}
//+------------------------------------------------------------------+
//| Return constant CME Volume indicator name                        |
//+------------------------------------------------------------------+
string ICmeProvider::VolumeIndName(void)
{
   #ifdef PRODUCTION
      return "Market\\CME Daily Bulletin Real Volume MT4";
   #else
      return "CME\\CME Daily Volume";
   #endif 
}
//+------------------------------------------------------------------+
//| Return constant CME Volume indicator name                        |
//+------------------------------------------------------------------+
string ICmeProvider::OiIndName(void)
{
   #ifdef PRODUCTION
      return "Market\\CME Daily Bulletin Open Interest MT4";
   #else
      return "CME\\CME Daily OI";
   #endif 
   
}
//+------------------------------------------------------------------+
//| Return constant CME Volume indicator name                        |
//+------------------------------------------------------------------+
string ICmeProvider::CallPutIndName(void)
{
   #ifdef PRODUCTION
      return "Market\\CME CallPut Option Ratio MT4";
   #else
      return "CME\\CME CallPut Ratio";
   #endif 
}
//+------------------------------------------------------------------+
//| Return string name of ENUM_CME_VOL_TYPE                          |
//+------------------------------------------------------------------+
string ICmeProvider::CmeVolumeToString(ENUM_CME_VOL_TYPE vol_type)
{
   switch(vol_type)
   {
      case CME_GLOBEX_VOLUME:
         return "Globex Volume";
      case CME_PIT_VOLUME:
         return "Pit Volume";
      case CME_EXPIT_VOLUME:
         return "ExPit Volume";
      case CME_OTC_VOLUME:
         return "OTC Volume";
      case CME_TOTAL_VOLUME:
         return "Total Volume";
      case CME_MTD_ADV_VOLUME:
         return "Avrg Month Volume";
      case CME_OPEN_INTEREST:
         return "Open Interest";
   }
   return "";
}