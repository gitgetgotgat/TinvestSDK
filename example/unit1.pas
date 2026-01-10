unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls, FileUtil,
  additional_unit, tinvest_api_unit
  ;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnCancelOrder: TButton;
    btnGetAssetFundamentals: TButton;
    btnGetAssets: TButton;
    btnStructuredNotes: TButton;
    btnGetBrands: TButton;
    btnGetOperationsByCursor: TButton;
    btnGetLastPrices: TButton;
    btnGetInstrumentBy: TButton;
    btnGetCandles: TButton;
    btnFindInstrument: TButton;
    btnGetAccounts: TButton;
    btnGetBonds: TButton;
    btnGetLastTrades: TButton;
    btnGetTradingStatus: TButton;
    btnGetTechAnalysis: TButton;
    btnGetETFs: TButton;
    btnGetFutures: TButton;
    btnGetMaxLots: TButton;
    btnCancelStopOrder: TButton;
    btnGetIndicators: TButton;
    btnGetClosePrices: TButton;
    btnGetTradingStatuses: TButton;
    btnPostStopOrder: TButton;
    btnGetOrders: TButton;
    btnGetOrderState: TButton;
    btnGetOrderPrice: TButton;
    btnGetPortfolio: TButton;
    btnGetShares: TButton;
    btnPostOrder: TButton;
    btnGetOrderBook: TButton;
    btnGetStopOrders: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    cmbGetAssets1: TComboBox;
    cmbGetAssets2: TComboBox;
    cmbStructuredNotes2: TComboBox;
    cmbStructuredNotes1: TComboBox;
    cmbGetShares2: TComboBox;
    cmbGetShares1: TComboBox;
    cmbGetCandles2: TComboBox;
    cmbGetFutures1: TComboBox;
    cmbGetFutures2: TComboBox;
    cmbGetETFs1: TComboBox;
    cmbGetETFs2: TComboBox;
    cmbGetBonds1: TComboBox;
    cmbGetBonds2: TComboBox;
    cmbGetIndicators: TComboBox;
    cmbGetLastPrices2: TComboBox;
    cmbGetClosePrices: TComboBox;
    cmbPostOrder1: TComboBox;
    cmbGetTechAnalysis1: TComboBox;
    cmbGetStopOrders: TComboBox;
    cmbGetAccounts: TComboBox;
    cmbGetCandles1: TComboBox;
    cmbGetTechAnalysis2: TComboBox;
    cmbGetTechAnalysis3: TComboBox;
    cmbPostOrder2: TComboBox;
    cmbPostOrder3: TComboBox;
    cmbPostStopOrder1: TComboBox;
    cmbPostStopOrder2: TComboBox;
    cmbPostStopOrder3: TComboBox;
    cmbPostStopOrder4: TComboBox;
    cmbPostStopOrder5: TComboBox;
    cmbPostStopOrder6: TComboBox;
    cmbGetLastPrices1: TComboBox;
    edtGetBrands1: TEdit;
    edtGetBrands2: TEdit;
    Label1: TLabel;
    Label3: TLabel;
    memGetTradingStatuses: TMemo;
    memGetClosePrices: TMemo;
    memGetLastPrices: TMemo;
    memGetAssetFundamentals: TMemo;
    memGetOperationsByCursor1: TMemo;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet10: TTabSheet;
    TabSheet11: TTabSheet;
    TabSheet12: TTabSheet;
    TabSheet13: TTabSheet;
    TabSheet14: TTabSheet;
    TabSheet15: TTabSheet;
    TabSheet16: TTabSheet;
    TabSheet17: TTabSheet;
    TabSheet18: TTabSheet;
    TabSheet19: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet20: TTabSheet;
    TabSheet21: TTabSheet;
    TabSheet22: TTabSheet;
    TabSheet23: TTabSheet;
    TabSheet24: TTabSheet;
    TabSheet25: TTabSheet;
    TabSheet26: TTabSheet;
    TabSheet27: TTabSheet;
    TabSheet28: TTabSheet;
    TabSheet29: TTabSheet;
    TabSheet30: TTabSheet;
    TabSteet29: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    TabSheet6: TTabSheet;
    TabSheet7: TTabSheet;
    TabSheet8: TTabSheet;
    TabSheet9: TTabSheet;
    txtCancelOrder1: TEdit;
    txtCancelOrder2: TEdit;
    txtCancelStopOrder2: TEdit;
    txtGetOperationsByCursor2: TEdit;
    txtGetOperationsByCursor4: TEdit;
    txtGetOperationsByCursor3: TEdit;
    txtGetInstrumentBy: TEdit;
    txtGetCandles4: TEdit;
    txtFind: TEdit;
    txtGetCandles2: TEdit;
    txtGetLastTrades1: TEdit;
    txtGetLastTrades2: TEdit;
    txtGetLastTrades3: TEdit;
    txtGetTechAnalysis4: TEdit;
    txtGetTechAnalysis2: TEdit;
    txtGetTechAnalysis1: TEdit;
    txtGetMaxLots1: TEdit;
    txtGetMaxLots2: TEdit;
    txtGetMaxLots3: TEdit;
    txtGetStopOrders2: TEdit;
    txtGetStopOrders3: TEdit;
    txtCancelStopOrder1: TEdit;
    txtGetCandles1: TEdit;
    txtGetTechAnalysis3: TEdit;
    txtGetTechAnalysis5: TEdit;
    txtGetTechAnalysis6: TEdit;
    txtGetTechAnalysis7: TEdit;
    txtGetTechAnalysis8: TEdit;
    txtGetTradingStatus: TEdit;
    txtPostOrder5: TEdit;
    txtPostStopOrder3: TEdit;
    txtPostStopOrder2: TEdit;
    txtGetOrderPrice3: TEdit;
    txtGetOrderPrice2: TEdit;
    txtGetOrderPrice1: TEdit;
    txtGetOrderBook2: TEdit;
    txtGetOrderPrice4: TEdit;
    txtGetOrders: TEdit;
    txtGetOrderState1: TEdit;
    txtGetOrderState2: TEdit;
    txtGetPortfolio: TEdit;
    Label2: TLabel;
    txtPostOrder1: TEdit;
    txtGetOrderBook1: TEdit;
    txtPostOrder2: TEdit;
    txtPostOrder3: TEdit;
    txtPostOrder4: TEdit;
    txtPostStopOrder1: TEdit;
    txtPostStopOrder4: TEdit;
    txtPostStopOrder5: TEdit;
    txtGetStopOrders1: TEdit;
    txtGetCandles3: TEdit;
    txtPostStopOrder6: TEdit;
    txtPostStopOrder7: TEdit;
    txtGetOperationsByCursor1: TEdit;
    txtToken: TEdit;
    Memo1: TMemo;
    procedure btnCancelOrderClick(Sender: TObject);
    procedure btnCancelStopOrderClick(Sender: TObject);
    procedure btnGetAssetsClick(Sender: TObject);
    procedure btnGetBrandsClick(Sender: TObject);
    procedure btnGetCandlesClick(Sender: TObject);
    procedure btnGetClosePricesClick(Sender: TObject);
    procedure btnGetFuturesClick(Sender: TObject);
    procedure btnGetInstrumentByClick(Sender: TObject);
    procedure btnGetAssetFundamentalsClick(Sender: TObject);
    procedure btnGetLastPricesClick(Sender: TObject);
    procedure btnGetMaxLotsClick(Sender: TObject);
    procedure btnGetLastTradesClick(Sender: TObject);
    procedure btnGetOperationsByCursorClick(Sender: TObject);
    procedure btnGetOrderBookClick(Sender: TObject);
    procedure btnGetOrderPriceClick(Sender: TObject);
    procedure btnGetOrdersClick(Sender: TObject);
    procedure btnGetOrderStateClick(Sender: TObject);
    procedure btnGetSharesClick(Sender: TObject);
    procedure btnGetAccountsClick(Sender: TObject);
    procedure btnGetPortfolioClick(Sender: TObject);
    procedure btnGetBondsClick(Sender: TObject);
    procedure btnGetETFsClick(Sender: TObject);
    procedure btnFindInstrumentClick(Sender: TObject);
    procedure btnGetStopOrdersClick(Sender: TObject);
    procedure btnGetIndicatorsClick(Sender: TObject);
    procedure btnGetTechAnalysisClick(Sender: TObject);
    procedure btnGetTradingStatusClick(Sender: TObject);
    procedure btnGetTradingStatusesClick(Sender: TObject);
    procedure btnPostOrderClick(Sender: TObject);
    procedure btnPostStopOrderClick(Sender: TObject);
    procedure btnStructuredNotesClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure txtPostOrder5Click(Sender: TObject);
    procedure txtPostStopOrder6Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

  ga_in  : ga_request;
  ga_out : ga_response;

  gi_in  : gi_request;
  gi_out : gi_response;

  gma_in  : gma_request;
  gma_out : gma_response;

  cfg_in  : cfg_request;
  cfg_out : cfg_response;

  gfg_in  : gfg_request;
  gfg_out : gfg_response;

  gai_in  : gai_request;
  gai_out : gai_response;

  ts_in  : ts_request;
  ts_out : ts_response;

  gut_in  : gut_request;
  gut_out : gut_response;

  gba_in  : gba_request;
  gba_out : gba_response;

  gp_in  : gp_request;
  gp_out : gp_response;

  gobc_in  : gobc_request;
  gobc_out : gobc_response;

  glt_in : glt_request;
  glt_out : glt_response;

  po_in  : po_request;
  po_out : po_response;

  co_in  : co_request;
  co_out : co_response;

  gml_in  : gml_request;
  gml_out : gml_response;

  gos_in  : gos_request;
  gos_out : gos_response;

  go_in  : go_request;
  go_out : go_response;

  gop_in  : gop_request;
  gop_out : gop_response;

  gc_in  : gc_request;
  gc_out : gc_response;
  conv_out : gc_response;

  gob_in  : gob_request;
  gob_out : gob_response;

  gts_in  : gts_request;
  gts_out : gts_response;

  gtss_in  : gtss_request;
  gtss_out : gtss_response;

  gta_in  : gta_request;
  gta_out : gta_response;

  s_in  : s_request;
  s_out : s_response;

  b_in  : b_request;
  b_out : b_response;

  c_in  : c_request;
  c_out : c_response;

  cb_in  : cb_request;
  cb_out : cb_response;

  gbc_in  : gbc_request;
  gbc_out : gbc_response;

  gbe_in  : gbe_request;
  gbe_out : gbe_response;

  gaf_in  : gaf_request;
  gaf_out : gaf_response;

  gas_in  : gas_request;
  gas_out : gas_response;

  gar_in  : gar_request;
  gar_out : gar_response;

  gep_in  : gep_request;
  gep_out : gep_response;

  gb_in  : gb_request;
  gb_out : gb_response;

  gbb_in  : gbb_request;
  gbb_out : gbb_response;

  ges_in  : ges_request;
  ges_out : ges_response;

  gsi_in  : gsi_request;
  gsi_out : gsi_response;

  cut_in  : cut_request;
  cut_out : cut_response;

  gwl_in  : gwl_request;
  gwl_out : gwl_response;

  gbr_in  : gbr_request;
  gbr_out : gbr_response;

  ind_in  : ind_request;
  ind_out : ind_response;

  gco_in  : gco_request;
  gco_out : gco_response;

  f_in  : f_request;
  f_out : f_response;

  e_in  : e_request;
  e_out : e_response;

  fi_in  : fi_request;
  fi_out : fi_response;

  pso_in  : pso_request;
  pso_out : pso_response;

  gso_in  : gso_request;
  gso_out : gso_response;

  cso_in  : cso_request;
  cso_out : cso_response;

  gfm_in  : gfm_request;
  gfm_out : gfm_response;

  gfb_in  : gfb_request;
  gfb_out : gfb_response;

  grr_in  : grr_request;
  grr_out : grr_response;

  gcf_in  : gcf_request;
  gcf_out : gcf_response;

  snb_in  : snb_request;
  snb_out : snb_response;

  gdfi_in  : gdfi_request;
  gdfi_out : gdfi_response;

  o_in  : o_request;
  o_out : o_response;

  ob_in  : ob_request;
  ob_out : ob_response;

  gid_in  : gid_request;
  gid_out : gid_response;

  ef_in  : ef_request;
  ef_out : ef_response;

  gf_in  : gf_request;
  gf_out : gf_response;

  gab_in  : gab_request;
  gab_out : gab_response;

  gd_in  : gd_request;
  gd_out : gd_response;

  geo_in  : geo_request;
  geo_out : geo_response;

  gmv_in  : gmv_request;
  gmv_out : gmv_response;

  gema_in : gema_request;
  gema_out : gema_response;

  grsi_in : grsi_request;
  grsi_out : grsi_response;

  gha_in : gha_request;
  gha_out : gha_response;

  sn_in : sn_request;
  sn_out : sn_response;

  gatr_in : gatr_request;
  gatr_out : gatr_response;

  gmacd_in : gmacd_request;
  gmacd_out : gmacd_response;

  gib_in : gib_request;
  gib_out : gib_response;

  gcp_in : gcp_request;
  gcp_out : gcp_response;

  glp_in : glp_request;
  glp_out : glp_response;


implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnGetSharesClick(Sender: TObject);
var

i, s_count : longint;

begin
  i := 0;

  s_in.s_token := txtToken.Text;
  s_in.s_instrumentStatus := cmbGetShares1.Text;
  s_in.s_instrumentExchange := cmbGetShares2.Text;

  memo1.Text := '';
  GetShares(s_in, s_out);

  s_count := high(s_out.s_instruments);

  memo1.Lines.BeginUpdate;

  while i <= s_count do  begin

  memo1.Lines.add(inttostr(i) + #9 + s_out.s_instruments[i].s_isin + #9 +
                                     s_out.s_instruments[i].s_ticker + #9 +
                                     s_out.s_instruments[i].s_exchange + #9 +
                                     s_out.s_instruments[i].s_figi + #9 +
                                     s_out.s_instruments[i].s_uid + #9 +
                                     'lots: ' + #9 + inttostr(s_out.s_instruments[i].s_lot) + #9 +
                                     s_out.s_instruments[i].s_name + #9 +
                                     booltostr(s_out.s_instruments[i].s_buyAvailableFlag, 'true', 'false') + #9 +
                                     booltostr(s_out.s_instruments[i].s_sellAvailableFlag, 'true', 'false') + #9 +
                                     'Asset: ' + s_out.s_instruments[i].s_assetUid
                                     );

  inc(i);
  end;

  memo1.Lines.EndUpdate;

