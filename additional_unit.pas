unit additional_unit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, math, DateUtils, tinvest_api_unit;

type

   // Структуры для процедуры Get_EMA
   gema_request = record
      gema_period : int64;                                                                                      // период расчета EMA
      gema_candles : array of gc_candlesStruct;                                                                 // массив свечек
   end;
   gema_arrStruct = record
      gema_ema : double;
      gema_time : string;
   end;
   gema_response = record
      gema_ema_arr : array of gema_arrStruct;                                                                   // массив значений EMA
   end;

   // Структуры для процедуры Get_RSI
   grsi_request = record
      grsi_period : int64;                                                                                      // период расчета RSI
      grsi_candles : array of gc_candlesStruct;                                                                 // массив свечек
   end;
   grsi_arrStruct = record
      grsi_rsi : double;
      grsi_time : string;
   end;
   grsi_response = record
      grsi_RSI_arr : array of grsi_arrStruct;                                                                   // массив значений RSI
   end;

   // Структуры для процедуры Get_HEIKEN_ASHI
   gha_request = record
      gha_candles : array of gc_candlesStruct;                                                                  // массив свечек
   end;
   gha_arrStruct = record
      gha_open : double;
      gha_high : double;
      gha_low : double;
      gha_close : double;
      gha_time : string;
   end;
   gha_response = record
      gha_HA_arr : array of gha_arrStruct;                                                                      // массив свечек HEIKEN ASHI
   end;

   // Структуры для процедуры Get_ATR
   gatr_request = record
      gatr_period : int64;                                                                                      // период расчета ATR
      gatr_candles : array of gc_candlesStruct;                                                                 // массив свечек
   end;
   gatr_arrStruct = record
      gatr_atr : double;
      gatr_time : string;
   end;
   gatr_response = record
      gatr_ATR_arr : array of gatr_arrStruct;                                                                   // массив значений ATR
   end;

   // Структуры для процедуры Get_MACD
   gmacd_request = record
      gmacd_fast_period : int64;                                                                                // Короткий период сглаживания для первой экспоненциальной скользящей средней (EMA)
      gmacd_slow_period : int64;                                                                                // Длинный период сглаживания для второй экспоненциальной скользящей средней (EMA)
      gmacd_smoothing_period : int64;                                                                           // Период сглаживания для третьей экспоненциальной скользящей средней (EMA)
      gmacd_candles : array of gc_candlesStruct;                                                                // массив свечек
   end;
   gmacd_arrStruct = record
      gmacd_macd_line : double;                                                                                 // массив значений линии MACD
      gmacd_signal_line : double;                                                                               // массив значений сигнальной линии MACD
      gmacd_histogram : double;                                                                                 // массив значений гистограммы
      gmacd_time : string;
   end;
   gmacd_response = record
      gmacd_macd_arr : array of gmacd_arrStruct;                                                                // массив параметров MACD
   end;


function Get_UUID() : string;
function ISOToLocalTime(const ISOStr: string) : string;
function LocalTimeToISO(const LocalStr: string) : string;
procedure GetExchangeCandles(candels_req: gc_request; out exc_output: gc_response);

procedure Get_EMA (gema_input : gema_request; out gema_output : gema_response);                                 // расчет индикатора EMA
procedure Get_RSI (grsi_input : grsi_request; out grsi_output : grsi_response);                                 // расчет индикатора RSI
procedure Get_HEIKEN_ASHI (gha_input : gha_request; out gha_output : gha_response);                             // расчет индикатора свечек Хейкен Аши
procedure Get_ATR (gatr_input : gatr_request; out gatr_output : gatr_response);                                 // расчет индикатора ATR
procedure Get_MACD (gmacd_input : gmacd_request; out gmacd_output : gmacd_response);                            // расчет индикатора MACD


implementation

function Get_UUID() : string;
var
   TG : TGUID;
   str_UUID : string;
