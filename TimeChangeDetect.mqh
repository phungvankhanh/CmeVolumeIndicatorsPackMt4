//+------------------------------------------------------------------+
//|                                             TimeChangeDetect.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property strict
#define CHANGE_SEC 1       // Second
#define CHANGE_MIN 2       // Minute
#define CHANGE_HOR 4       // Hour
#define CHANGE_DAY 8       // Day
#define CHANGE_WEK 16      // Week
#define CHANGE_MNT 32      // Month
#define CHANGE_QRT 64      // Quarter
#define CHANGE_YAR 128     // Year
class CTimeSet
{
public:
   datetime    time_prev;
   datetime    time_curr;
   MqlDateTime time_prev_str;
   MqlDateTime time_curr_str;
}; 
//+------------------------------------------------------------------+
//| Определяет изменение времени, возвращает набор флагов,           |
//| сигнализирующий о том, какой период времени изменился с          |
//| последнего доступа                                               |
//+------------------------------------------------------------------+
class CTimeChangeDetect
{
private:
   CTimeSet m_time_set;
   bool     ChangeSec(void);
   bool     ChangeMin(void);
   bool     ChangeHor(void);
   bool     ChangeDay(void);
   bool     ChangeWeek(void);
   bool     ChangeMonth(void);
   bool     ChangeQuarter(void);
   bool     ChangeYear(void);
public:
            CTimeChangeDetect(void);
   uint     ChangeTime(datetime time_now);
   void     ResetRememberTime(void);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTimeChangeDetect::CTimeChangeDetect(void)
{
   ResetRememberTime();
}
//+------------------------------------------------------------------+
//| Сбрасывает ранее запомненное состояние                           |
//+------------------------------------------------------------------+
void CTimeChangeDetect::ResetRememberTime(void)
{
   m_time_set.time_curr = 0;
   m_time_set.time_prev = 0;
   ZeroMemory(m_time_set.time_curr_str);
   ZeroMemory(m_time_set.time_prev_str); 
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
uint CTimeChangeDetect::ChangeTime(datetime time_now)
{
   m_time_set.time_curr = time_now;
   TimeToStruct(time_now, m_time_set.time_curr_str);
   int flags = 0;
   //--
   flags += ChangeSec();
   flags += ChangeMin()       << 1;
   flags += ChangeHor()       << 2;
   flags += ChangeDay()       << 3;
   flags += ChangeWeek()      << 4;
   flags += ChangeMonth()     << 5;
   flags += ChangeQuarter()   << 6;
   flags += ChangeYear()      << 7;
   //--
   m_time_set.time_prev = time_now;
   TimeToStruct(time_now, m_time_set.time_prev_str);
   return flags;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTimeChangeDetect::ChangeSec(void)
{
   return m_time_set.time_prev != m_time_set.time_curr;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTimeChangeDetect::ChangeMin(void)
{
   long tiks = (long)MathAbs(m_time_set.time_curr - m_time_set.time_prev);
   if(tiks >= 60)
      return true;
   return m_time_set.time_curr_str.min != m_time_set.time_prev_str.min;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTimeChangeDetect::ChangeHor(void)
{
   long tiks = (long)MathAbs(m_time_set.time_curr - m_time_set.time_prev);
   if(tiks >= 3600)
      return true;
   return m_time_set.time_curr_str.hour != m_time_set.time_prev_str.hour;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTimeChangeDetect::ChangeDay(void)
{
   long tiks = (long)MathAbs(m_time_set.time_curr - m_time_set.time_prev);
   if(tiks >= 86400)
      return true;
   return m_time_set.time_curr_str.day_of_year != m_time_set.time_prev_str.day_of_year;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTimeChangeDetect::ChangeWeek(void)
{
   long tiks = (long)MathAbs(m_time_set.time_curr - m_time_set.time_prev);
   if(tiks >= 604800)
      return true;
   //--
   return m_time_set.time_curr_str.day_of_week < m_time_set.time_prev_str.day_of_week;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTimeChangeDetect::ChangeMonth(void)
{
   bool cm = m_time_set.time_curr_str.mon != m_time_set.time_prev_str.mon;
   bool cy = m_time_set.time_curr_str.year != m_time_set.time_prev_str.year;
   return cm || cy;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTimeChangeDetect::ChangeQuarter(void)
{
   bool cy = m_time_set.time_curr_str.year != m_time_set.time_prev_str.year;
   if(cy)
      return true;
   int m_c = m_time_set.time_curr_str.mon;
   int m_p = m_time_set.time_prev_str.mon;
   if(m_c == m_p)
      return false;
   if(m_c >= 4 && m_p < 4)
      return true;
   if(m_c >= 7 && m_p < 7)
      return true;
   if(m_c >= 10 && m_p < 10)
      return true;
   if(m_c < 4)
      return m_time_set.time_curr_str.year != m_time_set.time_prev_str.year;
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTimeChangeDetect::ChangeYear(void)
{
   return m_time_set.time_curr_str.year != m_time_set.time_prev_str.year;
}