end;

procedure TForm1.btnGetFuturesClick(Sender: TObject);
var

i, f_count : longint;

begin
  i := 0;

  f_in.f_token := txtToken.Text;
  f_in.f_instrumentStatus := cmbGetFutures1.Text;
  f_in.f_instrumentExchange := cmbGetFutures2.Text;

  memo1.Text := '';
  GetFutures(f_in, f_out);

  f_count := high(f_out.f_instruments);


  memo1.Lines.BeginUpdate;

  while i <= f_count do  begin

        memo1.Lines.add(inttostr(i) + #9 + f_out.f_instruments[i].f_figi + #9 +
                                           f_out.f_instruments[i].f_uid + #9 +
                                           'lots: ' + #9 + inttostr(f_out.f_instruments[i].f_lot) + #9 +
                                           f_out.f_instruments[i].f_exchange + #9 +
                                           f_out.f_instruments[i].f_name + #9 +
                                           'шаг цены: ' + floattostr(f_out.f_instruments[i].f_minPriceIncrement) + #9 +
                                           'стоимость шага цены: ' + floattostr(f_out.f_instruments[i].f_minPriceIncrementAmount) + #9 +
                                           booltostr(f_out.f_instruments[i].f_buyAvailableFlag, 'true', 'false') + #9 +
                                           booltostr(f_out.f_instruments[i].f_sellAvailableFlag, 'true', 'false')
                                           );

  inc(i);
  end;

  memo1.Lines.EndUpdate;


end;

procedure TForm1.btnGetInstrumentByClick(Sender: TObject);
begin

  gib_in.gib_token := txtToken.Text;
  gib_in.gib_idType := 'INSTRUMENT_ID_TYPE_UID';
  gib_in.gib_id := txtGetInstrumentBy.Text;

  GetInstrumentBy(gib_in, gib_out);

  memo1.Text := gib_out.gib_instrument.gib_figi + #13 +
                gib_out.gib_instrument.gib_ticker + #13 +
                gib_out.gib_instrument.gib_classCode + #13 +
                gib_out.gib_instrument.gib_isin + #13 +
                inttostr(gib_out.gib_instrument.gib_lot) + #13 +
                gib_out.gib_instrument.gib_currency + #13 +
                floattostr(gib_out.gib_instrument.gib_klong) + #13 +
                floattostr(gib_out.gib_instrument.gib_kshort) + #13 +
                floattostr(gib_out.gib_instrument.gib_dlong) + #13 +
                floattostr(gib_out.gib_instrument.gib_dshort) + #13 +
                floattostr(gib_out.gib_instrument.gib_dlongMin) + #13 +
                floattostr(gib_out.gib_instrument.gib_dshortMin) + #13 +
                booltostr(gib_out.gib_instrument.gib_shortEnabledFlag, 'true', 'false') + #13 +
                gib_out.gib_instrument.gib_name + #13 +
                gib_out.gib_instrument.gib_exchange + #13 +
                gib_out.gib_instrument.gib_countryOfRisk + #13 +
                gib_out.gib_instrument.gib_countryOfRiskName + #13 +
                gib_out.gib_instrument.gib_instrumentType + #13 +
                gib_out.gib_instrument.gib_tradingStatus + #13 +
                booltostr(gib_out.gib_instrument.gib_otcFlag, 'true', 'false') + #13 +
                booltostr(gib_out.gib_instrument.gib_buyAvailableFlag, 'true', 'false') + #13 +
                booltostr(gib_out.gib_instrument.gib_sellAvailableFlag, 'true', 'false') + #13 +
                floattostr(gib_out.gib_instrument.gib_minPriceIncrement) + #13 +
                booltostr(gib_out.gib_instrument.gib_apiTradeAvailableFlag, 'true', 'false') + #13 +
                gib_out.gib_instrument.gib_uid + #13 +
                gib_out.gib_instrument.gib_realExchange + #13 +
                gib_out.gib_instrument.gib_positionUid + #13 +
                gib_out.gib_instrument.gib_assetUid + #13 +
                booltostr(gib_out.gib_instrument.gib_forIisFlag, 'true', 'false') + #13 +
                booltostr(gib_out.gib_instrument.gib_forQualInvestorFlag, 'true', 'false') + #13 +
                booltostr(gib_out.gib_instrument.gib_weekendFlag, 'true', 'false') + #13 +
                booltostr(gib_out.gib_instrument.gib_blockedTcaFlag, 'true', 'false') + #13 +
                gib_out.gib_instrument.gib_instrumentKind + #13 +
                gib_out.gib_instrument.gib_first1minCandleDate + #13 +
                gib_out.gib_instrument.gib_first1dayCandleDate + #13 +
                gib_out.gib_instrument.gib_brand.gib_logoName + #13 +
                gib_out.gib_instrument.gib_brand.gib_logoBaseColor + #13 +
                gib_out.gib_instrument.gib_brand.gib_textColor + #13 +
                floattostr(gib_out.gib_instrument.gib_dlongClient) + #13 +
                floattostr(gib_out.gib_instrument.gib_dshortClient) + #13 +

                ''
                ;

end;

procedure TForm1.btnGetAssetFundamentalsClick(Sender: TObject);
var
i, count_assets : longint;

begin
  count_assets := 0;
  i := 0;
  memo1.Clear;
  gaf_in.gaf_token := txtToken.Text;

  count_assets := memGetAssetFundamentals.Lines.Count;

  SetLength(gaf_in.gaf_assets, count_assets);

  while i < count_assets do  begin

     if memGetAssetFundamentals.Lines[i] <> '' then gaf_in.gaf_assets[i] := memGetAssetFundamentals.Lines[i];

     inc(i);
  end;

  GetAssetFundamentals(gaf_in, gaf_out);


end;

procedure TForm1.btnGetLastPricesClick(Sender: TObject);
var
i, count_uids : longint;

begin
  count_uids := 0;
  i := 0;
  memo1.Clear;

  glp_in.glp_token := txtToken.Text;
  glp_in.glp_lastPriceType := cmbGetLastPrices1.Text;
  glp_in.glp_instrumentStatus := cmbGetLastPrices2.Text;

  count_uids := memGetLastPrices.Lines.Count;

  SetLength(glp_in.glp_instruments, count_uids);

  for i := 0 to (count_uids-1) do glp_in.glp_instruments[i].glp_instrumentId := memGetLastPrices.Lines[i];

  GetLastPrices(glp_in, glp_out);

  i := 0;

  for i := 0 to (count_uids-1) do begin
     memo1.Lines.add(glp_out.glp_lastPrices[i].glp_figi + #9 +
                     glp_out.glp_lastPrices[i].glp_instrumentUid + #9 +
                     floattostr(glp_out.glp_lastPrices[i].glp_price) + #9 +
                     glp_out.glp_lastPrices[i].glp_lastPriceType + #9 +
                     glp_out.glp_lastPrices[i].glp_time
     );

  end;



