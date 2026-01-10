program tinvest_test;

{$mode objfpc}{$H+}

uses
  sysutils, tinvest_api_unit, additional_unit;

var
  gc_in : gc_request;
  gc_out : gc_response;
  i, gc_count : longint;

begin

   i := 0;

   gc_in.gc_token := 'your_token';
   gc_in.gc_from := '2025-12-22T00:00:00.00Z';
   gc_in.gc_to := '2025-12-26T23:00:00.00Z';
   gc_in.gc_interval := 'CANDLE_INTERVAL_5_MIN';
   gc_in.gc_instrumentId := '87db07bc-0e02-4e29-90bb-05e8ef791d7b';
   gc_in.gc_candleSourceType := 'CANDLE_SOURCE_UNSPECIFIED';
   gc_in.gc_limit := 100;

   GetExchangeCandles(gc_in, gc_out);

   gc_count := high(gc_out.gc_candles);

   while i <= gc_count do  begin

     Writeln( floattostr(gc_out.gc_candles[i].gc_open) + #9 + floattostr(gc_out.gc_candles[i].gc_high) + #9 + floattostr(gc_out.gc_candles[i].gc_low) + #9 +
             floattostr(gc_out.gc_candles[i].gc_close) + #9 + inttostr(gc_out.gc_candles[i].gc_volume) + #9 + ISOToLocalTime(gc_out.gc_candles[i].gc_time) + #9 +
             gc_out.gc_candles[i].gc_candleSource);

   inc(i);
   end;

  Readln();



end.