begin
   CreateGUID(TG);
   str_UUID := LowerCase(GUIDToString(TG));
   str_UUID := StringReplace(str_UUID, '{', '', [rfReplaceAll, rfIgnoreCase]);
   str_UUID := StringReplace(str_UUID, '}', '', [rfReplaceAll, rfIgnoreCase]);
   Result := str_UUID;
end;

function AdjustDateTime(Year, Month, Day, Hour, Min, Sec: Integer; AddHours: Integer; var MSecPart: string) : string;
var
  DT: TDateTime;
begin
  DT := EncodeDateTime(Year, Month, Day, Hour, Min, Sec, 0);
  DT := IncHour(DT, AddHours);

  Result := FormatDateTime('dd.mm.yyyy hh:nn:ss', DT);

  if MSecPart <> '' then
    Result := Result + ',' + MSecPart;
end;

function ISOToLocalTime(const ISOStr: string) : string;
var
  Y, M, D, H, N, S: Integer;
  MSecPart: string;
  P: Integer;
begin

  Y := StrToInt(Copy(ISOStr, 1, 4));
  M := StrToInt(Copy(ISOStr, 6, 2));
  D := StrToInt(Copy(ISOStr, 9, 2));
  H := StrToInt(Copy(ISOStr, 12, 2));
  N := StrToInt(Copy(ISOStr, 15, 2));
  S := StrToInt(Copy(ISOStr, 18, 2));

  P := Pos('.', ISOStr);
  if P > 0 then
    MSecPart := Copy(ISOStr, P + 1, Length(ISOStr) - P - 1)
  else
    MSecPart := '';

  Result := AdjustDateTime(Y, M, D, H, N, S, 3, MSecPart);
end;

function LocalTimeToISO(const LocalStr: string) : string;
var
  Y, M, D, H, N, S: Integer;
  MSecPart: string;
  P: Integer;
begin

  D := StrToInt(Copy(LocalStr, 1, 2));
  M := StrToInt(Copy(LocalStr, 4, 2));
  Y := StrToInt(Copy(LocalStr, 7, 4));
  H := StrToInt(Copy(LocalStr, 12, 2));
  N := StrToInt(Copy(LocalStr, 15, 2));
  S := StrToInt(Copy(LocalStr, 18, 2));

  P := Pos(',', LocalStr);
  if P > 0 then
    MSecPart := Copy(LocalStr, P + 1, Length(LocalStr) - P)
  else
    MSecPart := '';

  Result := AdjustDateTime(Y, M, D, H, N, S, -3, MSecPart);

  Result := FormatDateTime('yyyy-mm-dd', ScanDateTime('dd.mm.yyyy', Copy(Result, 1, 10))) +
            'T' + Copy(Result, 12, 8);

  if MSecPart <> '' then
    Result := Result + '.' + MSecPart;
  Result := Result + 'Z';
end;


procedure GetExchangeCandles(candels_req: gc_request; out exc_output: gc_response);
var
   temp: gc_response;
   i, j: integer;
begin
   temp.gc_candles := nil;
   temp.gc_error_code := 0;
   temp.gc_error_description := 0;
   temp.gc_error_message := '';

   GetCandles(candels_req, temp);

   if temp.gc_error_description <> 0 then begin exc_output := temp; exit; end;

   j := 0;
   for i := 0 to High(temp.gc_candles) do
      if temp.gc_candles[i].gc_candleSource = 'CANDLE_SOURCE_EXCHANGE' then inc(j);

   SetLength(exc_output.gc_candles, j);
   j := 0;
   for i := 0 to High(temp.gc_candles) do
      if temp.gc_candles[i].gc_candleSource = 'CANDLE_SOURCE_EXCHANGE' then begin
         exc_output.gc_candles[j] := temp.gc_candles[i];
         inc(j);
      end;

   exc_output.gc_error_code := temp.gc_error_code;
   exc_output.gc_error_message := temp.gc_error_message;
   exc_output.gc_error_description := temp.gc_error_description;