end;

procedure TForm1.btnGetMaxLotsClick(Sender: TObject);

begin
  gml_in.gml_token := txtToken.Text;
  gml_in.gml_accountId := txtGetMaxLots1.Text;
  gml_in.gml_instrumentId := txtGetMaxLots2.Text;
  gml_in.gml_price := strtofloat(txtGetMaxLots3.Text);

  GetMaxLots(gml_in, gml_out);

  memo1.Text := inttostr(gml_out.gml_buyLimits.gml_buyMaxLots);

end;

procedure TForm1.btnGetLastTradesClick(Sender: TObject);
var
i, count_types : longint;

begin
  count_types := 0;
  i := 0;
  memo1.Clear;
  glt_in.glt_token := txtToken.Text;
  glt_in.glt_from := txtGetLastTrades2.Text;
  glt_in.glt_to := txtGetLastTrades3.Text;
  glt_in.glt_instrumentId := txtGetLastTrades1.Text;

  GetLastTrades(glt_in, glt_out);

  count_types := high(glt_out.glt_trades);

  memo1.Lines.BeginUpdate;
  while i <= count_types do  begin

        memo1.Lines.add(inttostr(i) + #9 + glt_out.glt_trades[i].glt_instrumentUid + #9 + floattostr(glt_out.glt_trades[i].glt_price)

                                           );

  inc(i);
  end;
  memo1.Lines.EndUpdate;


end;

procedure TForm1.btnGetOperationsByCursorClick(Sender: TObject);
var
i, count_types : longint;
operations_count : int64;

begin
  count_types := 0;
  operations_count := 0;


  memo1.Clear;

  gobc_in.gobc_token := txtToken.Text;
  gobc_in.gobc_accountId := txtGetOperationsByCursor1.Text;
  gobc_in.gobc_instrumentId := txtGetOperationsByCursor2.Text;
  gobc_in.gobc_from := txtGetOperationsByCursor3.Text;
  gobc_in.gobc_to := txtGetOperationsByCursor4.Text;
  gobc_in.gobc_cursor := '0';
  gobc_in.gobc_limit := 1000;



  count_types := memGetOperationsByCursor1.Lines.Count;

  SetLength(gobc_in.gobc_operationTypes, count_types);

  for i := 0 to (count_types-1) do gobc_in.gobc_operationTypes[i].gobc_type := memGetOperationsByCursor1.Lines[i];

  GetOperationsByCursor(gobc_in, gobc_out);

  operations_count := high(gobc_out.gobc_items);

  memo1.Lines.BeginUpdate;
  for i := 0 to (operations_count) do begin
     memo1.Lines.add(gobc_out.gobc_items[i].gobc_instrumentUid + #9 +
                     floattostr(gobc_out.gobc_items[i].gobc_price.moneyval) + #9 +
                     gobc_out.gobc_items[i].gobc_state + #9 +
                     gobc_out.gobc_items[i].gobc_ticker + #9 +
                     gobc_out.gobc_items[i].gobc_date
     );

  end;
  memo1.Lines.EndUpdate;

end;

procedure TForm1.btnGetOrderBookClick(Sender: TObject);
var

i, gob_count : longint;
gts_in  : gts_request;
gts_out : gts_response;

begin
  FillByte(gts_out, SizeOf(gts_out), 0);

  gob_count := 0;

  memo1.Text := '';

  gob_in.gob_token := txtToken.Text;
  gob_in.gob_depth := strtoint(txtGetOrderBook1.Text);
  gob_in.gob_instrumentId := txtGetOrderBook2.Text;

  gts_in.gts_token := gob_in.gob_token;
  gts_in.gts_instrumentId := gob_in.gob_instrumentId;

  GetTradingStatus(gts_in, gts_out);

  if gts_out.gts_tradingStatus = 'SECURITY_TRADING_STATUS_NORMAL_TRADING' then begin
  GetOrderBook(gob_in, gob_out);

  gob_count := gob_out.gob_depth - 1;
  i := gob_count;

  memo1.Lines.BeginUpdate;

  while i >= 0 do  begin

     memo1.Lines.add( floattostr(gob_out.gob_asks[i].gob_price) + #9 + inttostr(gob_out.gob_asks[i].gob_quantity));

  dec(i);
  end;

  memo1.Text := memo1.Text + '- spread -' + #13;

  i := 0;

  while i <= gob_count do  begin

     memo1.Lines.add( floattostr(gob_out.gob_bids[i].gob_price) + #9 + inttostr(gob_out.gob_bids[i].gob_quantity));

  inc(i);
  end;

  memo1.Lines.EndUpdate;

  memo1.Text := memo1.Text + '-' + #13;

  memo1.Text := memo1.Text + floattostr(gob_out.gob_minask.gob_price) + #13;
  memo1.Text := memo1.Text + floattostr(gob_out.gob_maxbid.gob_price) + #13;

  memo1.Text := memo1.Text + 'Limit UP: ' + floattostr(gob_out.gob_limitUp) + #13;
  memo1.Text := memo1.Text + 'Limit DOWN: ' + floattostr(gob_out.gob_limitDown) + #13;

end;
end;

procedure TForm1.btnGetOrderPriceClick(Sender: TObject);

begin
  gop_in.gop_token := txtToken.Text;
  gop_in.gop_accountId := txtGetOrderPrice1.Text;
  gop_in.gop_instrumentId := txtGetOrderPrice2.Text;
  gop_in.gop_price := strtofloat(txtGetOrderPrice3.Text);
  gop_in.gop_quantity := strtoint(txtGetOrderPrice4.Text);
  gop_in.gop_direction := 'ORDER_DIRECTION_BUY';

  GetOrderPrice(gop_in, gop_out);

  memo1.Text := floattostr(gop_out.gop_totalOrderAmount.moneyval) + #13 + inttostr(gop_out.gop_error_code);

end;

procedure TForm1.btnCancelOrderClick(Sender: TObject);


begin
  co_in.co_token := txtToken.Text;
  co_in.co_accountId := txtCancelOrder1.Text;
  co_in.co_orderId := txtCancelOrder2.Text;
  co_in.co_orderIdType := 'ORDER_ID_TYPE_EXCHANGE';

  CancelOrder(co_in, co_out);

  memo1.Text := co_out.co_time + #13 + co_out.co_responseMetadata.po_trackingId + #13 + inttostr(co_out.co_error_code) ;

end;

procedure TForm1.btnCancelStopOrderClick(Sender: TObject);

begin
  cso_in.cso_token := txtToken.Text;
  cso_in.cso_accountId := txtCancelStopOrder1.Text;
  cso_in.cso_stopOrderId := txtCancelStopOrder2.Text;

  CancelStopOrder(cso_in, cso_out);

  memo1.Text := cso_out.cso_time + #13 + inttostr(cso_out.cso_error_code);
end;

procedure TForm1.btnGetAssetsClick(Sender: TObject);
var

i, a_count : longint;

begin
  i := 0;

  gas_in.gas_token := txtToken.Text;
  gas_in.gas_instrumentStatus := cmbGetAssets1.Text;
  gas_in.gas_instrumentType := cmbGetAssets2.Text;

  memo1.Text := '';
  GetAssets(gas_in, gas_out);

  a_count := high(gas_out.gas_assets);

  memo1.Lines.BeginUpdate;

  while i <= a_count do  begin

        memo1.Lines.add(inttostr(i) + #9 + gas_out.gas_assets[i].gas_uid + #9 +
                                           gas_out.gas_assets[i].gas_type + #9 +
                                           gas_out.gas_assets[i].gas_name + #9

                                           );

  inc(i);
  end;

  memo1.Lines.EndUpdate;

end;

procedure TForm1.btnGetBrandsClick(Sender: TObject);
var
i, brands_count : longint;

begin
  memo1.Text := '';
  i := 0;


  gb_in.gb_token := txtToken.Text;
  gb_in.gb_paging.gb_limit := strtoint(edtGetBrands1.Text);
  gb_in.gb_paging.gb_pageNumber := strtoint(edtGetBrands2.Text);


  GetBrands(gb_in, gb_out);

  brands_count := high(gb_out.gb_brands);

  memo1.Lines.BeginUpdate;

  while i <= brands_count do  begin

    memo1.Lines.add( gb_out.gb_brands[i].gb_uid + #9 + gb_out.gb_brands[i].gb_name + #9 + gb_out.gb_brands[i].gb_description + #9 + gb_out.gb_brands[i].gb_info + #9 +
                     gb_out.gb_brands[i].gb_company  + #9 + gb_out.gb_brands[i].gb_sector );

  inc(i);
  end;

  memo1.Lines.EndUpdate;



end;

procedure TForm1.btnGetCandlesClick(Sender: TObject);
var

i, gc_count : longint;

begin
  memo1.Text := '';
  i := 0;

  gc_in.gc_token := txtToken.Text;
  gc_in.gc_from := txtGetCandles1.Text;
  gc_in.gc_to := txtGetCandles2.Text;
  gc_in.gc_interval := cmbGetCandles1.Text;
  gc_in.gc_instrumentId := txtGetCandles3.Text;
  gc_in.gc_candleSourceType := cmbGetCandles2.Text;
  if txtGetCandles4.Text <> '' then gc_in.gc_limit := strtoint(txtGetCandles4.Text);

  GetExchangeCandles(gc_in, gc_out);

  gc_count := high(gc_out.gc_candles);


  memo1.Lines.BeginUpdate;

  while i <= gc_count do  begin

    memo1.Lines.add( floattostr(gc_out.gc_candles[i].gc_open) + #9 + floattostr(gc_out.gc_candles[i].gc_high) + #9 + floattostr(gc_out.gc_candles[i].gc_low) + #9 +
                  floattostr(gc_out.gc_candles[i].gc_close) + #9 + inttostr(gc_out.gc_candles[i].gc_volume) + #9 + ISOToLocalTime(gc_out.gc_candles[i].gc_time) + #9 + gc_out.gc_candles[i].gc_candleSource);

  inc(i);
  end;

  memo1.Lines.EndUpdate;

end;

procedure TForm1.btnGetClosePricesClick(Sender: TObject);
var
i, count_uids : longint;

begin
   i := 0;
   memo1.Clear;

   gcp_in.gcp_token := txtToken.Text;
   gcp_in.gcp_instrumentStatus := cmbGetClosePrices.Text;
   count_uids := memGetClosePrices.Lines.Count;

   SetLength(gcp_in.gcp_instruments, count_uids);

   for i := 0 to (count_uids-1) do gcp_in.gcp_instruments[i].gcp_instrumentId := memGetClosePrices.Lines[i];

   GetClosePrices(gcp_in, gcp_out);

   i := 0;

   for i := 0 to (count_uids-1) do begin
      memo1.Lines.add(gcp_out.gcp_closePrices[i].gcp_figi + #9 +
                      gcp_out.gcp_closePrices[i].gcp_instrumentUid + #9 +
                      floattostr(gcp_out.gcp_closePrices[i].gcp_price) + #9 +
                      floattostr(gcp_out.gcp_closePrices[i].gcp_eveningSessionPrice) + #9 +
                      gcp_out.gcp_closePrices[i].gcp_time
      );

   end;

end;

procedure TForm1.btnGetOrdersClick(Sender: TObject);
var
i, go_count : longint;

begin
  i := 0;

  go_in.go_token := txtToken.Text;
  go_in.go_accountId := txtGetOrders.text;

  GetOrders(go_in, go_out);

  go_count := high(go_out.go_orders);
  memo1.Text := '';

  while i <= go_count do  begin

     memo1.Text := memo1.Text + go_out.go_orders[i].go_orderId + #9 + go_out.go_orders[i].go_figi + #9 + go_out.go_orders[i].go_orderDate + #13;

  inc(i);
  end;

end;

procedure TForm1.btnGetOrderStateClick(Sender: TObject);

begin
  gos_in.gos_token := txtToken.Text;
  gos_in.gos_accountId := txtGetOrderState1.Text;
  gos_in.gos_orderId := txtGetOrderState2.Text;
  gos_in.gos_priceType := 'PRICE_TYPE_UNSPECIFIED';
  gos_in.gos_orderIdType := 'ORDER_ID_TYPE_UNSPECIFIED';

  GetOrderState(gos_in, gos_out);

  memo1.Text := 'Order_ID: ' + gos_out.gos_orderId + #13 +
                'Date: ' + ISOToLocalTime(gos_out.gos_orderDate) + #13 +
                'orderRequestId: ' + gos_out.gos_orderRequestId + #13 +
                'Instrument UID: ' + gos_out.gos_instrumentUid + #13 +
                'Order type: ' + gos_out.gos_orderType + #13 +
                'Status: ' + gos_out.gos_executionReportStatus + #13 +
                'Total order amount: ' + floattostr(gos_out.gos_totalOrderAmount.moneyval) + #13
  ;



end;

procedure TForm1.btnGetAccountsClick(Sender: TObject);
var

i, ga_count : longint;

begin
  i := 0;
  ga_in.ga_token := txtToken.Text;

  ga_in.ga_status := cmbGetAccounts.Text;

  GetAccounts(ga_in, ga_out);

  ga_count := high(ga_out.ga_accounts);

  memo1.Text := '';

  while i <= ga_count do  begin

     memo1.Text := memo1.Text + ga_out.ga_accounts[i].ga_id + #9 + ga_out.ga_accounts[i].ga_name + #13 ;

  inc(i);
  end;

end;

procedure TForm1.btnGetPortfolioClick(Sender: TObject);
var

i, gp_count : longint;

begin
  i := 0;
  gp_in.gp_token := txtToken.Text;
  gp_in.gp_accountId := txtGetPortfolio.Text;
  gp_in.gp_currency := 'RUB';

  GetPortfolio(gp_in, gp_out);

  gp_count := high(gp_out.gp_positions);

  memo1.Text := floattostr(gp_out.gp_totalAmountPortfolio.moneyval);

  memo1.Lines.BeginUpdate;

  while i <= gp_count do  begin

        memo1.Lines.add(inttostr(i) + #9 + gp_out.gp_positions[i].gp_instrumentUid + #9 + inttostr(gp_out.gp_positions[i].gp_quantity) + #9 +
                        floattostr(gp_out.gp_positions[i].gp_averagePositionPrice.moneyval) + #9 +  floattostr(gp_out.gp_positions[i].gp_currentPrice.moneyval) + #9 +
                        floattostr(gp_out.gp_positions[i].gp_expectedYield) + #9 + gp_out.gp_positions[i].gp_instrumentType );

  inc(i);
  end;
  memo1.Lines.EndUpdate;

end;

procedure TForm1.btnGetBondsClick(Sender: TObject);
var

i, b_count : longint;

begin
  i := 0;

  b_in.b_token := txtToken.Text;
  b_in.b_instrumentStatus := cmbGetBonds1.Text;
  b_in.b_instrumentExchange := cmbGetBonds2.Text;

  memo1.Text := '';
  GetBonds(b_in, b_out);

  b_count := high(b_out.b_instruments);

  memo1.Lines.BeginUpdate;

  while i <= b_count do  begin

        memo1.Lines.add(inttostr(i) + #9 + b_out.b_instruments[i].b_isin + #9 +
                                           b_out.b_instruments[i].b_ticker + #9 +
                                           b_out.b_instruments[i].b_exchange + #9 +
                                           b_out.b_instruments[i].b_figi + #9 +
                                           b_out.b_instruments[i].b_uid + #9 +
                                           'lots: ' + #9 + inttostr(b_out.b_instruments[i].b_lot) + #9 +
                                           b_out.b_instruments[i].b_name  + #9 +
                                           b_out.b_instruments[i].b_riskLevel  + #9 +
                                           b_out.b_instruments[i].b_placementDate  + #9 +
                                           b_out.b_instruments[i].b_maturityDate  + #9 +
                                           inttostr(b_out.b_instruments[i].b_couponQuantityPerYear)  + #9 +
                                           booltostr(b_out.b_instruments[i].b_buyAvailableFlag, 'true', 'false') + #9 +
                                           booltostr(b_out.b_instruments[i].b_sellAvailableFlag, 'true', 'false') + #9 +
                                           'Asset: ' + b_out.b_instruments[i].b_assetUid
                                           );

  inc(i);
  end;

  memo1.Lines.EndUpdate;


end;

procedure TForm1.btnGetETFsClick(Sender: TObject);
var

i, e_count : longint;

begin
  i := 0;

  e_in.e_token := txtToken.Text;
  e_in.e_instrumentStatus := cmbGetETFs1.Text;
  e_in.e_instrumentExchange := cmbGetETFs2.Text;

  memo1.Text := '';
  GetETFs(e_in, e_out);


  e_count := high(e_out.e_instruments);

  memo1.Lines.BeginUpdate;

  while i <= e_count do  begin

  memo1.Lines.add(inttostr(i) + #9 + e_out.e_instruments[i].e_isin + #9 +
                                     e_out.e_instruments[i].e_ticker + #9 +
                                     e_out.e_instruments[i].e_exchange + #9 +
                                     e_out.e_instruments[i].e_figi + #9 +
                                     e_out.e_instruments[i].e_uid + #9 +
                                     'lots: ' + #9 + inttostr(e_out.e_instruments[i].e_lot) + #9 +
                                     e_out.e_instruments[i].e_name + #9 +
                                     booltostr(e_out.e_instruments[i].e_buyAvailableFlag, 'true', 'false') + #9 +
                                     booltostr(e_out.e_instruments[i].e_sellAvailableFlag, 'true', 'false')
                                     );

  inc(i);
  end;

  memo1.Lines.EndUpdate;


end;

procedure TForm1.btnFindInstrumentClick(Sender: TObject);
var

i, fi_count : longint;

begin
  i := 0;
  fi_in.fi_token := txtToken.Text;
  fi_in.fi_query := txtFind.Text;
  fi_in.fi_instrumentKind := 'INSTRUMENT_TYPE_UNSPECIFIED';
  fi_in.fi_apiTradeAvailableFlag := true;

  memo1.Text := '';

  FindInstrument(fi_in, fi_out);

  fi_count := high(fi_out.fi_instruments);

  memo1.Lines.BeginUpdate;

  while i <= fi_count do  begin
        if fi_out.fi_instruments[i].fi_isin = '' then fi_out.fi_instruments[i].fi_isin := #9;


        memo1.Lines.add(inttostr(i) + #9 +
                        fi_out.fi_instruments[i].fi_isin + #9 +
                        fi_out.fi_instruments[i].fi_figi + #9 +
                        fi_out.fi_instruments[i].fi_ticker + #9 +
                        fi_out.fi_instruments[i].fi_classCode + #9 +
                        fi_out.fi_instruments[i].fi_instrumentType + #9 +
                        fi_out.fi_instruments[i].fi_name + #9 +
                        fi_out.fi_instruments[i].fi_uid + #9 +
                        fi_out.fi_instruments[i].fi_positionUid + #9 +
                        fi_out.fi_instruments[i].fi_instrumentKind + #9 +
                        booltostr(fi_out.fi_instruments[i].fi_apiTradeAvailableFlag, 'true', 'false') + #9 +
                        booltostr(fi_out.fi_instruments[i].fi_forIisFlag, 'true', 'false') + #9 +
                        fi_out.fi_instruments[i].fi_first1minCandleDate + #9 +
                        fi_out.fi_instruments[i].fi_first1dayCandleDate + #9 +
                        booltostr(fi_out.fi_instruments[i].fi_forQualInvestorFlag, 'true', 'false') + #9 +
                        booltostr(fi_out.fi_instruments[i].fi_weekendFlag, 'true', 'false') + #9 +
                        booltostr(fi_out.fi_instruments[i].fi_blockedTcaFlag, 'true', 'false') + #9 +
                        inttostr(fi_out.fi_instruments[i].fi_lot)
                        );

  inc(i);
  end;

  memo1.Lines.EndUpdate;


end;

procedure TForm1.btnGetStopOrdersClick(Sender: TObject);
var

  i, gso_count : longint;

begin
  i := 0;
  gso_in.gso_token := txtToken.Text;
  gso_in.gso_accountId := txtGetStopOrders1.Text;
  gso_in.gso_status := cmbGetStopOrders.Text;
  gso_in.gso_from := txtGetStopOrders2.Text;
  gso_in.gso_to := txtGetStopOrders3.Text;

  memo1.Text := '';

  GetStopOrders(gso_in, gso_out);

  gso_count := high(gso_out.gso_stopOrders);

  memo1.Lines.BeginUpdate;

  while i <= gso_count do  begin

        memo1.Lines.add(inttostr(i) + #9 + gso_out.gso_stopOrders[i].gso_stopOrderId + #9 +
                                           inttostr(gso_out.gso_stopOrders[i].gso_lotsRequested)  + #9 +
                                           gso_out.gso_stopOrders[i].gso_figi + #9 +
                                           gso_out.gso_stopOrders[i].gso_direction + #9 +
                                           gso_out.gso_stopOrders[i].gso_currency + #9 +
                                           gso_out.gso_stopOrders[i].gso_orderType + #9 +
                                           gso_out.gso_stopOrders[i].gso_createDate + #9 +
                                           gso_out.gso_stopOrders[i].gso_activationDateTime + #9 +
                                           gso_out.gso_stopOrders[i].gso_expirationTime + #9 +
                                           floattostr(gso_out.gso_stopOrders[i].gso_price.moneyval) + #9 +
                                           floattostr(gso_out.gso_stopOrders[i].gso_stopPrice.moneyval) + #9 +
                                           gso_out.gso_stopOrders[i].gso_instrumentUid + #9 +
                                           gso_out.gso_stopOrders[i].gso_takeProfitType + #9 +
                                           floattostr(gso_out.gso_stopOrders[i].gso_trailingData.gso_indent) + #9 +
                                           gso_out.gso_stopOrders[i].gso_trailingData.gso_indentType + #9 +
                                           floattostr(gso_out.gso_stopOrders[i].gso_trailingData.gso_spread) + #9 +
                                           gso_out.gso_stopOrders[i].gso_trailingData.gso_spreadType + #9 +
                                           gso_out.gso_stopOrders[i].gso_status + #9 +
                                           gso_out.gso_stopOrders[i].gso_exchangeOrderType + #9 +
                                           gso_out.gso_stopOrders[i].gso_exchangeOrderId
                                           );

  inc(i);
  end;

  memo1.Lines.EndUpdate;


end;

procedure TForm1.btnGetIndicatorsClick(Sender: TObject);
var

i, ind_count : int64;

begin
  i := 0;


  gc_in.gc_token := txtToken.Text;
  gc_in.gc_from := txtGetCandles1.Text;
  gc_in.gc_to := txtGetCandles2.Text;
  gc_in.gc_interval := cmbGetCandles1.Text;
  gc_in.gc_instrumentId := txtGetCandles3.Text;
  gc_in.gc_candleSourceType := cmbGetCandles2.Text;
  gc_in.gc_limit := strtoint(txtGetCandles4.Text);

  memo1.Text := '';

  GetExchangeCandles(gc_in, conv_out);



  if cmbGetIndicators.Text = 'INDICATOR_EMA' then begin

     gema_in.gema_candles := conv_out.gc_candles;
     gema_in.gema_period := 13;


     Get_EMA(gema_in, gema_out);

     ind_count := high(gema_out.gema_ema_arr);

     memo1.Lines.BeginUpdate;

     while i <= ind_count do  begin

        memo1.Lines.add(inttostr(i) + #9 + floattostr(gema_out.gema_ema_arr[i].gema_ema) + #9 + ISOToLocalTime(gema_out.gema_ema_arr[i].gema_time)  );

     inc(i);
     end;

     memo1.Lines.EndUpdate;

  end;

  if cmbGetIndicators.Text = 'INDICATOR_RSI' then begin

     grsi_in.grsi_candles := conv_out.gc_candles;
     grsi_in.grsi_period := 14;

     Get_RSI(grsi_in, grsi_out);

     ind_count := high(grsi_out.grsi_RSI_arr);

     memo1.Lines.BeginUpdate;

     while i <= ind_count do  begin

        memo1.Lines.add(inttostr(i) + #9 + floattostr(grsi_out.grsi_RSI_arr[i].grsi_rsi) + #9 + ISOToLocalTime(grsi_out.grsi_RSI_arr[i].grsi_time)  );

     inc(i);
     end;

     memo1.Lines.EndUpdate;
  end;

  if cmbGetIndicators.Text = 'INDICATOR_HEIKEN_ASHI' then begin

     gha_in.gha_candles := conv_out.gc_candles;

     Get_HEIKEN_ASHI(gha_in, gha_out);

     ind_count := high(gha_out.gha_HA_arr);

     memo1.Lines.BeginUpdate;

     while i <= ind_count do  begin

        memo1.Lines.add(inttostr(i) + #9 + floattostr(gha_out.gha_HA_arr[i].gha_open) + #9 + floattostr(gha_out.gha_HA_arr[i].gha_high) + #9 +
                        floattostr(gha_out.gha_HA_arr[i].gha_low) + #9 + floattostr(gha_out.gha_HA_arr[i].gha_close) + #9 + ISOToLocalTime(gha_out.gha_HA_arr[i].gha_time)  );

     inc(i);
     end;

     memo1.Lines.EndUpdate;
  end;

  if cmbGetIndicators.Text = 'INDICATOR_ATR' then begin

     gatr_in.gatr_candles := conv_out.gc_candles;
     gatr_in.gatr_period := 14;


     Get_ATR(gatr_in, gatr_out);

     ind_count := high(gatr_out.gatr_ATR_arr);

     memo1.Lines.BeginUpdate;

     while i <= ind_count do  begin

        memo1.Lines.add(inttostr(i) + #9 + floattostr(gatr_out.gatr_ATR_arr[i].gatr_atr) + #9 + ISOToLocalTime(gatr_out.gatr_ATR_arr[i].gatr_time)  );

     inc(i);
     end;

     memo1.Lines.EndUpdate;

  end;

  if cmbGetIndicators.Text = 'INDICATOR_MACD' then begin

     gmacd_in.gmacd_candles := conv_out.gc_candles;
     gmacd_in.gmacd_fast_period := 12;
     gmacd_in.gmacd_slow_period := 26;
     gmacd_in.gmacd_smoothing_period := 9;

     Get_MACD(gmacd_in, gmacd_out);

     ind_count := high(gmacd_out.gmacd_macd_arr);

     memo1.Lines.BeginUpdate;

     while i <= ind_count do  begin

        memo1.Lines.add(inttostr(i) + #9 + floattostr( gmacd_out.gmacd_macd_arr[i].gmacd_macd_line ) + #9 + floattostr(gmacd_out.gmacd_macd_arr[i].gmacd_signal_line) + #9 +
                        floattostr(gmacd_out.gmacd_macd_arr[i].gmacd_histogram) + #9 + ISOToLocalTime(gmacd_out.gmacd_macd_arr[i].gmacd_time) );

     inc(i);
     end;

     memo1.Lines.EndUpdate;

  end;


end;

procedure TForm1.btnGetTechAnalysisClick(Sender: TObject);
var

i, gta_count : longint;

begin
   i := 0;
   gta_in.gta_token := txtToken.Text;
   gta_in.gta_indicatorType := cmbGetTechAnalysis1.Text;
   gta_in.gta_instrumentUid := txtGetTechAnalysis1.Text;
   gta_in.gta_from := txtGetTechAnalysis2.Text;
   gta_in.gta_to := txtGetTechAnalysis3.Text;
   gta_in.gta_interval := cmbGetTechAnalysis2.Text;
   gta_in.gta_typeOfPrice := cmbGetTechAnalysis3.Text;
   gta_in.gta_length := strtoint(txtGetTechAnalysis4.Text);
   gta_in.gta_deviation.gta_deviationMultiplier := strtofloat(txtGetTechAnalysis5.Text);
   gta_in.gta_smoothing.gta_fastLength := strtoint(txtGetTechAnalysis6.Text);
   gta_in.gta_smoothing.gta_slowLength := strtoint(txtGetTechAnalysis7.Text);
   gta_in.gta_smoothing.gta_signalSmoothing := strtoint(txtGetTechAnalysis8.Text);

   GetTechAnalysis(gta_in, gta_out);

   gta_count := high(gta_out.gta_technicalIndicators);


   memo1.Text := '';

   while i <= gta_count do  begin

     memo1.Lines.add( floattostr(gta_out.gta_technicalIndicators[i].gta_signal) + #9 + floattostr(gta_out.gta_technicalIndicators[i].gta_macd) + #9 + gta_out.gta_technicalIndicators[i].gta_timestamp );

   inc(i);
   end;


end;

procedure TForm1.btnGetTradingStatusClick(Sender: TObject);


begin

   gts_in.gts_token := txtToken.Text;
   gts_in.gts_instrumentId := txtGetTradingStatus.Text;


   GetTradingStatus(gts_in, gts_out);


   memo1.Text := gts_out.gts_tradingStatus;

end;

procedure TForm1.btnGetTradingStatusesClick(Sender: TObject);
var
i, count_statuses, count_statusesfact : longint;

begin
  count_statuses := 0;
  i := 0;
  memo1.Clear;
  gtss_in.gtss_token := txtToken.Text;

  count_statuses := memGetTradingStatuses.Lines.Count;

  SetLength(gtss_in.gtss_instrumentId, count_statuses);

  while i < count_statuses do  begin

     if memGetTradingStatuses.Lines[i] <> '' then gtss_in.gtss_instrumentId[i] := memGetTradingStatuses.Lines[i];

     inc(i);
  end;

  GetTradingStatuses(gtss_in, gtss_out);


  count_statusesfact := high(gtss_out.gtss_tradingStatuses);

  i := 0;

  while i <= count_statusesfact do  begin
     memo1.Lines.add(gtss_out.gtss_tradingStatuses[i].gtss_figi + #9 +
                     gtss_out.gtss_tradingStatuses[i].gtss_tradingStatus + #9 +
                     gtss_out.gtss_tradingStatuses[i].gtss_ticker + #9 +
                     gtss_out.gtss_tradingStatuses[i].gtss_classCode + #9 +
                     booltostr(gtss_out.gtss_tradingStatuses[i].gtss_apiTradeAvailableFlag, 'true', 'false')
     );
     inc(i);
  end;

end;

procedure TForm1.btnPostOrderClick(Sender: TObject);

begin

  po_in.po_token := txtToken.Text;
  po_in.po_quantity := strtoint(txtPostOrder4.Text);
  po_in.po_price := strtofloat(txtPostOrder3.Text);
  po_in.po_direction := cmbPostOrder1.Text;
  po_in.po_accountId := txtPostOrder1.Text;
  po_in.po_orderType := cmbPostOrder2.Text;
  po_in.po_orderId := Get_UUID;
  po_in.po_instrumentId := txtPostOrder2.Text;
  po_in.po_timeInForce := cmbPostOrder3.Text;
  po_in.po_priceType := 'PRICE_TYPE_CURRENCY';
  po_in.po_confirmMarginTrade := true;

  PostOrder(po_in, po_out);


  memo1.Text := po_out.po_orderId + #13 + inttostr(po_out.po_error_code);
end;

procedure TForm1.btnPostStopOrderClick(Sender: TObject);

begin
  pso_in.pso_token := txtToken.Text;
  pso_in.pso_quantity := strtoint(txtPostStopOrder4.Text);
  pso_in.pso_price := strtofloat(txtPostStopOrder3.Text);
  pso_in.pso_stopPrice := strtofloat(txtPostStopOrder5.Text);
  pso_in.pso_direction := cmbPostStopOrder1.Text;
  pso_in.pso_accountId := txtPostStopOrder1.Text;
  pso_in.pso_expirationType := cmbPostStopOrder2.Text;
  pso_in.pso_stopOrderType := cmbPostStopOrder3.Text;
  pso_in.pso_expireDate := txtPostStopOrder7.Text;
  pso_in.pso_instrumentId := txtPostStopOrder2.Text;
  pso_in.pso_exchangeOrderType := cmbPostStopOrder4.Text;
  pso_in.pso_takeProfitType := cmbPostStopOrder5.Text;
  pso_in.pso_priceType := cmbPostStopOrder6.Text;
  pso_in.pso_orderId := txtPostStopOrder6.Text;
  pso_in.pso_confirmMarginTrade := true;
  pso_in.pso_trailingData.pso_indentType := 'TRAILING_VALUE_UNSPECIFIED';
  pso_in.pso_trailingData.pso_spreadType := 'TRAILING_VALUE_UNSPECIFIED';
  pso_in.pso_trailingData.pso_indent := 11;
  pso_in.pso_trailingData.pso_spread := 22;

  PostStopOrder(pso_in, pso_out);

  memo1.Text := pso_out.pso_orderRequestId + #9 +

                pso_out.pso_stopOrderId + #13 + inttostr(pso_out.pso_error_code);

end;

procedure TForm1.btnStructuredNotesClick(Sender: TObject);
var

i, sn_count : longint;

begin
  i := 0;

  sn_in.sn_token := txtToken.Text;
  sn_in.sn_instrumentStatus := cmbStructuredNotes1.Text;
  sn_in.sn_instrumentExchange := cmbStructuredNotes2.Text;

  memo1.Text := '';
  GetStructuredNotes(sn_in, sn_out);

  sn_count := high(sn_out.sn_instruments);

  memo1.Lines.BeginUpdate;

  while i <= sn_count do  begin

        memo1.Lines.add(inttostr(i) + #9 + sn_out.sn_instruments[i].sn_isin + #9 +
                                           sn_out.sn_instruments[i].sn_ticker + #9 +
                                           sn_out.sn_instruments[i].sn_exchange + #9 +
                                           sn_out.sn_instruments[i].sn_figi + #9 +
                                           sn_out.sn_instruments[i].sn_uid + #9 +
                                           'lots: ' + #9 + inttostr(sn_out.sn_instruments[i].sn_lot) + #9 +
                                           'issueSize: ' + #9 + inttostr(sn_out.sn_instruments[i].sn_issueSize) + #9 +
                                           sn_out.sn_instruments[i].sn_name  + #9 +
                                           sn_out.sn_instruments[i].sn_placementDate  + #9 +
                                           sn_out.sn_instruments[i].sn_maturityDate  + #9 +
                                           booltostr(sn_out.sn_instruments[i].sn_buyAvailableFlag, 'true', 'false') + #9 +
                                           booltostr(sn_out.sn_instruments[i].sn_sellAvailableFlag, 'true', 'false')
                                           );

  inc(i);
  end;

  memo1.Lines.EndUpdate;

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  txtGetTechAnalysis3.Text := formatdatetime('yyyy-mm-dd"T"hh:nn:ss.zzzzzz"Z"', now);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  txtGetCandles2.Text := formatdatetime('yyyy-mm-dd"T"hh:nn:ss.zzzzzz"Z"', now);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 txtGetStopOrders3.Text := formatdatetime('yyyy-mm-dd"T"hh:nn:ss.zzzzzz"Z"', now);
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  txtPostStopOrder6Click(self);
  txtPostOrder5Click(self);
end;

procedure TForm1.txtPostOrder5Click(Sender: TObject);
begin
  txtPostOrder5.Text := Get_UUID;
end;

procedure TForm1.txtPostStopOrder6Click(Sender: TObject);
begin
  txtPostStopOrder6.Text := Get_UUID;
end;


end.