end;

procedure Get_EMA(gema_input : gema_request; out gema_output : gema_response);
var
   count_candles, i : longint;
   summ_ema: double;
   EMA_solv : double;

begin
   summ_ema := 0;
   EMA_solv := 0;

   count_candles := high(gema_input.gema_candles);
   i := 0;

   SetLength(gema_output.gema_ema_arr, count_candles + 1);

   while i <= count_candles do begin

      if i < gema_input.gema_period  then begin
         summ_ema := summ_ema + gema_input.gema_candles[i].gc_close;
         gema_output.gema_ema_arr[i].gema_ema := 0;
      end;

      if i = (gema_input.gema_period - 1) then begin
         summ_ema := summ_ema / gema_input.gema_period;
         EMA_solv := summ_ema;
         gema_output.gema_ema_arr[i].gema_ema := EMA_solv;
      end;

      if i > (gema_input.gema_period - 1) then begin
         EMA_solv := gema_input.gema_candles[i].gc_close * (2/(gema_input.gema_period + 1)) + EMA_solv * (1-(2/(gema_input.gema_period + 1)));
         gema_output.gema_ema_arr[i].gema_ema := EMA_solv;
      end;

      gema_output.gema_ema_arr[i].gema_time := gema_input.gema_candles[i].gc_time;

      inc(i);
   end;
end;


procedure Get_RSI(grsi_input : grsi_request; out grsi_output : grsi_response);
var
   count_candles, i : longint;
   Summ_Gain, Summ_Loss : double;

   Change_arr, Gain_arr, Loss_arr, Av_Gain_arr, Av_Loss_arr, RS : array of double;

begin
   count_candles := high(grsi_input.grsi_candles);
   i := 0;

   SetLength(grsi_output.grsi_rsi_arr, count_candles + 1);

   SetLength(Change_arr, count_candles + 1);
   SetLength(Gain_arr, count_candles + 1);
   SetLength(Loss_arr, count_candles + 1);
   SetLength(Av_Gain_arr, count_candles + 1);
   SetLength(Av_Loss_arr, count_candles + 1);
   SetLength(RS, count_candles + 1);

   Summ_Gain := 0;
   Summ_Loss := 0;

   while i <= count_candles do begin

      if i >= 1  then begin
         Change_arr[i] := grsi_input.grsi_candles[i].gc_close - grsi_input.grsi_candles[i - 1].gc_close;

         Gain_arr[i] := 0;
         if (Change_arr[i] > 0) then Gain_arr[i] := Change_arr[i];

         Loss_arr[i] := 0;
         if (Change_arr[i] < 0) then Loss_arr[i] := abs(Change_arr[i]);

         Summ_Gain := Summ_Gain + Gain_arr[i];
         Summ_Loss := Summ_Loss + Loss_arr[i];

      end;

      if i = grsi_input.grsi_period then begin

         Av_Gain_arr[i] := Summ_Gain / grsi_input.grsi_period;
         Av_Loss_arr[i] := Summ_Loss / grsi_input.grsi_period;

         if (Av_Loss_arr[i] > 0) then RS[i] := Av_Gain_arr[i] / Av_Loss_arr[i];

         if (Av_Gain_arr[i] = 0) then
            grsi_output.grsi_rsi_arr[i].grsi_rsi := 100
         else
            grsi_output.grsi_rsi_arr[i].grsi_rsi := 100 - (100 / (1 + RS[i]));

      end;

      if i > grsi_input.grsi_period then begin

         Av_Gain_arr[i] := (Av_Gain_arr[i - 1] * (grsi_input.grsi_period - 1) + Gain_arr[i] ) / grsi_input.grsi_period;
         Av_Loss_arr[i] := (Av_Loss_arr[i - 1] * (grsi_input.grsi_period - 1) + Loss_arr[i] ) / grsi_input.grsi_period;

         if (Av_Loss_arr[i] > 0) then RS[i] := Av_Gain_arr[i] / Av_Loss_arr[i];

         if (Av_Gain_arr[i] = 0) then
            grsi_output.grsi_rsi_arr[i].grsi_rsi := 100
         else
           grsi_output.grsi_rsi_arr[i].grsi_rsi := 100 - (100 / (1 + RS[i]));

      end;

      grsi_output.grsi_rsi_arr[i].grsi_time := grsi_input.grsi_candles[i].gc_time;

      inc(i);
   end;
end;

procedure Get_HEIKEN_ASHI(gha_input : gha_request; out gha_output : gha_response);
var
   count_candles, i : longint;

begin

   count_candles := high(gha_input.gha_candles);
   i := 0;

  SetLength(gha_output.gha_HA_arr, count_candles + 1);

   while i <= count_candles do begin

      if i = 0 then
         gha_output.gha_HA_arr[i].gha_open := gha_input.gha_candles[i].gc_open
      else
         gha_output.gha_HA_arr[i].gha_open := (gha_output.gha_HA_arr[i-1].gha_open + gha_output.gha_HA_arr[i-1].gha_close) / 2;

      gha_output.gha_HA_arr[i].gha_close := (gha_input.gha_candles[i].gc_open + gha_input.gha_candles[i].gc_high + gha_input.gha_candles[i].gc_low + gha_input.gha_candles[i].gc_close)/4;
      gha_output.gha_HA_arr[i].gha_high := max(gha_input.gha_candles[i].gc_high, (max(gha_output.gha_HA_arr[i].gha_open, gha_output.gha_HA_arr[i].gha_close )));
      gha_output.gha_HA_arr[i].gha_low := min(gha_input.gha_candles[i].gc_low, (min(gha_output.gha_HA_arr[i].gha_open, gha_output.gha_HA_arr[i].gha_close )));

      gha_output.gha_HA_arr[i].gha_time := gha_input.gha_candles[i].gc_time;
      inc(i);
   end;
end;

procedure Get_ATR(gatr_input : gatr_request; out gatr_output : gatr_response);
var
   count_candles, i : longint;
   TR : array of double;
   Av_TR : double;

begin

   count_candles := high(gatr_input.gatr_candles);
   i := 0;
   Av_TR := 0;

   SetLength(gatr_output.gatr_ATR_arr, count_candles + 1);

   SetLength(TR, count_candles + 1);

   while i <= count_candles do begin

      if i = 0 then begin
         TR[i] := abs(gatr_input.gatr_candles[0].gc_high - gatr_input.gatr_candles[0].gc_low);
      end;

      Av_TR := Av_TR + TR[i];

      if i > 0 then begin

         TR[i] := max( abs(gatr_input.gatr_candles[i].gc_high -  gatr_input.gatr_candles[i].gc_low),
         max( abs(gatr_input.gatr_candles[i].gc_low -  gatr_input.gatr_candles[i-1].gc_close), abs(gatr_input.gatr_candles[i].gc_high -  gatr_input.gatr_candles[i-1].gc_close) ));

         Av_TR := Av_TR + TR[i];

         if i = (gatr_input.gatr_period - 1) then begin
            gatr_output.gatr_ATR_arr[i].gatr_atr :=  Av_TR / gatr_input.gatr_period;
         end;

         if i >= gatr_input.gatr_period then begin
            gatr_output.gatr_ATR_arr[i].gatr_atr :=  (gatr_output.gatr_ATR_arr[i-1].gatr_atr * (gatr_input.gatr_period - 1) + TR[i]) / gatr_input.gatr_period ;
         end;
      end;
      gatr_output.gatr_ATR_arr[i].gatr_time := gatr_input.gatr_candles[i].gc_time;
      inc(i);
   end;
end;

procedure Get_MACD(gmacd_input : gmacd_request; out gmacd_output : gmacd_response);
var
   count_candles, i : longint;
   summ_ema1, summ_ema2, summ_ema3 : double;
   ema_fast, ema_slow : array of double;

begin

   summ_ema1 := 0;
   summ_ema2 := 0;
   summ_ema3 := 0;

   count_candles := high(gmacd_input.gmacd_candles);
   i := 0;

   SetLength(gmacd_output.gmacd_macd_arr, count_candles + 1);

   SetLength(ema_fast, count_candles + 1);
   SetLength(ema_slow, count_candles + 1);

   while i <= count_candles do begin

      // расчет быстрой EMA
      if i < gmacd_input.gmacd_fast_period  then begin
         summ_ema1 := summ_ema1 + gmacd_input.gmacd_candles[i].gc_close;
      end;

      if i = (gmacd_input.gmacd_fast_period - 1) then begin
         summ_ema1 := summ_ema1 / gmacd_input.gmacd_fast_period;
         ema_fast[i] := summ_ema1;
      end;

      if i > (gmacd_input.gmacd_fast_period - 1) then begin
         ema_fast[i] := gmacd_input.gmacd_candles[i].gc_close * (2 / (gmacd_input.gmacd_fast_period + 1)) + ema_fast[i - 1] * (1-(2 / (gmacd_input.gmacd_fast_period + 1)));
      end;

      // расчет медленной EMA и линии MACD
      if i < gmacd_input.gmacd_slow_period  then begin
         summ_ema2 := summ_ema2 + gmacd_input.gmacd_candles[i].gc_close;
      end;

      if i = (gmacd_input.gmacd_slow_period - 1) then begin
         summ_ema2 := summ_ema2 / gmacd_input.gmacd_slow_period;
         ema_slow[i] := summ_ema2;
         gmacd_output.gmacd_macd_arr[i].gmacd_macd_line := ema_fast[i] - ema_slow[i];
         summ_ema3 := summ_ema3 + gmacd_output.gmacd_macd_arr[i].gmacd_macd_line;
      end;

      if i > (gmacd_input.gmacd_slow_period - 1) then begin
         ema_slow[i] := gmacd_input.gmacd_candles[i].gc_close * (2 / (gmacd_input.gmacd_slow_period + 1)) + ema_slow[i - 1] * (1-(2 / (gmacd_input.gmacd_slow_period + 1)));
         gmacd_output.gmacd_macd_arr[i].gmacd_macd_line := ema_fast[i] - ema_slow[i];
         summ_ema3 := summ_ema3 + gmacd_output.gmacd_macd_arr[i].gmacd_macd_line;
      end;

      // расчет сигнальной линии MACD
      if i = (gmacd_input.gmacd_smoothing_period + gmacd_input.gmacd_slow_period - 2) then begin
         gmacd_output.gmacd_macd_arr[i].gmacd_signal_line := summ_ema3 / gmacd_input.gmacd_smoothing_period;
         gmacd_output.gmacd_macd_arr[i].gmacd_histogram := gmacd_output.gmacd_macd_arr[i].gmacd_macd_line - gmacd_output.gmacd_macd_arr[i].gmacd_signal_line;
      end;

      if i > (gmacd_input.gmacd_smoothing_period + gmacd_input.gmacd_slow_period - 2) then begin
         gmacd_output.gmacd_macd_arr[i].gmacd_signal_line := gmacd_output.gmacd_macd_arr[i].gmacd_macd_line * (2 / (gmacd_input.gmacd_smoothing_period + 1)) + gmacd_output.gmacd_macd_arr[i - 1].gmacd_signal_line * (1-(2 / (gmacd_input.gmacd_smoothing_period + 1)));
         gmacd_output.gmacd_macd_arr[i].gmacd_histogram := gmacd_output.gmacd_macd_arr[i].gmacd_macd_line - gmacd_output.gmacd_macd_arr[i].gmacd_signal_line;
      end;

      gmacd_output.gmacd_macd_arr[i].gmacd_time := gmacd_input.gmacd_candles[i].gc_time;
      inc(i);
   end;
end;


end.

