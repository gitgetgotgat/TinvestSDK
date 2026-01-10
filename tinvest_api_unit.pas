unit tinvest_api_unit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fphttpClient, openssl, opensslsockets, jsonparser, Fpjson, DateUtils, Dialogs;

const
   url_tinvest = 'https://invest-public-api.tbank.ru/rest/tinkoff.public.invest.api.contract.v1.';

type

   // Структуры для лимитов
   http_headers = record
      h_tracking_id : string;
      h_date : string;
      h_ratelimit_limit : int64;
      h_ratelimit_remaining : int64;
      h_ratelimit_reset : int64;
   end;

   UnaryLimitation = record
      InstrumentsService_limit : http_headers;
      MarketDataService_limit : http_headers;
      OperationsService_limit : http_headers;
      OrdersService_limit : http_headers;
      StopOrdersService_limit : http_headers;
      UsersService_limit : http_headers;
      SignalService_limit : http_headers;
      Report_limit : http_headers;
      Currency_limit : http_headers;
   end;

   // Структура для валюты
   MoneyStruct = record
      moneyval : double;                                                                                        // значение стоимости
      currency : string;                                                                                        // строковый ISO-код валюты. Например, RUB или USD. https://ru.wikipedia.org/wiki/ISO_4217
   end;

   // Структуры для процедуры GetAccounts
   ga_request = record                                                                                          // Запрос для GetAccounts
      ga_token : string;                                                                                        // Токен
      ga_status : string;                                                                                       // Статус счета [ACCOUNT_STATUS_UNSPECIFIED, ACCOUNT_STATUS_NEW, ACCOUNT_STATUS_OPEN, ACCOUNT_STATUS_CLOSED, ACCOUNT_STATUS_ALL]
   end;
   ga_accountsStruct = record
      ga_id : string;                                                                                           // Идентификатор счета
      ga_type : string;                                                                                         // Тип счета
      ga_name : string;                                                                                         // Название счета
      ga_status : string;                                                                                       // Статус счета [ACCOUNT_STATUS_UNSPECIFIED, ACCOUNT_STATUS_NEW, ACCOUNT_STATUS_OPEN, ACCOUNT_STATUS_CLOSED, ACCOUNT_STATUS_ALL]
      ga_openedDate : string;                                                                                   // Дата открытия счета в часовом поясе UTC
      ga_closedDate : string;                                                                                   // Дата закрытия счета в часовом поясе UTC
      ga_accessLevel : string;                                                                                  // Уровень доступа к текущему счету (определяется токеном)
   end;
   ga_response = record                                                                                         // Ответ для GetAccounts
      ga_accounts : array of ga_accountsStruct;                                                                 // Массив счетов клиента
      ga_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      ga_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      ga_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetPortfolio
   gp_request = record                                                                                          // Запрос для GetPortfolio
      gp_token : string;                                                                                        // Токен
      gp_accountId : string;                                                                                    // Идентификатор счета пользователя
      gp_currency : string;                                                                                     // Валюта, в которой нужно рассчитать портфель
   end;
   gp_portfoliopositionStruct = record
      gp_figi : string;                                                                                         // FIGI-идентификатор инструмента
      gp_instrumentType : string;                                                                               // Тип инструмента
      gp_quantity : int64;                                                                                      // Количество инструмента в портфеле в штуках
      gp_averagePositionPrice : MoneyStruct;                                                                    // Средневзвешенная цена позиции. Для пересчета возможна задержка до одной секунды
      gp_expectedYield : double;                                                                                // Текущая рассчитанная доходность позиции
      gp_currentNkd : MoneyStruct;                                                                              // Текущий НКД
      gp_averagePositionPricePt : double;                                                                       // Deprecated Средняя цена позиции в пунктах (для фьючерсов). Для пересчета возможна задержка до одной секунды
      gp_currentPrice : MoneyStruct;                                                                            // Текущая цена за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gp_averagePositionPriceFifo : MoneyStruct;                                                                // Средняя цена позиции по методу FIFO. Для пересчета возможна задержка до одной секунды
      gp_quantityLots : int64;                                                                                  // Deprecated Количество лотов в портфеле
      gp_blocked : boolean;                                                                                     // Заблокировано на бирже
      gp_blockedLots : double;                                                                                  // Количество бумаг, заблокированных выставленными заявками
      gp_positionUid : string;                                                                                  // Уникальный идентификатор позиции
      gp_instrumentUid : string;                                                                                // Уникальный идентификатор инструмента
      gp_varMargin : MoneyStruct;                                                                               // Вариационная маржа
      gp_expectedYieldFifo : double;                                                                            // Текущая рассчитанная доходность позиции
      gp_dailyYield : MoneyStruct;                                                                              // Рассчитанная доходность портфеля за день
   end;
   gp_virtualportfoliopositionStruct = record
      gp_positionUid : string;                                                                                  // Уникальный идентификатор позиции
      gp_instrumentUid : string;                                                                                // Уникальный идентификатор инструмента
      gp_figi : string;                                                                                         // FIGI-идентификатор инструмента
      gp_instrumentType : string;                                                                               // Тип инструмента
      gp_quantity : int64;                                                                                      // Количество инструмента в портфеле в штуках
      gp_averagePositionPrice : double;                                                                         // Средневзвешенная цена позиции. Для пересчета возможна задержка до одной секунды
      gp_expectedYield : double;                                                                                // Текущая рассчитанная доходность позиции
      gp_expectedYieldFifo : double;                                                                            // Текущая рассчитанная доходность позиции
      gp_expireDate : string;                                                                                   // Дата, до которой нужно продать виртуальные бумаги. После этой даты виртуальная позиция «сгорает»
      gp_currentPrice : double;                                                                                 // Текущая цена за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gp_averagePositionPriceFifo : double;                                                                     // Средняя цена позиции по методу FIFO. Для пересчета возможна задержка до одной секунды
      gp_dailyYield : MoneyStruct;                                                                              // Рассчитанная доходность портфеля за день
   end;
   gp_response = record                                                                                         // Ответ для GetPortfolio
      gp_totalAmountShares : MoneyStruct;                                                                       // Общая стоимость акций в портфеле
      gp_totalAmountBonds : MoneyStruct;                                                                        // Общая стоимость облигаций в портфеле
      gp_totalAmountEtf : MoneyStruct;                                                                          // Общая стоимость фондов в портфеле
      gp_totalAmountCurrencies : MoneyStruct;                                                                   // Общая стоимость валют в портфеле
      gp_totalAmountFutures : MoneyStruct;                                                                      // Общая стоимость фьючерсов в портфеле
      gp_expectedYield : double;                                                                                // Текущая относительная доходность портфеля в %
      gp_positions : array of gp_portfoliopositionStruct;                                                       // Список позиций портфеля
      gp_accountId : string;                                                                                    // Идентификатор счета пользователя
      gp_totalAmountOptions : MoneyStruct;                                                                      // Общая стоимость опционов в портфеле
      gp_totalAmountSp : MoneyStruct;                                                                           // Общая стоимость структурных нот в портфеле
      gp_totalAmountPortfolio : MoneyStruct;                                                                    // Общая стоимость портфеля
      gp_virtualPositions : array of gp_virtualportfoliopositionStruct;                                         // Массив виртуальных позиций портфеля
      gp_dailyYield : double;                                                                                   // Рассчитанная доходность портфеля за день в рублях
      gp_dailyYieldRelative : double;                                                                           // Относительная доходность в день в %
      gp_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      gp_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      gp_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetOperationsByCursor
   gobc_operation = record
      gobc_type : string;                                                                                       // Идентификатор типа операции
   end;
   gobc_request = record                                                                                        // Запрос для GetOperationsByCursor
      gobc_token : string;                                                                                      // Токен
      gobc_accountId : string;                                                                                  // Идентификатор счета клиента
      gobc_instrumentId : string;                                                                               // Идентификатор инструмента — FIGI или UID инструмента
      gobc_from : string;                                                                                       // Начало периода по UTC
      gobc_to : string;                                                                                         // Окончание периода по UTC
      gobc_cursor : string;                                                                                     // Идентификатор элемента, с которого начать формировать ответ (для первого запроса "пусто", а далее в каждом запросе передеавать из nextCursor
      gobc_limit : int64;                                                                                       // Лимит количества операций. По умолчанию — 100, максимальное значение — 1000
      gobc_operationTypes : array of gobc_operation;                                                            // Тип операции. Принимает значение из списка
      gobc_state : string;                                                                                      // Статус запрашиваемых операций
      gobc_withoutCommissions : boolean;                                                                        // Флаг возврата комиссии. По умолчанию — false
      gobc_withoutTrades : boolean;                                                                             // Флаг получения ответа без массива сделок
      gobc_withoutOvernights : boolean;                                                                         // Флаг показа overnight операций

   end;
   gobc_tradesStruct = record
      gobc_num : string;                                                                                        // Номер сделки
      gobc_date : string;                                                                                       // Дата сделки
      gobc_quantity : int64;                                                                                    // Количество в единицах
      gobc_price : MoneyStruct;                                                                                 // Цена
      gobc_yield : MoneyStruct;                                                                                 // Доходность
      gobc_yieldRelative : double;                                                                              // Относительная доходность
   end;
   gobc_childOperationsStruct = record
      gobc_instrumentUid : string;                                                                              // Уникальный идентификатор инструмента
      gobc_payment : double;                                                                                    // Сумма операции
   end;

   gobc_itemsStruct = record
      gobc_cursor : string;                                                                                     // Идентификатор элемента
      gobc_brokerAccountId : string;                                                                            // Номер счета клиента
      gobc_id : string;                                                                                         // Идентификатор операции, может меняться с течением времени
      gobc_parentOperationId : string;                                                                          // Идентификатор родительской операции. Может измениться, если изменился ID родительской операции
      gobc_name : string;                                                                                       // Название операции
      gobc_date : string;                                                                                       // Дата поручения
      gobc_type : string;                                                                                       // Тип операции
      gobc_description : string;                                                                                // Описание операции
      gobc_state : string;                                                                                      // Статус запрашиваемых операций
      gobc_instrumentUid : string;                                                                              // Уникальный идентификатор инструмента
      gobc_figi : string;                                                                                       // FIGI
      gobc_instrumentType : string;                                                                             // Тип инструмента
      gobc_instrumentKind : string;                                                                             // Тип инструмента
      gobc_positionUid : string;                                                                                // Уникальный идентификатор позиции
      gobc_ticker : string;                                                                                     // Тикер инструмента
      gobc_classCode : string;                                                                                  // Класс-код (секция торгов)
      gobc_payment : MoneyStruct;                                                                               // Сумма операции
      gobc_price : MoneyStruct;                                                                                 // Цена операции за 1 инструмент
      gobc_commission : MoneyStruct;                                                                            // Комиссия
      gobc_yield : MoneyStruct;                                                                                 // Доходность
      gobc_yieldRelative : double;                                                                              // Относительная доходность
      gobc_accruedInt : MoneyStruct;                                                                            // Накопленный купонный доход
      gobc_quantity : int64;                                                                                    // Количество единиц инструмента
      gobc_quantityRest : int64;                                                                                // Неисполненный остаток по сделке
      gobc_quantityDone : int64;                                                                                // Исполненный остаток
      gobc_cancelDateTime : string;                                                                             // Дата и время снятия заявки
      gobc_cancelReason : string;                                                                               // Причина отмены операции
      gobc_tradesInfo : array of gobc_tradesStruct;                                                             // Массив с информацией о сделках
      gobc_assetUid : string;                                                                                   // Идентификатор актива
      gobc_childOperations : array of gobc_childOperationsStruct;                                               // Массив дочерних операций

   end;
   gobc_response = record                                                                                       // Ответ для GetOperationsByCursor
      gobc_hasNext : boolean;                                                                                   // Признак, есть ли следующий элемент
      gobc_nextCursor : string;                                                                                 // Следующий курсор
      gobc_items : array of gobc_itemsStruct;                                                                   // Список операций
      gobc_error_code : int64;                                                                                  // Уникальный идентификатор ошибки
      gobc_error_message : string;                                                                              // Пользовательское сообщение об ошибке
      gobc_error_description : int64;                                                                           // Код ошибки
   end;

   // Структуры для процедуры PostOrder
   po_request = record                                                                                          // Запрос для PostOrder
      po_token : string;                                                                                        // Токен
      po_quantity : int64;                                                                                      // Количество лотов
      po_price : double;                                                                                        // Цена за 1 инструмент. Для получения стоимости лота требуется умножить на лотность инструмента. Игнорируется для рыночных поручений
      po_direction : string;                                                                                    // Направление операции [ORDER_DIRECTION_UNSPECIFIED, ORDER_DIRECTION_BUY, ORDER_DIRECTION_SELL]
      po_accountId : string;                                                                                    // Номер счета
      po_orderType : string;                                                                                    // Тип заявки [ORDER_TYPE_UNSPECIFIED, ORDER_TYPE_LIMIT, ORDER_TYPE_MARKET, ORDER_TYPE_BESTPRICE]
      po_orderId : string;                                                                                      // Идентификатор запроса выставления поручения для целей идемпотентности в формате UID. Максимальная длина 36 символов
      po_instrumentId : string;                                                                                 // Идентификатор инструмента, принимает значения Figi или Instrument_uid
      po_timeInForce : string;                                                                                  // Алгоритм исполнения поручения, применяется только к лимитной заявке [TIME_IN_FORCE_UNSPECIFIED, TIME_IN_FORCE_DAY, TIME_IN_FORCE_FILL_AND_KILL, TIME_IN_FORCE_FILL_OR_KILL]
      po_priceType : string;                                                                                    // Тип цены [PRICE_TYPE_UNSPECIFIED, PRICE_TYPE_POINT, PRICE_TYPE_CURRENCY]
      po_confirmMarginTrade : boolean;                                                                          // Согласие на выставление заявки, которая может привести к непокрытой позиции, по умолчанию false
   end;
   po_responseMetadataStruct = record
      po_trackingId : string;                                                                                   // Идентификатор трекинга
      po_serverTime : string;                                                                                   // Серверное время
   end;
   po_response = record                                                                                         // Ответ для PostOrder
      po_orderId : string;                                                                                      // Биржевой идентификатор заявки
      po_executionReportStatus : string;                                                                        // Текущий статус заявки [EXECUTION_REPORT_STATUS_UNSPECIFIED, EXECUTION_REPORT_STATUS_FILL, EXECUTION_REPORT_STATUS_REJECTED, EXECUTION_REPORT_STATUS_CANCELLED, EXECUTION_REPORT_STATUS_NEW, EXECUTION_REPORT_STATUS_PARTIALLYFILL]
      po_lotsRequested : int64;                                                                                 // Запрошено лотов
      po_lotsExecuted : int64;                                                                                  // Исполнено лотов
      po_initialOrderPrice : MoneyStruct;                                                                       // Начальная цена заявки. Произведение количества запрошенных лотов на цену
      po_executedOrderPrice : MoneyStruct;                                                                      // Исполненная средняя цена одного инструмента в заявке
      po_totalOrderAmount : MoneyStruct;                                                                        // Итоговая стоимость заявки, включающая все комиссии
      po_initialCommission : MoneyStruct;                                                                       // Начальная комиссия. Комиссия рассчитанная при выставлении заявки
      po_executedCommission : MoneyStruct;                                                                      // Фактическая комиссия по итогам исполнения заявки
      po_aciValue : MoneyStruct;                                                                                // Значение НКД (накопленного купонного дохода) на дату
      po_figi : string;                                                                                         // Figi-идентификатор инструмента
      po_direction : string;                                                                                    // Направление сделки [ORDER_DIRECTION_UNSPECIFIED, ORDER_DIRECTION_BUY, ORDER_DIRECTION_SELL]
      po_initialSecurityPrice : MoneyStruct;                                                                    // Начальная цена за 1 инструмент. Для получения стоимости лота требуется умножить на лотность инструмента
      po_orderType : string;                                                                                    // Тип заявки [ORDER_TYPE_UNSPECIFIED, ORDER_TYPE_LIMIT, ORDER_TYPE_MARKET, ORDER_TYPE_BESTPRICE]
      po_message : string;                                                                                      // Дополнительные данные об исполнении заявки
      po_initialOrderPricePt : double;                                                                          // Начальная цена заявки в пунктах (для фьючерсов)
      po_instrumentUid : string;                                                                                // UID идентификатор инструмента
      po_orderRequestId : string;                                                                               // Идентификатор ключа идемпотентности, переданный клиентом, в формате UID. Максимальная длина 36 символов
      po_responseMetadata : po_responseMetadataStruct;                                                          // Метаданные
      po_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      po_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      po_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры ReplaceOrder
   ro_request = record                                                                                          // Запрос для ReplaceOrder
      ro_token : string;                                                                                        // Токен
      ro_accountId : string;                                                                                    // Номер счета
      ro_orderId : string;                                                                                      // Идентификатор заявки на бирже
      ro_idempotencyKey : string;                                                                               // Новый идентификатор запроса выставления поручения для целей идемпотентности. Максимальная длина 36 символов. Перезатирает старый ключ
      ro_quantity : int64;                                                                                      // Количество лотов
      ro_price : double;                                                                                        // Цена за 1 инструмент
      ro_priceType : string;                                                                                    // Тип цены [PRICE_TYPE_UNSPECIFIED, PRICE_TYPE_POINT, PRICE_TYPE_CURRENCY]
      ro_confirmMarginTrade : boolean;                                                                          // Согласие на выставление заявки, которая может привести к непокрытой позиции, по умолчанию false
   end;
   ro_responseMetadataStruct = record
      ro_trackingId : string;                                                                                   // Идентификатор трекинга
      ro_serverTime : string;                                                                                   // Серверное время
   end;
   ro_response = record                                                                                         // Ответ для ReplaceOrder
      ro_orderId : string;                                                                                      // Биржевой идентификатор заявки
      ro_executionReportStatus : string;                                                                        // Текущий статус заявки [EXECUTION_REPORT_STATUS_UNSPECIFIED, EXECUTION_REPORT_STATUS_FILL, EXECUTION_REPORT_STATUS_REJECTED, EXECUTION_REPORT_STATUS_CANCELLED, EXECUTION_REPORT_STATUS_NEW, EXECUTION_REPORT_STATUS_PARTIALLYFILL]
      ro_lotsRequested : int64;                                                                                 // Запрошено лотов
      ro_lotsExecuted : int64;                                                                                  // Исполнено лотов
      ro_initialOrderPrice : MoneyStruct;                                                                       // Начальная цена заявки. Произведение количества запрошенных лотов на цену
      ro_executedOrderPrice : MoneyStruct;                                                                      // Исполненная средняя цена одного инструмента в заявке
      ro_totalOrderAmount : MoneyStruct;                                                                        // Итоговая стоимость заявки, включающая все комиссии
      ro_initialCommission : MoneyStruct;                                                                       // Начальная комиссия. Комиссия рассчитанная при выставлении заявки
      ro_executedCommission : MoneyStruct;                                                                      // Фактическая комиссия по итогам исполнения заявки
      ro_aciValue : MoneyStruct;                                                                                // Значение НКД (накопленного купонного дохода) на дату
      ro_figi : string;                                                                                         // Figi-идентификатор инструмента
      ro_direction : string;                                                                                    // Направление операции [ORDER_DIRECTION_UNSPECIFIED, ORDER_DIRECTION_BUY, ORDER_DIRECTION_SELL]
      ro_initialSecurityPrice : MoneyStruct;                                                                    // Начальная цена за 1 инструмент. Для получения стоимости лота требуется умножить на лотность инструмента
      ro_orderType : string;                                                                                    // Тип заявки [ORDER_TYPE_UNSPECIFIED, ORDER_TYPE_LIMIT, ORDER_TYPE_MARKET, ORDER_TYPE_BESTPRICE]
      ro_message : string;                                                                                      // Дополнительные данные об исполнении заявки
      ro_initialOrderPricePt : double;                                                                          // Начальная цена заявки в пунктах (для фьючерсов)
      ro_instrumentUid : string;                                                                                // UID идентификатор инструмента
      ro_orderRequestId : string;                                                                               // Идентификатор ключа идемпотентности, переданный клиентом, в формате UID. Максимальная длина 36 символов
      ro_responseMetadata : ro_responseMetadataStruct;                                                          // Метаданные
      ro_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      ro_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      ro_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры CancelOrder
   co_request = record                                                                                          // Запрос для CancelOrder
      co_token : string;                                                                                        // Токен
      co_accountId : string;                                                                                    // Номер счета
      co_orderId : string;                                                                                      // Идентификатор заявки
      co_orderIdType : string;                                                                                  // Тип идентификатора заявки [ORDER_ID_TYPE_UNSPECIFIED, ORDER_ID_TYPE_EXCHANGE, ORDER_ID_TYPE_REQUEST]
   end;
   co_responseMetadataStruct = record
      po_trackingId : string;                                                                                   // Идентификатор трекинга
      po_serverTime : string;                                                                                   // Серверное время
   end;	
   co_response = record                                                                                         // Ответ для CancelOrder
      co_time : string;                                                                                         // Дата и время отмены заявки в часовом поясе UTC
      co_responseMetadata : co_responseMetadataStruct;                                                          // Метаданные
      co_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      co_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      co_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetMaxLots
   gml_request = record                                                                                         // Запрос для GetMaxLots
      gml_token : string;                                                                                       // Токен
      gml_accountId : string;                                                                                   // Номер счета
      gml_instrumentId : string;                                                                                // Идентификатор инструмента, принимает значения Figi или instrument_uid
      gml_price : double;                                                                                       // Цена инструмента. Если не указывать цену инструмента, то расчет произведется по текущум ценам в стакане: по лучшему предложению для покупки и по лучшему спросу для продажи
   end;
   gml_buyLimitsStruct = record
      gml_buyMoneyAmount : double;                                                                              // Количество доступной валюты для покупки
      gml_buyMaxLots : int64;                                                                                   // Максимальное доступное количество лотов для покупки
      gml_buyMaxMarketLots : int64;                                                                             // Максимальное доступное количество лотов для покупки для заявки по рыночной цене на текущий момент
   end;
   gml_buyMarginLimitsStruct = record
      gml_buyMoneyAmount : double;                                                                              // Количество доступной валюты для покупки
      gml_buyMaxLots : int64;                                                                                   // Максимальное доступное количество лотов для покупки
      gml_buyMaxMarketLots : int64;                                                                             // Максимальное доступное количество лотов для покупки для заявки по рыночной цене на текущий момент
   end;
   gml_sellLimitsStruct = record
      gml_sellMaxLots : int64;                                                                                  // Максимальное доступное количество лотов для продажи
   end;
   gml_sellMarginLimitsStruct = record
      gml_sellMaxLots : int64;                                                                                  // Максимальное доступное количество лотов для продажи
   end;
   gml_response = record                                                                                        // Ответ для GetMaxLots
      gml_currency : string;                                                                                    // Валюта инструмента
      gml_buyLimits : gml_buyLimitsStruct;                                                                      // Лимиты для покупок на собственные деньги
      gml_buyMarginLimits : gml_buyMarginLimitsStruct;                                                          // Лимиты для покупок с учетом маржинального кредитования
      gml_sellLimits : gml_sellLimitsStruct;                                                                    // Лимиты для продаж по собственной позиции
      gml_sellMarginLimits : gml_sellMarginLimitsStruct;                                                        // Лимиты для продаж с учетом маржинального кредитования
      gml_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gml_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gml_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetOrderState
   gos_request = record                                                                                         // Запрос для GetOrderState
      gos_token : string;                                                                                       // Токен
      gos_accountId : string;                                                                                   // Номер счета
      gos_orderId : string;                                                                                     // Идентификатор заявки
      gos_priceType : string;                                                                                   // Тип цены [PRICE_TYPE_UNSPECIFIED, PRICE_TYPE_POINT, PRICE_TYPE_CURRENCY]
      gos_orderIdType : string;                                                                                 // Тип идентификатора заявки [ORDER_ID_TYPE_UNSPECIFIED, ORDER_ID_TYPE_EXCHANGE, ORDER_ID_TYPE_REQUEST]
   end;
   gos_stagesStruct = record
      gos_price : double;                                                                                       // Цена за 1 инструмент. Для получения стоимости лота требуется умножить на лотность инструмента
      gos_quantity : int64;                                                                                     // Количество лотов
      gos_tradeId : string;                                                                                     // Идентификатор сделки
      gos_executionTime : string;                                                                               // Время исполнения сделки
   end;
   gos_response = record                                                                                        // Ответ для GetOrderState
      gos_orderId : string;                                                                                     // Биржевой идентификатор заявки
      gos_executionReportStatus : string;                                                                       // Текущий статус заявки [EXECUTION_REPORT_STATUS_UNSPECIFIED, EXECUTION_REPORT_STATUS_FILL, EXECUTION_REPORT_STATUS_REJECTED, EXECUTION_REPORT_STATUS_CANCELLED, EXECUTION_REPORT_STATUS_NEW, EXECUTION_REPORT_STATUS_PARTIALLYFILL]
      gos_lotsRequested : int64;                                                                                // Запрошено лотов
      gos_lotsExecuted : int64;                                                                                 // Исполнено лотов
      gos_initialOrderPrice : MoneyStruct;                                                                      // Начальная цена заявки. Произведение количества запрошенных лотов на цену
      gos_executedOrderPrice : MoneyStruct;                                                                     // Исполненная цена заявки. Произведение средней цены покупки на количество лотов
      gos_totalOrderAmount : MoneyStruct;                                                                       // Итоговая стоимость заявки, включающая все комиссии
      gos_averagePositionPrice : MoneyStruct;                                                                   // Средняя цена позиции по сделке
      gos_initialCommission : MoneyStruct;                                                                      // Начальная комиссия. Комиссия, рассчитанная на момент подачи заявки
      gos_executedCommission : MoneyStruct;                                                                     // Фактическая комиссия по итогам исполнения заявки
      gos_figi : string;                                                                                        // Figi-идентификатор инструмента
      gos_direction : string;                                                                                   // Направление заявки [ORDER_DIRECTION_UNSPECIFIED, ORDER_DIRECTION_BUY, ORDER_DIRECTION_SELL]
      gos_initialSecurityPrice : MoneyStruct;                                                                   // Начальная цена за 1 инструмент. Для получения стоимости лота требуется умножить на лотность инструмента
      gos_stages : array of gos_stagesStruct;                                                                   // Стадии выполнения заявки
      gos_serviceCommission : MoneyStruct;                                                                      // Сервисная комиссия
      gos_currency : string;                                                                                    // Валюта заявки
      gos_orderType : string;                                                                                   // Тип заявки [ORDER_TYPE_UNSPECIFIED, ORDER_TYPE_LIMIT, ORDER_TYPE_MARKET, ORDER_TYPE_BESTPRICE]
      gos_orderDate : string;                                                                                   // Дата и время выставления заявки в часовом поясе UTC
      gos_instrumentUid : string;                                                                               // UID идентификатор инструмента
      gos_orderRequestId : string;                                                                              // Идентификатор ключа идемпотентности, переданный клиентом, в формате UID. Максимальная длина — 36 символов
      gos_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gos_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gos_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetOrders
   go_request = record                                                                                          // Запрос для GetOrders
      go_token : string;                                                                                        // Токен
      go_accountId : string;                                                                                    // Номер счета
   end;
   go_stagesStruct = record
      go_price : MoneyStruct;                                                                                   // Цена за 1 инструмент. Для получения стоимости лота требуется умножить на лотность инструмента
      go_quantity : int64;                                                                                      // Количество лотов
      go_tradeId : string;                                                                                      // Идентификатор сделки
      go_executionTime : string;                                                                                // Время исполнения сделки
   end;
   go_ordersStruct = record
      go_orderId : string;                                                                                      // Биржевой идентификатор заявки
      go_executionReportStatus : string;                                                                        // Текущий статус заявки [EXECUTION_REPORT_STATUS_UNSPECIFIED, EXECUTION_REPORT_STATUS_FILL, EXECUTION_REPORT_STATUS_REJECTED, EXECUTION_REPORT_STATUS_CANCELLED, EXECUTION_REPORT_STATUS_NEW, EXECUTION_REPORT_STATUS_PARTIALLYFILL]
      go_lotsRequested : int64;                                                                                 // Запрошено лотов
      go_lotsExecuted : int64;                                                                                  // Исполнено лотов
      go_initialOrderPrice : MoneyStruct;                                                                       // Начальная цена заявки. Произведение количества запрошенных лотов на цену
      go_executedOrderPrice : MoneyStruct;                                                                      // Исполненная цена заявки. Произведение средней цены покупки на количество лотов
      go_totalOrderAmount : MoneyStruct;                                                                        // Итоговая стоимость заявки, включающая все комиссии
      go_averagePositionPrice : MoneyStruct;                                                                    // Средняя цена позиции по сделке
      go_initialCommission : MoneyStruct;                                                                       // Начальная комиссия. Комиссия, рассчитанная на момент подачи заявки
      go_executedCommission : MoneyStruct;                                                                      // Фактическая комиссия по итогам исполнения заявки
      go_figi : string;                                                                                         // Figi-идентификатор инструмента
      go_direction : string;                                                                                    // Направление заявки [ORDER_DIRECTION_UNSPECIFIED, ORDER_DIRECTION_BUY, ORDER_DIRECTION_SELL]
      go_initialSecurityPrice : MoneyStruct;                                                                    // Начальная цена за 1 инструмент. Для получения стоимости лота требуется умножить на лотность инструмента
      go_stages : array of go_stagesStruct;                                                                     // Стадии выполнения заявки
      go_serviceCommission : MoneyStruct;                                                                       // Сервисная комиссия
      go_currency : string;                                                                                     // Валюта заявки
      go_orderType : string;                                                                                    // Тип заявки [ORDER_TYPE_UNSPECIFIED, ORDER_TYPE_LIMIT, ORDER_TYPE_MARKET, ORDER_TYPE_BESTPRICE]
      go_orderDate : string;                                                                                    // Дата и время выставления заявки в часовом поясе UTC
      go_instrumentUid : string;                                                                                // UID идентификатор инструмента
      go_orderRequestId : string;                                                                               // Идентификатор ключа идемпотентности, переданный клиентом, в формате UID. Максимальная длина — 36 символов
   end;
   go_response = record                                                                                         // Ответ для GetOrders
      go_orders : array of go_ordersStruct;                                                                     // Массив активных заявок
      go_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      go_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      go_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetOrderPrice
   gop_request = record                                                                                         // Запрос для GetOrderPrice
      gop_token : string;                                                                                       // Токен
      gop_accountId : string;                                                                                   // Номер счета
      gop_instrumentId : string;                                                                                // Идентификатор инструмента, принимает значения Figi или instrument_uid
      gop_price : double;                                                                                       // Цена инструмента
      gop_direction : string;                                                                                   // Направление заявки [ORDER_DIRECTION_UNSPECIFIED, ORDER_DIRECTION_BUY, ORDER_DIRECTION_SELL]
      gop_quantity : int64;                                                                                     // Количество лотов
   end;
   gop_extraBondStruct = record
      gop_aciValue : MoneyStruct;                                                                               // Значение НКД (накопленного купонного дохода) на дату
      gop_nominalConversionRate : double;                                                                       // Курс конвертации для замещающих облигаций
   end;
   gop_extraFutureStruct = record
      gop_initialMargin : MoneyStruct;                                                                          // Гарантийное обеспечение для фьючерса
   end;
   gop_response = record                                                                                        // Ответ для GetOrderPrice
      gop_totalOrderAmount : MoneyStruct;                                                                       // Итоговая стоимость заявки
      gop_initialOrderAmount : MoneyStruct;                                                                     // Стоимость заявки без комиссий, НКД, ГО (для фьючерсов — стоимость контрактов)
      gop_lotsRequested : int64;                                                                                // Запрошено лотов
      gop_executedCommission : MoneyStruct;                                                                     // Общая комиссия
      gop_executedCommissionRub : MoneyStruct;                                                                  // Общая комиссия в рублях
      gop_serviceCommission : MoneyStruct;                                                                      // Сервисная комиссия
      gop_dealCommission : MoneyStruct;                                                                         // Комиссия за проведение сделки
      gop_extraBond : gop_extraBondStruct;                                                                      // Дополнительная информация по облигациям
      gop_extraFuture : gop_extraFutureStruct;                                                                  // Дополнительная информация по фьючерсам
      gop_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gop_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gop_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetCandles
   gc_request = record                                                                                          // Запрос для GetCandles
      gc_token : string;                                                                                        // Токен
      gc_from : string;                                                                                         // Начало запрашиваемого периода по UTC
      gc_to : string;                                                                                           // Окончание запрашиваемого периода по UTC
      gc_interval : string;                                                                                     // Интервал запрошенных свечей [CANDLE_INTERVAL_UNSPECIFIED, CANDLE_INTERVAL_1_MIN, CANDLE_INTERVAL_5_MIN, CANDLE_INTERVAL_15_MIN, CANDLE_INTERVAL_HOUR, CANDLE_INTERVAL_DAY, CANDLE_INTERVAL_2_MIN, CANDLE_INTERVAL_3_MIN, CANDLE_INTERVAL_10_MIN, CANDLE_INTERVAL_30_MIN, CANDLE_INTERVAL_2_HOUR, CANDLE_INTERVAL_4_HOUR, CANDLE_INTERVAL_WEEK, CANDLE_INTERVAL_MONTH]
      gc_instrumentId : string;                                                                                 // Идентификатор инструмента. Принимает значение figi или instrument_uid
      gc_candleSourceType : string;                                                                             // Тип источника свечи [CANDLE_SOURCE_UNSPECIFIED, CANDLE_SOURCE_EXCHANGE, CANDLE_SOURCE_INCLUDE_WEEKEND]
      gc_limit : int64;                                                                                         // Максимальное количество свечей в ответе
   end;
   gc_candlesStruct = record
      gc_open : double;                                                                                         // Цена открытия за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gc_high : double;                                                                                         // Максимальная цена за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gc_low : double;                                                                                          // Минимальная цена за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gc_close : double;                                                                                        // Цена закрытия за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gc_volume : int64;                                                                                        // Объем торгов в лотах
      gc_time : string;                                                                                         // Время свечи в часовом поясе UTC
      gc_isComplete : boolean;                                                                                  // Признак завершенности свечи. false — свеча за текущие интервал еще сформирована не полностью
      gc_candleSource : string;                                                                                 // Тип источника свечи [CANDLE_SOURCE_UNSPECIFIED, CANDLE_SOURCE_EXCHANGE, CANDLE_SOURCE_DEALER_WEEKEND]
      gc_volumeBuy : string;                                                                                    // Объем торгов на покупку
      gc_volumeSell : string;                                                                                   // Объем торгов на продажу
   end;
   gc_response = record                                                                                         // Ответ для GetCandles
      gc_candles : array of gc_candlesStruct;                                                                   // Массив свечей
      gc_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      gc_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      gc_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetOrderBook
   gob_request = record                                                                                         // Запрос для GetOrderBook
      gob_token : string;                                                                                       // Токен
      gob_depth : int64;                                                                                        // Глубина стакана (максимум 50)
      gob_instrumentId : string;                                                                                // Идентификатор инструмента. Принимает значение figi или instrument_uid
   end;
   gob_bidsStruct = record
      gob_price : double;                                                                                       // Цена за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gob_quantity : int64;                                                                                     // Количество в лотах
   end;
   gob_asksStruct = record
      gob_price : double;                                                                                       // Цена за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gob_quantity : int64;                                                                                     // Количество в лотах
   end;
   gob_response = record                                                                                        // Ответ для GetOrderBook
      gob_figi : string;                                                                                        // FIGI-идентификатор инструмента
      gob_depth : int64;                                                                                        // Глубина стакана (максимум 50)
      gob_bids : array of gob_bidsStruct;                                                                       // Множество пар значений на покупку
      gob_asks : array of gob_asksStruct;                                                                       // Множество пар значений на продажу
      gob_lastPrice : double;                                                                                   // Цена последней сделки за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gob_closePrice : double;                                                                                  // Цена закрытия за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gob_limitUp : double;                                                                                     // Верхний лимит цены за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gob_limitDown : double;                                                                                   // Нижний лимит цены за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gob_lastPriceTs : string;                                                                                 // Время получения цены последней сделки
      gob_closePriceTs : string;                                                                                // Время получения цены закрытия
      gob_orderbookTs : string;                                                                                 // Время формирования стакана на бирже
      gob_instrumentUid : string;                                                                               // UID инструмента
      gob_minask : gob_asksStruct;                                                                              // Верхняя величина спреда - минимальная цена на продажу и количество лотов
      gob_maxbid : gob_bidsStruct;                                                                              // Нижняя величина спреда - максимальная цена на покупку и количество лотов
      gob_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gob_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gob_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetTechAnalysis
   gta_deviationMultiplierStruct = record
      gta_deviationMultiplier : double;                                                                         // Количество стандартных отклонений, на которые отступают верхняя и нижняя границы
   end;
   gta_smoothingStruct =record
      gta_fastLength : int64;                                                                                   // Короткий период сглаживания для первой экспоненциальной скользящей средней (EMA)
      gta_slowLength : int64;                                                                                   // Длинный период сглаживания для второй экспоненциальной скользящей средней (EMA)
      gta_signalSmoothing : int64;                                                                              // Период сглаживания для третьей экспоненциальной скользящей средней (EMA)
   end;
   gta_request = record                                                                                         // Запрос для GetTechAnalysis
      gta_token : string;                                                                                       // Токен
      gta_indicatorType : string;                                                                               // Тип технического индикатора [INDICATOR_TYPE_UNSPECIFIED, INDICATOR_TYPE_BB, INDICATOR_TYPE_EMA, INDICATOR_TYPE_RSI, INDICATOR_TYPE_MACD, INDICATOR_TYPE_SMA]
      gta_instrumentUid : string;                                                                               // UID инструмента
      gta_from : string;                                                                                        // Начало запрашиваемого периода по UTC
      gta_to : string;                                                                                          // Окончание запрашиваемого периода по UTC
      gta_interval : string;                                                                                    // Интервал свечи [INDICATOR_INTERVAL_UNSPECIFIED, INDICATOR_INTERVAL_ONE_MINUTE, INDICATOR_INTERVAL_FIVE_MINUTES, INDICATOR_INTERVAL_FIFTEEN_MINUTES, INDICATOR_INTERVAL_ONE_HOUR, INDICATOR_INTERVAL_ONE_DAY, INDICATOR_INTERVAL_2_MIN, INDICATOR_INTERVAL_3_MIN, INDICATOR_INTERVAL_10_MIN, INDICATOR_INTERVAL_30_MIN, INDICATOR_INTERVAL_2_HOUR, INDICATOR_INTERVAL_4_HOUR, INDICATOR_INTERVAL_WEEK, INDICATOR_INTERVAL_MONTH]
      gta_typeOfPrice : string;                                                                                 // Тип цены, который используется при расчете индикатора [TYPE_OF_PRICE_UNSPECIFIED, TYPE_OF_PRICE_CLOSE, TYPE_OF_PRICE_OPEN, TYPE_OF_PRICE_HIGH, TYPE_OF_PRICE_LOW, TYPE_OF_PRICE_AVG]
      gta_length : int64;                                                                                       // Торговый период, за который рассчитывается индикатор
      gta_deviation : gta_deviationMultiplierStruct;                                                            // Параметры отклонения
      gta_smoothing : gta_smoothingStruct;                                                                      // Параметры сглаживания
   end;
   gta_technicalIndicatorsStruct = record
      gta_timestamp : string;                                                                                   // Временная метка по UTC, для которой были рассчитаны значения индикатора
      gta_middleBand : double;                                                                                  // Значение простого скользящего среднего (средней линии)
      gta_upperBand : double;                                                                                   // Значение верхней линии Боллинджера
      gta_lowerBand : double;                                                                                   // Значение нижней линии Боллинджера
      gta_signal : double;                                                                                      // Значение сигнальной линии
      gta_macd : double;                                                                                        // Значение линии MACD
   end;
   gta_response = record                                                                                        // Ответ для GetTechAnalysis
      gta_technicalIndicators : array of gta_technicalIndicatorsStruct;                                         // Массив значений результатов технического анализа
      gta_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gta_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gta_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры Shares
   s_request = record                                                                                           // Запрос для Shares
      s_token : string;                                                                                         // Токен
      s_instrumentStatus : string;                                                                              // Статус запрашиваемых инструментов [INSTRUMENT_TYPE_UNSPECIFIED, INSTRUMENT_STATUS_BASE, INSTRUMENT_STATUS_ALL]
      s_instrumentExchange : string;                                                                            // Тип площадки торговли [INSTRUMENT_EXCHANGE_UNSPECIFIED, INSTRUMENT_EXCHANGE_DEALER]
   end;
   s_brandStruct = record
      s_logoName : string;                                                                                      // Логотип инструмента. Имя файла для получения логотипа https://invest-brands.cdn-tbank.ru/<logoName<size>.png>, где <logoName<size>.png> — логотип компании с размерами в точках. Доступные размеры — x160, x320, x640
      s_logoBaseColor : string;                                                                                 // Цвет бренда в формате #000000...#ffffff
      s_textColor : string;                                                                                     // Цвет текста для цвета логотипа бренда в формате #000000...#ffffff
   end;
   s_instrumentsStruct = record
      s_figi : string;                                                                                          // FIGI-идентификатор инструмента
      s_ticker : string;                                                                                        // Тикер инструмента
      s_classCode : string;                                                                                     // Класс-код (секция торгов)
      s_isin : string;                                                                                          // ISIN-идентификатор инструмента
      s_lot : int64;                                                                                            // Лотность инструмента. Возможно совершение операций только на количества ценной бумаги, кратные параметру lot
      s_currency : string;                                                                                      // Валюта расчетов
      s_klong : double;                                                                                         // Коэффициент ставки риска длинной позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      s_kshort : double;                                                                                        // Коэффициент ставки риска короткой позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      s_dlong : double;                                                                                         // Ставка риска начальной маржи для КСУР лонг
      s_dshort : double;                                                                                        // Ставка риска начальной маржи для КСУР шорт
      s_dlongMin : double;                                                                                      // Ставка риска начальной маржи для КПУР лонг
      s_dshortMin : double;                                                                                     // Ставка риска начальной маржи для КПУР шорт
      s_shortEnabledFlag : boolean;                                                                             // Признак доступности для операций в шорт
      s_name : string;                                                                                          // Название инструмента
      s_exchange : string;                                                                                      // Tорговая площадка (секция биржи)
      s_ipoDate : string;                                                                                       // Дата IPO акции по UTC
      s_issueSize : int64;                                                                                      // Размер выпуска
      s_countryOfRisk : string;                                                                                 // Код страны риска — то есть страны, в которой компания ведет основной бизнес
      s_countryOfRiskName : string;                                                                             // Наименование страны риска — то есть страны, в которой компания ведет основной бизнес
      s_sector : string;                                                                                        // Сектор экономики
      s_issueSizePlan : int64;                                                                                  // Плановый размер выпуска
      s_nominal : MoneyStruct;                                                                                  // Номинал
      s_tradingStatus : string;                                                                                 // Текущий режим торгов инструмента [SECURITY_TRADING_STATUS_UNSPECIFIED, SECURITY_TRADING_STATUS_NOT_AVAILABLE_FOR_TRADING, SECURITY_TRADING_STATUS_OPENING_PERIOD, SECURITY_TRADING_STATUS_CLOSING_PERIOD, SECURITY_TRADING_STATUS_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_NORMAL_TRADING, SECURITY_TRADING_STATUS_CLOSING_AUCTION, SECURITY_TRADING_STATUS_DARK_POOL_AUCTION, SECURITY_TRADING_STATUS_DISCRETE_AUCTION, SECURITY_TRADING_STATUS_OPENING_AUCTION_PERIOD, SECURITY_TRADING_STATUS_TRADING_AT_CLOSING_AUCTION_PRICE, SECURITY_TRADING_STATUS_SESSION_ASSIGNED, SECURITY_TRADING_STATUS_SESSION_CLOSE, SECURITY_TRADING_STATUS_SESSION_OPEN, SECURITY_TRADING_STATUS_DEALER_NORMAL_TRADING, SECURITY_TRADING_STATUS_DEALER_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_DEALER_NOT_AVAILABLE_FOR_TRADING]
      s_otcFlag : boolean;                                                                                      // Флаг, используемый ранее для определения внебиржевых инструментов. На данный момент не используется для торгуемых через API инструментов. Может использоваться как фильтр для операций, совершавшихся некоторое время назад на ОТС площадке
      s_buyAvailableFlag : boolean;                                                                             // Признак доступности для покупки
      s_sellAvailableFlag : boolean;                                                                            // Признак доступности для продажи
      s_divYieldFlag : boolean;                                                                                 // Признак наличия дивидендной доходности
      s_shareType : string;                                                                                     // Тип акций [SHARE_TYPE_UNSPECIFIED, SHARE_TYPE_COMMON, SHARE_TYPE_PREFERRED, SHARE_TYPE_ADR, SHARE_TYPE_GDR, SHARE_TYPE_MLP, SHARE_TYPE_NY_REG_SHRS, SHARE_TYPE_CLOSED_END_FUND, SHARE_TYPE_REIT]
      s_minPriceIncrement : double;                                                                             // Шаг цены
      s_apiTradeAvailableFlag : boolean;                                                                        // Возможность торговать инструментом через API
      s_uid : string;                                                                                           // Уникальный идентификатор инструмента
      s_realExchange : string;                                                                                  // Реальная площадка исполнения расчетов [REAL_EXCHANGE_UNSPECIFIED, REAL_EXCHANGE_MOEX, REAL_EXCHANGE_RTS, REAL_EXCHANGE_OTC, REAL_EXCHANGE_DEALER]
      s_positionUid : string;                                                                                   // Уникальный идентификатор позиции инструмента
      s_assetUid : string;                                                                                      // Уникальный идентификатор актива
      s_instrumentExchange : string;                                                                            // Площадка торговли [INSTRUMENT_EXCHANGE_UNSPECIFIED, INSTRUMENT_EXCHANGE_DEALER]
      s_requiredTests : array of string;                                                                        // Тесты, которые необходимо пройти клиенту, чтобы совершать сделки по инструменту
      s_forIisFlag : boolean;                                                                                   // Признак доступности для ИИС
      s_forQualInvestorFlag : boolean;                                                                          // Флаг, отображающий доступность торговли инструментом только для квалифицированных инвесторов
      s_weekendFlag : boolean;                                                                                  // Флаг, отображающий доступность торговли инструментом по выходным
      s_blockedTcaFlag : boolean;                                                                               // Флаг заблокированного ТКС
      s_liquidityFlag : boolean;                                                                                // Флаг достаточной ликвидности
      s_first1minCandleDate : string;                                                                           // Дата первой минутной свечи
      s_first1dayCandleDate : string;                                                                           // Дата первой дневной свечи
      s_brand : s_brandStruct;                                                                                  // Информация о бренде
      s_dlongClient : double;                                                                                   // Ставка риска в лонг, с учетом текущего уровня риска портфеля клиента
      s_dshortClient : double;                                                                                  // Ставка риска в шорт, с учетом текущего уровня риска портфеля клиента
   end;
   s_response = record                                                                                          // Ответ для Shares
      s_instruments : array of s_instrumentsStruct;                                                             // Массив акций
      s_error_code : int64;                                                                                     // Уникальный идентификатор ошибки
      s_error_message : string;                                                                                 // Пользовательское сообщение об ошибке
      s_error_description : int64;                                                                              // Код ошибки
   end;

   // Структуры для процедуры ShareBy
   sb_request = record                                                                                          // Запрос для ShareBy
      sb_token : string;                                                                                        // Токен
      sb_idType : string;                                                                                       // Тип идентификатора инструмента [INSTRUMENT_ID_UNSPECIFIED, INSTRUMENT_ID_TYPE_FIGI, INSTRUMENT_ID_TYPE_TICKER, INSTRUMENT_ID_TYPE_UID, INSTRUMENT_ID_TYPE_POSITION_UID]
      sb_classCode : string;                                                                                    // Идентификатор class_code. Обязательный, если id_type = ticker
      sb_id : string;                                                                                           // Идентификатор запрашиваемого инструмента
   end;
   sb_response = record                                                                                         // Ответ для ShareBy
      sb_instrument : s_instrumentsStruct;                                                                      // Объект передачи информации об акции
      sb_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      sb_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      sb_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры Bonds
   b_request = record                                                                                           // Запрос для Bonds
      b_token : string;                                                                                         // Токен
      b_instrumentStatus : string;                                                                              // Статус запрашиваемых инструментов [INSTRUMENT_STATUS_UNSPECIFIED, INSTRUMENT_STATUS_BASE, INSTRUMENT_STATUS_ALL]
      b_instrumentExchange : string;                                                                            // Площадка торговли [INSTRUMENT_EXCHANGE_UNSPECIFIED, INSTRUMENT_EXCHANGE_DEALER]
   end;
   b_brandStruct = record
      b_logoName : string;                                                                                      // Логотип инструмента. Имя файла для получения логотипа https://invest-brands.cdn-tbank.ru/<logoName<size>.png>, где <logoName<size>.png> — логотип компании с размерами в точках. Доступные размеры — x160, x320, x640
      b_logoBaseColor : string;                                                                                 // Цвет бренда в формате #000000...#ffffff
      b_textColor : string;                                                                                     // Цвет текста для цвета логотипа бренда в формате #000000...#ffffff
   end;
   b_instrumentsStruct = record
      b_figi : string;                                                                                          // FIGI-идентификатор инструмента
      b_ticker : string;                                                                                        // Тикер инструмента
      b_classCode : string;                                                                                     // Класс-код (секция торгов)
      b_isin : string;                                                                                          // ISIN-идентификатор инструмента
      b_lot : int64;                                                                                            // Лотность инструмента. Возможно совершение операций только на количества ценной бумаги, кратные параметру lot
      b_currency : string;                                                                                      // Валюта расчетов
      b_klong : double;                                                                                         // Коэффициент ставки риска длинной позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      b_kshort : double;                                                                                        // Коэффициент ставки риска короткой позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      b_dlong : double;                                                                                         // Ставка риска начальной маржи для КСУР лонг
      b_dshort : double;                                                                                        // Ставка риска начальной маржи для КСУР шорт
      b_dlongMin : double;                                                                                      // Ставка риска начальной маржи для КПУР лонг
      b_dshortMin : double;                                                                                     // Ставка риска начальной маржи для КПУР шорт
      b_shortEnabledFlag : boolean;                                                                             // Признак доступности для операций в шорт
      b_name : string;                                                                                          // Название инструмента.
      b_exchange : string;                                                                                      // Tорговая площадка (секция биржи)
      b_couponQuantityPerYear : int64;                                                                          // Количество выплат по купонам в год
      b_maturityDate : string;                                                                                  // Дата погашения облигации по UTC
      b_nominal : MoneyStruct;                                                                                  // Номинал облигации
      b_initialNominal : MoneyStruct;                                                                           // Первоначальный номинал облигации
      b_stateRegDate : string;                                                                                  // Дата выпуска облигации по UTC
      b_placementDate : string;                                                                                 // Дата размещения по UTC
      b_placementPrice : MoneyStruct;                                                                           // Цена размещения
      b_aciValue : MoneyStruct;                                                                                 // Значение НКД (накопленного купонного дохода) на дату
      b_countryOfRisk : string;                                                                                 // Код страны риска — то есть страны, в которой компания ведет основной бизнес
      b_countryOfRiskName : string;                                                                             // Наименование страны риска — то есть страны, в которой компания ведет основной бизнес
      b_sector : string;                                                                                        // Сектор экономики
      b_issueKind : string;                                                                                     // Форма выпуска. Возможные значения: documentary — документарная; non_documentary — бездокументарная
      b_issueSize : int64;                                                                                      // Размер выпуска
      b_issueSizePlan : int64;                                                                                  // Плановый размер выпуска
      b_tradingStatus : string;                                                                                 // Текущий режим торгов инструмента [SECURITY_TRADING_STATUS_UNSPECIFIED, SECURITY_TRADING_STATUS_NOT_AVAILABLE_FOR_TRADING, SECURITY_TRADING_STATUS_OPENING_PERIOD, SECURITY_TRADING_STATUS_CLOSING_PERIOD, SECURITY_TRADING_STATUS_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_NORMAL_TRADING, SECURITY_TRADING_STATUS_CLOSING_AUCTION, SECURITY_TRADING_STATUS_DARK_POOL_AUCTION, SECURITY_TRADING_STATUS_DISCRETE_AUCTION, SECURITY_TRADING_STATUS_OPENING_AUCTION_PERIOD, SECURITY_TRADING_STATUS_TRADING_AT_CLOSING_AUCTION_PRICE, SECURITY_TRADING_STATUS_SESSION_ASSIGNED, SECURITY_TRADING_STATUS_SESSION_CLOSE, SECURITY_TRADING_STATUS_SESSION_OPEN, SECURITY_TRADING_STATUS_DEALER_NORMAL_TRADING, SECURITY_TRADING_STATUS_DEALER_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_DEALER_NOT_AVAILABLE_FOR_TRADING]
      b_otcFlag : boolean;                                                                                      // Флаг, используемый ранее для определения внебиржевых инструментов. На данный момент не используется для торгуемых через API инструментов. Может использоваться как фильтр для операций, совершавшихся некоторое время назад на ОТС площадке
      b_buyAvailableFlag : boolean;                                                                             // Признак доступности для покупки
      b_sellAvailableFlag : boolean;                                                                            // Признак доступности для продажи
      b_floatingCouponFlag : boolean;                                                                           // Признак облигации с плавающим купоном
      b_perpetualFlag : boolean;                                                                                // Признак бессрочной облигации
      b_amortizationFlag : boolean;                                                                             // Признак облигации с амортизацией долга
      b_minPriceIncrement : double;                                                                             // Шаг цены
      b_apiTradeAvailableFlag : boolean;                                                                        // Параметр указывает на возможность торговать инструментом через API
      b_uid : string;                                                                                           // Уникальный идентификатор инструмента
      b_realExchange : string;                                                                                  // Реальная площадка исполнения расчетов [REAL_EXCHANGE_UNSPECIFIED, REAL_EXCHANGE_MOEX, REAL_EXCHANGE_RTS, REAL_EXCHANGE_OTC, REAL_EXCHANGE_DEALER]
      b_positionUid : string;                                                                                   // Уникальный идентификатор позиции инструмента
      b_assetUid : string;                                                                                      // Уникальный идентификатор актива
      b_requiredTests : array of string;                                                                        // Тесты, которые необходимо пройти клиенту, чтобы совершать сделки по инструменту
      b_forIisFlag : boolean;                                                                                   // Признак доступности для ИИС
      b_forQualInvestorFlag : boolean;                                                                          // Флаг, отображающий доступность торговли инструментом только для квалифицированных инвесторов
      b_weekendFlag : boolean;                                                                                  // Флаг, отображающий доступность торговли инструментом по выходным
      b_blockedTcaFlag : boolean;                                                                               // Флаг заблокированного ТКС
      b_subordinatedFlag : boolean;                                                                             // Признак субординированной облигации
      b_liquidityFlag : boolean;                                                                                // Флаг достаточной ликвидности
      b_first1minCandleDate : string;                                                                           // Дата первой минутной свечи
      b_first1dayCandleDate : string;                                                                           // Дата первой дневной свечи
      b_riskLevel : string;                                                                                     // Уровень риска облигации
      b_brand : b_brandStruct;                                                                                  // Информация о бренде
      b_bondType : string;                                                                                      // Тип облигации [BOND_TYPE_UNSPECIFIED, BOND_TYPE_REPLACED]
      b_callDate : string;                                                                                      // Дата погашения облигации (оферта?)
      b_dlongClient : double;                                                                                   // Ставка риска в лонг, с учетом текущего уровня риска портфеля клиента
      b_dshortClient : double;                                                                                  // Ставка риска в шорт, с учетом текущего уровня риска портфеля клиента
   end;
   b_response = record                                                                                          // Ответ для Bonds
      b_instruments : array of b_instrumentsStruct;                                                             // Массив облигаций
      b_error_code : int64;                                                                                     // Уникальный идентификатор ошибки
      b_error_message : string;                                                                                 // Пользовательское сообщение об ошибке
      b_error_description : int64;                                                                              // Код ошибки
   end;

   // Структуры для процедуры BondBy
   bb_request = record                                                                                          // Запрос для BondBy
      bb_token : string;                                                                                        // Токен
      bb_idType : string;                                                                                       // Тип идентификатора инструмента [INSTRUMENT_ID_UNSPECIFIED, INSTRUMENT_ID_TYPE_FIGI, INSTRUMENT_ID_TYPE_TICKER, INSTRUMENT_ID_TYPE_UID, INSTRUMENT_ID_TYPE_POSITION_UID]
      bb_classCode : string;                                                                                    // Идентификатор class_code. Обязательный, если id_type = ticker
      bb_id : string;                                                                                           // Идентификатор запрашиваемого инструмента
   end;
   bb_response = record                                                                                         // Ответ для BondBy
      bb_instrument : b_instrumentsStruct;                                                                      // Объект передачи информации об облигации
      bb_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      bb_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      bb_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры Futures
   f_request = record                                                                                           // Запрос для Futures
      f_token : string;                                                                                         // Токен
      f_instrumentStatus : string;                                                                              // Статус запрашиваемых инструментов [INSTRUMENT_STATUS_UNSPECIFIED, INSTRUMENT_STATUS_BASE, INSTRUMENT_STATUS_ALL]
      f_instrumentExchange : string;                                                                            // Площадка торговли [INSTRUMENT_EXCHANGE_UNSPECIFIED, INSTRUMENT_EXCHANGE_DEALER]
   end;
   f_brandStruct = record
      f_logoName : string;                                                                                      // Логотип инструмента. Имя файла для получения логотипа https://invest-brands.cdn-tbank.ru/<logoName<size>.png>, где <logoName<size>.png> — логотип компании с размерами в точках. Доступные размеры — x160, x320, x640
      f_logoBaseColor : string;                                                                                 // Цвет бренда в формате #000000...#ffffff
      f_textColor : string;                                                                                     // Цвет текста для цвета логотипа бренда в формате #000000...#ffffff
   end;  
   f_instrumentsStruct = record
      f_figi : string;                                                                                          // FIGI-идентификатор инструмента
      f_ticker : string;                                                                                        // Тикер инструмента
      f_classCode : string;                                                                                     // Класс-код (секция торгов)
      f_lot : int64;                                                                                            // Лотность инструмента. Возможно совершение операций только на количества ценной бумаги, кратные параметру lot
      f_currency : string;                                                                                      // Валюта расчетов
      f_klong : double;                                                                                         // Коэффициент ставки риска длинной позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      f_kshort : double;                                                                                        // Коэффициент ставки риска короткой позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      f_dlong : double;                                                                                         // Ставка риска начальной маржи для КСУР лонг
      f_dshort : double;                                                                                        // Ставка риска начальной маржи для КСУР шорт
      f_dlongMin : double;                                                                                      // Ставка риска начальной маржи для КПУР лонг
      f_dshortMin : double;                                                                                     // Ставка риска начальной маржи для КПУР шорт
      f_shortEnabledFlag : boolean;                                                                             // Признак доступности для операций шорт
      f_name : string;                                                                                          // Название инструмента
      f_exchange : string;                                                                                      // Tорговая площадка (секция биржи)
      f_firstTradeDate : string;                                                                                // Дата начала обращения контракта по UTC
      f_lastTradeDate : string;                                                                                 // Дата по UTC, до которой возможно проведение операций с фьючерсом
      f_futuresType : string;                                                                                   // Тип фьючерса. Возможные значения: physical_delivery — физические поставки; cash_settlement — денежный эквивалент
      f_assetType : string;                                                                                     // Тип актива. Возможные значения: commodity — товар; currency — валюта; security — ценная бумага; index — индекс
      f_basicAsset : string;                                                                                    // Основной актив
      f_basicAssetSize : double;                                                                                // Размер основного актива
      f_countryOfRisk : string;                                                                                 // Код страны риска — то есть страны, в которой компания ведёт основной бизнес
      f_countryOfRiskName : string;                                                                             // Наименование страны риска — то есть страны, в которой компания ведёт основной бизнес
      f_sector : string;                                                                                        // Сектор экономики
      f_expirationDate : string;                                                                                // Дата истечения срока в часов поясе UTC
      f_tradingStatus : string;                                                                                 // Текущий режим торгов инструмента [SECURITY_TRADING_STATUS_UNSPECIFIED, SECURITY_TRADING_STATUS_NOT_AVAILABLE_FOR_TRADING, SECURITY_TRADING_STATUS_OPENING_PERIOD, SECURITY_TRADING_STATUS_CLOSING_PERIOD, SECURITY_TRADING_STATUS_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_NORMAL_TRADING, SECURITY_TRADING_STATUS_CLOSING_AUCTION, SECURITY_TRADING_STATUS_DARK_POOL_AUCTION, SECURITY_TRADING_STATUS_DISCRETE_AUCTION, SECURITY_TRADING_STATUS_OPENING_AUCTION_PERIOD, SECURITY_TRADING_STATUS_TRADING_AT_CLOSING_AUCTION_PRICE, SECURITY_TRADING_STATUS_SESSION_ASSIGNED, SECURITY_TRADING_STATUS_SESSION_CLOSE, SECURITY_TRADING_STATUS_SESSION_OPEN, SECURITY_TRADING_STATUS_DEALER_NORMAL_TRADING, SECURITY_TRADING_STATUS_DEALER_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_DEALER_NOT_AVAILABLE_FOR_TRADING]
      f_otcFlag : boolean;                                                                                      // Флаг, используемый ранее для определения внебиржевых инструментов. На данный момент не используется для торгуемых через API инструментов. Может использоваться как фильтр для операций, совершавшихся некоторое время назад на ОТС площадке
      f_buyAvailableFlag : boolean;                                                                             // Признак доступности для покупки
      f_sellAvailableFlag : boolean;                                                                            // Признак доступности для продажи
      f_minPriceIncrement : double;                                                                             // Шаг цены
      f_apiTradeAvailableFlag : boolean;                                                                        // Параметр указывает на возможность торговать инструментом через API
      f_uid : string;                                                                                           // Уникальный идентификатор инструмента
      f_realExchange : string;                                                                                  // Реальная площадка исполнения расчетов [REAL_EXCHANGE_UNSPECIFIED, REAL_EXCHANGE_MOEX, REAL_EXCHANGE_RTS, REAL_EXCHANGE_OTC, REAL_EXCHANGE_DEALER]
      f_positionUid : string;                                                                                   // Уникальный идентификатор позиции инструмента
      f_basicAssetPositionUid : string;                                                                         // Уникальный идентификатор позиции основного инструмента
      f_requiredTests : array of string;                                                                        // Тесты, которые необходимо пройти клиенту, чтобы совершать сделки по инструменту
      f_forIisFlag : boolean;                                                                                   // Признак доступности для ИИС
      f_forQualInvestorFlag : boolean;                                                                          // Флаг, отображающий доступность торговли инструментом только для квалифицированных инвесторов
      f_weekendFlag : boolean;                                                                                  // Флаг, отображающий доступность торговли инструментом по выходным
      f_blockedTcaFlag : boolean;                                                                               // Флаг заблокированного ТКС
      f_first1minCandleDate : string;                                                                           // Дата первой минутной свечи
      f_first1dayCandleDate : string;                                                                           // Дата первой дневной свечи
      f_initialMarginOnBuy : MoneyStruct;                                                                       // Гарантийное обеспечение при покупке
      f_initialMarginOnSell : MoneyStruct;                                                                      // Гарантийное обеспечение при продаже
      f_minPriceIncrementAmount : double;                                                                       // Стоимость шага цены
      f_brand : f_brandStruct;                                                                                  // Информация о бренде
      f_dlongClient : double;                                                                                   // Ставка риска в лонг, с учетом текущего уровня риска портфеля клиента
      f_dshortClient : double;                                                                                  // Ставка риска в шорт, с учетом текущего уровня риска портфеля клиента
   end;
   f_response = record                                                                                          // Ответ для Futures
      f_instruments : array of f_instrumentsStruct;                                                             // Массив облигаций
      f_error_code : int64;                                                                                     // Уникальный идентификатор ошибки
      f_error_message : string;                                                                                 // Пользовательское сообщение об ошибке
      f_error_description : int64;                                                                              // Код ошибки
   end;

   // Структуры для процедуры FutureBy
   fb_request = record                                                                                          // Запрос для FutureBy
      fb_token : string;                                                                                        // Токен
      fb_idType : string;                                                                                       // Тип идентификатора инструмента [INSTRUMENT_ID_UNSPECIFIED, INSTRUMENT_ID_TYPE_FIGI, INSTRUMENT_ID_TYPE_TICKER, INSTRUMENT_ID_TYPE_UID, INSTRUMENT_ID_TYPE_POSITION_UID]
      fb_classCode : string;                                                                                    // Идентификатор class_code. Обязательный, если id_type = ticker
      fb_id : string;                                                                                           // Идентификатор запрашиваемого инструмента
   end;
   fb_response = record                                                                                         // Ответ для FutureBy
      fb_instrument : f_instrumentsStruct;                                                                      // Объект передачи информации о фьючерсе
      fb_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      fb_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      fb_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры Etfs
   e_request = record                                                                                           // Запрос для Etfs
      e_token : string;                                                                                         // Токен
      e_instrumentStatus : string;                                                                              // Статус запрашиваемых инструментов [INSTRUMENT_STATUS_UNSPECIFIED, INSTRUMENT_STATUS_BASE, INSTRUMENT_STATUS_ALL]
      e_instrumentExchange : string;                                                                            // Площадка торговли [INSTRUMENT_EXCHANGE_UNSPECIFIED, INSTRUMENT_EXCHANGE_DEALER]
   end;
   e_brandStruct = record
      e_logoName : string;                                                                                      // Логотип инструмента. Имя файла для получения логотипа https://invest-brands.cdn-tbank.ru/<logoName<size>.png>, где <logoName<size>.png> — логотип компании с размерами в точках. Доступные размеры — x160, x320, x640
      e_logoBaseColor : string;                                                                                 // Цвет бренда в формате #000000...#ffffff
      e_textColor : string;                                                                                     // Цвет текста для цвета логотипа бренда в формате #000000...#ffffff
   end;
   e_instrumentsStruct = record
      e_figi : string;                                                                                          // FIGI-идентификатор инструмента
      e_ticker : string;                                                                                        // Тикер инструмента
      e_classCode : string;                                                                                     // Класс-код (секция торгов)
      e_isin : string;                                                                                          // ISIN-идентификатор инструмента
      e_lot : int64;                                                                                            // Лотность инструмента. Возможно совершение операций только на количества ценной бумаги, кратные параметру lot
      e_currency : string;                                                                                      // Валюта расчетов
      e_klong : double;                                                                                         // Коэффициент ставки риска длинной позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      e_kshort : double;                                                                                        // Коэффициент ставки риска короткой позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      e_dlong : double;                                                                                         // Ставка риска начальной маржи для КСУР лонг
      e_dshort : double;                                                                                        // Ставка риска начальной маржи для КСУР шорт
      e_dlongMin : double;                                                                                      // Ставка риска начальной маржи для КПУР лонг
      e_dshortMin : double;                                                                                     // Ставка риска начальной маржи для КПУР шорт
      e_shortEnabledFlag : boolean;                                                                             // Признак доступности для операций в шорт
      e_name : string;                                                                                          // Название инструмента
      e_exchange : string;                                                                                      // Tорговая площадка (секция биржи)
      e_fixedCommission : double;                                                                               // Размер фиксированной комиссии фонда
      e_focusType : string;                                                                                     // Возможные значения: equity — акции; fixed_income — облигации; mixed_allocation — смешанный; money_market — денежный рынок; real_estate — недвижимость; commodity — товары; specialty — специальный; private_equity — private equity; alternative_investment — альтернативные инвестиции
      e_releasedDate : string;                                                                                  // Дата выпуска по UTC
      e_numShares : double;                                                                                     // Количество паев фонда в обращении
      e_countryOfRisk : string;                                                                                 // Код страны риска — то есть страны, в которой компания ведет основной бизнес
      e_countryOfRiskName : string;                                                                             // Наименование страны риска — то есть страны, в которой компания ведет основной бизнес
      e_sector : string;                                                                                        // Сектор экономики
      e_rebalancingFreq : string;                                                                               // Частота ребалансировки
      e_tradingStatus : string;                                                                                 // Текущий режим торгов инструмента [SECURITY_TRADING_STATUS_UNSPECIFIED, SECURITY_TRADING_STATUS_NOT_AVAILABLE_FOR_TRADING, SECURITY_TRADING_STATUS_OPENING_PERIOD, SECURITY_TRADING_STATUS_CLOSING_PERIOD, SECURITY_TRADING_STATUS_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_NORMAL_TRADING, SECURITY_TRADING_STATUS_CLOSING_AUCTION, SECURITY_TRADING_STATUS_DARK_POOL_AUCTION, SECURITY_TRADING_STATUS_DISCRETE_AUCTION, SECURITY_TRADING_STATUS_OPENING_AUCTION_PERIOD, SECURITY_TRADING_STATUS_TRADING_AT_CLOSING_AUCTION_PRICE, SECURITY_TRADING_STATUS_SESSION_ASSIGNED, SECURITY_TRADING_STATUS_SESSION_CLOSE, SECURITY_TRADING_STATUS_SESSION_OPEN, SECURITY_TRADING_STATUS_DEALER_NORMAL_TRADING, SECURITY_TRADING_STATUS_DEALER_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_DEALER_NOT_AVAILABLE_FOR_TRADING]
      e_otcFlag : boolean;                                                                                      // Флаг, используемый ранее для определения внебиржевых инструментов. На данный момент не используется для торгуемых через API инструментов. Может использоваться как фильтр для операций, совершавшихся некоторое время назад на ОТС площадке
      e_buyAvailableFlag : boolean;                                                                             // Признак доступности для покупки
      e_sellAvailableFlag : boolean;                                                                            // Признак доступности для продажи
      e_minPriceIncrement : double;                                                                             // Шаг цены
      e_apiTradeAvailableFlag : boolean;                                                                        // Параметр указывает на возможность торговать инструментом через API
      e_uid : string;                                                                                           // Уникальный идентификатор инструмента
      e_realExchange : string;                                                                                  // Реальная площадка исполнения расчетов [REAL_EXCHANGE_UNSPECIFIED, REAL_EXCHANGE_MOEX, REAL_EXCHANGE_RTS, REAL_EXCHANGE_OTC, REAL_EXCHANGE_DEALER]
      e_positionUid : string;                                                                                   // Уникальный идентификатор позиции инструмента
      e_assetUid : string;                                                                                      // Уникальный идентификатор актива
      e_instrumentExchange : string;                                                                            // Площадка торговли [INSTRUMENT_EXCHANGE_UNSPECIFIED, INSTRUMENT_EXCHANGE_DEALER]
      e_requiredTests : array of string;                                                                        // Тесты, которые необходимо пройти клиенту, чтобы совершать сделки по инструменту
      e_forIisFlag : boolean;                                                                                   // Признак доступности для ИИС
      e_forQualInvestorFlag : boolean;                                                                          // Флаг, отображающий доступность торговли инструментом только для квалифицированных инвесторов
      e_weekendFlag : boolean;                                                                                  // Флаг, отображающий доступность торговли инструментом по выходным
      e_blockedTcaFlag : boolean;                                                                               // Флаг заблокированного ТКС
      e_liquidityFlag : boolean;                                                                                // Флаг достаточной ликвидности
      e_first1minCandleDate : string;                                                                           // Дата первой минутной свечи
      e_first1dayCandleDate : string;                                                                           // Дата первой дневной свечи
      e_brand : e_brandStruct;                                                                                  // Информация о бренде
      e_dlongClient : double;                                                                                   // Ставка риска в лонг, с учетом текущего уровня риска портфеля клиента
      e_dshortClient : double;                                                                                  // Ставка риска в шорт, с учетом текущего уровня риска портфеля клиента
   end;
   e_response = record                                                                                          // Ответ для Etfs
      e_instruments : array of e_instrumentsStruct;                                                             // Массив фондов
      e_error_code : int64;                                                                                     // Уникальный идентификатор ошибки
      e_error_message : string;                                                                                 // Пользовательское сообщение об ошибке
      e_error_description : int64;                                                                              // Код ошибки
   end;

   // Структуры для процедуры EtfBy
   eb_request = record                                                                                          // Запрос для EtfBy
      eb_token : string;                                                                                        // Токен
      eb_idType : string;                                                                                       // Тип идентификатора инструмента [INSTRUMENT_ID_UNSPECIFIED, INSTRUMENT_ID_TYPE_FIGI, INSTRUMENT_ID_TYPE_TICKER, INSTRUMENT_ID_TYPE_UID, INSTRUMENT_ID_TYPE_POSITION_UID]
      eb_classCode : string;                                                                                    // Идентификатор class_code. Обязательный, если id_type = ticker
      eb_id : string;                                                                                           // Идентификатор запрашиваемого инструмента
   end;
   eb_response = record                                                                                         // Ответ для EtfBy
      eb_instrument : e_instrumentsStruct;                                                                      // Объект передачи информации об инвестиционном фонде
      eb_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      eb_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      eb_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры FindInstrument
   fi_request = record                                                                                          // Запрос для FindInstrument
      fi_token : string;                                                                                        // Токен
      fi_query : string;                                                                                        // Строка поиска
      fi_instrumentKind : string;                                                                               // Тип инструмента [INSTRUMENT_TYPE_UNSPECIFIED, INSTRUMENT_TYPE_BOND, INSTRUMENT_TYPE_SHARE, INSTRUMENT_TYPE_CURRENCY, INSTRUMENT_TYPE_ETF, INSTRUMENT_TYPE_FUTURES, INSTRUMENT_TYPE_SP, INSTRUMENT_TYPE_OPTION, INSTRUMENT_TYPE_CLEARING_CERTIFICATE, INSTRUMENT_TYPE_INDEX, INSTRUMENT_TYPE_COMMODITY]
      fi_apiTradeAvailableFlag : boolean;                                                                       // Фильтр для отображения только торговых инструментов
   end;
   fi_instrumentsStruct = record
      fi_isin : string;                                                                                         // ISIN-идентификатор инструмента
      fi_figi : string;                                                                                         // FIGI-идентификатор инструмента
      fi_ticker : string;                                                                                       // Тикер инструмента
      fi_classCode : string;                                                                                    // Класс-код (секция торгов)
      fi_instrumentType : string;                                                                               // Тип инструмента
      fi_name : string;                                                                                         // Название инструмента
      fi_uid : string;                                                                                          // Уникальный идентификатор инструмента
      fi_positionUid : string;                                                                                  // Уникальный идентификатор позиции инструмента
      fi_instrumentKind : string;                                                                               // Тип инструмента [INSTRUMENT_TYPE_UNSPECIFIED, INSTRUMENT_TYPE_BOND, INSTRUMENT_TYPE_SHARE, INSTRUMENT_TYPE_CURRENCY, INSTRUMENT_TYPE_ETF, INSTRUMENT_TYPE_FUTURES, INSTRUMENT_TYPE_SP, INSTRUMENT_TYPE_OPTION, INSTRUMENT_TYPE_CLEARING_CERTIFICATE, INSTRUMENT_TYPE_INDEX, INSTRUMENT_TYPE_COMMODITY]
      fi_apiTradeAvailableFlag : boolean;                                                                       // Возможность торговать инструментом через API
      fi_forIisFlag : boolean;                                                                                  // Признак доступности для ИИС
      fi_first1minCandleDate : string;                                                                          // Дата первой минутной свечи
      fi_first1dayCandleDate : string;                                                                          // Дата первой дневной свечи
      fi_forQualInvestorFlag : boolean;                                                                         // Флаг, отображающий доступность торговли инструментом только для квалифицированных инвесторов
      fi_weekendFlag : boolean;                                                                                 // Флаг, отображающий доступность торговли инструментом по выходным
      fi_blockedTcaFlag : boolean;                                                                              // Флаг заблокированного ТКС
      fi_lot : int64;                                                                                           // Количество бумаг в лоте
   end;
   fi_response = record                                                                                         // Ответ для FindInstrument
      fi_instruments : array of fi_instrumentsStruct;                                                           // Массив инструментов, удовлетворяющих условиям поиска
      fi_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      fi_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      fi_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetTradingStatus
   gts_request = record                                                                                         // Запрос для GetTradingStatus
      gts_token : string;                                                                                       // Токен
      gts_instrumentId : string;                                                                                // Идентификатор инструмента. Принимает значение figi или instrument_uid
   end;
   gts_response = record                                                                                        // Ответ для GetTradingStatus
      gts_figi : string;                                                                                        // FIGI-идентификатор инструмента
      gts_tradingStatus : string;                                                                               // Статус торговли инструментом [SECURITY_TRADING_STATUS_UNSPECIFIED, SECURITY_TRADING_STATUS_NOT_AVAILABLE_FOR_TRADING, SECURITY_TRADING_STATUS_OPENING_PERIOD, SECURITY_TRADING_STATUS_CLOSING_PERIOD, SECURITY_TRADING_STATUS_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_NORMAL_TRADING, SECURITY_TRADING_STATUS_CLOSING_AUCTION, SECURITY_TRADING_STATUS_DARK_POOL_AUCTION, SECURITY_TRADING_STATUS_DISCRETE_AUCTION, SECURITY_TRADING_STATUS_OPENING_AUCTION_PERIOD, SECURITY_TRADING_STATUS_TRADING_AT_CLOSING_AUCTION_PRICE, SECURITY_TRADING_STATUS_SESSION_ASSIGNED, SECURITY_TRADING_STATUS_SESSION_CLOSE, SECURITY_TRADING_STATUS_SESSION_OPEN, SECURITY_TRADING_STATUS_DEALER_NORMAL_TRADING, SECURITY_TRADING_STATUS_DEALER_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_DEALER_NOT_AVAILABLE_FOR_TRADING]
      gts_limitOrderAvailableFlag : boolean;                                                                    // Признак доступности выставления лимитной заявки по инструменту
      gts_marketOrderAvailableFlag : boolean;                                                                   // Признак доступности выставления рыночной заявки по инструменту
      gts_apiTradeAvailableFlag : boolean;                                                                      // Признак доступности торгов через API
      gts_instrumentUid : string;                                                                               // UID инструмента
      gts_bestpriceOrderAvailableFlag : boolean;                                                                // Признак доступности завяки по лучшей цене
      gts_onlyBestPrice : boolean;                                                                              // Признак доступности только заявки по лучшей цене
      gts_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gts_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gts_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры CancelStopOrder
   cso_request = record                                                                                         // Запрос для CancelStopOrder
      cso_token : string;                                                                                       // Токен
      cso_accountId : string;                                                                                   // Идентификатор счета клиента
      cso_stopOrderId : string;                                                                                 // Уникальный идентификатор стоп-заявки
   end;
   cso_response = record                                                                                        // Ответ для CancelStopOrder
      cso_time : string;                                                                                        // Время отмены заявки по UTC
      cso_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      cso_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      cso_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры PostStopOrder
   pso_trailingDataStruct = record
      pso_indent : double;                                                                                      // Отступ
      pso_indentType : string;                                                                                  // Тип параметров значений трейлинг-стопа [TRAILING_VALUE_UNSPECIFIED, TRAILING_VALUE_ABSOLUTE, TRAILING_VALUE_RELATIVE]
      pso_spread : double;                                                                                      // Размер защитного спреда
      pso_spreadType : string;                                                                                  // Тип величины защитного спреда [TRAILING_VALUE_UNSPECIFIED, TRAILING_VALUE_ABSOLUTE, TRAILING_VALUE_RELATIVE]
   end;
   pso_request = record                                                                                         // Запрос для PostStopOrder
      pso_token : string;                                                                                       // Токен
      pso_quantity : int64;                                                                                     // Количество лотов
      pso_price : double;                                                                                       // Цена за 1 инструмент биржевой заявки, которая будет выставлена при срабатывании по достижению stop_price. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      pso_stopPrice : double;                                                                                   // Стоп-цена заявки за 1 инструмент. При достижении стоп-цены происходит активация стоп-заявки, в результате чего выставляется биржевая заявка. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      pso_direction : string;                                                                                   // Направление сделки стоп-заявки [STOP_ORDER_DIRECTION_UNSPECIFIED, STOP_ORDER_DIRECTION_BUY, STOP_ORDER_DIRECTION_SELL]
      pso_accountId : string;                                                                                   // Идентификатор счета клиента
      pso_expirationType : string;                                                                              // Тип экспирации стоп-заявке [STOP_ORDER_EXPIRATION_TYPE_UNSPECIFIED, STOP_ORDER_EXPIRATION_TYPE_GOOD_TILL_CANCEL, STOP_ORDER_EXPIRATION_TYPE_GOOD_TILL_DATE]
      pso_stopOrderType : string;                                                                               // Тип стоп-заявки [STOP_ORDER_TYPE_UNSPECIFIED, STOP_ORDER_TYPE_TAKE_PROFIT, STOP_ORDER_TYPE_STOP_LOSS, STOP_ORDER_TYPE_STOP_LIMIT]
      pso_expireDate : string;                                                                                  // Дата и время окончания действия стоп-заявки по UTC. Для ExpirationType = GoodTillDate заполнение обязательно, для GoodTillCancel игнорируется
      pso_instrumentId : string;                                                                                // Идентификатор инструмента. Принимает значение figi или instrument_uid
      pso_exchangeOrderType : string;                                                                           // Тип выставляемой заявки [EXCHANGE_ORDER_TYPE_UNSPECIFIED, EXCHANGE_ORDER_TYPE_MARKET, EXCHANGE_ORDER_TYPE_LIMIT]
      pso_takeProfitType : string;                                                                              // Тип TakeProfit-заявки [TAKE_PROFIT_TYPE_UNSPECIFIED, TAKE_PROFIT_TYPE_REGULAR, TAKE_PROFIT_TYPE_TRAILING]
      pso_trailingData : pso_trailingDataStruct;                                                                // Массив с параметрами трейлинг-стопа
      pso_priceType : string;                                                                                   // Тип цены [PRICE_TYPE_UNSPECIFIED, PRICE_TYPE_POINT, PRICE_TYPE_CURRENCY]
      pso_orderId : string;                                                                                     // Идентификатор запроса выставления поручения для целей идемпотентности в формате UID. Максимальная длина — 36 символов
      pso_confirmMarginTrade : boolean;                                                                         // Согласие на выставление заявки, которая может привести к непокрытой позиции, по умолчанию false
   end;
   pso_responseMetadataStruct = record
      pso_trackingId : string;                                                                                  // Идентификатор трекинга
      pso_serverTime : string;                                                                                  // Серверное время
   end;
   pso_response = record                                                                                        // Ответ для PostStopOrder
      pso_stopOrderId : string;                                                                                 // Уникальный идентификатор стоп-заявки
      pso_orderRequestId : string;                                                                              // Идентификатор ключа идемпотентности, переданный клиентом, в формате UID. Максимальная длина 36 — символов
      pso_responseMetadata : pso_responseMetadataStruct;                                                        // Метадата
      pso_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      pso_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      pso_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetStopOrders
   gso_request = record                                                                                         // Запрос для GetStopOrders
      gso_token : string;                                                                                       // Токен
      gso_accountId : string;                                                                                   // Идентификатор счета клиента
      gso_status : string;                                                                                      // Статус стоп-заявки [STOP_ORDER_STATUS_UNSPECIFIED, STOP_ORDER_STATUS_ALL, STOP_ORDER_STATUS_ACTIVE, STOP_ORDER_STATUS_EXECUTED, STOP_ORDER_STATUS_CANCELED, STOP_ORDER_STATUS_EXPIRED]
      gso_from : string;                                                                                        // Левая граница в формате UTC
      gso_to : string;                                                                                          // Правая граница в формате UTC
   end;
   gso_trailingDataStruct = record
      gso_indent : double;                                                                                      // Отступ
      gso_indentType : string;                                                                                  // Тип параметров значений трейлинг-стопа [TRAILING_VALUE_UNSPECIFIED, TRAILING_VALUE_ABSOLUTE, TRAILING_VALUE_RELATIVE]
      gso_spread : double;                                                                                      // Размер защитного спреда
      gso_spreadType : string;                                                                                  // Тип величины защитного спреда [TRAILING_VALUE_UNSPECIFIED, TRAILING_VALUE_ABSOLUTE, TRAILING_VALUE_RELATIVE]
   end;
   gso_stopOrdersStruct = record
      gso_stopOrderId : string;                                                                                 // Уникальный идентификатор стоп-заявки
      gso_lotsRequested : int64;                                                                                // Запрошено лотов
      gso_figi : string;                                                                                        // FIGI-идентификатор инструмента
      gso_direction : string;                                                                                   // Направление сделки стоп-заявки [STOP_ORDER_DIRECTION_UNSPECIFIED, STOP_ORDER_DIRECTION_BUY, STOP_ORDER_DIRECTION_SELL]
      gso_currency : string;                                                                                    // Валюта стоп-заявки
      gso_orderType : string;                                                                                   // Тип стоп-заявки [STOP_ORDER_TYPE_UNSPECIFIED, STOP_ORDER_TYPE_TAKE_PROFIT, STOP_ORDER_TYPE_STOP_LOSS, STOP_ORDER_TYPE_STOP_LIMIT]
      gso_createDate : string;                                                                                  // Дата и время выставления заявки по UTC
      gso_activationDateTime : string;                                                                          // Дата и время конвертации стоп-заявки в биржевую по UTC
      gso_expirationTime : string;                                                                              // Дата и время снятия заявки по UTC
      gso_price : MoneyStruct;                                                                                  // Цена заявки за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gso_stopPrice : MoneyStruct;                                                                              // Цена активации стоп-заявки за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      gso_instrumentUid : string;                                                                               // instrument_uid-идентификатор инструмента
      gso_takeProfitType : string;                                                                              // Тип TakeProfit-заявки [TAKE_PROFIT_TYPE_UNSPECIFIED, TAKE_PROFIT_TYPE_REGULAR, TAKE_PROFIT_TYPE_TRAILING]
      gso_trailingData : gso_trailingDataStruct;                                                                // Параметры трейлинг-стопа
      gso_status : string;                                                                                      // Статус стоп-заявки [STOP_ORDER_STATUS_UNSPECIFIED, STOP_ORDER_STATUS_ALL, STOP_ORDER_STATUS_ACTIVE, STOP_ORDER_STATUS_EXECUTED, STOP_ORDER_STATUS_CANCELED, STOP_ORDER_STATUS_EXPIRED]
      gso_exchangeOrderType : string;                                                                           // Тип выставляемой заявки [EXCHANGE_ORDER_TYPE_UNSPECIFIED, EXCHANGE_ORDER_TYPE_MARKET, EXCHANGE_ORDER_TYPE_LIMIT]
      gso_exchangeOrderId : string;                                                                             // Идентификатор биржевой заявки
   end;
   gso_response = record                                                                                        // Ответ для GetStopOrders
      gso_stopOrders : array of gso_stopOrdersStruct;                                                           // Массив стоп-заявок по счету
      gso_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gso_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gso_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetInstrumentBy
   gib_request = record                                                                                         // Запрос для GetInstrumentBy
      gib_token : string;                                                                                       // Токен
      gib_idType : string;                                                                                      // Тип идентификатора инструмента [INSTRUMENT_ID_UNSPECIFIED, INSTRUMENT_ID_TYPE_FIGI, INSTRUMENT_ID_TYPE_TICKER, INSTRUMENT_ID_TYPE_UID, INSTRUMENT_ID_TYPE_POSITION_UID]
      gib_classCode : string;                                                                                   // Идентификатор class_code. Обязательный, если id_type = ticker
      gib_id : string;                                                                                          // Идентификатор запрашиваемого инструмента
   end;
   gib_brandStruct = record
      gib_logoName : string;                                                                                    // Логотип инструмента. Имя файла для получения логотипа https://invest-brands.cdn-tbank.ru/<logoName<size>.png>, где <logoName<size>.png> — логотип компании с размерами в точках. Доступные размеры — x160, x320, x640
      gib_logoBaseColor : string;                                                                               // Цвет бренда в формате #000000...#ffffff
      gib_textColor : string;                                                                                   // Цвет текста для цвета логотипа бренда в формате #000000...#ffffff
   end;
   gib_instrumentStruct = record
      gib_figi : string;                                                                                        // FIGI-идентификатор инструмента
      gib_ticker : string;                                                                                      // Тикер инструмента
      gib_classCode : string;                                                                                   // Класс-код инструмента
      gib_isin : string;                                                                                        // ISIN-идентификатор инструмента
      gib_lot : int64;                                                                                          // Лотность инструмента. Возможно совершение операций только на количества ценной бумаги, кратные параметру lot
      gib_currency : string;                                                                                    // Валюта расчетов
      gib_klong : double;                                                                                       // Коэффициент ставки риска длинной позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      gib_kshort : double;                                                                                      // Коэффициент ставки риска короткой позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      gib_dlong : double;                                                                                       // Ставка риска начальной маржи для КСУР лонг
      gib_dshort : double;                                                                                      // Ставка риска начальной маржи для КСУР шорт
      gib_dlongMin : double;                                                                                    // Ставка риска начальной маржи для КПУР лонг
      gib_dshortMin : double;                                                                                   // Ставка риска начальной маржи для КПУР шорт
      gib_shortEnabledFlag : boolean;                                                                           // Признак доступности для операций в шорт
      gib_name : string;                                                                                        // Название инструмента
      gib_exchange : string;                                                                                    // Tорговая площадка (секция биржи)
      gib_countryOfRisk : string;                                                                               // Код страны риска — то есть страны, в которой компания ведет основной бизнес
      gib_countryOfRiskName : string;                                                                           // Наименование страны риска — то есть страны, в которой компания ведет основной бизнес
      gib_instrumentType : string;                                                                              // Тип инструмента
      gib_tradingStatus : string;                                                                               // Текущий режим торгов инструмента [SECURITY_TRADING_STATUS_UNSPECIFIED, SECURITY_TRADING_STATUS_NOT_AVAILABLE_FOR_TRADING, SECURITY_TRADING_STATUS_OPENING_PERIOD, SECURITY_TRADING_STATUS_CLOSING_PERIOD, SECURITY_TRADING_STATUS_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_NORMAL_TRADING, SECURITY_TRADING_STATUS_CLOSING_AUCTION, SECURITY_TRADING_STATUS_DARK_POOL_AUCTION, SECURITY_TRADING_STATUS_DISCRETE_AUCTION, SECURITY_TRADING_STATUS_OPENING_AUCTION_PERIOD, SECURITY_TRADING_STATUS_TRADING_AT_CLOSING_AUCTION_PRICE, SECURITY_TRADING_STATUS_SESSION_ASSIGNED, SECURITY_TRADING_STATUS_SESSION_CLOSE, SECURITY_TRADING_STATUS_SESSION_OPEN, SECURITY_TRADING_STATUS_DEALER_NORMAL_TRADING, SECURITY_TRADING_STATUS_DEALER_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_DEALER_NOT_AVAILABLE_FOR_TRADING]
      gib_otcFlag : boolean;                                                                                    // Флаг, используемый ранее для определения внебиржевых инструментов. На данный момент не используется для торгуемых через API инструментов. Может использоваться как фильтр для операций, совершавшихся некоторое время назад на ОТС площадке
      gib_buyAvailableFlag : boolean;                                                                           // Признак доступности для покупки
      gib_sellAvailableFlag : boolean;                                                                          // Признак доступности для продажи
      gib_minPriceIncrement : double;                                                                           // Шаг цены
      gib_apiTradeAvailableFlag : boolean;                                                                      // Параметр указывает на возможность торговать инструментом через API
      gib_uid : string;                                                                                         // Уникальный идентификатор инструмента
      gib_realExchange : string;                                                                                // Реальная площадка исполнения расчетов [REAL_EXCHANGE_UNSPECIFIED, REAL_EXCHANGE_MOEX, REAL_EXCHANGE_RTS, REAL_EXCHANGE_OTC, REAL_EXCHANGE_DEALER]
      gib_positionUid : string;                                                                                 // Уникальный идентификатор позиции инструмента
      gib_assetUid : string;                                                                                    // Уникальный идентификатор актива
      gib_requiredTests : array of string;                                                                      // Тесты, которые необходимо пройти клиенту, чтобы совершать сделки по инструменту
      gib_forIisFlag : boolean;                                                                                 // Признак доступности для ИИС
      gib_forQualInvestorFlag : boolean;                                                                        // Флаг, отображающий доступность торговли инструментом только для квалифицированных инвесторов
      gib_weekendFlag : boolean;                                                                                // Флаг, отображающий доступность торговли инструментом по выходным
      gib_blockedTcaFlag : boolean;                                                                             // Флаг заблокированного ТКС
      gib_instrumentKind : string;                                                                              // Тип инструмента [INSTRUMENT_TYPE_BOND, INSTRUMENT_TYPE_SHARE, INSTRUMENT_TYPE_CURRENCY, INSTRUMENT_TYPE_ETF, INSTRUMENT_TYPE_FUTURES, INSTRUMENT_TYPE_SP, INSTRUMENT_TYPE_OPTION, INSTRUMENT_TYPE_CLEARING_CERTIFICATE, INSTRUMENT_TYPE_INDEX, INSTRUMENT_TYPE_COMMODITY]
      gib_first1minCandleDate : string;                                                                         // Дата первой минутной свечи
      gib_first1dayCandleDate : string;                                                                         // Дата первой дневной свечи
      gib_brand : gib_brandStruct;                                                                              // Информация о бренде
      gib_dlongClient : double;                                                                                 // Ставка риска в лонг, с учетом текущего уровня риска портфеля клиента
      gib_dshortClient : double;                                                                                // Ставка риска в шорт, с учетом текущего уровня риска портфеля клиента
   end;
   gib_response = record                                                                                        // Ответ для GetInstrumentBy
      gib_instrument : gib_instrumentStruct;                                                                    // Объект передачи основной информации об инструменте
      gib_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gib_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gib_error_description : int64;                                                                            // Код ошибки
   end;
   
   // Структуры для процедуры GetClosePrices
   gcp_instrumentIdStruct = record
      gcp_instrumentId : string;                                                                                // Идентификатор инструмента. Принимает значение figi или instrument_uid
   end;

   gcp_request = record                                                                                         // Запрос для GetClosePrices
      gcp_token : string;                                                                                       // Токен
      gcp_instruments : array of gcp_instrumentIdStruct;                                                        // Массив по инструментам
      gcp_instrumentStatus : string;                                                                            // Статус запрашиваемых инструментов [INSTRUMENT_STATUS_UNSPECIFIED, INSTRUMENT_STATUS_BASE, INSTRUMENT_STATUS_ALL]
   end;

   gcp_closePricesStruct = record
      gcp_figi : string;                                                                                        // FIGI инструмента
      gcp_instrumentUid : string;                                                                               // UID инструмента
      gcp_price : double;                                                                                       // Цена основной сессии
      gcp_eveningSessionPrice : double;                                                                         // Цена вечерней сессии
      gcp_time : string;                                                                                        // Дата совершения и время торгов
   end;

   gcp_response = record                                                                                        // Ответ для GetClosePrices
      gcp_closePrices : array of gcp_closePricesStruct;                                                         // Массив по инструментам
      gcp_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gcp_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gcp_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetLastPrices
   glp_instrumentIdStruct = record
      glp_instrumentId : string;                                                                                // Идентификатор инструмента. Принимает значение figi или instrument_uid
   end;

   glp_request = record                                                                                         // Запрос для GetLastPrices
      glp_token : string;                                                                                       // Токен
      glp_instruments : array of glp_instrumentIdStruct;                                                        // Массив по инструментам
      glp_lastPriceType : string;                                                                               // Тип последней цены [LAST_PRICE_UNSPECIFIED, LAST_PRICE_EXCHANGE, LAST_PRICE_DEALER]
      glp_instrumentStatus : string;                                                                            // Статус запрашиваемых инструментов
   end;

   glp_lastPricesStruct = record
      glp_figi : string;                                                                                        // FIGI инструмента
      glp_instrumentUid : string;                                                                               // UID инструмента
      glp_price : double;                                                                                       // Цена основной сессии
      glp_lastPriceType : string;                                                                               // Тип последней цены [LAST_PRICE_UNSPECIFIED, LAST_PRICE_EXCHANGE, LAST_PRICE_DEALER]
      glp_time : string;                                                                                        // Дата совершения и время торгов
   end;

   glp_response = record                                                                                        // Ответ для GetLastPrices
      glp_lastPrices : array of glp_lastPricesStruct;                                                           // Массив по инструментам
      glp_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      glp_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      glp_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetLastTrades
   glt_request = record                                                                                         // Запрос для GetLastTrades
      glt_token : string;                                                                                       // Токен
      glt_from : string;                                                                                        // Начало запрашиваемого периода по UTC
      glt_to : string;                                                                                          // Окончание запрашиваемого периода по UTC
      glt_instrumentId : string;                                                                                // Идентификатор инструмента. Принимает значение `figi`, `instrument_uid` или `ticker + '_' + class_code`
      glt_tradeSource : string;                                                                                 // Типы источников сделок [TRADE_SOURCE_UNSPECIFIED, TRADE_SOURCE_EXCHANGE, TRADE_SOURCE_DEALER, TRADE_SOURCE_ALL]
   end;

   glt_tradesStruct = record
      glt_figi : string;                                                                                        // FIGI-идентификатор инструмента
      glt_direction : string;                                                                                   // Направление сделки [TRADE_DIRECTION_UNSPECIFIED, TRADE_DIRECTION_BUY, TRADE_DIRECTION_SELL]
      glt_price : double;                                                                                       // Цена
      glt_quantity : int64;                                                                                     // Количество лотов
      glt_time : string;                                                                                        // Время сделки в часовом поясе UTC по времени биржи
      glt_instrumentUid : string;                                                                               // UID инструмента
      glt_tradeSource : string;                                                                                 // Типы источников сделок
      glt_ticker : string;                                                                                      // Тикер инструмента
      glt_classCode : string;                                                                                   // Класс-код (секция торгов)
   end;

   glt_response = record                                                                                        // Ответ для GetLastTrades
      glt_trades : array of glt_tradesStruct;                                                                   // Массив сделок
      glt_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      glt_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      glt_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetInfo
   gi_request = record                                                                                          // Запрос для GetInfo
      gi_token : string;                                                                                        // Токен
   end;

   gi_response = record                                                                                         // Ответ для GetInfo
      gi_premStatus : boolean;                                                                                  // Признак премиум клиента
      gi_qualStatus : boolean;                                                                                  // Признак квалифицированного инвестора
      gi_qualifiedForWorkWith : array of string;                                                                // Набор требующих тестирования инструментов и возможностей, с которыми может работать пользователь
      gi_tariff : string;                                                                                       // Наименование тарифа пользователя
      gi_userId : string;                                                                                       // Идентификатор пользователя
      gi_riskLevelCode : string;                                                                                // Категория риска
      gi_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      gi_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      gi_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetMarginAttributes
   gma_request = record                                                                                         // Запрос для GetMarginAttributes
      gma_token : string;                                                                                       // Токен
      gma_accountId : string;                                                                                   // Идентификатор счeта пользователя
   end;

   gma_response = record                                                                                        // Ответ для GetMarginAttributes
      gma_liquidPortfolio : MoneyStruct;                                                                        // Ликвидная стоимость портфеля
      gma_startingMargin : MoneyStruct;                                                                         // Начальная маржа — начальное обеспечение для совершения новой сделки
      gma_minimalMargin : MoneyStruct;                                                                          // Минимальная маржа — это минимальное обеспечение для поддержания позиции, которую вы уже открыли
      gma_fundsSufficiencyLevel : double;                                                                       // Уровень достаточности средств. Соотношение стоимости ликвидного портфеля к начальной марже
      gma_amountOfMissingFunds : MoneyStruct;                                                                   // Объем недостающих средств. Разница между стартовой маржой и ликвидной стоимости портфеля
      gma_correctedMargin : MoneyStruct;                                                                        // Скорректированная маржа. Начальная маржа, в которой плановые позиции рассчитываются с учетом активных заявок на покупку позиций лонг или продажу позиций шорт
      gma_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gma_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gma_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры CreateFavoriteGroup
   cfg_request = record                                                                                         // Запрос для CreateFavoriteGroup
      cfg_token : string;                                                                                       // Токен
      cfg_groupName : string;                                                                                   // Название группы, не более 255 символов
      cfg_groupColor : string;                                                                                  // Цвет группы. Принимает значения в HEX-формате, от "000000" до "FFFFFF"
      cfg_note : string;                                                                                        // Описание
   end;

   cfg_response = record                                                                                        // Ответ для CreateFavoriteGroup
      cfg_groupId : string;                                                                                     // Уникальный идентификатор группы
      cfg_groupName : string;                                                                                   // Название группы
      cfg_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      cfg_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      cfg_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры DeleteFavoriteGroup
   dfg_request = record                                                                                         // Запрос для DeleteFavoriteGroup
      dfg_token : string;                                                                                       // Токен
      dfg_groupId : string;                                                                                     // Уникальный идентификатор группы
   end;

   dfg_response = record                                                                                        // Ответ для DeleteFavoriteGroup
      dfg_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      dfg_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      dfg_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetFavoriteGroups
   gfg_request = record                                                                                         // Запрос для GetFavoriteGroups
      gfg_token : string;                                                                                       // Токен
      gfg_instrumentId : array of string;                                                                       // Массив идентификаторов инструментов. Принимает значение figi или instrument_uid. Если в группе будет хотя бы один из инструментов массива, то в ответе у группы вернется признак containsInstrument = true
      gfg_excludedGroupId : array of string;                                                                    // Массив идентификаторов групп, которые необходимо исключить из ответа
   end;

   gfg_groupsStruct = record
      gfg_groupId : string;                                                                                     // Уникальный идентификатор группы
      gfg_groupName : string;                                                                                   // Название группы
      gfg_color : string;                                                                                       // Цвет группы в HEX-формате
      gfg_size : int64;                                                                                         // Количество инструментов в группе
      gfg_containsInstrument : boolean;                                                                         // Признак наличия в группе хотя бы одного инструмента из запроса
   end;

   gfg_response = record                                                                                        // Ответ для GetFavoriteGroups
      gfg_groups : array of gfg_groupsStruct;                                                                   // Массив групп избранных списков инструментов
      gfg_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gfg_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gfg_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetAccruedInterests
   gai_request = record                                                                                         // Запрос для GetAccruedInterests
      gai_token : string;                                                                                       // Токен
      gai_from : string;                                                                                        // Начало запрашиваемого периода по UTC
      gai_to : string;                                                                                          // Окончание запрашиваемого периода по UTC
      gai_instrumentId : string;                                                                                // Идентификатор инструмента — figi или instrument_uid
   end;

   gai_accruedInterestsStruct = record
      gai_date : string;                                                                                        // Дата и время выплаты по UTC
      gai_value : double;                                                                                       // Величина выплаты
      gai_valuePercent : double;                                                                                // Величина выплаты в процентах от номинала
      gai_nominal : double;                                                                                     // Номинал облигации
   end;

   gai_response = record                                                                                        // Ответ для GetAccruedInterests
      gai_accruedInterests : array of gai_accruedInterestsStruct;                                               // Массив операций начисления купонов
      gai_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gai_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gai_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры TradingSchedules
   ts_request = record                                                                                          // Запрос для TradingSchedules
      ts_token : string;                                                                                        // Токен
      ts_exchange : string;                                                                                     // Наименование биржи или расчетного календаря. Если не передается, возвращается информация по всем доступным торговым площадкам
      ts_from : string;                                                                                         // Начало периода по UTC
      ts_to : string;                                                                                           // Окончание периода по UTC
   end;

   ts_intervalStruct = record
      ts_startTs : string;                                                                                      // Время начала интервала
      ts_endTs : string;                                                                                        // Время окончания интервала
   end;

   ts_intervalsStruct = record
      ts_type : string;                                                                                         // Название интервала
      ts_interval : ts_intervalStruct;                                                                          // Интервал
   end;

   ts_daysStruct = record
      ts_date : string;                                                                                         // Дата
      ts_isTradingDay : boolean;                                                                                // Признак торгового дня на бирже
      ts_startTime : string;                                                                                    // Время начала торгов по UTC
      ts_endTime : string;                                                                                      // Время окончания торгов по UTC
      ts_openingAuctionStartTime : string;                                                                      // Время начала аукциона открытия по UTC
      ts_closingAuctionEndTime : string;                                                                        // Время окончания аукциона закрытия по UTC
      ts_eveningOpeningAuctionStartTime : string;                                                               // Время начала аукциона открытия вечерней сессии по UTC
      ts_eveningStartTime : string;                                                                             // Время начала вечерней сессии по UTC
      ts_eveningEndTime : string;                                                                               // Время окончания вечерней сессии по UTC
      ts_clearingStartTime : string;                                                                            // Время начала основного клиринга по UTC
      ts_clearingEndTime : string;                                                                              // Время окончания основного клиринга по UTC
      ts_premarketStartTime : string;                                                                           // Время начала премаркета по UTC
      ts_premarketEndTime : string;                                                                             // Время окончания премаркета по UTC
      ts_closingAuctionStartTime : string;                                                                      // Время начала аукциона закрытия по UTC
      ts_openingAuctionEndTime : string;                                                                        // Время окончания аукциона открытия по UTC
      ts_intervals : array of ts_intervalsStruct;                                                               // Торговые интервалы
   end;

   ts_exchangesStruct = record
      ts_exchange : string;                                                                                     // Наименование торговой площадки
      ts_days : array of ts_daysStruct;                                                                         // Массив с торговыми и неторговыми днями
   end;

   ts_response = record                                                                                         // Ответ для TradingSchedules
      ts_exchanges : array of ts_exchangesStruct;                                                               // Список торговых площадок и режимов торгов
      ts_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      ts_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      ts_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetUserTariff
   gut_request = record                                                                                         // Запрос для GetUserTariff
      gut_token : string;                                                                                       // Токен
   end;

   gut_unaryLimitsStruct =record
      gut_limitPerMinute : int64;                                                                               // Количество unary-запросов в минуту
      gut_methods : array of string;                                                                            // Названия методов
      gut_limitPerSecond : int64;                                                                               // Количество unary-запросов в секунду
   end;

   gut_streamLimitsStruct =record
      gut_limit : int64;                                                                                        // Максимальное количество stream-соединений
      gut_streams : array of string;                                                                            // Названия stream-методов
      gut_open : int64;                                                                                         // Текущее количество открытых stream-соединений
   end;

   gut_response = record                                                                                        // Ответ для GetUserTariff
      gut_unaryLimits : array of gut_unaryLimitsStruct;                                                         // Массив лимитов пользователя по unary-запросам
      gut_streamLimits : array of gut_streamLimitsStruct;                                                       // Массив лимитов пользователей для stream-соединений
      gut_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gut_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gut_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetBankAccounts
   gba_request = record                                                                                         // Запрос для GetBankAccounts
      gba_token : string;                                                                                       // Токен
   end;

   gba_bankAccountsStruct = record
      gba_id : string;                                                                                          // Идентификатор счeта
      gba_name : string;                                                                                        // Название счeта
      gba_money : array of MoneyStruct;                                                                         // Список валютных позиций на счeте
      gba_openedDate : string;                                                                                  // Дата открытия счeта в часовом поясе UTC
      gba_type : string;                                                                                        // Тип счeта
   end;

   gba_response = record                                                                                        // Ответ для GetBankAccounts
      gba_bankAccounts : array of gba_bankAccountsStruct;                                                       // Массив банковских счетов
      gba_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gba_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gba_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры PostOrderAsync
   poa_request = record                                                                                         // Запрос для PostOrderAsync
      poa_token : string;                                                                                       // Токен
      poa_instrumentId : string;                                                                                // Идентификатор инструмента, принимает значения Figi или Instrument_uid
      poa_quantity : int64;                                                                                     // Количество лотов
      poa_price : double;                                                                                       // Цена за 1 инструмент. Для получения стоимости лота требуется умножить на лотность инструмента. Игнорируется для рыночных поручений
      poa_direction : string;                                                                                   // Направление операции [ORDER_DIRECTION_UNSPECIFIED, ORDER_DIRECTION_BUY, ORDER_DIRECTION_SELL]
      poa_accountId : string;                                                                                   // Номер счета
      poa_orderType : string;                                                                                   // Тип заявки [ORDER_TYPE_UNSPECIFIED, ORDER_TYPE_LIMIT, ORDER_TYPE_MARKET, ORDER_TYPE_BESTPRICE]
      poa_orderId : string;                                                                                     // Идентификатор запроса выставления поручения для целей идемпотентности в формате UID. Максимальная длина 36 символов
      poa_timeInForce : string;                                                                                 // Алгоритм исполнения поручения, применяется только к лимитной заявке [TIME_IN_FORCE_UNSPECIFIED, TIME_IN_FORCE_DAY, TIME_IN_FORCE_FILL_AND_KILL, TIME_IN_FORCE_FILL_OR_KILL]
      poa_priceType : string;                                                                                   // Тип цены [PRICE_TYPE_UNSPECIFIED, PRICE_TYPE_POINT, PRICE_TYPE_CURRENCY]
      poa_confirmMarginTrade : boolean;                                                                         // Согласие на выставление заявки, которая может привести к непокрытой позиции, по умолчанию false
   end;

   poa_response = record                                                                                        // Ответ для PostOrderAsync
      poa_orderRequestId : string;                                                                              // Идентификатор ключа идемпотентности, переданный клиентом, в формате UID. Максимальная длина 36 символов
      poa_executionReportStatus : string;                                                                       // Текущий статус заявки [EXECUTION_REPORT_STATUS_UNSPECIFIED, EXECUTION_REPORT_STATUS_FILL, EXECUTION_REPORT_STATUS_REJECTED, EXECUTION_REPORT_STATUS_CANCELLED, EXECUTION_REPORT_STATUS_NEW, EXECUTION_REPORT_STATUS_PARTIALLYFILL]
      poa_tradeIntentId : string;                                                                               // Идентификатор торгового поручения
      poa_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      poa_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      poa_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры Currencies
   c_request = record                                                                                           // Запрос для Currencies
      c_token : string;                                                                                         // Токен
      c_instrumentStatus : string;                                                                              // Статус запрашиваемых инструментов
      c_instrumentExchange : string;                                                                            // Площадка торговли
   end;

   c_brandStruct = record
      c_logoName : string;                                                                                      // Логотип инструмента. Имя файла для получения логотипа
      c_logoBaseColor : string;                                                                                 // Цвет бренда
      c_textColor : string;                                                                                     // Цвет текста для цвета логотипа бренда
   end;

   c_instrumentsStruct = record
      c_figi : string;                                                                                          // FIGI-идентификатор инструмента
      c_ticker : string;                                                                                        // Тикер инструмента
      c_classCode : string;                                                                                     // Класс-код (секция торгов)
      c_isin : string;                                                                                          // ISIN-идентификатор инструмента
      c_lot : int64;                                                                                            // Лотность инструмента. Возможно совершение операций только на количества ценной бумаги, кратные параметру lot
      c_currency : string;                                                                                      // Валюта расчетов
      c_klong : double;                                                                                         // Коэффициент ставки риска длинной позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      c_kshort : double;                                                                                        // Коэффициент ставки риска короткой позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      c_dlong : double;                                                                                         // Ставка риска начальной маржи для КСУР лонг
      c_dshort : double;                                                                                        // Ставка риска начальной маржи для КСУР шорт
      c_dlongMin : double;                                                                                      // Ставка риска начальной маржи для КПУР лонг
      c_dshortMin : double;                                                                                     // Ставка риска начальной маржи для КПУР шорт
      c_shortEnabledFlag : boolean;                                                                             // Признак доступности для операций в шорт
      c_name : string;                                                                                          // Название инструмента
      c_exchange : string;                                                                                      // Tорговая площадка (секция биржи)
      c_nominal : MoneyStruct;                                                                                  // Номинал
      c_countryOfRisk : string;                                                                                 // Код страны риска — то есть страны, в которой компания ведет основной бизнес
      c_countryOfRiskName : string;                                                                             // Наименование страны риска — то есть страны, в которой компания ведет основной бизнес
      c_tradingStatus : string;                                                                                 // Текущий режим торгов инструмента
      c_otcFlag : boolean;                                                                                      // Флаг, используемый ранее для определения внебиржевых инструментов. На данный момент не используется для торгуемых через API инструментов. Может использоваться как фильтр для операций, совершавшихся некоторое время назад на ОТС площадке
      c_buyAvailableFlag : boolean;                                                                             // Признак доступности для покупки
      c_sellAvailableFlag : boolean;                                                                            // Признак доступности для продажи
      c_isoCurrencyName : string;                                                                               // Строковый ISO-код валюты
      c_minPriceIncrement : double;                                                                             // Шаг цены
      c_apiTradeAvailableFlag : boolean;                                                                        // Параметр указывает на возможность торговать инструментом через API
      c_uid : string;                                                                                           // Уникальный идентификатор инструмента
      c_realExchange : string;                                                                                  // Реальная площадка исполнения расчетов
      c_positionUid : string;                                                                                   // Уникальный идентификатор позиции инструмента
      c_requiredTests : array of string;                                                                        // Тесты, которые необходимо пройти клиенту, чтобы совершать сделки по инструменту
      c_forIisFlag : boolean;                                                                                   // Признак доступности для ИИС
      c_forQualInvestorFlag : boolean;                                                                          // Флаг, отображающий доступность торговли инструментом только для квалифицированных инвесторов
      c_weekendFlag : boolean;                                                                                  // Флаг, отображающий доступность торговли инструментом по выходным
      c_blockedTcaFlag : boolean;                                                                               // Флаг заблокированного ТКС
      c_first1minCandleDate : string;                                                                           // Дата первой минутной свечи
      c_first1dayCandleDate : string;                                                                           // Дата первой дневной свечи
      c_brand : c_brandStruct;                                                                                  // Информация о бренде
      c_dlongClient : double;                                                                                   // Ставка риска в лонг с учетом текущего уровня риска портфеля клиента
      c_dshortClient : double;                                                                                  // Ставка риска в шорт с учетом текущего уровня риска портфеля клиента
   end;

   c_response = record                                                                                          // Ответ для Currencies
      c_instruments : array of c_instrumentsStruct;                                                             // Массив валют
      c_error_code : int64;                                                                                     // Уникальный идентификатор ошибки
      c_error_message : string;                                                                                 // Пользовательское сообщение об ошибке
      c_error_description : int64;                                                                              // Код ошибки
   end;

   // Структуры для процедуры CurrencyBy
   cb_request = record                                                                                          // Запрос для CurrencyBy
      cb_token : string;                                                                                        // Токен
      cb_idType : string;                                                                                       // Тип идентификатора инструмента [INSTRUMENT_ID_UNSPECIFIED, INSTRUMENT_ID_TYPE_FIGI, INSTRUMENT_ID_TYPE_TICKER, INSTRUMENT_ID_TYPE_UID, INSTRUMENT_ID_TYPE_POSITION_UID]
      cb_classCode : string;                                                                                    // Идентификатор class_code. Обязательный, если id_type = ticker
      cb_id : string;                                                                                           // Идентификатор запрашиваемого инструмента
   end;

   cb_response = record                                                                                         // Ответ для CurrencyBy
      cb_instrument : c_instrumentsStruct;                                                                      // Объект передачи информации о валюте
      cb_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      cb_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      cb_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetBondCoupons
   gbc_request = record                                                                                         // Запрос для GetBondCoupons
      gbc_token : string;                                                                                       // Токен
      gbc_from : string;                                                                                        // Начало запрашиваемого периода по UTC. Фильтрация по coupon_date — дата выплаты купона
      gbc_to : string;                                                                                          // Окончание запрашиваемого периода по UTC. Фильтрация по coupon_date — дата выплаты купона
      gbc_instrumentId : string;                                                                                // Идентификатор инструмента — figi или instrument_uid
   end;

   gbc_eventsStruct = record
      gbc_figi : string;                                                                                        // FIGI-идентификатор инструмента
      gbc_couponDate : string;                                                                                  // Дата выплаты купона
      gbc_couponNumber : int64;                                                                                 // Номер купона
      gbc_fixDate : string;                                                                                     // Дата фиксации реестра для выплаты купона — опционально
      gbc_payOneBond : MoneyStruct;                                                                             // Выплата на одну облигацию
      gbc_couponType : string;                                                                                  // Тип купонов [COUPON_TYPE_UNSPECIFIED, COUPON_TYPE_CONSTANT, COUPON_TYPE_FLOATING, COUPON_TYPE_DISCOUNT, COUPON_TYPE_MORTGAGE, COUPON_TYPE_FIX, COUPON_TYPE_VARIABLE, COUPON_TYPE_OTHER]
      gbc_couponStartDate : string;                                                                             // Начало купонного периода
      gbc_couponEndDate : string;                                                                               // Окончание купонного периода
      gbc_couponPeriod : int64;                                                                                 // Купонный период в днях
   end;

   gbc_response = record                                                                                        // Ответ для GetBondCoupons
      gbc_events : array of gbc_eventsStruct;                                                                   // Объект передачи информации о купоне облигации
      gbc_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gbc_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gbc_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetBondEvents
   gbe_request = record                                                                                         // Запрос для GetBondEvents
      gbe_token : string;                                                                                       // Токен
      gbe_from : string;                                                                                        // Начало запрашиваемого периода по UTC
      gbe_to : string;                                                                                          // Окончание запрашиваемого периода по UTC
      gbe_instrumentId : string;                                                                                // Идентификатор инструмента — figi или instrument_uid
      gbe_type : string;                                                                                        // Тип события [EVENT_TYPE_UNSPECIFIED, EVENT_TYPE_CPN, EVENT_TYPE_CALL, EVENT_TYPE_MTY, EVENT_TYPE_CONV]
   end;

   gbe_eventsStruct = record
      gbe_instrumentId : string;                                                                                // Идентификатор инструмента
      gbe_eventNumber : int64;                                                                                  // Номер события для данного типа события
      gbe_eventDate : string;                                                                                   // Дата события
      gbe_eventType : string;                                                                                   // Тип события [EVENT_TYPE_UNSPECIFIED, EVENT_TYPE_CPN, EVENT_TYPE_CALL, EVENT_TYPE_MTY, EVENT_TYPE_CONV]
      gbe_eventTotalVol : double;                                                                               // Полное количество бумаг, задействованных в событии
      gbe_fixDate : string;                                                                                     // Дата фиксации владельцев для участия в событии
      gbe_rateDate : string;                                                                                    // Дата определения даты или факта события
      gbe_defaultDate : string;                                                                                 // Дата дефолта, если применимо
      gbe_realPayDate : string;                                                                                 // Дата реального исполнения обязательства
      gbe_payDate : string;                                                                                     // Дата выплаты
      gbe_payOneBond : MoneyStruct;                                                                             // Выплата на одну облигацию
      gbe_moneyFlowVal : MoneyStruct;                                                                           // Выплаты на все бумаги, задействованные в событии
      gbe_execution : string;                                                                                   // Признак исполнения
      gbe_operationType : string;                                                                               // Тип операции
      gbe_value : double;                                                                                       // Стоимость операции — ставка купона, доля номинала, цена выкупа или коэффициент конвертации
      gbe_note : string;                                                                                        // Примечание
      gbe_convertToFinToolId : string;                                                                          // ID выпуска бумаг, в который произведена конвертация (для конвертаций)
      gbe_couponStartDate : string;                                                                             // Начало купонного периода
      gbe_couponEndDate : string;                                                                               // Окончание купонного периода
      gbe_couponPeriod : int64;                                                                                 // Купонный период в днях
      gbe_couponInterestRate : double;                                                                          // Ставка купона, процентов годовых
   end;

   gbe_response = record                                                                                        // Ответ для GetBondEvents
      gbe_events : array of gbe_eventsStruct;                                                                   // Список событий
      gbe_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gbe_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gbe_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetAssetFundamentals
   gaf_request = record                                                                                         // Запрос для GetAssetFundamentals
      gaf_token : string;                                                                                       // Токен
      gaf_assets : array of string;                                                                             // Массив идентификаторов активов, не более 100 шт.
   end;

   gaf_fundamentalsStruct = record
      gaf_assetUid : string;                                                                                    // Идентификатор актива
      gaf_currency : string;                                                                                    // Валюта
      gaf_marketCapitalization : double;                                                                        // Рыночная капитализация
      gaf_highPriceLast52Weeks : double;                                                                        // Максимум за год
      gaf_lowPriceLast52Weeks : double;                                                                         // Минимум за год
      gaf_averageDailyVolumeLast10Days : double;                                                                // Средний объем торгов за 10 дней
      gaf_averageDailyVolumeLast4Weeks : double;                                                                // Средний объем торгов за месяц
      gaf_beta : double;                                                                                        // Коэффициент бета
      gaf_freeFloat : double;                                                                                   // Доля акций в свободном обращении
      gaf_forwardAnnualDividendYield : double;                                                                  // Процент форвардной дивидендной доходности по отношению к цене акций
      gaf_sharesOutstanding : double;                                                                           // Количество акций в обращении
      gaf_revenueTtm : double;                                                                                  // Выручка
      gaf_ebitdaTtm : double;                                                                                   // EBITDA — прибыль до вычета процентов, налогов, износа и амортизации
      gaf_netIncomeTtm : double;                                                                                // Чистая прибыль
      gaf_epsTtm : double;                                                                                      // EPS — величина чистой прибыли компании, которая приходится на каждую обыкновенную акцию
      gaf_dilutedEpsTtm : double;                                                                               // EPS компании с допущением, что все конвертируемые ценные бумаги компании были сконвертированы в обыкновенные акции
      gaf_freeCashFlowTtm : double;                                                                             // Свободный денежный поток
      gaf_fiveYearAnnualRevenueGrowthRate : double;                                                             // Среднегодовой рocт выручки за 5 лет
      gaf_threeYearAnnualRevenueGrowthRate : double;                                                            // Среднегодовой рocт выручки за 3 года
      gaf_peRatioTtm : double;                                                                                  // Соотношение рыночной капитализации компании к ее чистой прибыли
      gaf_priceToSalesTtm : double;                                                                             // Соотношение рыночной капитализации компании к ее выручке
      gaf_priceToBookTtm : double;                                                                              // Соотношение рыночной капитализации компании к ее балансовой стоимости
      gaf_priceToFreeCashFlowTtm : double;                                                                      // Соотношение рыночной капитализации компании к ее свободному денежному потоку
      gaf_totalEnterpriseValueMrq : double;                                                                     // Рыночная стоимость компании
      gaf_evToEbitdaMrq : double;                                                                               // Соотношение EV и EBITDA
      gaf_netMarginMrq : double;                                                                                // Маржа чистой прибыли
      gaf_netInterestMarginMrq : double;                                                                        // Рентабельность чистой прибыли
      gaf_roe : double;                                                                                         // Рентабельность собственного капитала
      gaf_roa : double;                                                                                         // Рентабельность активов
      gaf_roic : double;                                                                                        // Рентабельность активов
      gaf_totalDebtMrq : double;                                                                                // Сумма краткосрочных и долгосрочных обязательств компании
      gaf_totalDebtToEquityMrq : double;                                                                        // Соотношение долга к собственному капиталу
      gaf_totalDebtToEbitdaMrq : double;                                                                        // Total Debt/EBITDA
      gaf_freeCashFlowToPrice : double;                                                                         // Отношение свободногоо кэша к стоимости
      gaf_netDebtToEbitda : double;                                                                             // Отношение чистого долга к EBITDA
      gaf_currentRatioMrq : double;                                                                             // Коэффициент текущей ликвидности
      gaf_fixedChargeCoverageRatioFy : double;                                                                  // Коэффициент покрытия фиксированных платежей — FCCR
      gaf_dividendYieldDailyTtm : double;                                                                       // Дивидендная доходность за 12 месяцев
      gaf_dividendRateTtm : double;                                                                             // Выплаченные дивиденды за 12 месяцев
      gaf_dividendsPerShare : double;                                                                           // Значение дивидендов на акцию
      gaf_fiveYearsAverageDividendYield : double;                                                               // Средняя дивидендная доходность за 5 лет
      gaf_fiveYearAnnualDividendGrowthRate : double;                                                            // Среднегодовой рост дивидендов за 5 лет
      gaf_dividendPayoutRatioFy : double;                                                                       // Процент чистой прибыли, уходящий на выплату дивидендов
      gaf_buyBackTtm : double;                                                                                  // Деньги, потраченные на обратный выкуп акций
      gaf_oneYearAnnualRevenueGrowthRate : double;                                                              // Рост выручки за 1 год
      gaf_domicileIndicatorCode : string;                                                                       // Код страны
      gaf_adrToCommonShareRatio : double;                                                                       // Соотношение депозитарной расписки к акциям
      gaf_numberOfEmployees : double;                                                                           // Количество сотрудников
      gaf_exDividendDate : string;                                                                              //
      gaf_fiscalPeriodStartDate : string;                                                                       // Начало фискального периода
      gaf_fiscalPeriodEndDate : string;                                                                         // Окончание фискального периода
      gaf_revenueChangeFiveYears : double;                                                                      // Изменение общего дохода за 5 лет
      gaf_epsChangeFiveYears : double;                                                                          // Изменение EPS за 5 лет
      gaf_ebitdaChangeFiveYears : double;                                                                       // Изменение EBIDTA за 5 лет
      gaf_totalDebtChangeFiveYears : double;                                                                    // Изменение общей задолжности за 5 лет
      gaf_evToSales : double;                                                                                   // Отношение EV к выручке
   end;

   gaf_response = record                                                                                        // Ответ для GetAssetFundamentals
      gaf_fundamentals : array of gaf_fundamentalsStruct;                                                       // Массив объектов фундаментальных показателей
      gaf_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gaf_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gaf_error_description : int64;                                                                            // Код ошибки
   end;


   // Структуры для процедуры GetAssets
   gas_request = record                                                                                         // Запрос для GetAssets
      gas_token : string;                                                                                       // Токен
      gas_instrumentType : string;                                                                              // Тип инструмента [INSTRUMENT_TYPE_BOND, INSTRUMENT_TYPE_SHARE, INSTRUMENT_TYPE_CURRENCY, INSTRUMENT_TYPE_ETF, INSTRUMENT_TYPE_FUTURES, INSTRUMENT_TYPE_SP, INSTRUMENT_TYPE_OPTION, INSTRUMENT_TYPE_CLEARING_CERTIFICATE, INSTRUMENT_TYPE_INDEX, INSTRUMENT_TYPE_COMMODITY]
      gas_instrumentStatus : string;                                                                            // Статус запрашиваемых инструментов [INSTRUMENT_STATUS_UNSPECIFIED, INSTRUMENT_STATUS_BASE, INSTRUMENT_STATUS_ALL]
   end;

   gas_linksStruct = record
      gas_type : string;                                                                                        // Тип связи
      gas_instrumentUid : string;                                                                               // UID-идентификатор связанного инструмента
   end;

   gas_instrumentsStruct = record
      gas_uid : string;                                                                                         // UID-идентификатор инструмента
      gas_figi : string;                                                                                        // FIGI-идентификатор инструмента
      gas_instrumentType : string;                                                                              // Тип инструмента
      gas_ticker : string;                                                                                      // Тикер инструмента
      gas_classCode : string;                                                                                   // Класс-код (секция торгов)
      gas_links : array of gas_linksStruct;                                                                     // Массив связанных инструментов
      gas_instrumentKind : string;                                                                              // Тип инструмента
      gas_positionUid : string;                                                                                 // ID позиции
   end;

   gas_assetsStruct =record
      gas_uid : string;                                                                                         // Уникальный идентификатор актива
      gas_type : string;                                                                                        // Тип актива [ASSET_TYPE_UNSPECIFIED, ASSET_TYPE_CURRENCY, ASSET_TYPE_COMMODITY, ASSET_TYPE_INDEX, ASSET_TYPE_SECURITY]
      gas_name : string;                                                                                        // Наименование актива
      gas_instruments : array of gas_instrumentsStruct;                                                         // Массив идентификаторов инструментов
   end;

   gas_response = record                                                                                        // Ответ для GetAssets
      gas_assets : array of gas_assetsStruct;                                                                   // Активы
      gas_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gas_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gas_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetAssetReports
   gar_request = record                                                                                         // Запрос для GetAssetReports
      gar_token : string;                                                                                       // Токен
      gar_instrumentId : string;                                                                                // Идентификатор инструмента
      gar_from : string;                                                                                        // Начало запрашиваемого периода по UTC
      gar_to : string;                                                                                          // Окончание запрашиваемого периода по UTC
   end;

   gar_eventsStruct = record
      gar_instrumentId : string;                                                                                // Идентификатор инструмента
      gar_reportDate : string;                                                                                  // Дата публикации отчета
      gar_periodYear : int64;                                                                                   // Год периода отчета
      gar_periodNum : int64;                                                                                    // Номер периода
      gar_periodType : string;                                                                                  // Тип отчета [PERIOD_TYPE_UNSPECIFIED, PERIOD_TYPE_QUARTER, PERIOD_TYPE_SEMIANNUAL, PERIOD_TYPE_ANNUAL]
      gar_createdAt : string;                                                                                   // Дата создания записи
   end;

   gar_response = record                                                                                        // Ответ для GetAssetReports
      gar_events : array of gar_eventsStruct;                                                                   // Массив событий
      gar_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gar_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gar_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetPositions
   gep_request = record                                                                                         // Запрос для GetPositions
      gep_token : string;                                                                                       // Токен
      gep_accountId : string;                                                                                   // Идентификатор счета пользователя
   end;

   gep_securitiesStruct = record
      gep_figi : string;                                                                                        // FIGI-идентификатор бумаги
      gep_blocked : int64;                                                                                      // Количество бумаг, заблокированных выставленными заявками
      gep_balance : int64;                                                                                      // Текущий незаблокированный баланс
      gep_positionUid : string;                                                                                 // Уникальный идентификатор позиции
      gep_instrumentUid : string;                                                                               // Уникальный идентификатор инструмента
      gep_ticker : string;                                                                                      // Тикер инструмента
      gep_classCode : string;                                                                                   // Класс-код (секция торгов)
      gep_exchangeBlocked : boolean;                                                                            // Заблокировано на бирже
      gep_instrumentType : string;                                                                              // Тип инструмента
   end;

   gep_futuresStruct = record
      gep_figi : string;                                                                                        // FIGI-идентификатор фьючерса
      gep_blocked : int64;                                                                                      // Количество бумаг, заблокированных выставленными заявками
      gep_balance : int64;                                                                                      // Текущий незаблокированный баланс
      gep_positionUid : string;                                                                                 // Уникальный идентификатор позиции
      gep_instrumentUid : string;                                                                               // Уникальный идентификатор инструмента
      gep_ticker : string;                                                                                      // Тикер инструмента
      gep_classCode : string;                                                                                   // Класс-код (секция торгов)
   end;

   gep_optionsStruct = record
      gep_positionUid : string;                                                                                 // Уникальный идентификатор позиции
      gep_instrumentUid : string;                                                                               // Уникальный идентификатор инструмента
      gep_ticker : string;                                                                                      // Тикер инструмента
      gep_classCode : string;                                                                                   // Класс-код (секция торгов)
      gep_blocked : int64;                                                                                      // Количество бумаг, заблокированных выставленными заявками
      gep_balance : int64;                                                                                      // Текущий незаблокированный баланс
   end;

   gep_response = record                                                                                        // Ответ для GetPositions
      gep_money : array of MoneyStruct;                                                                         // Массив валютных позиций портфеля
      gep_blocked : array of MoneyStruct;                                                                       // Массив заблокированных валютных позиций портфеля
      gep_securities : array of gep_securitiesStruct;                                                           // Список ценно-бумажных позиций портфеля
      gep_limitsLoadingInProgress : boolean;                                                                    // Признак идущей выгрузки лимитов в данный момент
      gep_futures : array of gep_futuresStruct;                                                                 // Список фьючерсов портфеля
      gep_options : array of gep_optionsStruct;                                                                 // Список опционов портфеля
      gep_accountId : string;                                                                                   // Идентификатор счета пользователя
      gep_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gep_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gep_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetBrands
   gb_pagingStruct = record
      gb_limit : int64;                                                                                         // Максимальное число возвращаемых записей
      gb_pageNumber : int64;                                                                                    // Порядковый номер страницы, начиная с 0
      gb_totalCount : int64;                                                                                    // Общее количество записей (данное поле используется только в ответе)
   end;

   gb_request = record                                                                                          // Запрос для GetBrands
      gb_token : string;                                                                                        // Токен
      gb_paging : gb_pagingStruct;                                                                              // Настройки пагинации
   end;

   gb_brandsStruct = record
      gb_uid : string;                                                                                          // UID-идентификатор бренда
      gb_name : string;                                                                                         // Наименование бренда
      gb_description : string;                                                                                  // Описание
      gb_info : string;                                                                                         // Информация о бренде
      gb_company : string;                                                                                      // Компания
      gb_sector : string;                                                                                       // Сектор
      gb_countryOfRisk : string;                                                                                // Код страны риска
      gb_countryOfRiskName : string;                                                                            // Наименование страны риска
   end;

   gb_response = record                                                                                         // Ответ для GetBrands
      gb_brands : array of gb_brandsStruct;                                                                     // Массив брендов
      gb_paging : gb_pagingStruct;                                                                              // Данные по пагинации
      gb_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      gb_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      gb_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetBrandBy
   gbb_request = record                                                                                         // Запрос для GetBrandBy
      gbb_token : string;                                                                                       // Токен
      gbb_id : string;                                                                                          // UID-идентификатор бренда
   end;

   gbb_response = record                                                                                        // Ответ для GetBrandBy
      gbb_uid : string;                                                                                         // UID-идентификатор бренда
      gbb_name : string;                                                                                        // Наименование бренда
      gbb_description : string;                                                                                 // Описание
      gbb_info : string;                                                                                        // Информация о бренде
      gbb_company : string;                                                                                     // Компания
      gbb_sector : string;                                                                                      // Сектор
      gbb_countryOfRisk : string;                                                                               // Код страны риска
      gbb_countryOfRiskName : string;                                                                           // Наименование страны риска
      gbb_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gbb_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gbb_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetTradingStatuses
   gtss_request = record                                                                                        // Запрос для GetTradingStatuses
      gtss_token : string;                                                                                      // Токен
      gtss_instrumentId : array of string;                                                                      // Идентификатор инструмента. Принимает значение "figi", "instrument_uid" или "ticker + "_" + class_code"
   end;

   gtss_tradingStatusesStruct = record
      gtss_figi : string;                                                                                       // FIGI-идентификатор инструмента
      gtss_tradingStatus : string;                                                                              // Режим торгов инструмента
      gtss_limitOrderAvailableFlag : boolean;                                                                   // Признак доступности выставления лимитной заявки по инструменту
      gtss_marketOrderAvailableFlag : boolean;                                                                  // Признак доступности выставления рыночной заявки по инструменту
      gtss_apiTradeAvailableFlag : boolean;                                                                     // Признак доступности торгов через API
      gtss_instrumentUid : string;                                                                              // UID инструмента
      gtss_bestpriceOrderAvailableFlag : boolean;                                                               // Признак доступности завяки по лучшей цене
      gtss_onlyBestPrice : boolean;                                                                             // Признак доступности только заявки по лучшей цене
      gtss_ticker : string;                                                                                     // Тикер инструмента
      gtss_classCode : string;                                                                                  // Класс-код (секция торгов)
   end;

   gtss_response = record                                                                                       // Ответ для GetTradingStatuses
      gtss_tradingStatuses : array of gtss_tradingStatusesStruct;                                               // Массив информации о торговых статусах
      gtss_error_code : int64;                                                                                  // Уникальный идентификатор ошибки
      gtss_error_message : string;                                                                              // Пользовательское сообщение об ошибке
      gtss_error_description : int64;                                                                           // Код ошибки
   end;

   // Структуры для процедуры GetStrategies
   ges_request = record                                                                                         // Запрос для GetStrategies
      ges_token : string;                                                                                       // Токен
      ges_strategyId : string;                                                                                  // Идентификатор стратегии
   end;

   ges_strategiesStruct = record
      ges_strategyId : string;                                                                                  // Идентификатор стратегии
      ges_strategyName : string;                                                                                // Название стратегии
      ges_strategyDescription : string;                                                                         // Описание стратегии
      ges_strategyendpoint_url : string;                                                                        // Ссылка на страницу с описанием стратегии
      ges_strategyType : string;                                                                                // Тип стратегии [STRATEGY_TYPE_UNSPECIFIED, STRATEGY_TYPE_TECHNICAL, STRATEGY_TYPE_FUNDAMENTAL]
      ges_activeSignals : int64;                                                                                // Количество активных сигналов
      ges_totalSignals : int64;                                                                                 // Общее количество сигналов
      ges_timeInPosition : int64;                                                                               // Среднее время нахождения сигнала в позиции
      ges_averageSignalYield : double;                                                                          // Средняя доходность сигнала в стратегии
      ges_averageSignalYieldYear : double;                                                                      // Средняя доходность сигналов в стратегии за последний год
      ges_yield : double;                                                                                       // Доходность стратегии
      ges_yieldYear : double;                                                                                   // Доходность стратегии за последний год
   end;

   ges_response = record                                                                                        // Ответ для GetStrategies
      ges_strategies : array of ges_strategiesStruct;                                                           // Массив стратегий
      ges_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      ges_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      ges_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetSignals
   gsi_pagingStruct = record
      gsi_limit : int64;                                                                                        // Максимальное число возвращаемых записей
      gsi_pageNumber : int64;                                                                                   // Порядковый номер страницы, начиная с 0
      gsi_totalCount : int64;                                                                                   // Общее количество записей (данное поле используется только в ответе)
   end;

   gsi_request = record                                                                                         // Запрос для GetSignals
      gsi_token : string;                                                                                       // Токен
      gsi_signalId : string;                                                                                    // Идентификатор сигнала
      gsi_strategyId : string;                                                                                  // Идентификатор стратегии
      gsi_strategyType : string;                                                                                // Тип стратегии [STRATEGY_TYPE_UNSPECIFIED, STRATEGY_TYPE_TECHNICAL, STRATEGY_TYPE_FUNDAMENTAL]
      gsi_instrumentUid : string;                                                                               // Идентификатор бумаги
      gsi_from : string;                                                                                        // Дата начала запрашиваемого интервала по UTC
      gsi_to : string;                                                                                          // Дата конца запрашиваемого интервала по UTC
      gsi_direction : string;                                                                                   // Направление сигнала [SIGNAL_DIRECTION_UNSPECIFIED, SIGNAL_DIRECTION_BUY, SIGNAL_DIRECTION_SELL]
      gsi_active : string;                                                                                      // Статус сигнала [SIGNAL_STATE_UNSPECIFIED, SIGNAL_STATE_ACTIVE, SIGNAL_STATE_CLOSED, SIGNAL_STATE_ALL]
      gsi_paging : gsi_pagingStruct;                                                                            // Настройки пагинации
   end;

   gsi_signalsStruct = record
      gsi_signalId : string;                                                                                    // Идентификатор сигнала
      gsi_strategyId : string;                                                                                  // Идентификатор стратегии
      gsi_strategyName : string;                                                                                // Название стратегии
      gsi_instrumentUid : string;                                                                               // Идентификатор бумаги
      gsi_createDt : string;                                                                                    // Дата и время создания сигнала по UTC
      gsi_direction : string;                                                                                   // Направление сигнала [SIGNAL_DIRECTION_UNSPECIFIED, SIGNAL_DIRECTION_BUY, SIGNAL_DIRECTION_SELL]
      gsi_initialPrice : double;                                                                                // Цена бумаги на момент формирования сигнала
      gsi_info : string;                                                                                        // Дополнительная информация о сигнале
      gsi_name : string;                                                                                        // Название сигнала
      gsi_targetPrice : double;                                                                                 // Целевая цена
      gsi_endDt : string;                                                                                       // Дата и время дедлайна сигнала по UTC
      gsi_probability : int64;                                                                                  // Вероятность сигнала
      gsi_stoploss : double;                                                                                    // Порог закрытия сигнала по стоплосс
      gsi_closePrice : double;                                                                                  // Цена закрытия сигнала
      gsi_closeDt : string;                                                                                     // Дата и время закрытия сигнала по UTC
   end;

   gsi_response = record                                                                                        // Ответ для GetSignals
      gsi_signals : array of gsi_signalsStruct;                                                                 // Массив сигналов
      gsi_paging : gsi_pagingStruct;                                                                            // Настройки пагинации
      gsi_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gsi_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gsi_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры CurrencyTransfer
   cut_request = record                                                                                         // Запрос для CurrencyTransfer
      cut_token : string;                                                                                       // Токен
      cut_fromAccountId : string;                                                                               // Номер счета списания
      cut_toAccountId : string;                                                                                 // Номер счета зачисления
      cut_amount : MoneyStruct;                                                                                 // Денежная сумма в определенной валюте
      cut_transactionId : string;                                                                               // Идентификатор запроса выставления поручения для целей идемпотентности в формате UUID
   end;

   cut_response = record                                                                                        // Ответ для CurrencyTransfer
      cut_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      cut_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      cut_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры PayIn
   pi_request = record                                                                                          // Запрос для PayIn
      pi_token : string;                                                                                        // Токен
      pi_fromAccountId : string;                                                                                // Номер счета списания
      pi_toAccountId : string;                                                                                  // Номер брокерского счета зачисления
      pi_amount : MoneyStruct;                                                                                  // Денежная сумма в определенной валюте
   end;

   pi_response = record                                                                                         // Ответ для PayIn
      pi_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      pi_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      pi_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetWithdrawLimits
   gwl_request = record                                                                                         // Запрос для GetWithdrawLimits
      gwl_token : string;                                                                                       // Токен
      gwl_accountId : string;                                                                                   // Идентификатор счета пользователя
   end;

   gwl_response = record                                                                                        // Ответ для GetWithdrawLimits
      gwl_money : array of MoneyStruct;                                                                         // Массив валютных позиций портфеля
      gwl_blocked : array of MoneyStruct;                                                                       // Массив заблокированных валютных позиций портфеля
      gwl_blockedGuarantee : array of MoneyStruct;                                                              // Заблокировано под гарантийное обеспечение фьючерсов
      gwl_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gwl_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gwl_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetBrokerReport
   gbr_generateBrokerReportRequestStruct = record
      gbr_accountId : string;                                                                                   // Идентификатор счета клиента
      gbr_from : string;                                                                                        // Начало периода по UTC
      gbr_to : string;                                                                                          // Окончание периода по UTC
   end;

   gbr_getBrokerReportRequestStruct = record
      gbr_taskId : string;                                                                                      // Идентификатор задачи формирования брокерского отчета (при первом вызове указывать не надо, генерируется один раз!)
      gbr_page : int64;                                                                                         // Номер страницы отчета, начинается с 1. Значение по умолчанию — 0
   end;

   gbr_request = record                                                                                         // Запрос для GetBrokerReport
      gbr_token : string;                                                                                       // Токен
      gbr_generateBrokerReportRequest : gbr_generateBrokerReportRequestStruct;                                  //
      gbr_getBrokerReportRequest : gbr_getBrokerReportRequestStruct;                                            //
   end;

   gbr_generateBrokerReportResponseStruct = record
      gbr_taskId : string;                                                                                      // Идентификатор задачи формирования брокерского отчета
   end;

   gbr_brokerReportStruct = record
      gbr_tradeId : string;                                                                                     // Номер сделки
      gbr_orderId : string;                                                                                     // Номер поручения
      gbr_figi : string;                                                                                        // FIGI-идентификаторинструмента
      gbr_executeSign : string;                                                                                 // Признак исполнения
      gbr_tradeDatetime : string;                                                                               // Дата и время заключения по UTC
      gbr_exchange : string;                                                                                    // Торговая площадка
      gbr_classCode : string;                                                                                   // Режим торгов
      gbr_direction : string;                                                                                   // Вид сделки
      gbr_name : string;                                                                                        // Сокращенное наименование актива
      gbr_ticker : string;                                                                                      // Код актива
      gbr_price : MoneyStruct;                                                                                  // Цена за единицу
      gbr_quantity : int64;                                                                                     // Количество
      gbr_orderAmount : MoneyStruct;                                                                            // Сумма без НКД
      gbr_aciValue : double;                                                                                    // НКД
      gbr_totalOrderAmount : MoneyStruct;                                                                       // Сумма сделки
      gbr_brokerCommission : MoneyStruct;                                                                       // Комиссия брокера
      gbr_exchangeCommission : MoneyStruct;                                                                     // Комиссия биржи
      gbr_exchangeClearingCommission : MoneyStruct;                                                             // Комиссия клирингового центра
      gbr_repoRate : double;                                                                                    // Ставка РЕПО, %
      gbr_party : string;                                                                                       // Контрагент или брокерарокер
      gbr_clearValueDate : string;                                                                              // Дата расчетов по UTC
      gbr_secValueDate : string;                                                                                // Дата поставки по UTC
      gbr_brokerStatus : string;                                                                                // Статус брокера
      gbr_separateAgreementType : string;                                                                       // Тип договора
      gbr_separateAgreementNumber : string;                                                                     // Номер договора
      gbr_separateAgreementDate : string;                                                                       // Дата договора
      gbr_deliveryType : string;                                                                                // Тип расчета по сделке
   end;

   gbr_getBrokerReportResponseStruct = record
      gbr_brokerReport : array of gbr_brokerReportStruct;                                                       // Массив объектов
      gbr_itemsCount : int64;                                                                                   // Количество записей в отчете
      gbr_pagesCount : int64;                                                                                   // Количество страниц с данными отчета, начинается с 0
      gbr_page : int64;                                                                                         // Текущая страница, начинается с 0
   end;

   gbr_response = record                                                                                        // Ответ для GetBrokerReport
      gbr_generateBrokerReportResponse : gbr_generateBrokerReportResponseStruct;                                //
      gbr_getBrokerReportResponse : gbr_getBrokerReportResponseStruct;                                          //
      gbr_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gbr_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gbr_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры Indicatives
   ind_request = record                                                                                         // Запрос для Indicatives
      ind_token : string;                                                                                       // Токен
   end;

   ind_instrumentsStruct = record
      ind_figi : string;                                                                                        // FIGI-идентификатор инструмента
      ind_ticker : string;                                                                                      // Тикер инструмента
      ind_classCode : string;                                                                                   // Класс-код инструмента
      ind_currency : string;                                                                                    // Валюта расчетов
      ind_instrumentKind : string;                                                                              // Тип инструмента
      ind_name : string;                                                                                        // Название инструмента
      ind_exchange : string;                                                                                    // Tорговая площадка (секция биржи)
      ind_uid : string;                                                                                         // Уникальный идентификатор инструмента
      ind_buyAvailableFlag : boolean;                                                                           // Признак доступности для покупки
      ind_sellAvailableFlag : boolean;                                                                          // Признак доступности для продажи
   end;

   ind_response = record                                                                                        // Ответ для Indicatives
      ind_instruments : array of ind_instrumentsStruct;                                                         // Массив инструментов
      ind_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      ind_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      ind_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetCountries
   gco_request = record                                                                                         // Запрос для GetCountries
      gco_token : string;                                                                                       // Токен
   end;

   gco_countriesStruct = record
      gco_alfaTwo : string;                                                                                     // Двухбуквенный код страны
      gco_alfaThree : string;                                                                                   // Трехбуквенный код страны
      gco_name : string;                                                                                        // Наименование страны
      gco_nameBrief : string;                                                                                   // Краткое наименование страны
   end;

   gco_response = record                                                                                        // Ответ для GetCountries
      gco_countries : array of gco_countriesStruct;                                                             // Массив стран
      gco_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gco_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gco_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetFuturesMargin
   gfm_request = record                                                                                         // Запрос для GetFuturesMargin
      gfm_token : string;                                                                                       // Токен
      gfm_instrumentId : string;                                                                                // Идентификатор инструмента — figi или instrument_uid
   end;

   gfm_response = record                                                                                        // Ответ для GetFuturesMargin
      gfm_initialMarginOnBuy : MoneyStruct;                                                                     // Гарантийное обеспечение при покупке
      gfm_initialMarginOnSell : MoneyStruct;                                                                    // Гарантийное обеспечение при продаже
      gfm_minPriceIncrement : double;                                                                           // Шаг цены
      gfm_minPriceIncrementAmount : double;                                                                     // Стоимость шага цены
      gfm_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gfm_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gfm_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetForecastBy
   gfb_request = record                                                                                         // Запрос для GetForecastBy
      gfb_token : string;                                                                                       // Токен
      gfb_instrumentId : string;                                                                                // Идентификатор инструмента
   end;

   gfb_targetsStruct = record
      gfb_uid : string;                                                                                         // Уникальный идентификатор инструмента
      gfb_ticker : string;                                                                                      // Тикер инструмента
      gfb_company : string;                                                                                     // Название компании, давшей прогноз
      gfb_recommendation : string;                                                                              // Прогноз [RECOMMENDATION_UNSPECIFIED, RECOMMENDATION_BUY, RECOMMENDATION_HOLD, RECOMMENDATION_SELL]
      gfb_recommendationDate : string;                                                                          // Дата прогноза
      gfb_currency : string;                                                                                    // Валюта
      gfb_currentPrice : double;                                                                                // Текущая цена
      gfb_targetPrice : double;                                                                                 // Прогнозируемая цена
      gfb_priceChange : double;                                                                                 // Изменение цены
      gfb_priceChangeRel : double;                                                                              // Относительное изменение цены
      gfb_showName : string;                                                                                    // Наименование инструмента
   end;

   gfb_consensusStruct = record
      gfb_uid : string;                                                                                         // Уникальный идентификатор инструмента
      gfb_ticker : string;                                                                                      // Тикер инструмента
      gfb_recommendation : string;                                                                              // Прогноз [RECOMMENDATION_UNSPECIFIED, RECOMMENDATION_BUY, RECOMMENDATION_HOLD, RECOMMENDATION_SELL]
      gfb_currency : string;                                                                                    // Валюта
      gfb_currentPrice : double;                                                                                // Текущая цена
      gfb_consensus : double;                                                                                   // Прогнозируемая цена
      gfb_minTarget : double;                                                                                   // Минимальная цена прогноза
      gfb_maxTarget : double;                                                                                   // Максимальная цена прогноза
      gfb_priceChange : double;                                                                                 // Изменение цены
      gfb_priceChangeRel : double;                                                                              // Относительное изменение цены
   end;

   gfb_response = record                                                                                        // Ответ для GetForecastBy
      gfb_targets : array of gfb_targetsStruct;                                                                 // Массив прогнозов
      gfb_consensus : gfb_consensusStruct;                                                                      // Консенсус-прогноз
      gfb_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gfb_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gfb_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetRiskRates
   grr_request = record                                                                                         // Запрос для GetRiskRates
      grr_token : string;                                                                                       // Токен
      grr_instrumentId : array of string;                                                                       // Идентификатор инструмента
   end;

   grr_riskLevelCodeStruct = record
      grr_riskLevelCode : string;                                                                               // Категория риска
      grr_value : double;                                                                                       // Значение ставки риска
   end;

   grr_instrumentRiskRatesStruct = record
      grr_instrumentUid : string;                                                                               // UID-идентификатор инструмента
      grr_shortRiskRate : grr_riskLevelCodeStruct;                                                              // Ставка риска пользователя в шорт
      grr_longRiskRate : grr_riskLevelCodeStruct;                                                               // Ставка риска пользователя в лонг
      grr_shortRiskRates : array of grr_riskLevelCodeStruct;                                                    // Доступные ставки риска в шорт
      grr_longRiskRates : array of grr_riskLevelCodeStruct;                                                     // Доступные ставки риска в лонг
      grr_error : string;                                                                                       // Ошибка
   end;

   grr_response = record                                                                                        // Ответ для GetRiskRates
      grr_instrumentRiskRates : array of grr_instrumentRiskRatesStruct;                                         // Массив объектов
      grr_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      grr_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      grr_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetConsensusForecasts
   gcf_pagingStruct = record
      gcf_limit : int64;                                                                                        // Максимальное число возвращаемых записей
      gcf_pageNumber : int64;                                                                                   // Порядковый номер страницы, начиная с 0
      gcf_totalCount : int64;                                                                                   // Общее количество записей (данное поле используется только в ответе)
   end;

   gcf_request = record                                                                                         // Запрос для GetConsensusForecasts
      gcf_token : string;                                                                                       // Токен
      gcf_paging : gcf_pagingStruct;                                                                            // Настройки пагинации
   end;

   gcf_itemsStruct = record
      gcf_uid : string;                                                                                         // UID-идентификатор
      gcf_assetUid : string;                                                                                    // UID-идентификатор актива
      gcf_createdAt : string;                                                                                   // Дата и время создания записи
      gcf_bestTargetPrice : double;                                                                             // Целевая цена на 12 месяцев
      gcf_bestTargetLow : double;                                                                               // Минимальная прогнозная цена
      gcf_bestTargetHigh : double;                                                                              // Максимальная прогнозная цена
      gcf_totalBuyRecommend : int64;                                                                            // Количество аналитиков рекомендующих покупать
      gcf_totalHoldRecommend : int64;                                                                           // Количество аналитиков рекомендующих держать
      gcf_totalSellRecommend : int64;                                                                           // Количество аналитиков рекомендующих продавать
      gcf_currency : string;                                                                                    // Валюта прогнозов инструмента
      gcf_consensus : string;                                                                                   // Консенсус-прогноз
      gcf_prognosisDate : string;                                                                               // Дата прогноза
   end;

   gcf_response = record                                                                                        // Ответ для GetConsensusForecasts
      gcf_items : array of gcf_itemsStruct;                                                                     // Массив прогнозов
      gcf_page : gcf_pagingStruct;                                                                              // Данные по пагинации
      gcf_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gcf_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gcf_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры StructuredNotes
   sn_request = record                                                                                          // Запрос для StructuredNotes
      sn_token : string;                                                                                        // Токен
      sn_instrumentStatus : string;                                                                             // Статус запрашиваемых инструментов [INSTRUMENT_STATUS_UNSPECIFIED, INSTRUMENT_STATUS_BASE, INSTRUMENT_STATUS_ALL]
      sn_instrumentExchange : string;                                                                           //
   end;

   sn_basicAssetsStruct = record
      sn_uid : string;                                                                                          // Уникальный идентификатор базового актива
      sn_type : string;                                                                                         // Тип актива [ASSET_TYPE_UNSPECIFIED, ASSET_TYPE_CURRENCY, ASSET_TYPE_COMMODITY, ASSET_TYPE_INDEX, ASSET_TYPE_SECURITY]
      sn_initialPrice : double;                                                                                 // Начальная цена базового актива
   end;

   sn_yieldStruct = record
      sn_type : string;                                                                                         // Тип доходности [YIELD_TYPE_UNSPECIFIED, YIELD_TYPE_GUARANTED_COUPON, YIELD_TYPE_CONDITIONAL_COUPON, YIELD_TYPE_PARTICIPATION]
      sn_value : double;                                                                                        // Значение доходности
   end;

   sn_instrumentsStruct = record
      sn_uid : string;                                                                                          // Уникальный идентификатор инструмента
      sn_figi : string;                                                                                         // FIGI-идентификатор инструмента
      sn_ticker : string;                                                                                       // Тикер инструмента
      sn_classCode : string;                                                                                    // Класс-код (секция торгов)
      sn_isin : string;                                                                                         // ISIN-идентификатор инструмента
      sn_name : string;                                                                                         // Название инструмента
      sn_assetUid : string;                                                                                     // Уникальный идентификатор актива
      sn_positionUid : string;                                                                                  // Уникальный идентификатор позиции
      sn_minPriceIncrement : double;                                                                            // Шаг цены
      sn_lot : int64;                                                                                           // Лотность инструмента
      sn_nominal : MoneyStruct;                                                                                 // Номинал
      sn_currency : string;                                                                                     // Валюта расчетов
      sn_maturityDate : string;                                                                                 // Дата погашения облигации в формате UTC
      sn_placementDate : string;                                                                                // Дата размещения в формате UTC
      sn_issueKind : string;                                                                                    // Форма выпуска
      sn_issueSize : int64;                                                                                     // Размер выпуска
      sn_issueSizePlan : int64;                                                                                 // Плановый размер выпуска
      sn_dlongClient : double;                                                                                  // Ставка риска клиента по инструменту лонг
      sn_dshortClient : double;                                                                                 // Ставка риска клиента по инструменту шорт
      sn_shortEnabledFlag : boolean;                                                                            // Признак доступности для операций в шорт
      sn_exchange : string;                                                                                     // Торговая площадка (секция биржи)
      sn_tradingStatus : string;                                                                                // Текущий режим торгов инструмента [SECURITY_TRADING_STATUS_UNSPECIFIED, SECURITY_TRADING_STATUS_NOT_AVAILABLE_FOR_TRADING, SECURITY_TRADING_STATUS_OPENING_PERIOD, SECURITY_TRADING_STATUS_CLOSING_PERIOD, SECURITY_TRADING_STATUS_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_NORMAL_TRADING, SECURITY_TRADING_STATUS_CLOSING_AUCTION, SECURITY_TRADING_STATUS_DARK_POOL_AUCTION, SECURITY_TRADING_STATUS_DISCRETE_AUCTION, SECURITY_TRADING_STATUS_OPENING_AUCTION_PERIOD, SECURITY_TRADING_STATUS_TRADING_AT_CLOSING_AUCTION_PRICE, SECURITY_TRADING_STATUS_SESSION_ASSIGNED, SECURITY_TRADING_STATUS_SESSION_CLOSE, SECURITY_TRADING_STATUS_SESSION_OPEN, SECURITY_TRADING_STATUS_DEALER_NORMAL_TRADING, SECURITY_TRADING_STATUS_DEALER_BREAK_IN_TRADING, SECURITY_TRADING_STATUS_DEALER_NOT_AVAILABLE_FOR_TRADING]
      sn_apiTradeAvailableFlag : boolean;                                                                       // Признак доступности торгов по бумаге через API
      sn_buyAvailableFlag : boolean;                                                                            // Признак доступности для покупки
      sn_sellAvailableFlag : boolean;                                                                           // Признак доступности для продажи
      sn_limitOrderAvailableFlag : boolean;                                                                     // Признак доступности выставления лимитной заявки по инструменту
      sn_marketOrderAvailableFlag : boolean;                                                                    // Признак доступности выставления рыночной заявки по инструменту
      sn_bestpriceOrderAvailableFlag : boolean;                                                                 // Признак доступности выставления bestprice заявки по инструменту
      sn_weekendFlag : boolean;                                                                                 // Флаг отображающий доступность торговли инструментом по выходным
      sn_liquidityFlag : boolean;                                                                               // Флаг достаточной ликвидности
      sn_forIisFlag : boolean;                                                                                  // Возможность покупки/продажи на ИИС
      sn_forQualInvestorFlag : boolean;                                                                         // Флаг отображающий доступность торговли инструментом только для квалифицированных инвесторов
      sn_pawnshopListFlag : boolean;                                                                            // Признак ФИ, включенного в ломбардный список
      sn_realExchange : string;                                                                                 // Реальная площадка исполнения расчетов [REAL_EXCHANGE_UNSPECIFIED, REAL_EXCHANGE_MOEX, REAL_EXCHANGE_RTS, REAL_EXCHANGE_OTC, REAL_EXCHANGE_DEALER]
      sn_first1minCandleDate : string;                                                                          // Дата первой минутной свечи
      sn_first1dayCandleDate : string;                                                                          // Дата первой дневной свечи
      sn_borrowName : string;                                                                                   // Название заемщика
      sn_type : string;                                                                                         // Тип структурной ноты
      sn_logicPortfolio : string;                                                                               // Стратегия портфеля [LOGIC_PORTFOLIO_UNSPECIFIED, LOGIC_PORTFOLIO_VOLATILITY, LOGIC_PORTFOLIO_CORRELATION]
      sn_assetType : string;                                                                                    // Тип актива [ASSET_TYPE_UNSPECIFIED, ASSET_TYPE_CURRENCY, ASSET_TYPE_COMMODITY, ASSET_TYPE_INDEX, ASSET_TYPE_SECURITY]
      sn_basicAssets : array of sn_basicAssetsStruct;                                                           // Базовые активы, входящие в ноту
      sn_safetyBarrier : double;                                                                                // Барьер сохранности (в процентах)
      sn_couponPeriodBase : string;                                                                             // Базис расчета НКД
      sn_observationPrinciple : string;                                                                         // Принцип наблюдений [OBSERVATION_PRINCIPLE_UNSPECIFIED, OBSERVATION_PRINCIPLE_WORST_BASIC_ASSET, OBSERVATION_PRINCIPLE_BEST_BASIC_ASSET, OBSERVATION_PRINCIPLE_AVERAGE_OF_BASIC_ASSETS, OBSERVATION_PRINCIPLE_SINGLE_BASIC_ASSET_PERFORMANCE]
      sn_observationFrequency : string;                                                                         // Частота наблюдений
      sn_initialPriceFixingDate : string;                                                                       // Дата фиксации цен базовых активов
      sn_yield : array of sn_yieldStruct;                                                                       // Доходность по ноте в годовом выражении
      sn_couponSavingFlag : boolean;                                                                            // Признак сохранения купонов
      sn_sector : string;                                                                                       // Сектор экономики
      sn_countryOfRisk : string;                                                                                // Код страны рисков
      sn_countryOfRiskName : string;                                                                            // Наименование страны рисков
      sn_logoName : string;                                                                                     // Имя файла логотипа эмитента
      sn_requiredTests : array of string;                                                                       // Тесты, которые необходимо пройти клиенту, чтобы совершать покупки по бумаге
   end;

   sn_response = record                                                                                         // Ответ для StructuredNotes
      sn_instruments : array of sn_instrumentsStruct;                                                           // Массив структурных нот
      sn_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      sn_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      sn_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры StructuredNoteBy
   snb_request = record                                                                                         // Запрос для StructuredNoteBy
      snb_token : string;                                                                                       // Токен
      snb_idType : string;                                                                                      // Тип идентификатора инструмента [INSTRUMENT_ID_UNSPECIFIED, INSTRUMENT_ID_TYPE_FIGI, INSTRUMENT_ID_TYPE_TICKER, INSTRUMENT_ID_TYPE_UID, INSTRUMENT_ID_TYPE_POSITION_UID]
      snb_classCode : string;                                                                                   // Идентификатор class_code. Обязательный, если id_type = ticker
      snb_id : string;                                                                                          // Идентификатор запрашиваемого инструмента
   end;


   snb_response = record                                                                                        // Ответ для StructuredNoteBy
      snb_instrument : sn_instrumentsStruct;                                                                    // Объект передачи информации о структурной ноте
      snb_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      snb_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      snb_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetDividendsForeignIssuer
   gdfi_generateDivForeignIssuerReportStruct = record
      gdfi_accountId : string;                                                                                  // Идентификатор счета клиента
      gdfi_from : string;                                                                                       // Начало периода по UTC
      gdfi_to : string;                                                                                         // Окончание периода по UTC. Как правило, можно сформировать отчет по дату на несколько дней меньше текущей. Начало и окончание периода должны быть в рамках одного календарного года
   end;

   gdfi_getDivForeignIssuerReportStruct = record
      gdfi_taskId : string;                                                                                     // Идентификатор задачи формирования отчета
      gdfi_page : int64;                                                                                        // Номер страницы отчета (начинается с 0), значение по умолчанию: 0
   end;

   gdfi_request = record                                                                                        // Запрос для GetDividendsForeignIssuer
      gdfi_token : string;                                                                                      // Токен
      gdfi_generateDivForeignIssuerReport : gdfi_generateDivForeignIssuerReportStruct;                          // Объект запроса формирования отчета «Справка о доходах за пределами РФ»
      gdfi_getDivForeignIssuerReport : gdfi_getDivForeignIssuerReportStruct;                                    // Объект запроса сформированного отчета «Справка о доходах за пределами РФ» (при первом выполнении структура необязательна. Далее работает по taskId)
   end;

   gdfi_generateDivForeignIssuerReportResponseStruct = record
      gdfi_taskId : string;                                                                                     // Идентификатор задачи формирования отчета
   end;

   gdfi_dividendsForeignIssuerReportStruct = record
      gdfi_recordDate : string;                                                                                 // Дата фиксации реестра
      gdfi_paymentDate : string;                                                                                // Дата выплаты
      gdfi_securityName : string;                                                                               // Наименование ценной бумаги
      gdfi_isin : string;                                                                                       // ISIN-идентификатор ценной бумаги
      gdfi_issuerCountry : string;                                                                              // Страна эмитента. Для депозитарных расписок указывается страна эмитента базового актива
      gdfi_quantity : int64;                                                                                    // Количество ценных бумаг
      gdfi_dividend : double;                                                                                   // Выплаты на одну бумагу
      gdfi_externalCommission : double;                                                                         // Комиссия внешних платежных агентов
      gdfi_dividendGross : double;                                                                              // Сумма до удержания налога
      gdfi_tax : double;                                                                                        // Сумма налога, удержанного агентом
      gdfi_dividendAmount : double;                                                                             // Итоговая сумма выплаты
      gdfi_currency : string;                                                                                   // Валюта
   end;

   gdfi_divForeignIssuerReportStruct = record
      gdfi_dividendsForeignIssuerReport : array of gdfi_dividendsForeignIssuerReportStruct;                     // Отчет «Справка о доходах за пределами РФ»
      gdfi_itemsCount : int64;                                                                                  // Количество записей в отчете
      gdfi_pagesCount : int64;                                                                                  // Количество страниц с данными отчета, начинается с 0
      gdfi_page : int64;                                                                                        // Текущая страница, начинается с 0
   end;

   gdfi_response = record                                                                                       // Ответ для GetDividendsForeignIssuer
      gdfi_generateDivForeignIssuerReportResponse : gdfi_generateDivForeignIssuerReportResponseStruct;          // Объект результата задачи запуска формирования отчета «Справка о доходах за пределами РФ»
      gdfi_divForeignIssuerReport : gdfi_divForeignIssuerReportStruct;                                          //
      gdfi_error_code : int64;                                                                                  // Уникальный идентификатор ошибки
      gdfi_error_message : string;                                                                              // Пользовательское сообщение об ошибке
      gdfi_error_description : int64;                                                                           // Код ошибки
   end;

   // Структуры для процедуры OptionsBy
   o_request = record                                                                                           // Запрос для OptionsBy
      o_token : string;                                                                                         // Токен
      o_basicAssetUid : string;                                                                                 // Идентификатор базового актива опциона
      o_basicAssetPositionUid : string;                                                                         // Идентификатор позиции базового актива опциона
      o_basicInstrumentId : string;                                                                             // Идентификатор базового инструмента, принимает значение принимает значения figi, instrument_uid или ticker+"_"+classCode
   end;

   o_brandStruct = record
      o_logoName : string;                                                                                      // Логотип инструмента. Имя файла для получения логотипа
      o_logoBaseColor : string;                                                                                 // Цвет бренда
      o_textColor : string;                                                                                     // Цвет текста для цвета логотипа бренда
   end;

   o_instrumentsStruct = record
      o_uid : string;                                                                                           // Уникальный идентификатор инструмента
      o_positionUid : string;                                                                                   // Уникальный идентификатор позиции
      o_ticker : string;                                                                                        // Тикер инструмента
      o_classCode : string;                                                                                     // Класс-код
      o_basicAssetPositionUid : string;                                                                         // Уникальный идентификатор позиции основного инструмента
      o_tradingStatus : string;                                                                                 // Текущий режим торгов инструмента
      o_realExchange : string;                                                                                  // Реальная площадка исполнения расчетов
      o_direction : string;                                                                                     // Тип опциона по направлению сделки
      o_paymentType : string;                                                                                   // Тип расчетов по опциону
      o_style : string;                                                                                         // Тип опциона по стилю
      o_settlementType : string;                                                                                // Тип опциона по способу исполнения [OPTION_EXECUTION_TYPE_UNSPECIFIED, OPTION_EXECUTION_TYPE_PHYSICAL_DELIVERY, OPTION_EXECUTION_TYPE_CASH_SETTLEMENT]
      o_name : string;                                                                                          // Название инструмента
      o_currency : string;                                                                                      // Валюта
      o_settlementCurrency : string;                                                                            // Валюта, в которой оценивается контракт
      o_assetType : string;                                                                                     // Тип актива
      o_basicAsset : string;                                                                                    // Основной актив
      o_exchange : string;                                                                                      // Tорговая площадка (секция биржи)
      o_countryOfRisk : string;                                                                                 // Код страны рисков
      o_countryOfRiskName : string;                                                                             // Наименование страны рисков
      o_sector : string;                                                                                        // Сектор экономики
      o_brand : o_brandStruct;                                                                                  // Информация о бренде
      o_lot : int64;                                                                                            // Количество бумаг в лоте
      o_basicAssetSize : double;                                                                                // Размер основного актива
      o_klong : double;                                                                                         // Коэффициент ставки риска длинной позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      o_kshort : double;                                                                                        // Коэффициент ставки риска короткой позиции по клиенту. 2 – клиент со стандартным уровнем риска (КСУР); 1 – клиент с повышенным уровнем риска (КПУР)
      o_dlong : double;                                                                                         // Ставка риска начальной маржи для КСУР лонг
      o_dshort : double;                                                                                        // Ставка риска начальной маржи для КСУР шорт
      o_dlongMin : double;                                                                                      // Ставка риска начальной маржи для КПУР лонг
      o_dshortMin : double;                                                                                     // Ставка риска начальной маржи для КПУР шорт
      o_minPriceIncrement : double;                                                                             // Минимальный шаг цены
      o_strikePrice : MoneyStruct;                                                                              // Цена страйка
      o_dlongClient : double;                                                                                   // Ставка риска в лонг с учетом текущего уровня риска портфеля клиента
      o_dshortClient : double;                                                                                  // Ставка риска в шорт с учетом текущего уровня риска портфеля клиента
      o_expirationDate : string;                                                                                // Дата истечения срока в формате UTC
      o_firstTradeDate : string;                                                                                // Дата начала обращения контракта в формате UTC
      o_lastTradeDate : string;                                                                                 // Дата исполнения в формате UTC
      o_first1minCandleDate : string;                                                                           // Дата первой минутной свечи в формате UTC
      o_first1dayCandleDate : string;                                                                           // Дата первой дневной свечи в формате UTC
      o_shortEnabledFlag : boolean;                                                                             // Признак доступности для операций шорт
      o_forIisFlag : boolean;                                                                                   // Возможность покупки или продажи на ИИС
      o_otcFlag : boolean;                                                                                      // Флаг, используемый ранее для определения внебиржевых инструментов. На данный момент не используется для торгуемых через API инструментов. Может использоваться как фильтр для операций, совершавшихся некоторое время назад на ОТС площадке
      o_buyAvailableFlag : boolean;                                                                             // Признак доступности для покупки
      o_sellAvailableFlag : boolean;                                                                            // Признак доступности для продажи
      o_forQualInvestorFlag : boolean;                                                                          // Флаг, отображающий доступность торговли инструментом только для квалифицированных инвесторов
      o_weekendFlag : boolean;                                                                                  // Флаг, отображающий доступность торговли инструментом по выходным
      o_blockedTcaFlag : boolean;                                                                               // Флаг заблокированного ТКС
      o_apiTradeAvailableFlag : boolean;                                                                        // Возможность торговать инструментом через API
      o_requiredTests : array of string;                                                                        // Тесты, которые необходимо пройти клиенту, чтобы совершать сделки по инструменту
   end;

   o_response = record                                                                                          // Ответ для OptionsBy
      o_instruments : array of o_instrumentsStruct;                                                             // Массив данных по опциону
      o_error_code : int64;                                                                                     // Уникальный идентификатор ошибки
      o_error_message : string;                                                                                 // Пользовательское сообщение об ошибке
      o_error_description : int64;                                                                              // Код ошибки
   end;

   // Структуры для процедуры OptionBy
   ob_request = record                                                                                          // Запрос для OptionBy
      ob_token : string;                                                                                        // Токен
      ob_idType : string;                                                                                       // Тип идентификатора инструмента [INSTRUMENT_ID_UNSPECIFIED, INSTRUMENT_ID_TYPE_FIGI, INSTRUMENT_ID_TYPE_TICKER, INSTRUMENT_ID_TYPE_UID, INSTRUMENT_ID_TYPE_POSITION_UID]
      ob_classCode : string;                                                                                    // Идентификатор class_code. Обязательный, если id_type = ticker
      ob_id : string;                                                                                           // Идентификатор запрашиваемого инструмента
   end;

   ob_response = record                                                                                         // Ответ для OptionBy
      ob_instrument : o_instrumentsStruct;                                                                      // Опцион
      ob_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      ob_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      ob_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetInsiderDeals
   gid_request = record                                                                                         // Запрос для GetInsiderDeals
      gid_token : string;                                                                                       // Токен
      gid_instrumentId : string;                                                                                // Уникальный идентификатор инструмента
      gid_limit : int64;                                                                                        // Количество сделок в ответе
      gid_nextCursor : string;                                                                                  // Курсор для получения следующей страницы
   end;

   gid_insiderDealsStruct = record
      gid_tradeId : string;                                                                                     // Уникальный идентификатор сделки
      gid_direction : string;                                                                                   // Направление сделки [TRADE_DIRECTION_UNSPECIFIED, TRADE_DIRECTION_BUY, TRADE_DIRECTION_SELL, TRADE_DIRECTION_INCREASE, TRADE_DIRECTION_DECREASE]
      gid_currency : string;                                                                                    // Валюта сделки
      gid_date : string;                                                                                        // Дата сделки
      gid_quantity : int64;                                                                                     // Количество
      gid_price : double;                                                                                       // Цена
      gid_instrumentUid : string;                                                                               // Уникальный идентификатор инструмента
      gid_ticker : string;                                                                                      // Тикер инструмента
      gid_investorName : string;                                                                                // Имя инвестора
      gid_investorPosition : string;                                                                            // Отношение покупателя/продавца к эмитенту
      gid_percentage : double;                                                                                  // Купленный/проданный объём от общего количества ценных бумаг на рынке
      gid_isOptionExecution : boolean;                                                                          // Признак того, является ли сделка реализацией опциона
      gid_disclosureDate : string;                                                                              // Дата раскрытия сделки
   end;

   gid_response = record                                                                                        // Ответ для GetInsiderDeals
      gid_insiderDeals : array of gid_insiderDealsStruct;                                                       // Массив сделок
      gid_nextCursor : string;                                                                                  // Курсор для получения следующей страницы
      gid_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gid_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gid_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры EditFavorites
   ef_instrumentsStruct = record
      ef_instrumentId : string;                                                                                 // Идентификатор инструмента — figi или instrument_uid
   end;

   ef_request = record                                                                                          // Запрос для EditFavorites
      ef_token : string;                                                                                        // Токен
      ef_instruments : array of ef_instrumentsStruct;                                                           // Массив инструментов
      ef_actionType : string;                                                                                   // Тип действия со списком избранных инструментов [EDIT_FAVORITES_ACTION_TYPE_UNSPECIFIED, EDIT_FAVORITES_ACTION_TYPE_ADD, EDIT_FAVORITES_ACTION_TYPE_DEL]
      ef_groupId : string;                                                                                      // Уникальный идентификатор группы
   end;

   ef_favoriteInstrumentsStruct = record
      ef_figi : string;                                                                                         // FIGI-идентификатор инструмента
      ef_ticker : string;                                                                                       // Тикер инструмента
      ef_classCode : string;                                                                                    // Класс-код инструмента
      ef_isin : string;                                                                                         // ISIN-идентификатор инструмента
      ef_instrumentType : string;                                                                               // Тип инструмента
      ef_name : string;                                                                                         // Название инструмента
      ef_uid : string;                                                                                          // Уникальный идентификатор инструмента
      ef_otcFlag : boolean;                                                                                     // Флаг, используемый ранее для определения внебиржевых инструментов. На данный момент не используется для торгуемых через API инструментов. Может использоваться как фильтр для операций, совершавшихся некоторое время назад на ОТС площадке
      ef_apiTradeAvailableFlag : boolean;                                                                       // Возможность торговать инструментом через API
      ef_instrumentKind : string;                                                                               // Тип инструмента [INSTRUMENT_TYPE_BOND, INSTRUMENT_TYPE_SHARE, INSTRUMENT_TYPE_CURRENCY, INSTRUMENT_TYPE_ETF, INSTRUMENT_TYPE_FUTURES, INSTRUMENT_TYPE_SP, INSTRUMENT_TYPE_OPTION, INSTRUMENT_TYPE_CLEARING_CERTIFICATE, INSTRUMENT_TYPE_INDEX, INSTRUMENT_TYPE_COMMODITY]
   end;

   ef_response = record                                                                                         // Ответ для EditFavorites
      ef_favoriteInstruments : array of ef_favoriteInstrumentsStruct;                                           // Массив инструментов
      ef_groupId : string;                                                                                      // Уникальный идентификатор группы
      ef_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      ef_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      ef_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetFavorites
   gf_request = record                                                                                          // Запрос для GetFavorites
      gf_token : string;                                                                                        // Токен
      gf_groupId : string;                                                                                      // Уникальный идентификатор группы
   end;

   gf_response = record                                                                                         // Ответ для GetFavorites
      gf_favoriteInstruments : array of ef_favoriteInstrumentsStruct;                                           // Массив инструментов
      gf_groupId : string;                                                                                      // Уникальный идентификатор группы
      gf_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      gf_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      gf_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetAssetBy
   gab_request = record                                                                                         // Запрос для GetAssetBy
      gab_token : string;                                                                                       // Токен
      gab_id : string;                                                                                          // UID-идентификатор актива
   end;

   gab_currencyStruct = record
      gab_baseCurrency : string;                                                                                // ISO-код валюты
   end;

   gab_shareStruct = record
      gab_type : string;                                                                                        // Тип акций [SHARE_TYPE_UNSPECIFIED, SHARE_TYPE_COMMON, SHARE_TYPE_PREFERRED, SHARE_TYPE_ADR, SHARE_TYPE_GDR, SHARE_TYPE_MLP, SHARE_TYPE_NY_REG_SHRS, SHARE_TYPE_CLOSED_END_FUND, SHARE_TYPE_REIT]
      gab_issueSize : double;                                                                                   // Объем выпуска (шт.)
      gab_nominal : double;                                                                                     // Номинал
      gab_nominalCurrency : string;                                                                             // Валюта номинала
      gab_primaryIndex : string;                                                                                // Индекс (Bloomberg)
      gab_dividendRate : double;                                                                                // Ставка дивиденда (для привилегированных акций)
      gab_preferredShareType : string;                                                                          // Тип привилегированных акций
      gab_ipoDate : string;                                                                                     // Дата IPO
      gab_registryDate : string;                                                                                // Дата регистрации
      gab_divYieldFlag : boolean;                                                                               // Признак наличия дивидендной доходности
      gab_issueKind : string;                                                                                   // Форма выпуска ФИ
      gab_placementDate : string;                                                                               // Дата размещения акции
      gab_represIsin : string;                                                                                  // ISIN базового актива
      gab_issueSizePlan : double;                                                                               // Объявленное количество, шт.
      gab_totalFloat : double;                                                                                  // Количество акций в свободном обращении
   end;

   gab_bondStruct = record
      gab_currentNominal : double;                                                                              // Текущий номинал
      gab_borrowName : string;                                                                                  // Наименование заемщика
      gab_issueSize : double;                                                                                   // Объем эмиссии облигации (стоимость)
      gab_nominal : double;                                                                                     // Номинал облигации
      gab_nominalCurrency : string;                                                                             // Валюта номинала
      gab_issueKind : string;                                                                                   // Форма выпуска облигации
      gab_interestKind : string;                                                                                // Форма дохода облигации
      gab_couponQuantityPerYear : int64;                                                                        // Количество выплат в год
      gab_indexedNominalFlag : boolean;                                                                         // Признак облигации с индексируемым номиналом
      gab_subordinatedFlag : boolean;                                                                           // Признак субординированной облигации
      gab_collateralFlag : boolean;                                                                             // Признак обеспеченной облигации
      gab_taxFreeFlag : boolean;                                                                                // Признак показывает, что купоны облигации не облагаются налогом — для mass market
      gab_amortizationFlag : boolean;                                                                           // Признак облигации с амортизацией долга
      gab_floatingCouponFlag : boolean;                                                                         // Признак облигации с плавающим купоном
      gab_perpetualFlag : boolean;                                                                              // Признак бессрочной облигации
      gab_maturityDate : string;                                                                                // Дата погашения облигации
      gab_returnCondition : string;                                                                             // Описание и условия получения дополнительного дохода
      gab_stateRegDate : string;                                                                                // Дата выпуска облигации
      gab_placementDate : string;                                                                               // Дата размещения облигации
      gab_placementPrice : double;                                                                              // Цена размещения облигации
      gab_issueSizePlan : double;                                                                               // Объявленное количество, шт.
   end;

   gab_spStruct = record
      gab_borrowName : string;                                                                                  // Наименование заемщика
      gab_nominal : double;                                                                                     // Номинал
      gab_nominalCurrency : string;                                                                             // Валюта номинала
      gab_type : string;                                                                                        // Тип структурной ноты [SP_TYPE_UNSPECIFIED, SP_TYPE_DELIVERABLE, SP_TYPE_NON_DELIVERABLE]
      gab_logicPortfolio : string;                                                                              // Стратегия портфеля
      gab_assetType : string;                                                                                   // Тип актива [ASSET_TYPE_UNSPECIFIED, ASSET_TYPE_CURRENCY, ASSET_TYPE_COMMODITY, ASSET_TYPE_INDEX, ASSET_TYPE_SECURITY]
      gab_basicAsset : string;                                                                                  // Вид базового актива в зависимости от типа базового актива
      gab_safetyBarrier : double;                                                                               // Барьер сохранности в процентах
      gab_maturityDate : string;                                                                                // Дата погашения
      gab_issueSizePlan : double;                                                                               // Объявленное количество, шт.
      gab_issueSize : double;                                                                                   // Объем размещения
      gab_placementDate : string;                                                                               // Дата размещения ноты
      gab_issueKind : string;                                                                                   // Форма выпуска
   end;

   gab_etfStruct = record
      gab_totalExpense : double;                                                                                // Суммарные расходы фонда в процентах
      gab_hurdleRate : double;                                                                                  // Барьерная ставка доходности, после которой фонд имеет право на perfomance fee — в процентах
      gab_performanceFee : double;                                                                              // Комиссия за успешные результаты фонда в процентах
      gab_fixedCommission : double;                                                                             // Фиксированная комиссия за управление в процентах
      gab_paymentType : string;                                                                                 // Тип распределения доходов от выплат по бумагам.
      gab_watermarkFlag : boolean;                                                                              // Признак необходимости выхода фонда в плюс для получения комиссии
      gab_buyPremium : double;                                                                                  // Премия (надбавка к цене) при покупке доли в фонде — в процентах
      gab_sellDiscount : double;                                                                                // Ставка дисконта (вычет из цены) при продаже доли в фонде — в процентах
      gab_rebalancingFlag : boolean;                                                                            // Признак ребалансируемости портфеля фонда
      gab_rebalancingFreq : string;                                                                             // Периодичность ребалансировки
      gab_managementType : string;                                                                              // Тип управления
      gab_primaryIndex : string;                                                                                // Индекс, который реплицирует (старается копировать) фонд
      gab_focusType : string;                                                                                   // База ETF
      gab_leveragedFlag : boolean;                                                                              // Признак использования заемных активов (плечо)
      gab_numShare : double;                                                                                    // Количество акций в обращении
      gab_ucitsFlag : boolean;                                                                                  // Признак обязательства по отчетности перед регулятором
      gab_releasedDate : string;                                                                                // Дата выпуска
      gab_description : string;                                                                                 // Описание фонда
      gab_primaryIndexDescription : string;                                                                     // Описание индекса, за которым следует фонд
      gab_primaryIndexCompany : string;                                                                         // Основные компании, в которые вкладывается фонд
      gab_indexRecoveryPeriod : double;                                                                         // Срок восстановления индекса после просадки
      gab_inavCode : string;                                                                                    // IVAV-код
      gab_divYieldFlag : boolean;                                                                               // Признак наличия дивидендной доходности
      gab_expenseCommission : double;                                                                           // Комиссия на покрытие расходов фонда в процентах
      gab_primaryIndexTrackingError : double;                                                                   // Ошибка следования за индексом в процентах
      gab_rebalancingPlan : string;                                                                             // Плановая ребалансировка портфеля
      gab_taxRate : string;                                                                                     // Ставки налогообложения дивидендов и купонов
      gab_rebalancingDates : array of string;                                                                   // Даты ребалансировок
      gab_issueKind : string;                                                                                   // Форма выпуска
      gab_nominal : double;                                                                                     // Номинал
      gab_nominalCurrency : string;                                                                             // Валюта номинала
   end;

   gab_clearingCertificateStruct = record
      gab_nominal : double;                                                                                     // Номинал
      gab_nominalCurrency : string;                                                                             // Валюта номинала
   end;

   gab_securityStruct = record
      gab_isin : string;                                                                                        // ISIN-идентификатор ценной бумаги
      gab_type : string;                                                                                        // Тип ценной бумаги
      gab_instrumentKind : string;                                                                              // Тип инструмента [INSTRUMENT_TYPE_BOND, INSTRUMENT_TYPE_SHARE, INSTRUMENT_TYPE_CURRENCY, INSTRUMENT_TYPE_ETF, INSTRUMENT_TYPE_FUTURES, INSTRUMENT_TYPE_SP, INSTRUMENT_TYPE_OPTION, INSTRUMENT_TYPE_CLEARING_CERTIFICATE, INSTRUMENT_TYPE_INDEX, INSTRUMENT_TYPE_COMMODITY]
      gab_share : gab_shareStruct;                                                                              // Акция
      gab_bond : gab_bondStruct;                                                                                // Облигация
      gab_sp : gab_spStruct;                                                                                    // Структурная нота
      gab_etf : gab_etfStruct;                                                                                  // Фонд
      gab_clearingCertificate : gab_clearingCertificateStruct;                                                  // Клиринговый сертификат участия
   end;

   gab_brandStruct = record
      gab_uid : string;                                                                                         // UID-идентификатор бренда
      gab_name : string;                                                                                        // Наименование бренда
      gab_description : string;                                                                                 // Описание
      gab_info : string;                                                                                        // Информация о бренде
      gab_company : string;                                                                                     // Компания
      gab_sector : string;                                                                                      // Сектор
      gab_countryOfRisk : string;                                                                               // Код страны риска
      gab_countryOfRiskName : string;                                                                           // Наименование страны риска
   end;

   gab_linksStruct = record
      gab_type : string;                                                                                        // Тип связи
      gab_instrumentUid : string;                                                                               // UID-идентификатор связанного инструмента
   end;

   gab_instrumentsStruct = record
      gab_uid : string;                                                                                         // UID-идентификатор инструмента
      gab_figi : string;                                                                                        // FIGI-идентификатор инструмента
      gab_instrumentType : string;                                                                              // Тип инструмента
      gab_ticker : string;                                                                                      // Тикер инструмента
      gab_classCode : string;                                                                                   // Класс-код (секция торгов)
      gab_links : array of gab_linksStruct;                                                                     // Массив связанных инструментов
      gab_instrumentKind : string;                                                                              // Тип инструмента [INSTRUMENT_TYPE_BOND, INSTRUMENT_TYPE_SHARE, INSTRUMENT_TYPE_CURRENCY, INSTRUMENT_TYPE_ETF, INSTRUMENT_TYPE_FUTURES, INSTRUMENT_TYPE_SP, INSTRUMENT_TYPE_OPTION, INSTRUMENT_TYPE_CLEARING_CERTIFICATE, INSTRUMENT_TYPE_INDEX, INSTRUMENT_TYPE_COMMODITY]
      gab_positionUid : string;                                                                                 // ID позиции
   end;

   gab_assetStruct = record
      gab_uid : string;                                                                                         // Уникальный идентификатор актива
      gab_type : string;                                                                                        // Тип актива [ASSET_TYPE_UNSPECIFIED, ASSET_TYPE_CURRENCY, ASSET_TYPE_COMMODITY, ASSET_TYPE_INDEX, ASSET_TYPE_SECURITY]
      gab_name : string;                                                                                        // Наименование актива
      gab_nameBrief : string;                                                                                   // Короткое наименование актива
      gab_description : string;                                                                                 // Описание актива
      gab_deletedAt : string;                                                                                   // Дата и время удаления актива
      gab_requiredTests : array of string;                                                                      // Тестирование клиентов
      gab_currency : gab_currencyStruct;                                                                        // Валюта
      gab_security : gab_securityStruct;                                                                        // Ценная бумага
      gab_gosRegCode : string;                                                                                  // Номер государственной регистрации
      gab_cfi : string;                                                                                         // Код CFI
      gab_codeNsd : string;                                                                                     // Код НРД инструмента
      gab_status : string;                                                                                      // Статус актива
      gab_brand : gab_brandStruct;                                                                              // Бренд
      gab_updatedAt : string;                                                                                   // Дата и время последнего обновления записи
      gab_brCode : string;                                                                                      // Код типа ц.б. по классификации Банка России
      gab_brCodeName : string;                                                                                  // Наименование кода типа ц.б. по классификации Банка России
      gab_instruments : array of gab_instrumentsStruct;                                                         // Массив идентификаторов инструментов
   end;

   gab_response = record                                                                                        // Ответ для GetAssetBy
      gab_asset : gab_assetStruct;                                                                              // Актив
      gab_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gab_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gab_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetDividends
   gd_request = record                                                                                          // Запрос для GetDividends
      gd_token : string;                                                                                        // Токен
      gd_from : string;                                                                                         // Начало запрашиваемого периода по UTC. Фильтрация происходит по параметру record_date — дата фиксации реестра
      gd_to : string;                                                                                           // Окончание запрашиваемого периода по UTC. Фильтрация происходит по параметру record_date — дата фиксации реестра
      gd_instrumentId : string;                                                                                 // Идентификатор инструмента — figi или instrument_uid
   end;

   gd_dividendsStruct = record
      gd_dividendNet : MoneyStruct;                                                                             // Величина дивиденда на 1 ценную бумагу (включая валюту)
      gd_paymentDate : string;                                                                                  // Дата фактических выплат по UTC
      gd_declaredDate : string;                                                                                 // Дата объявления дивидендов по UTC
      gd_lastBuyDate : string;                                                                                  // Последний день (включительно) покупки для получения выплаты по UTC
      gd_dividendType : string;                                                                                 // Тип выплаты. Возможные значения: Regular Cash – регулярные выплаты, Cancelled – выплата отменена, Daily Accrual – ежедневное начисление, Return of Capital – возврат капитала, прочие типы выплат
      gd_recordDate : string;                                                                                   // Дата фиксации реестра по UTC
      gd_regularity : string;                                                                                   // Регулярность выплаты. Возможные значения: Annual – ежегодная, Semi-Anl – каждые полгода, прочие типы выплат
      gd_closePrice : MoneyStruct;                                                                              // Цена закрытия инструмента на момент ex_dividend_date
      gd_yieldValue : double;                                                                                   // Величина доходности
      gd_createdAt : string;                                                                                    // Дата и время создания записи по UTC
   end;

   gd_response = record                                                                                         // Ответ для GetDividends
      gd_dividends : array of gd_dividendsStruct;                                                               // Информация о выплате
      gd_error_code : int64;                                                                                    // Уникальный идентификатор ошибки
      gd_error_message : string;                                                                                // Пользовательское сообщение об ошибке
      gd_error_description : int64;                                                                             // Код ошибки
   end;

   // Структуры для процедуры GetOperations
   geo_request = record                                                                                         // Запрос для GetOperations
      geo_token : string;                                                                                       // Токен
      geo_accountId : string;                                                                                   // Идентификатор счета клиента
      geo_from : string;                                                                                        // Начало периода по UTC
      geo_to : string;                                                                                          // Окончание периода по UTC
      geo_state : string;                                                                                       // Статус запрашиваемых операций [OPERATION_STATE_UNSPECIFIED, OPERATION_STATE_EXECUTED, OPERATION_STATE_CANCELED, OPERATION_STATE_PROGRESS]
      geo_figi : string;                                                                                        // FIGI-идентификатор инструмента для фильтрации (поддерживается UID)
   end;

   geo_tradesStruct = record
      geo_tradeId : string;                                                                                     // Идентификатор сделки
      geo_dateTime : string;                                                                                    // Дата и время сделки по UTC
      geo_quantity : int64;                                                                                     // Количество инструментов
      geo_price : MoneyStruct;                                                                                  // Цена за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
   end;

   geo_childOperationsStruct = record
      geo_instrumentUid : string;                                                                               // Уникальный идентификатор инструмента
      geo_payment : MoneyStruct;                                                                                // Сумма операции
   end;

   geo_operationsStruct = record
      geo_id : string;                                                                                          // Идентификатор операции
      geo_parentOperationId : string;                                                                           // Идентификатор родительской операции
      geo_currency : string;                                                                                    // Валюта операции
      geo_payment : MoneyStruct;                                                                                // Сумма операции
      geo_price : MoneyStruct;                                                                                  // Цена операции за 1 инструмент. Чтобы получить стоимость лота, нужно умножить на лотность инструмента
      geo_state : string;                                                                                       // Статус запрашиваемых операций [OPERATION_STATE_UNSPECIFIED, OPERATION_STATE_EXECUTED, OPERATION_STATE_CANCELED, OPERATION_STATE_PROGRESS]
      geo_quantity : int64;                                                                                     // Количество единиц инструмента
      geo_quantityRest : int64;                                                                                 // Неисполненный остаток по сделке
      geo_figi : string;                                                                                        // FIGI-идентификатор инструмента, связанного с операцией
      geo_instrumentType : string;                                                                              // Тип инструмента
      geo_date : string;                                                                                        // Дата и время операции в формате часовом поясе UTC
      geo_type : string;                                                                                        // Текстовое описание типа операции
      geo_operationType : string;                                                                               // Тип операции
      geo_trades : array of geo_tradesStruct;                                                                   // Массив сделок
      geo_assetUid : string;                                                                                    // Идентификатор актива
      geo_positionUid : string;                                                                                 // Уникальный идентификатор позиции
      geo_instrumentUid : string;                                                                               // Уникальный идентификатор инструмента
      geo_childOperations : array of geo_childOperationsStruct;                                                 // Массив дочерних операций
   end;

   geo_response = record                                                                                        // Ответ для GetOperations
      geo_operations : array of geo_operationsStruct;                                                           // Массив операций
      geo_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      geo_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      geo_error_description : int64;                                                                            // Код ошибки
   end;

   // Структуры для процедуры GetMarketValues
   gmv_request = record                                                                                         // Запрос для GetMarketValues
      gmv_token : string;                                                                                       // Токен
      gmv_instrumentId : array of string;                                                                       // Массив идентификаторов инструментов. Принимает значения figi, instrument_uid или ticker + '_' + class_code
      gmv_values : array of string;                                                                             // Массив запрашиваемых параметров [INSTRUMENT_VALUE_UNSPECIFIED, INSTRUMENT_VALUE_LAST_PRICE, INSTRUMENT_VALUE_LAST_PRICE_DEALER, INSTRUMENT_VALUE_CLOSE_PRICE, INSTRUMENT_VALUE_EVENING_SESSION_PRICE, INSTRUMENT_VALUE_OPEN_INTEREST, INSTRUMENT_VALUE_THEOR_PRICE, INSTRUMENT_VALUE_YIELD]
   end;

   gmv_valuesStruct = record
      gmv_type : string;                                                                                        // Тип параметра
      gmv_value : double;                                                                                       // Значение
      gmv_time : string;                                                                                        // Дата и время
   end;

   gmv_instrumentsStruct = record
      gmv_instrumentUid : string;                                                                               // Идентификатор инструмента
      gmv_values : array of gmv_valuesStruct;                                                                   // Массив параметров инструмента
      gmv_ticker : string;                                                                                      // Тикер инструмента
      gmv_classCode : string;                                                                                   // Класс-код (секция торгов)
   end;

   gmv_response = record                                                                                        // Ответ для GetMarketValues
      gmv_instruments : array of gmv_instrumentsStruct;                                                         // Массив значений параметров
      gmv_error_code : int64;                                                                                   // Уникальный идентификатор ошибки
      gmv_error_message : string;                                                                               // Пользовательское сообщение об ошибке
      gmv_error_description : int64;                                                                            // Код ошибки
   end;


{InstrumentsService}
procedure CreateFavoriteGroup (cfg_input : cfg_request; out cfg_output : cfg_response);                         // создать новую группу избранных инструментов
procedure Currencies (c_input : c_request; out c_output : c_response);                                          // список валют
procedure CurrencyBy (cb_input : cb_request; out cb_output : cb_response);                                      // получить валюту по ее идентификатору
procedure DeleteFavoriteGroup (dfg_input : dfg_request; out dfg_output : dfg_response);                         // удалить группу избранных инструментов
procedure EditFavorites (ef_input : ef_request; out ef_output : ef_response);                                   // отредактировать список избранных инструментов
procedure FindInstrument (fi_input : fi_request; out fi_output : fi_response);                                  // найти инструмент
procedure GetAccruedInterests (gai_input : gai_request; out gai_output : gai_response);                         // накопленный купонный доход по облигации
procedure GetAssetBy (gab_input : gab_request; out gab_output : gab_response);                                  // получить актив по его идентификатору
procedure GetAssetFundamentals (gaf_input : gaf_request; out gaf_output : gaf_response);                        // фундаментальные показатели по активу
procedure GetAssetReports (gar_input : gar_request; out gar_output : gar_response);                             // расписания выхода отчетностей эмитентов
procedure GetAssets (gas_input : gas_request; out gas_output : gas_response);                                   // список активов
procedure GetBondBy (bb_input : bb_request; out bb_output : bb_response);                                       // получить облигацию по ее идентификатору
procedure GetBondCoupons (gbc_input : gbc_request; out gbc_output : gbc_response);                              // график выплат купонов по облигации
procedure GetBondEvents (gbe_input : gbe_request; out gbe_output : gbe_response);                               // события по облигации
procedure GetBonds (b_input : b_request; out b_output : b_response);                                            // список облигаций
procedure GetBrandBy (gbb_input : gbb_request; out gbb_output : gbb_response);                                  // получить бренд по его идентификатору
procedure GetBrands (gb_input : gb_request; out gb_output : gb_response);                                       // список брендов
procedure GetConsensusForecasts (gcf_input : gcf_request; out gcf_output : gcf_response);                       // мнения аналитиков по инструменту
procedure GetCountries (gco_input : gco_request; out gco_output : gco_response);                                // список стран
procedure GetDividends (gd_input : gd_request; out gd_output : gd_response);                                    // события выплаты дивидендов по инструменту
procedure GetETFBy (eb_input : eb_request; out eb_output : eb_response);                                        // получить инвестиционный фонд по его идентификатору
procedure GetETFs (e_input : e_request; out e_output : e_response);                                             // список инвестиционных фондов
procedure GetFavoriteGroups (gfg_input : gfg_request; out gfg_output : gfg_response);                           // список групп избранных инструментов
procedure GetFavorites (gf_input : gf_request; out gf_output : gf_response);                                    // получить список избранных инструментов
procedure GetForecastBy (gfb_input : gfb_request; out gfb_output : gfb_response);                               // прогнозы инвестдомов по инструменту
procedure GetFutureBy (fb_input : fb_request; out fb_output : fb_response);                                     // получить фьючерс по его идентификатору
procedure GetFutures (f_input : f_request; out f_output : f_response);                                          // список фьючерсов
procedure GetFuturesMargin (gfm_input : gfm_request; out gfm_output : gfm_response);                            // размер гарантийного обеспечения по фьючерсам
procedure GetInsiderDeals (gid_input : gid_request; out gid_output : gid_response);                             // сделки инсайдеров по инструментам
procedure GetInstrumentBy (gib_input : gib_request; out gib_output : gib_response);                             // основная информация об инструменте
procedure GetOptionBy (ob_input : ob_request; out ob_output : ob_response);                                     // получить опцион по его идентификатору
procedure GetOptionsBy (o_input : o_request; out o_output : o_response);                                        // список опционов
procedure GetRiskRates (grr_input : grr_request; out grr_output : grr_response);                                // ставки риска по инструменту
procedure GetShareBy (sb_input : sb_request; out sb_output : sb_response);                                      // получить акцию по ее идентификатору
procedure GetShares (s_input : s_request; out s_output : s_response);                                           // список акций
procedure GetStructuredNoteBy (snb_input : snb_request; out snb_output : snb_response);                         // получить структурную ноту по ее идентификатору
procedure GetStructuredNotes (sn_input : sn_request; out sn_output : sn_response);                              // список структурных нот
procedure Indicatives (ind_input : ind_request; out ind_output : ind_response);                                 // индикативные инструменты — индексы, товары и другие
procedure TradingSchedules (ts_input : ts_request; out ts_output : ts_response);                                // расписания торговых площадок

{MarketDataService}
procedure GetCandles (gc_input : gc_request; out gc_output : gc_response);                                      // исторические свечи по инструменту
procedure GetClosePrices (gcp_input : gcp_request; out gcp_output : gcp_response);                              // цены закрытия торговой сессии по инструментам
procedure GetLastPrices (glp_input : glp_request; out glp_output : glp_response);                               // цены последних сделок по инструментам
procedure GetLastTrades (glt_input : glt_request; out glt_output : glt_response);                               // Обезличенные сделки по инструменту. Метод гарантирует получение информации за последний час
procedure GetMarketValues (gmv_input : gmv_request; out gmv_output : gmv_response);                             // рыночные данные по инструментам
procedure GetOrderBook (gob_input : gob_request; out gob_output : gob_response);                                // стакан по инструменту
procedure GetTechAnalysis (gta_input : gta_request; out gta_output : gta_response);                             // технические индикаторы по инструменту
procedure GetTradingStatus (gts_input : gts_request; out gts_output : gts_response);                            // статус торгов по инструменту
procedure GetTradingStatuses (gtss_input : gtss_request; out gtss_output : gtss_response);                      // статус торгов по инструментам

{OperationsService}
procedure GetBrokerReport (gbr_input : gbr_request; out gbr_output : gbr_response);                             // брокерский отчет
procedure GetDividendsForeignIssuer (gdfi_input : gdfi_request; out gdfi_output : gdfi_response);               // отчет «Справка о доходах за пределами РФ»
procedure GetOperations (geo_input : geo_request; out geo_output : geo_response);                               // список операций по счету
procedure GetOperationsByCursor (gobc_input : gobc_request; out gobc_output : gobc_response);                   // список операций по счету
procedure GetPortfolio (gp_input : gp_request; out gp_output : gp_response);                                    // портфель по счету
procedure GetPositions (gep_input : gep_request; out gep_output : gep_response);                                // список позиций по счету
procedure GetWithdrawLimits (gwl_input : gwl_request; out gwl_output : gwl_response);                           // доступный остаток для вывода средств

{OrdersService}
procedure CancelOrder (co_input : co_request; out co_output : co_response);                                     // отменить заявку
procedure GetMaxLots (gml_input : gml_request; out gml_output : gml_response);                                  // расчет количества доступных для покупки/продажи лотов
procedure GetOrderPrice (gop_input : gop_request; out gop_output : gop_response);                               // получить предварительную стоимость для лимитной заявки
procedure GetOrderState (gos_input : gos_request; out gos_output : gos_response);                               // получить статус торгового поручения
procedure GetOrders (go_input : go_request; out go_output : go_response);                                       // получить список активных заявок по счету
procedure PostOrder (po_input : po_request; out po_output : po_response);                                       // выставить заявку
procedure PostOrderAsync (poa_input : poa_request; out poa_output : poa_response);                              // выставить заявку асинхронным методом
procedure ReplaceOrder (ro_input : ro_request; out ro_output : ro_response);                                    // изменить выставленную заявку

{StopOrdersService}
procedure CancelStopOrder (cso_input : cso_request; out cso_output : cso_response);                             // отменить стоп-заявку
procedure GetStopOrders (gso_input : gso_request; out gso_output : gso_response);                               // получить список активных стоп-заявок по счету
procedure PostStopOrder (pso_input : pso_request; out pso_output : pso_response);                               // выставить стоп-заявку

{UsersService}
procedure CurrencyTransfer (cut_input : cut_request; out cut_output : cut_response);                            // перевод денежных средств между счетами
procedure GetAccounts (ga_input : ga_request; out ga_output : ga_response);                                     // счета пользователя
procedure GetBankAccounts (gba_input : gba_request; out gba_output : gba_response);                             // банковские счета пользователя
procedure GetInfo (gi_input : gi_request; out gi_output : gi_response);                                         // информация о пользователе
procedure GetMarginAttributes (gma_input : gma_request; out gma_output : gma_response);                         // маржинальные показатели по счeту
procedure GetUserTariff (gut_input : gut_request; out gut_output : gut_response);                               // тариф пользователя
procedure PayIn (pi_input : pi_request; out pi_output : pi_response);                                           // пополнение брокерского счета

{SignalService}
procedure GetSignals (gsi_input : gsi_request; out gsi_output : gsi_response);                                  // сигналы
procedure GetStrategies (ges_input : ges_request; out ges_output : ges_response);                               // стратегии

function UnitsNanoToDouble(int_units, int_nano : int64) : double; inline;
function ParseHeaders(const HeaderString: string): http_headers;

implementation

var
   requests_limit : UnaryLimitation;

function UnitsNanoToDouble(int_units, int_nano : int64) : double; inline;
begin
   result := int_units + int_nano/1000000000;
end;

function ParseHeaders(const HeaderString: string): http_headers;
var
   Lines: TStringList;
   i, p, j: Integer;
   Line, Key: string;
   NumValue: Int64;
begin
   Result.h_tracking_id := '';
   Result.h_date := '';
   Result.h_ratelimit_limit := 0;
   Result.h_ratelimit_remaining := 0;
   Result.h_ratelimit_reset := 0;
   Lines := TStringList.Create;
   try
      Lines.Text := StringReplace(HeaderString, #13#10, LineEnding, [rfReplaceAll]);

      for i := 0 to Lines.Count - 1 do begin
         Line := Lines[i];
         p := Pos(': ', Line);
         if p = 0 then Continue;

         Key := Copy(Line, 1, p - 1);

         if Key = 'grpc-metadata-x-tracking-id' then
            Result.h_tracking_id := Copy(Line, p + 2, Length(Line))
         else if Key = 'date' then
            Result.h_date := Copy(Line, p + 2, Length(Line))
         else if (Key = 'x-ratelimit-limit') or (Key = 'x-ratelimit-remaining') or (Key = 'x-ratelimit-reset') then begin
            NumValue := 0;
            for j := p + 2 to Length(Line) do begin
               if (Line[j] >= '0') and (Line[j] <= '9') then
                  NumValue := NumValue * 10 + (Ord(Line[j]) - Ord('0'))
               else if NumValue > 0 then
                  Break;
            end;
            if Key = 'x-ratelimit-limit' then
               Result.h_ratelimit_limit := NumValue
            else if Key = 'x-ratelimit-remaining' then
               Result.h_ratelimit_remaining := NumValue
            else
               Result.h_ratelimit_reset := NumValue;
         end;
      end;
   finally
      Lines.Free;
   end;
end;


procedure GetAccounts(ga_input : ga_request; out ga_output : ga_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, acc_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.UsersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.UsersService_limit.h_ratelimit_reset * 1000);
        requests_limit.UsersService_limit.h_ratelimit_remaining := requests_limit.UsersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if ga_input.ga_status <> '' then json_base.Add('status', ga_input.ga_status);

      endpoint_url := url_tinvest + 'UsersService/GetAccounts';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + ga_input.ga_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.UsersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            ga_output.ga_error_code := JSN.FindPath('code').AsInt64;
            ga_output.ga_error_message := JSN.FindPath('message').AsString;
            ga_output.ga_error_description := JSN.FindPath('description').AsInt64;
         end;

         if ga_output.ga_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('accounts'));

            acc_count := json_output_array.Count;
            i := 0;

            SetLength(ga_output.ga_accounts, acc_count);

            while i < acc_count do  begin
               ga_output.ga_accounts[i].ga_id := JSN.FindPath('accounts[' + inttostr(i) + '].id').AsString;
               ga_output.ga_accounts[i].ga_type := JSN.FindPath('accounts[' + inttostr(i) + '].type').AsString;
               ga_output.ga_accounts[i].ga_name := JSN.FindPath('accounts[' + inttostr(i) + '].name').AsString;
               ga_output.ga_accounts[i].ga_status := JSN.FindPath('accounts[' + inttostr(i) + '].status').AsString;
               ga_output.ga_accounts[i].ga_openedDate := JSN.FindPath('accounts[' + inttostr(i) + '].openedDate').AsString;
               ga_output.ga_accounts[i].ga_closedDate := JSN.FindPath('accounts[' + inttostr(i) + '].closedDate').AsString;
               ga_output.ga_accounts[i].ga_accessLevel := JSN.FindPath('accounts[' + inttostr(i) + '].accessLevel').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetPortfolio(gp_input : gp_request; out gp_output : gp_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, pos_count, vir_pos_count, i, j : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.OperationsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OperationsService_limit.h_ratelimit_reset * 1000);
        requests_limit.OperationsService_limit.h_ratelimit_remaining := requests_limit.OperationsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if gp_input.gp_accountId <> '' then json_base.Add('accountId', gp_input.gp_accountId);
      if gp_input.gp_currency <> '' then json_base.Add('currency', gp_input.gp_currency);

      endpoint_url := url_tinvest + 'OperationsService/GetPortfolio';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gp_input.gp_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OperationsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gp_output.gp_error_code := JSN.FindPath('code').AsInt64;
            gp_output.gp_error_message := JSN.FindPath('message').AsString;
            gp_output.gp_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gp_output.gp_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('positions'));
            pos_count := json_output_array.Count;

            json_output_array := TJSONArray(JSN.FindPath('virtualPositions'));
            vir_pos_count := json_output_array.Count;

            gp_output.gp_totalAmountShares.moneyval := UnitsNanoToDouble(JSN.FindPath('totalAmountShares.units').AsInt64 , JSN.FindPath('totalAmountShares.nano').AsInt64);
            gp_output.gp_totalAmountShares.currency := JSN.FindPath('totalAmountShares.currency').AsString;
            gp_output.gp_totalAmountBonds.moneyval := UnitsNanoToDouble(JSN.FindPath('totalAmountBonds.units').AsInt64 , JSN.FindPath('totalAmountBonds.nano').AsInt64);
            gp_output.gp_totalAmountBonds.currency := JSN.FindPath('totalAmountBonds.currency').AsString;
            gp_output.gp_totalAmountEtf.moneyval := UnitsNanoToDouble(JSN.FindPath('totalAmountEtf.units').AsInt64 , JSN.FindPath('totalAmountEtf.nano').AsInt64);
            gp_output.gp_totalAmountEtf.currency := JSN.FindPath('totalAmountEtf.currency').AsString;
            gp_output.gp_totalAmountCurrencies.moneyval := UnitsNanoToDouble(JSN.FindPath('totalAmountCurrencies.units').AsInt64 , JSN.FindPath('totalAmountCurrencies.nano').AsInt64);
            gp_output.gp_totalAmountCurrencies.currency := JSN.FindPath('totalAmountCurrencies.currency').AsString;
            gp_output.gp_totalAmountFutures.moneyval := UnitsNanoToDouble(JSN.FindPath('totalAmountFutures.units').AsInt64 , JSN.FindPath('totalAmountFutures.nano').AsInt64);
            gp_output.gp_totalAmountFutures.currency := JSN.FindPath('totalAmountFutures.currency').AsString;
            gp_output.gp_expectedYield := UnitsNanoToDouble(JSN.FindPath('expectedYield.units').AsInt64 , JSN.FindPath('expectedYield.nano').AsInt64);
            gp_output.gp_totalAmountPortfolio.moneyval := UnitsNanoToDouble(JSN.FindPath('totalAmountPortfolio.units').AsInt64 , JSN.FindPath('totalAmountPortfolio.nano').AsInt64);
            gp_output.gp_totalAmountPortfolio.currency := JSN.FindPath('totalAmountPortfolio.currency').AsString;
            gp_output.gp_accountId := JSN.FindPath('accountId').AsString;
            gp_output.gp_totalAmountOptions.moneyval := UnitsNanoToDouble(JSN.FindPath('totalAmountOptions.units').AsInt64 , JSN.FindPath('totalAmountOptions.nano').AsInt64);
            gp_output.gp_totalAmountOptions.currency := JSN.FindPath('totalAmountOptions.currency').AsString;
            gp_output.gp_totalAmountSp.moneyval := UnitsNanoToDouble(JSN.FindPath('totalAmountSp.units').AsInt64 , JSN.FindPath('totalAmountSp.nano').AsInt64);
            gp_output.gp_totalAmountSp.currency := JSN.FindPath('totalAmountSp.currency').AsString;
            gp_output.gp_dailyYieldRelative := UnitsNanoToDouble(JSN.FindPath('dailyYieldRelative.units').AsInt64 , JSN.FindPath('dailyYieldRelative.nano').AsInt64);

            i := 0;
            j := 0;

            SetLength(gp_output.gp_positions, pos_count);
            SetLength(gp_output.gp_virtualPositions, vir_pos_count);

            while i < pos_count do  begin
               gp_output.gp_positions[i].gp_figi := JSN.FindPath('positions[' + inttostr(i) + '].figi').AsString;
               gp_output.gp_positions[i].gp_instrumentType := JSN.FindPath('positions[' + inttostr(i) + '].instrumentType').AsString;
               gp_output.gp_positions[i].gp_quantity := JSN.FindPath('positions[' + inttostr(i) + '].quantity.units').AsInt64;
               gp_output.gp_positions[i].gp_averagePositionPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('positions[' + inttostr(i) + '].averagePositionPrice.units').AsInt64 , JSN.FindPath('positions[' + inttostr(i) + '].averagePositionPrice.nano').AsInt64);
               gp_output.gp_positions[i].gp_averagePositionPrice.currency := JSN.FindPath('positions[' + inttostr(i) + '].averagePositionPrice.currency').AsString;
               gp_output.gp_positions[i].gp_expectedYield := UnitsNanoToDouble(JSN.FindPath('positions[' + inttostr(i) + '].expectedYield.units').AsInt64 , JSN.FindPath('positions[' + inttostr(i) + '].expectedYield.nano').AsInt64);
               if (JSN.FindPath('positions[' + inttostr(i) + '].currentNkd')) <> nil then begin
                  gp_output.gp_positions[i].gp_currentNkd.moneyval := UnitsNanoToDouble(JSN.FindPath('positions[' + inttostr(i) + '].currentNkd.units').AsInt64 , JSN.FindPath('positions[' + inttostr(i) + '].currentNkd.nano').AsInt64);
                  gp_output.gp_positions[i].gp_currentNkd.currency := JSN.FindPath('positions[' + inttostr(i) + '].currentNkd.currency').AsString;
               end;
               gp_output.gp_positions[i].gp_averagePositionPricePt := UnitsNanoToDouble(JSN.FindPath('positions[' + inttostr(i) + '].averagePositionPricePt.units').AsInt64 , JSN.FindPath('positions[' + inttostr(i) + '].averagePositionPricePt.nano').AsInt64);
               gp_output.gp_positions[i].gp_currentPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('positions[' + inttostr(i) + '].currentPrice.units').AsInt64 , JSN.FindPath('positions[' + inttostr(i) + '].currentPrice.nano').AsInt64);
               gp_output.gp_positions[i].gp_currentPrice.currency := JSN.FindPath('positions[' + inttostr(i) + '].currentPrice.currency').AsString;
               gp_output.gp_positions[i].gp_averagePositionPriceFifo.moneyval := UnitsNanoToDouble(JSN.FindPath('positions[' + inttostr(i) + '].averagePositionPriceFifo.units').AsInt64 , JSN.FindPath('positions[' + inttostr(i) + '].averagePositionPriceFifo.nano').AsInt64);
               gp_output.gp_positions[i].gp_averagePositionPriceFifo.currency := JSN.FindPath('positions[' + inttostr(i) + '].averagePositionPriceFifo.currency').AsString;
               if (JSN.FindPath('positions[' + inttostr(i) + '].quantityLots.units')) <> nil then
                  gp_output.gp_positions[i].gp_quantityLots := JSN.FindPath('positions[' + inttostr(i) + '].quantityLots.units').AsInt64;
               gp_output.gp_positions[i].gp_blocked := JSN.FindPath('positions[' + inttostr(i) + '].blocked').AsBoolean;
               gp_output.gp_positions[i].gp_blockedLots := UnitsNanoToDouble(JSN.FindPath('positions[' + inttostr(i) + '].blockedLots.units').AsInt64 , JSN.FindPath('positions[' + inttostr(i) + '].blockedLots.nano').AsInt64);
               gp_output.gp_positions[i].gp_positionUid := JSN.FindPath('positions[' + inttostr(i) + '].positionUid').AsString;
               gp_output.gp_positions[i].gp_instrumentUid := JSN.FindPath('positions[' + inttostr(i) + '].instrumentUid').AsString;
               gp_output.gp_positions[i].gp_varMargin.moneyval := UnitsNanoToDouble(JSN.FindPath('positions[' + inttostr(i) + '].varMargin.units').AsInt64 , JSN.FindPath('positions[' + inttostr(i) + '].varMargin.nano').AsInt64);
               gp_output.gp_positions[i].gp_varMargin.currency := JSN.FindPath('positions[' + inttostr(i) + '].varMargin.currency').AsString;
               gp_output.gp_positions[i].gp_expectedYieldFifo := UnitsNanoToDouble(JSN.FindPath('positions[' + inttostr(i) + '].expectedYieldFifo.units').AsInt64 , JSN.FindPath('positions[' + inttostr(i) + '].expectedYieldFifo.nano').AsInt64);
               gp_output.gp_positions[i].gp_dailyYield.moneyval := UnitsNanoToDouble(JSN.FindPath('positions[' + inttostr(i) + '].dailyYield.units').AsInt64 , JSN.FindPath('positions[' + inttostr(i) + '].dailyYield.nano').AsInt64);
               gp_output.gp_positions[i].gp_dailyYield.currency := JSN.FindPath('positions[' + inttostr(i) + '].dailyYield.currency').AsString;
               inc(i);
            end;

            while j < vir_pos_count do  begin
               gp_output.gp_virtualPositions[j].gp_positionUid := JSN.FindPath('virtualPositions[' + inttostr(j) + '].positionUid').AsString;
               gp_output.gp_virtualPositions[j].gp_instrumentUid := JSN.FindPath('virtualPositions[' + inttostr(j) + '].instrumentUid').AsString;
               gp_output.gp_virtualPositions[j].gp_figi := JSN.FindPath('virtualPositions[' + inttostr(j) + '].figi').AsString;
               gp_output.gp_virtualPositions[j].gp_instrumentType := JSN.FindPath('virtualPositions[' + inttostr(j) + '].instrumentType').AsString;
               gp_output.gp_virtualPositions[j].gp_quantity := JSN.FindPath('virtualPositions[' + inttostr(j) + '].quantity.units').AsInt64;
               gp_output.gp_virtualPositions[j].gp_averagePositionPrice := UnitsNanoToDouble(JSN.FindPath('virtualPositions[' + inttostr(j) + '].averagePositionPrice.units').AsInt64 , JSN.FindPath('virtualPositions[' + inttostr(j) + '].averagePositionPrice.nano').AsInt64);
               gp_output.gp_virtualPositions[j].gp_expectedYield := UnitsNanoToDouble(JSN.FindPath('virtualPositions[' + inttostr(j) + '].expectedYield.units').AsInt64 , JSN.FindPath('virtualPositions[' + inttostr(j) + '].expectedYield.nano').AsInt64);
               gp_output.gp_virtualPositions[j].gp_expectedYieldFifo := UnitsNanoToDouble(JSN.FindPath('virtualPositions[' + inttostr(j) + '].expectedYieldFifo.units').AsInt64 , JSN.FindPath('virtualPositions[' + inttostr(j) + '].expectedYieldFifo.nano').AsInt64);
               gp_output.gp_virtualPositions[j].gp_expireDate := JSN.FindPath('virtualPositions[' + inttostr(j) + '].expireDate').AsString;
               gp_output.gp_virtualPositions[j].gp_currentPrice := UnitsNanoToDouble(JSN.FindPath('virtualPositions[' + inttostr(j) + '].currentPrice.units').AsInt64 , JSN.FindPath('virtualPositions[' + inttostr(j) + '].currentPrice.nano').AsInt64);
               gp_output.gp_virtualPositions[j].gp_averagePositionPriceFifo := UnitsNanoToDouble(JSN.FindPath('virtualPositions[' + inttostr(j) + '].averagePositionPriceFifo.units').AsInt64 , JSN.FindPath('virtualPositions[' + inttostr(j) + '].averagePositionPriceFifo.nano').AsInt64);
               gp_output.gp_virtualPositions[j].gp_dailyYield.moneyval := UnitsNanoToDouble(JSN.FindPath('virtualPositions[' + inttostr(j) + '].dailyYield.units').AsInt64 , JSN.FindPath('virtualPositions[' + inttostr(j) + '].dailyYield.nano').AsInt64);
               gp_output.gp_virtualPositions[j].gp_dailyYield.currency := JSN.FindPath('virtualPositions[' + inttostr(i) + '].dailyYield.currency').AsString;
               inc(j);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetOperationsByCursor (gobc_input : gobc_request; out gobc_output : gobc_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   operations_count, operations_numb, status_code, trades_count, child_count, i, j : int64;
   json_base : TJSONObject;
   json_input_array : TJSONArray;

begin
   try
      if requests_limit.OperationsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OperationsService_limit.h_ratelimit_reset * 1000);
        requests_limit.OperationsService_limit.h_ratelimit_remaining := requests_limit.OperationsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_input_array := TJSONArray.Create;

      if gobc_input.gobc_accountId <> '' then json_base.Add('accountId', gobc_input.gobc_accountId);
      if gobc_input.gobc_instrumentId <> '' then json_base.Add('instrumentId', gobc_input.gobc_instrumentId);
      if gobc_input.gobc_from <> '' then json_base.Add('from', gobc_input.gobc_from);
      if gobc_input.gobc_to <> '' then json_base.Add('to', gobc_input.gobc_to);
      if gobc_input.gobc_cursor <> '' then json_base.Add('cursor', gobc_input.gobc_cursor);
      if gobc_input.gobc_limit >= 0 then json_base.Add('limit', gobc_input.gobc_limit);

      operations_count := high(gobc_input.gobc_operationTypes);
      for i := 0 to operations_count do begin
         json_input_array.Add(gobc_input.gobc_operationTypes[i].gobc_type);
      end;
      if operations_count > 0 then json_base.Add('operationTypes', json_input_array);

      if gobc_input.gobc_state <> '' then json_base.Add('state', gobc_input.gobc_state);
      json_base.Add('withoutCommissions', gobc_input.gobc_withoutCommissions);
      json_base.Add('withoutTrades', gobc_input.gobc_withoutTrades);
      json_base.Add('withoutOvernights', gobc_input.gobc_withoutTrades);

      endpoint_url := url_tinvest + 'OperationsService/GetOperationsByCursor';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gobc_input.gobc_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OperationsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gobc_output.gobc_error_code := JSN.FindPath('code').AsInt64;
            gobc_output.gobc_error_message := JSN.FindPath('message').AsString;
            gobc_output.gobc_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gobc_output.gobc_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('items'));
            operations_numb := json_output_array.Count;

            i := 0;

            SetLength(gobc_output.gobc_items, operations_numb +1);

            gobc_output.gobc_hasNext := JSN.FindPath('hasNext').AsBoolean;
            gobc_output.gobc_nextCursor := JSN.FindPath('nextCursor').AsString;

            while i < operations_numb do  begin
               gobc_output.gobc_items[i].gobc_cursor := JSN.FindPath('items[' + inttostr(i) + '].cursor').AsString;
               gobc_output.gobc_items[i].gobc_brokerAccountId := JSN.FindPath('items[' + inttostr(i) + '].brokerAccountId').AsString;
               gobc_output.gobc_items[i].gobc_id := JSN.FindPath('items[' + inttostr(i) + '].id').AsString;
               gobc_output.gobc_items[i].gobc_parentOperationId := JSN.FindPath('items[' + inttostr(i) + '].parentOperationId').AsString;
               gobc_output.gobc_items[i].gobc_name := JSN.FindPath('items[' + inttostr(i) + '].name').AsString;
               gobc_output.gobc_items[i].gobc_date := JSN.FindPath('items[' + inttostr(i) + '].date').AsString;
               gobc_output.gobc_items[i].gobc_type := JSN.FindPath('items[' + inttostr(i) + '].type').AsString;
               gobc_output.gobc_items[i].gobc_description := JSN.FindPath('items[' + inttostr(i) + '].description').AsString;
               gobc_output.gobc_items[i].gobc_state := JSN.FindPath('items[' + inttostr(i) + '].state').AsString;
               gobc_output.gobc_items[i].gobc_instrumentUid := JSN.FindPath('items[' + inttostr(i) + '].instrumentUid').AsString;
               gobc_output.gobc_items[i].gobc_figi := JSN.FindPath('items[' + inttostr(i) + '].figi').AsString;
               gobc_output.gobc_items[i].gobc_instrumentType := JSN.FindPath('items[' + inttostr(i) + '].instrumentType').AsString;
               gobc_output.gobc_items[i].gobc_instrumentKind := JSN.FindPath('items[' + inttostr(i) + '].instrumentKind').AsString;
               gobc_output.gobc_items[i].gobc_positionUid := JSN.FindPath('items[' + inttostr(i) + '].positionUid').AsString;
               gobc_output.gobc_items[i].gobc_ticker := JSN.FindPath('items[' + inttostr(i) + '].ticker').AsString;
               gobc_output.gobc_items[i].gobc_classCode := JSN.FindPath('items[' + inttostr(i) + '].classCode').AsString;
               gobc_output.gobc_items[i].gobc_payment.moneyval := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].payment.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].payment.nano').AsInt64);
               gobc_output.gobc_items[i].gobc_payment.currency := JSN.FindPath('items[' + inttostr(i) + '].payment.currency').AsString;
               gobc_output.gobc_items[i].gobc_price.moneyval := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].price.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].price.nano').AsInt64);
               gobc_output.gobc_items[i].gobc_price.currency := JSN.FindPath('items[' + inttostr(i) + '].price.currency').AsString;
               gobc_output.gobc_items[i].gobc_commission.moneyval := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].commission.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].commission.nano').AsInt64);
               gobc_output.gobc_items[i].gobc_commission.currency := JSN.FindPath('items[' + inttostr(i) + '].commission.currency').AsString;
               gobc_output.gobc_items[i].gobc_yield.moneyval := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].yield.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].yield.nano').AsInt64);
               gobc_output.gobc_items[i].gobc_yield.currency := JSN.FindPath('items[' + inttostr(i) + '].yield.currency').AsString;
               gobc_output.gobc_items[i].gobc_yieldRelative := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].yieldRelative.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].yieldRelative.nano').AsInt64);
               gobc_output.gobc_items[i].gobc_accruedInt.moneyval := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].accruedInt.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].accruedInt.nano').AsInt64);
               gobc_output.gobc_items[i].gobc_accruedInt.currency := JSN.FindPath('items[' + inttostr(i) + '].accruedInt.currency').AsString;
               gobc_output.gobc_items[i].gobc_quantity := JSN.FindPath('items[' + inttostr(i) + '].quantity').AsInt64;
               gobc_output.gobc_items[i].gobc_quantityRest := JSN.FindPath('items[' + inttostr(i) + '].quantityRest').AsInt64;
               gobc_output.gobc_items[i].gobc_quantityDone := JSN.FindPath('items[' + inttostr(i) + '].quantityDone').AsInt64;
               if JSN.FindPath('items[' + inttostr(i) + '].cancelDateTime') <> nil then
                  gobc_output.gobc_items[i].gobc_cancelDateTime := JSN.FindPath('items[' + inttostr(i) + '].cancelDateTime').AsString;
               gobc_output.gobc_items[i].gobc_cancelReason := JSN.FindPath('items[' + inttostr(i) + '].cancelReason').AsString;
               gobc_output.gobc_items[i].gobc_assetUid := JSN.FindPath('items[' + inttostr(i) + '].assetUid').AsString;

               if JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades') <> nil then begin
                  json_output_array := TJSONArray(JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades'));
                  trades_count := json_output_array.Count;
                  j := 0;

                  SetLength(gobc_output.gobc_items[i].gobc_tradesInfo, trades_count);

                  while j < trades_count do  begin
                     gobc_output.gobc_items[i].gobc_tradesInfo[j].gobc_num := JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades[' + inttostr(j) + '].num').AsString;
                     gobc_output.gobc_items[i].gobc_tradesInfo[j].gobc_date := JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades[' + inttostr(j) + '].date').AsString;
                     gobc_output.gobc_items[i].gobc_tradesInfo[j].gobc_quantity := JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades[' + inttostr(j) + '].quantity').AsInt64;
                     gobc_output.gobc_items[i].gobc_tradesInfo[j].gobc_price.moneyval := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades[' + inttostr(j) + '].price.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades[' + inttostr(j) + '].price.nano').AsInt64);
                     gobc_output.gobc_items[i].gobc_tradesInfo[j].gobc_price.currency := JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades[' + inttostr(j) + '].price.currency').AsString;
                     gobc_output.gobc_items[i].gobc_tradesInfo[j].gobc_yield.moneyval := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades[' + inttostr(j) + '].yield.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades[' + inttostr(j) + '].yield.nano').AsInt64);
                     gobc_output.gobc_items[i].gobc_tradesInfo[j].gobc_yield.currency := JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades[' + inttostr(j) + '].yield.currency').AsString;
                     gobc_output.gobc_items[i].gobc_tradesInfo[j].gobc_yieldRelative := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades[' + inttostr(j) + '].yieldRelative.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].tradesInfo.trades[' + inttostr(j) + '].yieldRelative.nano').AsInt64);
                     inc(j);
                  end;
               end;

               if JSN.FindPath('items[' + inttostr(i) + '].childOperations') <> nil then begin
                  json_output_array := TJSONArray(JSN.FindPath('items[' + inttostr(i) + '].childOperations'));
                  child_count := json_output_array.Count;
                  j := 0;

                  SetLength(gobc_output.gobc_items[i].gobc_childOperations, child_count);

                  while j < child_count do  begin
                     gobc_output.gobc_items[i].gobc_childOperations[j].gobc_instrumentUid := JSN.FindPath('items[' + inttostr(i) + '].childOperations[' + inttostr(j) + '].instrumentUid').AsString;
                     gobc_output.gobc_items[i].gobc_childOperations[j].gobc_payment := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].childOperations[' + inttostr(j) + '].payment.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].childOperations[' + inttostr(j) + '].payment.nano').AsInt64);
                     inc(j);
                  end;
               end;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetBonds(b_input : b_request; out b_output : b_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, bonds_count, tests_count, i, j : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if b_input.b_instrumentStatus <> '' then json_base.Add('instrumentStatus', b_input.b_instrumentStatus);
      if b_input.b_instrumentExchange <> '' then json_base.Add('instrumentExchange', b_input.b_instrumentExchange);

      endpoint_url := url_tinvest + 'InstrumentsService/Bonds';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + b_input.b_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            b_output.b_error_code := JSN.FindPath('code').AsInt64;
            b_output.b_error_message := JSN.FindPath('message').AsString;
            b_output.b_error_description := JSN.FindPath('description').AsInt64;
         end;

         if b_output.b_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('instruments'));

            bonds_count := json_output_array.Count;

            SetLength(b_output.b_instruments, bonds_count);

            i := 0;

            while i < bonds_count do  begin
               b_output.b_instruments[i].b_figi := JSN.FindPath('instruments[' + inttostr(i) + '].figi').AsString;
               b_output.b_instruments[i].b_ticker := JSN.FindPath('instruments[' + inttostr(i) + '].ticker').AsString;
               b_output.b_instruments[i].b_classCode := JSN.FindPath('instruments[' + inttostr(i) + '].classCode').AsString;
               b_output.b_instruments[i].b_isin := JSN.FindPath('instruments[' + inttostr(i) + '].isin').AsString;
               b_output.b_instruments[i].b_lot := JSN.FindPath('instruments[' + inttostr(i) + '].lot').AsInt64;
               b_output.b_instruments[i].b_currency := JSN.FindPath('instruments[' + inttostr(i) + '].currency').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].klong') <> nil then
                  b_output.b_instruments[i].b_klong := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].klong.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].klong.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].kshort') <> nil then
                  b_output.b_instruments[i].b_kshort := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].kshort.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].kshort.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlong') <> nil then
                  b_output.b_instruments[i].b_dlong := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlong.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlong.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshort') <> nil then
                  b_output.b_instruments[i].b_dshort := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshort.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshort.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin') <> nil then
                  b_output.b_instruments[i].b_dlongMin := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin') <> nil then
                  b_output.b_instruments[i].b_dshortMin := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.nano').AsInt64);
               b_output.b_instruments[i].b_shortEnabledFlag := JSN.FindPath('instruments[' + inttostr(i) + '].shortEnabledFlag').AsBoolean;
               b_output.b_instruments[i].b_name := JSN.FindPath('instruments[' + inttostr(i) + '].name').AsString;
               b_output.b_instruments[i].b_exchange := JSN.FindPath('instruments[' + inttostr(i) + '].exchange').AsString;
               b_output.b_instruments[i].b_couponQuantityPerYear := JSN.FindPath('instruments[' + inttostr(i) + '].couponQuantityPerYear').AsInt64;
               if JSN.FindPath('instruments[' + inttostr(i) + '].maturityDate') <> nil then
                  b_output.b_instruments[i].b_maturityDate := JSN.FindPath('instruments[' + inttostr(i) + '].maturityDate').AsString;
               b_output.b_instruments[i].b_nominal.moneyval := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].nominal.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].nominal.nano').AsInt64);
               b_output.b_instruments[i].b_nominal.currency := JSN.FindPath('instruments[' + inttostr(i) + '].nominal.currency').AsString;
               b_output.b_instruments[i].b_initialNominal.moneyval := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].initialNominal.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].initialNominal.nano').AsInt64);
               b_output.b_instruments[i].b_initialNominal.currency := JSN.FindPath('instruments[' + inttostr(i) + '].initialNominal.currency').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].stateRegDate') <> nil then
                  b_output.b_instruments[i].b_stateRegDate := JSN.FindPath('instruments[' + inttostr(i) + '].stateRegDate').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].placementDate') <> nil then
                  b_output.b_instruments[i].b_placementDate := JSN.FindPath('instruments[' + inttostr(i) + '].placementDate').AsString;
               b_output.b_instruments[i].b_placementPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].placementPrice.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].placementPrice.nano').AsInt64);
               b_output.b_instruments[i].b_placementPrice.currency := JSN.FindPath('instruments[' + inttostr(i) + '].placementPrice.currency').AsString;
               b_output.b_instruments[i].b_aciValue.moneyval := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].aciValue.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].aciValue.nano').AsInt64);
               b_output.b_instruments[i].b_aciValue.currency := JSN.FindPath('instruments[' + inttostr(i) + '].aciValue.currency').AsString;
               b_output.b_instruments[i].b_countryOfRisk := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRisk').AsString;
               b_output.b_instruments[i].b_countryOfRiskName := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRiskName').AsString;
               b_output.b_instruments[i].b_sector := JSN.FindPath('instruments[' + inttostr(i) + '].sector').AsString;
               b_output.b_instruments[i].b_issueKind := JSN.FindPath('instruments[' + inttostr(i) + '].issueKind').AsString;
               b_output.b_instruments[i].b_issueSize := JSN.FindPath('instruments[' + inttostr(i) + '].issueSize').AsInt64;
               b_output.b_instruments[i].b_issueSizePlan := JSN.FindPath('instruments[' + inttostr(i) + '].issueSizePlan').AsInt64;
               b_output.b_instruments[i].b_tradingStatus := JSN.FindPath('instruments[' + inttostr(i) + '].tradingStatus').AsString;
               b_output.b_instruments[i].b_otcFlag := JSN.FindPath('instruments[' + inttostr(i) + '].otcFlag').AsBoolean;
               b_output.b_instruments[i].b_buyAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].buyAvailableFlag').AsBoolean;
               b_output.b_instruments[i].b_sellAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].sellAvailableFlag').AsBoolean;
               b_output.b_instruments[i].b_floatingCouponFlag := JSN.FindPath('instruments[' + inttostr(i) + '].floatingCouponFlag').AsBoolean;
               b_output.b_instruments[i].b_perpetualFlag := JSN.FindPath('instruments[' + inttostr(i) + '].perpetualFlag').AsBoolean;
               b_output.b_instruments[i].b_amortizationFlag := JSN.FindPath('instruments[' + inttostr(i) + '].amortizationFlag').AsBoolean;
               if JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement') <> nil then
                  b_output.b_instruments[i].b_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.nano').AsInt64);
               b_output.b_instruments[i].b_apiTradeAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].apiTradeAvailableFlag').AsBoolean;
               b_output.b_instruments[i].b_uid := JSN.FindPath('instruments[' + inttostr(i) + '].uid').AsString;
               b_output.b_instruments[i].b_realExchange := JSN.FindPath('instruments[' + inttostr(i) + '].realExchange').AsString;
               b_output.b_instruments[i].b_positionUid := JSN.FindPath('instruments[' + inttostr(i) + '].positionUid').AsString;
               b_output.b_instruments[i].b_assetUid := JSN.FindPath('instruments[' + inttostr(i) + '].assetUid').AsString;
               b_output.b_instruments[i].b_forIisFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forIisFlag').AsBoolean;
               b_output.b_instruments[i].b_forQualInvestorFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forQualInvestorFlag').AsBoolean;
               b_output.b_instruments[i].b_weekendFlag := JSN.FindPath('instruments[' + inttostr(i) + '].weekendFlag').AsBoolean;
               b_output.b_instruments[i].b_blockedTcaFlag := JSN.FindPath('instruments[' + inttostr(i) + '].blockedTcaFlag').AsBoolean;
               b_output.b_instruments[i].b_subordinatedFlag := JSN.FindPath('instruments[' + inttostr(i) + '].subordinatedFlag').AsBoolean;
               b_output.b_instruments[i].b_liquidityFlag := JSN.FindPath('instruments[' + inttostr(i) + '].liquidityFlag').AsBoolean;
               if JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate') <> nil then
                  b_output.b_instruments[i].b_first1minCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate') <> nil then
                  b_output.b_instruments[i].b_first1dayCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate').AsString;
               b_output.b_instruments[i].b_riskLevel := JSN.FindPath('instruments[' + inttostr(i) + '].riskLevel').AsString;
               b_output.b_instruments[i].b_brand.b_logoName := JSN.FindPath('instruments[' + inttostr(i) + '].brand.logoName').AsString;
               b_output.b_instruments[i].b_brand.b_logoBaseColor := JSN.FindPath('instruments[' + inttostr(i) + '].brand.logoBaseColor').AsString;
               b_output.b_instruments[i].b_brand.b_textColor := JSN.FindPath('instruments[' + inttostr(i) + '].brand.textColor').AsString;
               b_output.b_instruments[i].b_bondType := JSN.FindPath('instruments[' + inttostr(i) + '].bondType').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].callDate') <> nil then
                  b_output.b_instruments[i].b_callDate := JSN.FindPath('instruments[' + inttostr(i) + '].callDate').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient') <> nil then
                  b_output.b_instruments[i].b_dlongClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient') <> nil then
                  b_output.b_instruments[i].b_dshortClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.nano').AsInt64);

               json_output_array := TJSONArray(JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests'));
               tests_count := json_output_array.Count;
               SetLength(b_output.b_instruments[i].b_requiredTests, tests_count);
               j := 0;

               while j < tests_count do  begin
                  b_output.b_instruments[i].b_requiredTests[j] := JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests[' + inttostr(j) + ']').AsString;
                  inc(j);
               end;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetShares(s_input : s_request; out s_output : s_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, shares_count, tests_count, i, j : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if s_input.s_instrumentStatus <> '' then json_base.Add('instrumentStatus', s_input.s_instrumentStatus);
      if s_input.s_instrumentExchange <> '' then json_base.Add('instrumentExchange', s_input.s_instrumentExchange);

      endpoint_url := url_tinvest + 'InstrumentsService/Shares';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + s_input.s_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            s_output.s_error_code := JSN.FindPath('code').AsInt64;
            s_output.s_error_message := JSN.FindPath('message').AsString;
            s_output.s_error_description := JSN.FindPath('description').AsInt64;
         end;

         if s_output.s_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('instruments'));

            shares_count := json_output_array.Count;

            SetLength(s_output.s_instruments, shares_count);

            i := 0;

            while i < shares_count do  begin
               s_output.s_instruments[i].s_figi := JSN.FindPath('instruments[' + inttostr(i) + '].figi').AsString;
               s_output.s_instruments[i].s_ticker := JSN.FindPath('instruments[' + inttostr(i) + '].ticker').AsString;
               s_output.s_instruments[i].s_classCode := JSN.FindPath('instruments[' + inttostr(i) + '].classCode').AsString;
               s_output.s_instruments[i].s_isin := JSN.FindPath('instruments[' + inttostr(i) + '].isin').AsString;
               s_output.s_instruments[i].s_lot := JSN.FindPath('instruments[' + inttostr(i) + '].lot').AsInt64;
               s_output.s_instruments[i].s_currency := JSN.FindPath('instruments[' + inttostr(i) + '].currency').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].klong') <> nil then
                  s_output.s_instruments[i].s_klong := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].klong.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].klong.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].kshort') <> nil then
                  s_output.s_instruments[i].s_kshort := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].kshort.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].kshort.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlong') <> nil then
                  s_output.s_instruments[i].s_dlong := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlong.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlong.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshort') <> nil then
                  s_output.s_instruments[i].s_dshort := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshort.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshort.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin') <> nil then
                  s_output.s_instruments[i].s_dlongMin := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin') <> nil then
                  s_output.s_instruments[i].s_dshortMin := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].shortEnabledFlag') <> nil then
                  s_output.s_instruments[i].s_shortEnabledFlag := JSN.FindPath('instruments[' + inttostr(i) + '].shortEnabledFlag').AsBoolean;
               s_output.s_instruments[i].s_name := JSN.FindPath('instruments[' + inttostr(i) + '].name').AsString;
               s_output.s_instruments[i].s_exchange := JSN.FindPath('instruments[' + inttostr(i) + '].exchange').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].ipoDate') <> nil then
                  s_output.s_instruments[i].s_ipoDate := JSN.FindPath('instruments[' + inttostr(i) + '].ipoDate').AsString;
               s_output.s_instruments[i].s_issueSize := JSN.FindPath('instruments[' + inttostr(i) + '].issueSize').AsInt64;
               s_output.s_instruments[i].s_countryOfRisk := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRisk').AsString;
               s_output.s_instruments[i].s_countryOfRiskName := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRiskName').AsString;
               s_output.s_instruments[i].s_sector := JSN.FindPath('instruments[' + inttostr(i) + '].sector').AsString;
               s_output.s_instruments[i].s_issueSizePlan := JSN.FindPath('instruments[' + inttostr(i) + '].issueSizePlan').AsInt64;
               s_output.s_instruments[i].s_nominal.moneyval := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].nominal.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].nominal.nano').AsInt64);
               s_output.s_instruments[i].s_nominal.currency := JSN.FindPath('instruments[' + inttostr(i) + '].nominal.currency').AsString;
               s_output.s_instruments[i].s_tradingStatus := JSN.FindPath('instruments[' + inttostr(i) + '].tradingStatus').AsString;
               s_output.s_instruments[i].s_otcFlag := JSN.FindPath('instruments[' + inttostr(i) + '].otcFlag').AsBoolean;
               s_output.s_instruments[i].s_buyAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].buyAvailableFlag').AsBoolean;
               s_output.s_instruments[i].s_sellAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].sellAvailableFlag').AsBoolean;
               s_output.s_instruments[i].s_divYieldFlag := JSN.FindPath('instruments[' + inttostr(i) + '].divYieldFlag').AsBoolean;
               s_output.s_instruments[i].s_shareType := JSN.FindPath('instruments[' + inttostr(i) + '].shareType').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement') <> nil then
                  s_output.s_instruments[i].s_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.nano').AsInt64);
               s_output.s_instruments[i].s_apiTradeAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].apiTradeAvailableFlag').AsBoolean;
               s_output.s_instruments[i].s_uid := JSN.FindPath('instruments[' + inttostr(i) + '].uid').AsString;
               s_output.s_instruments[i].s_realExchange := JSN.FindPath('instruments[' + inttostr(i) + '].realExchange').AsString;
               s_output.s_instruments[i].s_positionUid := JSN.FindPath('instruments[' + inttostr(i) + '].positionUid').AsString;
               s_output.s_instruments[i].s_assetUid := JSN.FindPath('instruments[' + inttostr(i) + '].assetUid').AsString;
               s_output.s_instruments[i].s_instrumentExchange := JSN.FindPath('instruments[' + inttostr(i) + '].instrumentExchange').AsString;
               s_output.s_instruments[i].s_forIisFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forIisFlag').AsBoolean;
               s_output.s_instruments[i].s_forQualInvestorFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forQualInvestorFlag').AsBoolean;
               s_output.s_instruments[i].s_weekendFlag := JSN.FindPath('instruments[' + inttostr(i) + '].weekendFlag').AsBoolean;
               s_output.s_instruments[i].s_blockedTcaFlag := JSN.FindPath('instruments[' + inttostr(i) + '].blockedTcaFlag').AsBoolean;
               s_output.s_instruments[i].s_liquidityFlag := JSN.FindPath('instruments[' + inttostr(i) + '].liquidityFlag').AsBoolean;
               if JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate') <> nil then
                  s_output.s_instruments[i].s_first1minCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate') <> nil then
                  s_output.s_instruments[i].s_first1dayCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate').AsString;
               s_output.s_instruments[i].s_brand.s_logoName := JSN.FindPath('instruments[' + inttostr(i) + '].brand.logoName').AsString;
               s_output.s_instruments[i].s_brand.s_logoBaseColor := JSN.FindPath('instruments[' + inttostr(i) + '].brand.logoBaseColor').AsString;
               s_output.s_instruments[i].s_brand.s_textColor := JSN.FindPath('instruments[' + inttostr(i) + '].brand.textColor').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient') <> nil then
                  s_output.s_instruments[i].s_dlongClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient') <> nil then
                  s_output.s_instruments[i].s_dshortClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.nano').AsInt64);

               json_output_array := TJSONArray(JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests'));
               tests_count := json_output_array.Count;
               SetLength(s_output.s_instruments[i].s_requiredTests, tests_count);
               j := 0;

               while j < tests_count do  begin
                  s_output.s_instruments[i].s_requiredTests[j] := JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests[' + inttostr(j) + ']').AsString;
                  inc(j);
               end;

               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetFutures(f_input : f_request; out f_output : f_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, futures_count, tests_count, i, j : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if f_input.f_instrumentStatus <> '' then json_base.Add('instrumentStatus', f_input.f_instrumentStatus);
      if f_input.f_instrumentExchange <> '' then json_base.Add('instrumentExchange', f_input.f_instrumentExchange);

      endpoint_url := url_tinvest + 'InstrumentsService/Futures';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + f_input.f_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            f_output.f_error_code := JSN.FindPath('code').AsInt64;
            f_output.f_error_message := JSN.FindPath('message').AsString;
            f_output.f_error_description := JSN.FindPath('description').AsInt64;
         end;

         if f_output.f_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('instruments'));

            futures_count := json_output_array.Count;
            SetLength(f_output.f_instruments, futures_count);

            i := 0;

            while i < futures_count do  begin
               f_output.f_instruments[i].f_figi := JSN.FindPath('instruments[' + inttostr(i) + '].figi').AsString;
               f_output.f_instruments[i].f_ticker := JSN.FindPath('instruments[' + inttostr(i) + '].ticker').AsString;
               f_output.f_instruments[i].f_classCode := JSN.FindPath('instruments[' + inttostr(i) + '].classCode').AsString;
               f_output.f_instruments[i].f_lot := JSN.FindPath('instruments[' + inttostr(i) + '].lot').AsInt64;
               f_output.f_instruments[i].f_currency := JSN.FindPath('instruments[' + inttostr(i) + '].currency').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].klong') <> nil then
                  f_output.f_instruments[i].f_klong := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].klong.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].klong.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].kshort') <> nil then
                  f_output.f_instruments[i].f_kshort := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].kshort.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].kshort.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlong') <> nil then
                  f_output.f_instruments[i].f_dlong := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlong.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlong.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshort') <> nil then
                  f_output.f_instruments[i].f_dshort := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshort.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshort.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin') <> nil then
                  f_output.f_instruments[i].f_dlongMin := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin') <> nil then
                  f_output.f_instruments[i].f_dshortMin := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.nano').AsInt64);
               f_output.f_instruments[i].f_shortEnabledFlag := JSN.FindPath('instruments[' + inttostr(i) + '].shortEnabledFlag').AsBoolean;
               f_output.f_instruments[i].f_name := JSN.FindPath('instruments[' + inttostr(i) + '].name').AsString;
               f_output.f_instruments[i].f_exchange := JSN.FindPath('instruments[' + inttostr(i) + '].exchange').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].firstTradeDate') <> nil then
                  f_output.f_instruments[i].f_firstTradeDate := JSN.FindPath('instruments[' + inttostr(i) + '].firstTradeDate').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].lastTradeDate') <> nil then
                  f_output.f_instruments[i].f_lastTradeDate := JSN.FindPath('instruments[' + inttostr(i) + '].lastTradeDate').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].futuresType') <> nil then
                  f_output.f_instruments[i].f_futuresType := JSN.FindPath('instruments[' + inttostr(i) + '].futuresType').AsString;
               f_output.f_instruments[i].f_assetType := JSN.FindPath('instruments[' + inttostr(i) + '].assetType').AsString;
               f_output.f_instruments[i].f_basicAsset := JSN.FindPath('instruments[' + inttostr(i) + '].basicAsset').AsString;
               f_output.f_instruments[i].f_basicAssetSize := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].basicAssetSize.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].basicAssetSize.nano').AsInt64);
               f_output.f_instruments[i].f_countryOfRisk := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRisk').AsString;
               f_output.f_instruments[i].f_countryOfRiskName := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRiskName').AsString;
               f_output.f_instruments[i].f_sector := JSN.FindPath('instruments[' + inttostr(i) + '].sector').AsString;
               f_output.f_instruments[i].f_expirationDate := JSN.FindPath('instruments[' + inttostr(i) + '].expirationDate').AsString;
               f_output.f_instruments[i].f_tradingStatus := JSN.FindPath('instruments[' + inttostr(i) + '].tradingStatus').AsString;
               f_output.f_instruments[i].f_otcFlag := JSN.FindPath('instruments[' + inttostr(i) + '].otcFlag').AsBoolean;
               f_output.f_instruments[i].f_buyAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].buyAvailableFlag').AsBoolean;
               f_output.f_instruments[i].f_sellAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].sellAvailableFlag').AsBoolean;
               if JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement') <> nil then
                  f_output.f_instruments[i].f_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.nano').AsInt64);
               f_output.f_instruments[i].f_apiTradeAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].apiTradeAvailableFlag').AsBoolean;
               f_output.f_instruments[i].f_uid := JSN.FindPath('instruments[' + inttostr(i) + '].uid').AsString;
               f_output.f_instruments[i].f_realExchange := JSN.FindPath('instruments[' + inttostr(i) + '].realExchange').AsString;
               f_output.f_instruments[i].f_positionUid := JSN.FindPath('instruments[' + inttostr(i) + '].positionUid').AsString;
               f_output.f_instruments[i].f_basicAssetPositionUid := JSN.FindPath('instruments[' + inttostr(i) + '].basicAssetPositionUid').AsString;
               f_output.f_instruments[i].f_forIisFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forIisFlag').AsBoolean;
               f_output.f_instruments[i].f_forQualInvestorFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forQualInvestorFlag').AsBoolean;
               f_output.f_instruments[i].f_weekendFlag := JSN.FindPath('instruments[' + inttostr(i) + '].weekendFlag').AsBoolean;
               f_output.f_instruments[i].f_blockedTcaFlag := JSN.FindPath('instruments[' + inttostr(i) + '].blockedTcaFlag').AsBoolean;
               if JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate') <> nil then
                  f_output.f_instruments[i].f_first1minCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate') <> nil then
                  f_output.f_instruments[i].f_first1dayCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate').AsString;
               f_output.f_instruments[i].f_initialMarginOnBuy.moneyval := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].initialMarginOnBuy.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].initialMarginOnBuy.nano').AsInt64);
               f_output.f_instruments[i].f_initialMarginOnBuy.currency := JSN.FindPath('instruments[' + inttostr(i) + '].initialMarginOnBuy.currency').AsString;
               f_output.f_instruments[i].f_initialMarginOnSell.moneyval := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].initialMarginOnSell.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].initialMarginOnSell.nano').AsInt64);
               f_output.f_instruments[i].f_initialMarginOnSell.currency := JSN.FindPath('instruments[' + inttostr(i) + '].initialMarginOnSell.currency').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrementAmount') <> nil then
                  f_output.f_instruments[i].f_minPriceIncrementAmount := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrementAmount.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrementAmount.nano').AsInt64);
               f_output.f_instruments[i].f_brand.f_logoName := JSN.FindPath('instruments[' + inttostr(i) + '].brand.logoName').AsString;
               f_output.f_instruments[i].f_brand.f_logoBaseColor := JSN.FindPath('instruments[' + inttostr(i) + '].brand.logoBaseColor').AsString;
               f_output.f_instruments[i].f_brand.f_textColor := JSN.FindPath('instruments[' + inttostr(i) + '].brand.textColor').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient') <> nil then
                  f_output.f_instruments[i].f_dlongClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient') <> nil then
                  f_output.f_instruments[i].f_dshortClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.nano').AsInt64);

               json_output_array := TJSONArray(JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests'));
               tests_count := json_output_array.Count;
               SetLength(f_output.f_instruments[i].f_requiredTests, tests_count);
               j := 0;

               while j < tests_count do  begin
                  f_output.f_instruments[i].f_requiredTests[j] := JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests[' + inttostr(j) + ']').AsString;
                  inc(j);
               end;

               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetETFs(e_input : e_request; out e_output : e_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, etfs_count, tests_count, i, j : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if e_input.e_instrumentStatus <> '' then json_base.Add('instrumentStatus', e_input.e_instrumentStatus);
      if e_input.e_instrumentExchange <> '' then json_base.Add('instrumentExchange', e_input.e_instrumentExchange);

      endpoint_url := url_tinvest + 'InstrumentsService/Etfs';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + e_input.e_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            e_output.e_error_code := JSN.FindPath('code').AsInt64;
            e_output.e_error_message := JSN.FindPath('message').AsString;
            e_output.e_error_description := JSN.FindPath('description').AsInt64;
         end;

         if e_output.e_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('instruments'));

            etfs_count := json_output_array.Count;
            SetLength(e_output.e_instruments, etfs_count);

            i := 0;

            while i < etfs_count do  begin
               e_output.e_instruments[i].e_figi := JSN.FindPath('instruments[' + inttostr(i) + '].figi').AsString;
               e_output.e_instruments[i].e_ticker := JSN.FindPath('instruments[' + inttostr(i) + '].ticker').AsString;
               e_output.e_instruments[i].e_classCode := JSN.FindPath('instruments[' + inttostr(i) + '].classCode').AsString;
               e_output.e_instruments[i].e_isin := JSN.FindPath('instruments[' + inttostr(i) + '].isin').AsString;
               e_output.e_instruments[i].e_lot := JSN.FindPath('instruments[' + inttostr(i) + '].lot').AsInt64;
               e_output.e_instruments[i].e_currency := JSN.FindPath('instruments[' + inttostr(i) + '].currency').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].klong') <> nil then
                  e_output.e_instruments[i].e_klong := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].klong.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].klong.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].kshort') <> nil then
                  e_output.e_instruments[i].e_kshort := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].kshort.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].kshort.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlong') <> nil then
                  e_output.e_instruments[i].e_dlong := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlong.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlong.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshort') <> nil then
                  e_output.e_instruments[i].e_dshort := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshort.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshort.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin') <> nil then
                  e_output.e_instruments[i].e_dlongMin := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin') <> nil then
                  e_output.e_instruments[i].e_dshortMin := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.nano').AsInt64);
               e_output.e_instruments[i].e_shortEnabledFlag := JSN.FindPath('instruments[' + inttostr(i) + '].shortEnabledFlag').AsBoolean;
               e_output.e_instruments[i].e_name := JSN.FindPath('instruments[' + inttostr(i) + '].name').AsString;
               e_output.e_instruments[i].e_exchange := JSN.FindPath('instruments[' + inttostr(i) + '].exchange').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].fixedCommission') <> nil then
                  e_output.e_instruments[i].e_fixedCommission := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].fixedCommission.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].fixedCommission.nano').AsInt64);
               e_output.e_instruments[i].e_focusType := JSN.FindPath('instruments[' + inttostr(i) + '].focusType').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].releasedDate') <> nil then
                  e_output.e_instruments[i].e_releasedDate := JSN.FindPath('instruments[' + inttostr(i) + '].releasedDate').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].numShares') <> nil then
                  e_output.e_instruments[i].e_numShares := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].numShares.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].numShares.nano').AsInt64);
               e_output.e_instruments[i].e_countryOfRisk := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRisk').AsString;
               e_output.e_instruments[i].e_countryOfRiskName := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRiskName').AsString;
               e_output.e_instruments[i].e_sector := JSN.FindPath('instruments[' + inttostr(i) + '].sector').AsString;
               e_output.e_instruments[i].e_rebalancingFreq := JSN.FindPath('instruments[' + inttostr(i) + '].rebalancingFreq').AsString;
               e_output.e_instruments[i].e_tradingStatus := JSN.FindPath('instruments[' + inttostr(i) + '].tradingStatus').AsString;
               e_output.e_instruments[i].e_otcFlag := JSN.FindPath('instruments[' + inttostr(i) + '].otcFlag').AsBoolean;
               e_output.e_instruments[i].e_buyAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].buyAvailableFlag').AsBoolean;
               e_output.e_instruments[i].e_sellAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].sellAvailableFlag').AsBoolean;
               if JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement') <> nil then
                  e_output.e_instruments[i].e_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.nano').AsInt64);
               e_output.e_instruments[i].e_apiTradeAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].apiTradeAvailableFlag').AsBoolean;
               e_output.e_instruments[i].e_uid := JSN.FindPath('instruments[' + inttostr(i) + '].uid').AsString;
               e_output.e_instruments[i].e_realExchange := JSN.FindPath('instruments[' + inttostr(i) + '].realExchange').AsString;
               e_output.e_instruments[i].e_positionUid := JSN.FindPath('instruments[' + inttostr(i) + '].positionUid').AsString;
               e_output.e_instruments[i].e_assetUid := JSN.FindPath('instruments[' + inttostr(i) + '].assetUid').AsString;
               e_output.e_instruments[i].e_instrumentExchange := JSN.FindPath('instruments[' + inttostr(i) + '].instrumentExchange').AsString;
               e_output.e_instruments[i].e_forIisFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forIisFlag').AsBoolean;
               e_output.e_instruments[i].e_forQualInvestorFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forQualInvestorFlag').AsBoolean;
               e_output.e_instruments[i].e_weekendFlag := JSN.FindPath('instruments[' + inttostr(i) + '].weekendFlag').AsBoolean;
               e_output.e_instruments[i].e_blockedTcaFlag := JSN.FindPath('instruments[' + inttostr(i) + '].blockedTcaFlag').AsBoolean;
               e_output.e_instruments[i].e_liquidityFlag := JSN.FindPath('instruments[' + inttostr(i) + '].liquidityFlag').AsBoolean;
               if JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate') <> nil then
                  e_output.e_instruments[i].e_first1minCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate') <> nil then
                  e_output.e_instruments[i].e_first1dayCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate').AsString;
               e_output.e_instruments[i].e_brand.e_logoName := JSN.FindPath('instruments[' + inttostr(i) + '].brand.logoName').AsString;
               e_output.e_instruments[i].e_brand.e_logoBaseColor := JSN.FindPath('instruments[' + inttostr(i) + '].brand.logoBaseColor').AsString;
               e_output.e_instruments[i].e_brand.e_textColor := JSN.FindPath('instruments[' + inttostr(i) + '].brand.textColor').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient') <> nil then
                  e_output.e_instruments[i].e_dlongClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient') <> nil then
                  e_output.e_instruments[i].e_dshortClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.nano').AsInt64);

               json_output_array := TJSONArray(JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests'));
               tests_count := json_output_array.Count;
               SetLength(e_output.e_instruments[i].e_requiredTests, tests_count);
               j := 0;

               while j < tests_count do  begin
                  e_output.e_instruments[i].e_requiredTests[j] := JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests[' + inttostr(j) + ']').AsString;
                  inc(j);
               end;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure FindInstrument(fi_input : fi_request; out fi_output : fi_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, instruments_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if fi_input.fi_query <> '' then json_base.Add('query', fi_input.fi_query);
      if fi_input.fi_instrumentKind <> '' then json_base.Add('instrumentKind', fi_input.fi_instrumentKind);
      json_base.Add('apiTradeAvailableFlag', fi_input.fi_apiTradeAvailableFlag);

      endpoint_url := url_tinvest + 'InstrumentsService/FindInstrument';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + fi_input.fi_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            fi_output.fi_error_code := JSN.FindPath('code').AsInt64;
            fi_output.fi_error_message := JSN.FindPath('message').AsString;
            fi_output.fi_error_description := JSN.FindPath('description').AsInt64;
         end;

         if fi_output.fi_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('instruments'));

            instruments_count := json_output_array.Count;
            SetLength(fi_output.fi_instruments, instruments_count);

            i := 0;

            while i < instruments_count do  begin
               fi_output.fi_instruments[i].fi_isin := JSN.FindPath('instruments[' + inttostr(i) + '].isin').AsString;
               fi_output.fi_instruments[i].fi_figi := JSN.FindPath('instruments[' + inttostr(i) + '].figi').AsString;
               fi_output.fi_instruments[i].fi_ticker := JSN.FindPath('instruments[' + inttostr(i) + '].ticker').AsString;
               fi_output.fi_instruments[i].fi_classCode := JSN.FindPath('instruments[' + inttostr(i) + '].classCode').AsString;
               fi_output.fi_instruments[i].fi_instrumentType := JSN.FindPath('instruments[' + inttostr(i) + '].instrumentType').AsString;
               fi_output.fi_instruments[i].fi_name := JSN.FindPath('instruments[' + inttostr(i) + '].name').AsString;
               fi_output.fi_instruments[i].fi_uid := JSN.FindPath('instruments[' + inttostr(i) + '].uid').AsString;
               fi_output.fi_instruments[i].fi_positionUid := JSN.FindPath('instruments[' + inttostr(i) + '].positionUid').AsString;
               fi_output.fi_instruments[i].fi_instrumentKind := JSN.FindPath('instruments[' + inttostr(i) + '].instrumentKind').AsString;
               fi_output.fi_instruments[i].fi_apiTradeAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].apiTradeAvailableFlag').AsBoolean;
               fi_output.fi_instruments[i].fi_forIisFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forIisFlag').AsBoolean;
               fi_output.fi_instruments[i].fi_first1minCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate').AsString;
               fi_output.fi_instruments[i].fi_first1dayCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate').AsString;
               fi_output.fi_instruments[i].fi_forQualInvestorFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forQualInvestorFlag').AsBoolean;
               fi_output.fi_instruments[i].fi_weekendFlag := JSN.FindPath('instruments[' + inttostr(i) + '].weekendFlag').AsBoolean;
               fi_output.fi_instruments[i].fi_blockedTcaFlag := JSN.FindPath('instruments[' + inttostr(i) + '].blockedTcaFlag').AsBoolean;
               fi_output.fi_instruments[i].fi_lot := JSN.FindPath('instruments[' + inttostr(i) + '].lot').AsInt64;

               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetBondBy(bb_input : bb_request; out bb_output : bb_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, tests_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if bb_input.bb_idType <> '' then json_base.Add('idType', bb_input.bb_idType);
      if bb_input.bb_classCode <> '' then json_base.Add('classCode', bb_input.bb_classCode);
      if bb_input.bb_id <> '' then json_base.Add('id', bb_input.bb_id);

      endpoint_url := url_tinvest + 'InstrumentsService/BondBy';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + bb_input.bb_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            bb_output.bb_error_code := JSN.FindPath('code').AsInt64;
            bb_output.bb_error_message := JSN.FindPath('message').AsString;
            bb_output.bb_error_description := JSN.FindPath('description').AsInt64;
         end;

         if bb_output.bb_error_description = 0 then begin

            bb_output.bb_instrument.b_figi := JSN.FindPath('instrument.figi').AsString;
            bb_output.bb_instrument.b_ticker := JSN.FindPath('instrument.ticker').AsString;
            bb_output.bb_instrument.b_classCode := JSN.FindPath('instrument.classCode').AsString;
            bb_output.bb_instrument.b_isin := JSN.FindPath('instrument.isin').AsString;
            bb_output.bb_instrument.b_lot := JSN.FindPath('instrument.lot').AsInt64;
            bb_output.bb_instrument.b_currency := JSN.FindPath('instrument.currency').AsString;
            if JSN.FindPath('instrument.klong') <> nil then
               bb_output.bb_instrument.b_klong := UnitsNanoToDouble(JSN.FindPath('instrument.klong.units').AsInt64 , JSN.FindPath('instrument.klong.nano').AsInt64);
            if JSN.FindPath('instrument.kshort') <> nil then
               bb_output.bb_instrument.b_kshort := UnitsNanoToDouble(JSN.FindPath('instrument.kshort.units').AsInt64 , JSN.FindPath('instrument.kshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlong') <> nil then
               bb_output.bb_instrument.b_dlong := UnitsNanoToDouble(JSN.FindPath('instrument.dlong.units').AsInt64 , JSN.FindPath('instrument.dlong.nano').AsInt64);
            if JSN.FindPath('instrument.dshort') <> nil then
               bb_output.bb_instrument.b_dshort := UnitsNanoToDouble(JSN.FindPath('instrument.dshort.units').AsInt64 , JSN.FindPath('instrument.dshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlongMin') <> nil then
               bb_output.bb_instrument.b_dlongMin := UnitsNanoToDouble(JSN.FindPath('instrument.dlongMin.units').AsInt64 , JSN.FindPath('instrument.dlongMin.nano').AsInt64);
            if JSN.FindPath('instrument.dshortMin') <> nil then
               bb_output.bb_instrument.b_dshortMin := UnitsNanoToDouble(JSN.FindPath('instrument.dshortMin.units').AsInt64 , JSN.FindPath('instrument.dshortMin.nano').AsInt64);
            bb_output.bb_instrument.b_shortEnabledFlag := JSN.FindPath('instrument.shortEnabledFlag').AsBoolean;
            bb_output.bb_instrument.b_name := JSN.FindPath('instrument.name').AsString;
            bb_output.bb_instrument.b_exchange := JSN.FindPath('instrument.exchange').AsString;
            bb_output.bb_instrument.b_couponQuantityPerYear := JSN.FindPath('instrument.couponQuantityPerYear').AsInt64;
            if JSN.FindPath('instrument.maturityDate') <> nil then
               bb_output.bb_instrument.b_maturityDate := JSN.FindPath('instrument.maturityDate').AsString;
            bb_output.bb_instrument.b_nominal.moneyval := UnitsNanoToDouble(JSN.FindPath('instrument.nominal.units').AsInt64 , JSN.FindPath('instrument.nominal.nano').AsInt64);
            bb_output.bb_instrument.b_nominal.currency := JSN.FindPath('instrument.nominal.currency').AsString;
            bb_output.bb_instrument.b_initialNominal.moneyval := UnitsNanoToDouble(JSN.FindPath('instrument.initialNominal.units').AsInt64 , JSN.FindPath('instrument.initialNominal.nano').AsInt64);
            bb_output.bb_instrument.b_initialNominal.currency := JSN.FindPath('instrument.initialNominal.currency').AsString;
            if JSN.FindPath('instrument.stateRegDate') <> nil then
               bb_output.bb_instrument.b_stateRegDate := JSN.FindPath('instrument.stateRegDate').AsString;
            if JSN.FindPath('instrument.placementDate') <> nil then
               bb_output.bb_instrument.b_placementDate := JSN.FindPath('instrument.placementDate').AsString;
            bb_output.bb_instrument.b_placementPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('instrument.placementPrice.units').AsInt64 , JSN.FindPath('instrument.placementPrice.nano').AsInt64);
            bb_output.bb_instrument.b_placementPrice.currency := JSN.FindPath('instrument.placementPrice.currency').AsString;
            bb_output.bb_instrument.b_aciValue.moneyval := UnitsNanoToDouble(JSN.FindPath('instrument.aciValue.units').AsInt64 , JSN.FindPath('instrument.aciValue.nano').AsInt64);
            bb_output.bb_instrument.b_aciValue.currency := JSN.FindPath('instrument.aciValue.currency').AsString;
            bb_output.bb_instrument.b_countryOfRisk := JSN.FindPath('instrument.countryOfRisk').AsString;
            bb_output.bb_instrument.b_countryOfRiskName := JSN.FindPath('instrument.countryOfRiskName').AsString;
            bb_output.bb_instrument.b_sector := JSN.FindPath('instrument.sector').AsString;
            bb_output.bb_instrument.b_issueKind := JSN.FindPath('instrument.issueKind').AsString;
            bb_output.bb_instrument.b_issueSize := JSN.FindPath('instrument.issueSize').AsInt64;
            bb_output.bb_instrument.b_issueSizePlan := JSN.FindPath('instrument.issueSizePlan').AsInt64;
            bb_output.bb_instrument.b_tradingStatus := JSN.FindPath('instrument.tradingStatus').AsString;
            bb_output.bb_instrument.b_otcFlag := JSN.FindPath('instrument.otcFlag').AsBoolean;
            bb_output.bb_instrument.b_buyAvailableFlag := JSN.FindPath('instrument.buyAvailableFlag').AsBoolean;
            bb_output.bb_instrument.b_sellAvailableFlag := JSN.FindPath('instrument.sellAvailableFlag').AsBoolean;
            bb_output.bb_instrument.b_floatingCouponFlag := JSN.FindPath('instrument.floatingCouponFlag').AsBoolean;
            bb_output.bb_instrument.b_perpetualFlag := JSN.FindPath('instrument.perpetualFlag').AsBoolean;
            bb_output.bb_instrument.b_amortizationFlag := JSN.FindPath('instrument.amortizationFlag').AsBoolean;
            if JSN.FindPath('instrument.minPriceIncrement') <> nil then
               bb_output.bb_instrument.b_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instrument.minPriceIncrement.units').AsInt64 , JSN.FindPath('instrument.minPriceIncrement.nano').AsInt64);
            bb_output.bb_instrument.b_apiTradeAvailableFlag := JSN.FindPath('instrument.apiTradeAvailableFlag').AsBoolean;
            bb_output.bb_instrument.b_uid := JSN.FindPath('instrument.uid').AsString;
            bb_output.bb_instrument.b_realExchange := JSN.FindPath('instrument.realExchange').AsString;
            bb_output.bb_instrument.b_positionUid := JSN.FindPath('instrument.positionUid').AsString;
            bb_output.bb_instrument.b_assetUid := JSN.FindPath('instrument.assetUid').AsString;
            bb_output.bb_instrument.b_forIisFlag := JSN.FindPath('instrument.forIisFlag').AsBoolean;
            bb_output.bb_instrument.b_forQualInvestorFlag := JSN.FindPath('instrument.forQualInvestorFlag').AsBoolean;
            bb_output.bb_instrument.b_weekendFlag := JSN.FindPath('instrument.weekendFlag').AsBoolean;
            bb_output.bb_instrument.b_blockedTcaFlag := JSN.FindPath('instrument.blockedTcaFlag').AsBoolean;
            bb_output.bb_instrument.b_subordinatedFlag := JSN.FindPath('instrument.subordinatedFlag').AsBoolean;
            bb_output.bb_instrument.b_liquidityFlag := JSN.FindPath('instrument.liquidityFlag').AsBoolean;
            if JSN.FindPath('instrument.first1minCandleDate') <> nil then
               bb_output.bb_instrument.b_first1minCandleDate := JSN.FindPath('instrument.first1minCandleDate').AsString;
            if JSN.FindPath('instrument.first1dayCandleDate') <> nil then
               bb_output.bb_instrument.b_first1dayCandleDate := JSN.FindPath('instrument.first1dayCandleDate').AsString;
            bb_output.bb_instrument.b_riskLevel := JSN.FindPath('instrument.riskLevel').AsString;
            bb_output.bb_instrument.b_brand.b_logoName := JSN.FindPath('instrument.brand.logoName').AsString;
            bb_output.bb_instrument.b_brand.b_logoBaseColor := JSN.FindPath('instrument.brand.logoBaseColor').AsString;
            bb_output.bb_instrument.b_brand.b_textColor := JSN.FindPath('instrument.brand.textColor').AsString;
            bb_output.bb_instrument.b_bondType := JSN.FindPath('instrument.bondType').AsString;
            if JSN.FindPath('instrument.callDate') <> nil then
               bb_output.bb_instrument.b_callDate := JSN.FindPath('instrument.callDate').AsString;
            if JSN.FindPath('instrument.dlongClient') <> nil then
               bb_output.bb_instrument.b_dlongClient := UnitsNanoToDouble(JSN.FindPath('instrument.dlongClient.units').AsInt64 , JSN.FindPath('instrument.dlongClient.nano').AsInt64);
            if JSN.FindPath('instrument.dshortClient') <> nil then
               bb_output.bb_instrument.b_dshortClient := UnitsNanoToDouble(JSN.FindPath('instrument.dshortClient.units').AsInt64 , JSN.FindPath('instrument.dshortClient.nano').AsInt64);

            json_output_array := TJSONArray(JSN.FindPath('instrument.requiredTests'));
            tests_count := json_output_array.Count;
            SetLength(bb_output.bb_instrument.b_requiredTests, tests_count);
            i := 0;

            while i < tests_count do  begin
               bb_output.bb_instrument.b_requiredTests[i] := JSN.FindPath('instrument.requiredTests[' + inttostr(i) + ']').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetETFBy(eb_input : eb_request; out eb_output : eb_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, tests_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if eb_input.eb_idType <> '' then json_base.Add('idType', eb_input.eb_idType);
      if eb_input.eb_classCode <> '' then json_base.Add('classCode', eb_input.eb_classCode);
      if eb_input.eb_id <> '' then json_base.Add('id', eb_input.eb_id);

      endpoint_url := url_tinvest + 'InstrumentsService/EtfBy';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + eb_input.eb_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            eb_output.eb_error_code := JSN.FindPath('code').AsInt64;
            eb_output.eb_error_message := JSN.FindPath('message').AsString;
            eb_output.eb_error_description := JSN.FindPath('description').AsInt64;
         end;

         if eb_output.eb_error_description = 0 then begin

            eb_output.eb_instrument.e_figi := JSN.FindPath('instrument.figi').AsString;
            eb_output.eb_instrument.e_ticker := JSN.FindPath('instrument.ticker').AsString;
            eb_output.eb_instrument.e_classCode := JSN.FindPath('instrument.classCode').AsString;
            eb_output.eb_instrument.e_isin := JSN.FindPath('instrument.isin').AsString;
            eb_output.eb_instrument.e_lot := JSN.FindPath('instrument.lot').AsInt64;
            eb_output.eb_instrument.e_currency := JSN.FindPath('instrument.currency').AsString;
            if JSN.FindPath('instrument.klong') <> nil then
               eb_output.eb_instrument.e_klong := UnitsNanoToDouble(JSN.FindPath('instrument.klong.units').AsInt64 , JSN.FindPath('instrument.klong.nano').AsInt64);
            if JSN.FindPath('instrument.kshort') <> nil then
               eb_output.eb_instrument.e_kshort := UnitsNanoToDouble(JSN.FindPath('instrument.kshort.units').AsInt64 , JSN.FindPath('instrument.kshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlong') <> nil then
               eb_output.eb_instrument.e_dlong := UnitsNanoToDouble(JSN.FindPath('instrument.dlong.units').AsInt64 , JSN.FindPath('instrument.dlong.nano').AsInt64);
            if JSN.FindPath('instrument.dshort') <> nil then
               eb_output.eb_instrument.e_dshort := UnitsNanoToDouble(JSN.FindPath('instrument.dshort.units').AsInt64 , JSN.FindPath('instrument.dshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlongMin') <> nil then
               eb_output.eb_instrument.e_dlongMin := UnitsNanoToDouble(JSN.FindPath('instrument.dlongMin.units').AsInt64 , JSN.FindPath('instrument.dlongMin.nano').AsInt64);
            if JSN.FindPath('instrument.dshortMin') <> nil then
               eb_output.eb_instrument.e_dshortMin := UnitsNanoToDouble(JSN.FindPath('instrument.dshortMin.units').AsInt64 , JSN.FindPath('instrument.dshortMin.nano').AsInt64);
            eb_output.eb_instrument.e_shortEnabledFlag := JSN.FindPath('instrument.shortEnabledFlag').AsBoolean;
            eb_output.eb_instrument.e_name := JSN.FindPath('instrument.name').AsString;
            eb_output.eb_instrument.e_exchange := JSN.FindPath('instrument.exchange').AsString;
            if JSN.FindPath('instrument.fixedCommission') <> nil then
               eb_output.eb_instrument.e_fixedCommission := UnitsNanoToDouble(JSN.FindPath('instrument.fixedCommission.units').AsInt64 , JSN.FindPath('instrument.fixedCommission.nano').AsInt64);
            eb_output.eb_instrument.e_focusType := JSN.FindPath('instrument.focusType').AsString;
            if JSN.FindPath('instrument.releasedDate') <> nil then
               eb_output.eb_instrument.e_releasedDate := JSN.FindPath('instrument.releasedDate').AsString;
            if JSN.FindPath('instrument.numShares') <> nil then
               eb_output.eb_instrument.e_numShares := UnitsNanoToDouble(JSN.FindPath('instrument.numShares.units').AsInt64 , JSN.FindPath('instrument.numShares.nano').AsInt64);
            eb_output.eb_instrument.e_countryOfRisk := JSN.FindPath('instrument.countryOfRisk').AsString;
            eb_output.eb_instrument.e_countryOfRiskName := JSN.FindPath('instrument.countryOfRiskName').AsString;
            eb_output.eb_instrument.e_sector := JSN.FindPath('instrument.sector').AsString;
            eb_output.eb_instrument.e_rebalancingFreq := JSN.FindPath('instrument.rebalancingFreq').AsString;
            eb_output.eb_instrument.e_tradingStatus := JSN.FindPath('instrument.tradingStatus').AsString;
            eb_output.eb_instrument.e_otcFlag := JSN.FindPath('instrument.otcFlag').AsBoolean;
            eb_output.eb_instrument.e_buyAvailableFlag := JSN.FindPath('instrument.buyAvailableFlag').AsBoolean;
            eb_output.eb_instrument.e_sellAvailableFlag := JSN.FindPath('instrument.sellAvailableFlag').AsBoolean;
            if JSN.FindPath('instrument.minPriceIncrement') <> nil then
               eb_output.eb_instrument.e_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instrument.minPriceIncrement.units').AsInt64 , JSN.FindPath('instrument.minPriceIncrement.nano').AsInt64);
            eb_output.eb_instrument.e_apiTradeAvailableFlag := JSN.FindPath('instrument.apiTradeAvailableFlag').AsBoolean;
            eb_output.eb_instrument.e_uid := JSN.FindPath('instrument.uid').AsString;
            eb_output.eb_instrument.e_realExchange := JSN.FindPath('instrument.realExchange').AsString;
            eb_output.eb_instrument.e_positionUid := JSN.FindPath('instrument.positionUid').AsString;
            eb_output.eb_instrument.e_assetUid := JSN.FindPath('instrument.assetUid').AsString;
            eb_output.eb_instrument.e_instrumentExchange := JSN.FindPath('instrument.instrumentExchange').AsString;
            eb_output.eb_instrument.e_forIisFlag := JSN.FindPath('instrument.forIisFlag').AsBoolean;
            eb_output.eb_instrument.e_forQualInvestorFlag := JSN.FindPath('instrument.forQualInvestorFlag').AsBoolean;
            eb_output.eb_instrument.e_weekendFlag := JSN.FindPath('instrument.weekendFlag').AsBoolean;
            eb_output.eb_instrument.e_blockedTcaFlag := JSN.FindPath('instrument.blockedTcaFlag').AsBoolean;
            eb_output.eb_instrument.e_liquidityFlag := JSN.FindPath('instrument.liquidityFlag').AsBoolean;
            if JSN.FindPath('instrument.first1minCandleDate') <> nil then
               eb_output.eb_instrument.e_first1minCandleDate := JSN.FindPath('instrument.first1minCandleDate').AsString;
            if JSN.FindPath('instrument.first1dayCandleDate') <> nil then
               eb_output.eb_instrument.e_first1dayCandleDate := JSN.FindPath('instrument.first1dayCandleDate').AsString;
            eb_output.eb_instrument.e_brand.e_logoName := JSN.FindPath('instrument.brand.logoName').AsString;
            eb_output.eb_instrument.e_brand.e_logoBaseColor := JSN.FindPath('instrument.brand.logoBaseColor').AsString;
            eb_output.eb_instrument.e_brand.e_textColor := JSN.FindPath('instrument.brand.textColor').AsString;
            if JSN.FindPath('instrument.dlongClient') <> nil then
               eb_output.eb_instrument.e_dlongClient := UnitsNanoToDouble(JSN.FindPath('instrument.dlongClient.units').AsInt64 , JSN.FindPath('instrument.dlongClient.nano').AsInt64);
            if JSN.FindPath('instrument.dshortClient') <> nil then
               eb_output.eb_instrument.e_dshortClient := UnitsNanoToDouble(JSN.FindPath('instrument.dshortClient.units').AsInt64 , JSN.FindPath('instrument.dshortClient.nano').AsInt64);

            json_output_array := TJSONArray(JSN.FindPath('instrument.requiredTests'));
            tests_count := json_output_array.Count;
            SetLength(eb_output.eb_instrument.e_requiredTests, tests_count);
            i := 0;

            while i < tests_count do  begin
               eb_output.eb_instrument.e_requiredTests[i] := JSN.FindPath('instrument.requiredTests[' + inttostr(i) + ']').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetFutureBy(fb_input : fb_request; out fb_output : fb_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, tests_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if fb_input.fb_idType <> '' then json_base.Add('idType', fb_input.fb_idType);
      if fb_input.fb_classCode <> '' then json_base.Add('classCode', fb_input.fb_classCode);
      if fb_input.fb_id <> '' then json_base.Add('id', fb_input.fb_id);

      endpoint_url := url_tinvest + 'InstrumentsService/FutureBy';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + fb_input.fb_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            fb_output.fb_error_code := JSN.FindPath('code').AsInt64;
            fb_output.fb_error_message := JSN.FindPath('message').AsString;
            fb_output.fb_error_description := JSN.FindPath('description').AsInt64;
         end;

         if fb_output.fb_error_description = 0 then begin

            fb_output.fb_instrument.f_figi := JSN.FindPath('instrument.figi').AsString;
            fb_output.fb_instrument.f_ticker := JSN.FindPath('instrument.ticker').AsString;
            fb_output.fb_instrument.f_classCode := JSN.FindPath('instrument.classCode').AsString;
            fb_output.fb_instrument.f_lot := JSN.FindPath('instrument.lot').AsInt64;
            fb_output.fb_instrument.f_currency := JSN.FindPath('instrument.currency').AsString;
            if JSN.FindPath('instrument.klong') <> nil then
               fb_output.fb_instrument.f_klong := UnitsNanoToDouble(JSN.FindPath('instrument.klong.units').AsInt64 , JSN.FindPath('instrument.klong.nano').AsInt64);
            if JSN.FindPath('instrument.kshort') <> nil then
               fb_output.fb_instrument.f_kshort := UnitsNanoToDouble(JSN.FindPath('instrument.kshort.units').AsInt64 , JSN.FindPath('instrument.kshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlong') <> nil then
               fb_output.fb_instrument.f_dlong := UnitsNanoToDouble(JSN.FindPath('instrument.dlong.units').AsInt64 , JSN.FindPath('instrument.dlong.nano').AsInt64);
            if JSN.FindPath('instrument.dshort') <> nil then
               fb_output.fb_instrument.f_dshort := UnitsNanoToDouble(JSN.FindPath('instrument.dshort.units').AsInt64 , JSN.FindPath('instrument.dshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlongMin') <> nil then
               fb_output.fb_instrument.f_dlongMin := UnitsNanoToDouble(JSN.FindPath('instrument.dlongMin.units').AsInt64 , JSN.FindPath('instrument.dlongMin.nano').AsInt64);
            if JSN.FindPath('instrument.dshortMin') <> nil then
               fb_output.fb_instrument.f_dshortMin := UnitsNanoToDouble(JSN.FindPath('instrument.dshortMin.units').AsInt64 , JSN.FindPath('instrument.dshortMin.nano').AsInt64);
            fb_output.fb_instrument.f_shortEnabledFlag := JSN.FindPath('instrument.shortEnabledFlag').AsBoolean;
            fb_output.fb_instrument.f_name := JSN.FindPath('instrument.name').AsString;
            fb_output.fb_instrument.f_exchange := JSN.FindPath('instrument.exchange').AsString;
            if JSN.FindPath('instrument.firstTradeDate') <> nil then
               fb_output.fb_instrument.f_firstTradeDate := JSN.FindPath('instrument.firstTradeDate').AsString;
            if JSN.FindPath('instrument.lastTradeDate') <> nil then
               fb_output.fb_instrument.f_lastTradeDate := JSN.FindPath('instrument.lastTradeDate').AsString;
            if JSN.FindPath('instrument.futuresType') <> nil then
               fb_output.fb_instrument.f_futuresType := JSN.FindPath('instrument.futuresType').AsString;
            fb_output.fb_instrument.f_assetType := JSN.FindPath('instrument.assetType').AsString;
            fb_output.fb_instrument.f_basicAsset := JSN.FindPath('instrument.basicAsset').AsString;
            fb_output.fb_instrument.f_basicAssetSize := UnitsNanoToDouble(JSN.FindPath('instrument.basicAssetSize.units').AsInt64 , JSN.FindPath('instrument.basicAssetSize.nano').AsInt64);
            fb_output.fb_instrument.f_countryOfRisk := JSN.FindPath('instrument.countryOfRisk').AsString;
            fb_output.fb_instrument.f_countryOfRiskName := JSN.FindPath('instrument.countryOfRiskName').AsString;
            fb_output.fb_instrument.f_sector := JSN.FindPath('instrument.sector').AsString;
            fb_output.fb_instrument.f_expirationDate := JSN.FindPath('instrument.expirationDate').AsString;
            fb_output.fb_instrument.f_tradingStatus := JSN.FindPath('instrument.tradingStatus').AsString;
            fb_output.fb_instrument.f_otcFlag := JSN.FindPath('instrument.otcFlag').AsBoolean;
            fb_output.fb_instrument.f_buyAvailableFlag := JSN.FindPath('instrument.buyAvailableFlag').AsBoolean;
            fb_output.fb_instrument.f_sellAvailableFlag := JSN.FindPath('instrument.sellAvailableFlag').AsBoolean;
            if JSN.FindPath('instrument.minPriceIncrement') <> nil then
               fb_output.fb_instrument.f_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instrument.minPriceIncrement.units').AsInt64 , JSN.FindPath('instrument.minPriceIncrement.nano').AsInt64);
            fb_output.fb_instrument.f_apiTradeAvailableFlag := JSN.FindPath('instrument.apiTradeAvailableFlag').AsBoolean;
            fb_output.fb_instrument.f_uid := JSN.FindPath('instrument.uid').AsString;
            fb_output.fb_instrument.f_realExchange := JSN.FindPath('instrument.realExchange').AsString;
            fb_output.fb_instrument.f_positionUid := JSN.FindPath('instrument.positionUid').AsString;
            fb_output.fb_instrument.f_basicAssetPositionUid := JSN.FindPath('instrument.basicAssetPositionUid').AsString;
            fb_output.fb_instrument.f_forIisFlag := JSN.FindPath('instrument.forIisFlag').AsBoolean;
            fb_output.fb_instrument.f_forQualInvestorFlag := JSN.FindPath('instrument.forQualInvestorFlag').AsBoolean;
            fb_output.fb_instrument.f_weekendFlag := JSN.FindPath('instrument.weekendFlag').AsBoolean;
            fb_output.fb_instrument.f_blockedTcaFlag := JSN.FindPath('instrument.blockedTcaFlag').AsBoolean;
            if JSN.FindPath('instrument.first1minCandleDate') <> nil then
               fb_output.fb_instrument.f_first1minCandleDate := JSN.FindPath('instrument.first1minCandleDate').AsString;
            if JSN.FindPath('instrument.first1dayCandleDate') <> nil then
               fb_output.fb_instrument.f_first1dayCandleDate := JSN.FindPath('instrument.first1dayCandleDate').AsString;
            fb_output.fb_instrument.f_initialMarginOnBuy.moneyval := UnitsNanoToDouble(JSN.FindPath('instrument.initialMarginOnBuy.units').AsInt64 , JSN.FindPath('instrument.initialMarginOnBuy.nano').AsInt64);
            fb_output.fb_instrument.f_initialMarginOnBuy.currency := JSN.FindPath('instrument.initialMarginOnBuy.currency').AsString;
            fb_output.fb_instrument.f_initialMarginOnSell.moneyval := UnitsNanoToDouble(JSN.FindPath('instrument.initialMarginOnSell.units').AsInt64 , JSN.FindPath('instrument.initialMarginOnSell.nano').AsInt64);
            fb_output.fb_instrument.f_initialMarginOnSell.currency := JSN.FindPath('instrument.initialMarginOnSell.currency').AsString;
            if JSN.FindPath('instrument.minPriceIncrementAmount') <> nil then
               fb_output.fb_instrument.f_minPriceIncrementAmount := UnitsNanoToDouble(JSN.FindPath('instrument.minPriceIncrementAmount.units').AsInt64 , JSN.FindPath('instrument.minPriceIncrementAmount.nano').AsInt64);
            fb_output.fb_instrument.f_brand.f_logoName := JSN.FindPath('instrument.brand.logoName').AsString;
            fb_output.fb_instrument.f_brand.f_logoBaseColor := JSN.FindPath('instrument.brand.logoBaseColor').AsString;
            fb_output.fb_instrument.f_brand.f_textColor := JSN.FindPath('instrument.brand.textColor').AsString;
            if JSN.FindPath('instrument.dlongClient') <> nil then
               fb_output.fb_instrument.f_dlongClient := UnitsNanoToDouble(JSN.FindPath('instrument.dlongClient.units').AsInt64 , JSN.FindPath('instrument.dlongClient.nano').AsInt64);
            if JSN.FindPath('instrument.dshortClient') <> nil then
               fb_output.fb_instrument.f_dshortClient := UnitsNanoToDouble(JSN.FindPath('instrument.dshortClient.units').AsInt64 , JSN.FindPath('instrument.dshortClient.nano').AsInt64);

            json_output_array := TJSONArray(JSN.FindPath('instrument.requiredTests'));
            tests_count := json_output_array.Count;
            SetLength(fb_output.fb_instrument.f_requiredTests, tests_count);
            i := 0;

            while i < tests_count do  begin
               fb_output.fb_instrument.f_requiredTests[i] := JSN.FindPath('instrument.requiredTests[' + inttostr(i) + ']').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetShareBy(sb_input : sb_request; out sb_output : sb_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, tests_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if sb_input.sb_idType <> '' then json_base.Add('idType', sb_input.sb_idType);
      if sb_input.sb_classCode <> '' then json_base.Add('classCode', sb_input.sb_classCode);
      if sb_input.sb_id <> '' then json_base.Add('id', sb_input.sb_id);

      endpoint_url := url_tinvest + 'InstrumentsService/ShareBy';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + sb_input.sb_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            sb_output.sb_error_code := JSN.FindPath('code').AsInt64;
            sb_output.sb_error_message := JSN.FindPath('message').AsString;
            sb_output.sb_error_description := JSN.FindPath('description').AsInt64;
         end;

         if sb_output.sb_error_description = 0 then begin

            sb_output.sb_instrument.s_figi := JSN.FindPath('instrument.figi').AsString;
            sb_output.sb_instrument.s_ticker := JSN.FindPath('instrument.ticker').AsString;
            sb_output.sb_instrument.s_classCode := JSN.FindPath('instrument.classCode').AsString;
            sb_output.sb_instrument.s_isin := JSN.FindPath('instrument.isin').AsString;
            sb_output.sb_instrument.s_lot := JSN.FindPath('instrument.lot').AsInt64;
            sb_output.sb_instrument.s_currency := JSN.FindPath('instrument.currency').AsString;
            if JSN.FindPath('instrument.klong') <> nil then
               sb_output.sb_instrument.s_klong := UnitsNanoToDouble(JSN.FindPath('instrument.klong.units').AsInt64 , JSN.FindPath('instrument.klong.nano').AsInt64);
            if JSN.FindPath('instrument.kshort') <> nil then
               sb_output.sb_instrument.s_kshort := UnitsNanoToDouble(JSN.FindPath('instrument.kshort.units').AsInt64 , JSN.FindPath('instrument.kshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlong') <> nil then
               sb_output.sb_instrument.s_dlong := UnitsNanoToDouble(JSN.FindPath('instrument.dlong.units').AsInt64 , JSN.FindPath('instrument.dlong.nano').AsInt64);
            if JSN.FindPath('instrument.dshort') <> nil then
               sb_output.sb_instrument.s_dshort := UnitsNanoToDouble(JSN.FindPath('instrument.dshort.units').AsInt64 , JSN.FindPath('instrument.dshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlongMin') <> nil then
               sb_output.sb_instrument.s_dlongMin := UnitsNanoToDouble(JSN.FindPath('instrument.dlongMin.units').AsInt64 , JSN.FindPath('instrument.dlongMin.nano').AsInt64);
            if JSN.FindPath('instrument.dshortMin') <> nil then
               sb_output.sb_instrument.s_dshortMin := UnitsNanoToDouble(JSN.FindPath('instrument.dshortMin.units').AsInt64 , JSN.FindPath('instrument.dshortMin.nano').AsInt64);
            if JSN.FindPath('instrument.shortEnabledFlag') <> nil then
               sb_output.sb_instrument.s_shortEnabledFlag := JSN.FindPath('instrument.shortEnabledFlag').AsBoolean;
            sb_output.sb_instrument.s_name := JSN.FindPath('instrument.name').AsString;
            sb_output.sb_instrument.s_exchange := JSN.FindPath('instrument.exchange').AsString;
            if JSN.FindPath('instrument.ipoDate') <> nil then
               sb_output.sb_instrument.s_ipoDate := JSN.FindPath('instrument.ipoDate').AsString;
            sb_output.sb_instrument.s_issueSize := JSN.FindPath('instrument.issueSize').AsInt64;
            sb_output.sb_instrument.s_countryOfRisk := JSN.FindPath('instrument.countryOfRisk').AsString;
            sb_output.sb_instrument.s_countryOfRiskName := JSN.FindPath('instrument.countryOfRiskName').AsString;
            sb_output.sb_instrument.s_sector := JSN.FindPath('instrument.sector').AsString;
            sb_output.sb_instrument.s_issueSizePlan := JSN.FindPath('instrument.issueSizePlan').AsInt64;
            sb_output.sb_instrument.s_nominal.moneyval := UnitsNanoToDouble(JSN.FindPath('instrument.nominal.units').AsInt64 , JSN.FindPath('instrument.nominal.nano').AsInt64);
            sb_output.sb_instrument.s_nominal.currency := JSN.FindPath('instrument.nominal.currency').AsString;
            sb_output.sb_instrument.s_tradingStatus := JSN.FindPath('instrument.tradingStatus').AsString;
            sb_output.sb_instrument.s_otcFlag := JSN.FindPath('instrument.otcFlag').AsBoolean;
            sb_output.sb_instrument.s_buyAvailableFlag := JSN.FindPath('instrument.buyAvailableFlag').AsBoolean;
            sb_output.sb_instrument.s_sellAvailableFlag := JSN.FindPath('instrument.sellAvailableFlag').AsBoolean;
            sb_output.sb_instrument.s_divYieldFlag := JSN.FindPath('instrument.divYieldFlag').AsBoolean;
            sb_output.sb_instrument.s_shareType := JSN.FindPath('instrument.shareType').AsString;
            if JSN.FindPath('instrument.minPriceIncrement') <> nil then
               sb_output.sb_instrument.s_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instrument.minPriceIncrement.units').AsInt64 , JSN.FindPath('instrument.minPriceIncrement.nano').AsInt64);
            sb_output.sb_instrument.s_apiTradeAvailableFlag := JSN.FindPath('instrument.apiTradeAvailableFlag').AsBoolean;
            sb_output.sb_instrument.s_uid := JSN.FindPath('instrument.uid').AsString;
            sb_output.sb_instrument.s_realExchange := JSN.FindPath('instrument.realExchange').AsString;
            sb_output.sb_instrument.s_positionUid := JSN.FindPath('instrument.positionUid').AsString;
            sb_output.sb_instrument.s_assetUid := JSN.FindPath('instrument.assetUid').AsString;
            sb_output.sb_instrument.s_instrumentExchange := JSN.FindPath('instrument.instrumentExchange').AsString;
            sb_output.sb_instrument.s_forIisFlag := JSN.FindPath('instrument.forIisFlag').AsBoolean;
            sb_output.sb_instrument.s_forQualInvestorFlag := JSN.FindPath('instrument.forQualInvestorFlag').AsBoolean;
            sb_output.sb_instrument.s_weekendFlag := JSN.FindPath('instrument.weekendFlag').AsBoolean;
            sb_output.sb_instrument.s_blockedTcaFlag := JSN.FindPath('instrument.blockedTcaFlag').AsBoolean;
            sb_output.sb_instrument.s_liquidityFlag := JSN.FindPath('instrument.liquidityFlag').AsBoolean;
            if JSN.FindPath('instrument.first1minCandleDate') <> nil then
               sb_output.sb_instrument.s_first1minCandleDate := JSN.FindPath('instrument.first1minCandleDate').AsString;
            if JSN.FindPath('instrument.first1dayCandleDate') <> nil then
               sb_output.sb_instrument.s_first1dayCandleDate := JSN.FindPath('instrument.first1dayCandleDate').AsString;
            sb_output.sb_instrument.s_brand.s_logoName := JSN.FindPath('instrument.brand.logoName').AsString;
            sb_output.sb_instrument.s_brand.s_logoBaseColor := JSN.FindPath('instrument.brand.logoBaseColor').AsString;
            sb_output.sb_instrument.s_brand.s_textColor := JSN.FindPath('instrument.brand.textColor').AsString;
            if JSN.FindPath('instrument.dlongClient') <> nil then
               sb_output.sb_instrument.s_dlongClient := UnitsNanoToDouble(JSN.FindPath('instrument.dlongClient.units').AsInt64 , JSN.FindPath('instrument.dlongClient.nano').AsInt64);
            if JSN.FindPath('instrument.dshortClient') <> nil then
               sb_output.sb_instrument.s_dshortClient := UnitsNanoToDouble(JSN.FindPath('instrument.dshortClient.units').AsInt64 , JSN.FindPath('instrument.dshortClient.nano').AsInt64);

            json_output_array := TJSONArray(JSN.FindPath('instrument.requiredTests'));
            tests_count := json_output_array.Count;
            SetLength(sb_output.sb_instrument.s_requiredTests, tests_count);
            i := 0;

            while i < tests_count do  begin
               sb_output.sb_instrument.s_requiredTests[i] := JSN.FindPath('instrument.requiredTests[' + inttostr(i) + ']').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetInstrumentBy(gib_input : gib_request; out gib_output : gib_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, tests_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if gib_input.gib_idType <> '' then json_base.Add('idType', gib_input.gib_idType);
      if gib_input.gib_classCode <> '' then json_base.Add('classCode', gib_input.gib_classCode);
      if gib_input.gib_id <> '' then json_base.Add('id', gib_input.gib_id);

      endpoint_url := url_tinvest + 'InstrumentsService/GetInstrumentBy';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gib_input.gib_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gib_output.gib_error_code := JSN.FindPath('code').AsInt64;
            gib_output.gib_error_message := JSN.FindPath('message').AsString;
            gib_output.gib_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gib_output.gib_error_description = 0 then begin

            gib_output.gib_instrument.gib_figi := JSN.FindPath('instrument.figi').AsString;
            gib_output.gib_instrument.gib_ticker := JSN.FindPath('instrument.ticker').AsString;
            gib_output.gib_instrument.gib_classCode := JSN.FindPath('instrument.classCode').AsString;
            gib_output.gib_instrument.gib_isin := JSN.FindPath('instrument.isin').AsString;
            gib_output.gib_instrument.gib_lot := JSN.FindPath('instrument.lot').AsInt64;
            gib_output.gib_instrument.gib_currency := JSN.FindPath('instrument.currency').AsString;
            if JSN.FindPath('instrument.klong') <> nil then
               gib_output.gib_instrument.gib_klong := UnitsNanoToDouble(JSN.FindPath('instrument.klong.units').AsInt64 , JSN.FindPath('instrument.klong.nano').AsInt64);
            if JSN.FindPath('instrument.kshort') <> nil then
               gib_output.gib_instrument.gib_kshort := UnitsNanoToDouble(JSN.FindPath('instrument.kshort.units').AsInt64 , JSN.FindPath('instrument.kshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlong') <> nil then
               gib_output.gib_instrument.gib_dlong := UnitsNanoToDouble(JSN.FindPath('instrument.dlong.units').AsInt64 , JSN.FindPath('instrument.dlong.nano').AsInt64);
            if JSN.FindPath('instrument.dshort') <> nil then
               gib_output.gib_instrument.gib_dshort := UnitsNanoToDouble(JSN.FindPath('instrument.dshort.units').AsInt64 , JSN.FindPath('instrument.dshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlongMin') <> nil then
               gib_output.gib_instrument.gib_dlongMin := UnitsNanoToDouble(JSN.FindPath('instrument.dlongMin.units').AsInt64 , JSN.FindPath('instrument.dlongMin.nano').AsInt64);
            if JSN.FindPath('instrument.dshortMin') <> nil then
               gib_output.gib_instrument.gib_dshortMin := UnitsNanoToDouble(JSN.FindPath('instrument.dshortMin.units').AsInt64 , JSN.FindPath('instrument.dshortMin.nano').AsInt64);
            if JSN.FindPath('instrument.shortEnabledFlag') <> nil then
               gib_output.gib_instrument.gib_shortEnabledFlag := JSN.FindPath('instrument.shortEnabledFlag').AsBoolean;
            gib_output.gib_instrument.gib_name := JSN.FindPath('instrument.name').AsString;
            gib_output.gib_instrument.gib_exchange := JSN.FindPath('instrument.exchange').AsString;
            gib_output.gib_instrument.gib_countryOfRisk := JSN.FindPath('instrument.countryOfRisk').AsString;
            gib_output.gib_instrument.gib_countryOfRiskName := JSN.FindPath('instrument.countryOfRiskName').AsString;
            gib_output.gib_instrument.gib_tradingStatus := JSN.FindPath('instrument.tradingStatus').AsString;
            gib_output.gib_instrument.gib_otcFlag := JSN.FindPath('instrument.otcFlag').AsBoolean;
            gib_output.gib_instrument.gib_buyAvailableFlag := JSN.FindPath('instrument.buyAvailableFlag').AsBoolean;
            gib_output.gib_instrument.gib_sellAvailableFlag := JSN.FindPath('instrument.sellAvailableFlag').AsBoolean;
            if JSN.FindPath('instrument.minPriceIncrement') <> nil then
               gib_output.gib_instrument.gib_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instrument.minPriceIncrement.units').AsInt64 , JSN.FindPath('instrument.minPriceIncrement.nano').AsInt64);
            gib_output.gib_instrument.gib_apiTradeAvailableFlag := JSN.FindPath('instrument.apiTradeAvailableFlag').AsBoolean;
            gib_output.gib_instrument.gib_uid := JSN.FindPath('instrument.uid').AsString;
            gib_output.gib_instrument.gib_realExchange := JSN.FindPath('instrument.realExchange').AsString;
            gib_output.gib_instrument.gib_positionUid := JSN.FindPath('instrument.positionUid').AsString;
            gib_output.gib_instrument.gib_assetUid := JSN.FindPath('instrument.assetUid').AsString;
            gib_output.gib_instrument.gib_forIisFlag := JSN.FindPath('instrument.forIisFlag').AsBoolean;
            gib_output.gib_instrument.gib_forQualInvestorFlag := JSN.FindPath('instrument.forQualInvestorFlag').AsBoolean;
            gib_output.gib_instrument.gib_weekendFlag := JSN.FindPath('instrument.weekendFlag').AsBoolean;
            gib_output.gib_instrument.gib_blockedTcaFlag := JSN.FindPath('instrument.blockedTcaFlag').AsBoolean;
            if JSN.FindPath('instrument.first1minCandleDate') <> nil then
               gib_output.gib_instrument.gib_first1minCandleDate := JSN.FindPath('instrument.first1minCandleDate').AsString;
            if JSN.FindPath('instrument.first1dayCandleDate') <> nil then
               gib_output.gib_instrument.gib_first1dayCandleDate := JSN.FindPath('instrument.first1dayCandleDate').AsString;
            gib_output.gib_instrument.gib_brand.gib_logoName := JSN.FindPath('instrument.brand.logoName').AsString;
            gib_output.gib_instrument.gib_brand.gib_logoBaseColor := JSN.FindPath('instrument.brand.logoBaseColor').AsString;
            gib_output.gib_instrument.gib_brand.gib_textColor := JSN.FindPath('instrument.brand.textColor').AsString;
            if JSN.FindPath('instrument.dlongClient') <> nil then
               gib_output.gib_instrument.gib_dlongClient := UnitsNanoToDouble(JSN.FindPath('instrument.dlongClient.units').AsInt64 , JSN.FindPath('instrument.dlongClient.nano').AsInt64);
            if JSN.FindPath('instrument.dshortClient') <> nil then
               gib_output.gib_instrument.gib_dshortClient := UnitsNanoToDouble(JSN.FindPath('instrument.dshortClient.units').AsInt64 , JSN.FindPath('instrument.dshortClient.nano').AsInt64);

            json_output_array := TJSONArray(JSN.FindPath('instrument.requiredTests'));
            tests_count := json_output_array.Count;
            SetLength(gib_output.gib_instrument.gib_requiredTests, tests_count);
            i := 0;

            while i < tests_count do  begin
               gib_output.gib_instrument.gib_requiredTests[i] := JSN.FindPath('instrument.requiredTests[' + inttostr(i) + ']').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
  end;
end;

procedure GetCandles(gc_input : gc_request; out gc_output : gc_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, candles_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.MarketDataService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.MarketDataService_limit.h_ratelimit_reset * 1000);
        requests_limit.MarketDataService_limit.h_ratelimit_remaining := requests_limit.MarketDataService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if gc_input.gc_from <> '' then json_base.Add('from', gc_input.gc_from);
      if gc_input.gc_to <> '' then json_base.Add('to', gc_input.gc_to);
      if gc_input.gc_interval <> '' then json_base.Add('interval', gc_input.gc_interval);
      if gc_input.gc_instrumentId <> '' then json_base.Add('instrumentId', gc_input.gc_instrumentId);
      if gc_input.gc_candleSourceType <> '' then json_base.Add('candleSourceType', gc_input.gc_candleSourceType);
      if gc_input.gc_limit >0 then json_base.Add('limit', gc_input.gc_limit);

      endpoint_url := url_tinvest + 'MarketDataService/GetCandles';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gc_input.gc_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.MarketDataService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gc_output.gc_error_code := JSN.FindPath('code').AsInt64;
            gc_output.gc_error_message := JSN.FindPath('message').AsString;
            gc_output.gc_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gc_output.gc_error_description = 0 then begin
         json_output_array := TJSONArray(JSN.FindPath('candles'));

         candles_count := json_output_array.Count;

         i := 0;

         SetLength(gc_output.gc_candles, candles_count);

         while i < candles_count do  begin

            gc_output.gc_candles[i].gc_open := UnitsNanoToDouble(JSN.FindPath('candles[' + inttostr(i) + '].open.units').AsInt64 , JSN.FindPath('candles[' + inttostr(i) + '].open.nano').AsInt64);
            gc_output.gc_candles[i].gc_high := UnitsNanoToDouble(JSN.FindPath('candles[' + inttostr(i) + '].high.units').AsInt64 , JSN.FindPath('candles[' + inttostr(i) + '].high.nano').AsInt64);
            gc_output.gc_candles[i].gc_low := UnitsNanoToDouble(JSN.FindPath('candles[' + inttostr(i) + '].low.units').AsInt64 , JSN.FindPath('candles[' + inttostr(i) + '].low.nano').AsInt64);
            gc_output.gc_candles[i].gc_close := UnitsNanoToDouble(JSN.FindPath('candles[' + inttostr(i) + '].close.units').AsInt64 , JSN.FindPath('candles[' + inttostr(i) + '].close.nano').AsInt64);
            gc_output.gc_candles[i].gc_volume := JSN.FindPath('candles[' + inttostr(i) + '].volume').AsInt64;
            gc_output.gc_candles[i].gc_time := JSN.FindPath('candles[' + inttostr(i) + '].time').AsString;
            gc_output.gc_candles[i].gc_isComplete := JSN.FindPath('candles[' + inttostr(i) + '].isComplete').AsBoolean;
            if JSN.FindPath('candles[' + inttostr(i) + '].candleSource') <> nil then
               gc_output.gc_candles[i].gc_candleSource := JSN.FindPath('candles[' + inttostr(i) + '].candleSource').AsString;
            if JSN.FindPath('candles[' + inttostr(i) + '].volumeBuy') <> nil then
               gc_output.gc_candles[i].gc_volumeBuy := JSN.FindPath('candles[' + inttostr(i) + '].volumeBuy').AsString;
            if JSN.FindPath('candles[' + inttostr(i) + '].volumeSell') <> nil then
               gc_output.gc_candles[i].gc_volumeSell := JSN.FindPath('candles[' + inttostr(i) + '].volumeSell').AsString;
            inc(i);
         end;
      end;
   end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetOrderBook(gob_input : gob_request; out gob_output : gob_response);
var
   JSN: TJSONData;
   jsn_bids, jsn_asks : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, bids_count, asks_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.MarketDataService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.MarketDataService_limit.h_ratelimit_reset * 1000);
        requests_limit.MarketDataService_limit.h_ratelimit_remaining := requests_limit.MarketDataService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if gob_input.gob_depth >0 then json_base.Add('depth', gob_input.gob_depth);
      if gob_input.gob_instrumentId <> '' then json_base.Add('instrumentId', gob_input.gob_instrumentId);

      endpoint_url := url_tinvest + 'MarketDataService/GetOrderBook';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gob_input.gob_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.MarketDataService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gob_output.gob_error_code := JSN.FindPath('code').AsInt64;
            gob_output.gob_error_message := JSN.FindPath('message').AsString;
            gob_output.gob_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gob_output.gob_error_description = 0 then begin

            jsn_asks := TJSONArray(JSN.FindPath('asks'));
            jsn_bids := TJSONArray(JSN.FindPath('bids'));

            asks_count := jsn_asks.Count;
            bids_count := jsn_bids.Count;

            i := gob_input.gob_depth - 1;

            SetLength(gob_output.gob_asks, asks_count);
            SetLength(gob_output.gob_bids, bids_count);

            while i >= 0 do  begin
               gob_output.gob_asks[i].gob_price := UnitsNanoToDouble(JSN.FindPath('asks[' + inttostr(i) + '].price.units').AsInt64 , JSN.FindPath('asks[' + inttostr(i) + '].price.nano').AsInt64);
               gob_output.gob_asks[i].gob_quantity := JSN.FindPath('asks[' + inttostr(i) + '].quantity').AsInt64;
              dec(i);
            end;

            gob_output.gob_minask.gob_price := UnitsNanoToDouble(JSN.FindPath('asks[0].price.units').AsInt64 , JSN.FindPath('asks[0].price.nano').AsInt64);
            gob_output.gob_minask.gob_quantity := JSN.FindPath('asks[0].quantity').AsInt64;

            i := 0;

            gob_output.gob_maxbid.gob_price := UnitsNanoToDouble(JSN.FindPath('bids[0].price.units').AsInt64 , JSN.FindPath('bids[0].price.nano').AsInt64);
            gob_output.gob_maxbid.gob_quantity := JSN.FindPath('bids[0].quantity').AsInt64;

            while i < bids_count do  begin
               gob_output.gob_bids[i].gob_price := UnitsNanoToDouble(JSN.FindPath('bids[' + inttostr(i) + '].price.units').AsInt64 , JSN.FindPath('bids[' + inttostr(i) + '].price.nano').AsInt64);
               gob_output.gob_bids[i].gob_quantity := JSN.FindPath('bids[' + inttostr(i) + '].quantity').AsInt64;
               inc(i);
            end;

            gob_output.gob_figi := JSN.FindPath('figi').AsString;
            gob_output.gob_depth := JSN.FindPath('depth').AsInt64;
            gob_output.gob_lastPrice := UnitsNanoToDouble(JSN.FindPath('lastPrice.units').AsInt64 , JSN.FindPath('lastPrice.nano').AsInt64);
            if JSN.FindPath('closePrice') <> nil then
               gob_output.gob_closePrice := UnitsNanoToDouble(JSN.FindPath('closePrice.units').AsInt64 , JSN.FindPath('closePrice.nano').AsInt64);
            gob_output.gob_limitUp := UnitsNanoToDouble(JSN.FindPath('limitUp.units').AsInt64 , JSN.FindPath('limitUp.nano').AsInt64);
            gob_output.gob_limitDown := UnitsNanoToDouble(JSN.FindPath('limitDown.units').AsInt64 , JSN.FindPath('limitDown.nano').AsInt64);
            gob_output.gob_lastPriceTs := JSN.FindPath('lastPriceTs').AsString;
            gob_output.gob_closePriceTs := JSN.FindPath('closePriceTs').AsString;
            gob_output.gob_orderbookTs := JSN.FindPath('orderbookTs').AsString;
            gob_output.gob_instrumentUid := JSN.FindPath('instrumentUid').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetTechAnalysis(gta_input : gta_request; out gta_output : gta_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, indicators_count, i : int64;
   json_base, json_nested1, json_nested2, json_nested3 : TJSONObject;

begin
   try
      if requests_limit.MarketDataService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.MarketDataService_limit.h_ratelimit_reset * 1000);
        requests_limit.MarketDataService_limit.h_ratelimit_remaining := requests_limit.MarketDataService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested1 := TJSONObject.Create;
      json_nested2 := TJSONObject.Create;
      json_nested3 := TJSONObject.Create;

      if gta_input.gta_indicatorType <> '' then json_base.Add('indicatorType', gta_input.gta_indicatorType);
      if gta_input.gta_instrumentUid <> '' then json_base.Add('instrumentUid', gta_input.gta_instrumentUid);
      if gta_input.gta_from <> '' then json_base.Add('from', gta_input.gta_from);
      if gta_input.gta_to <> '' then json_base.Add('to', gta_input.gta_to);
      if gta_input.gta_interval <> '' then json_base.Add('interval', gta_input.gta_interval);
      if gta_input.gta_typeOfPrice <> '' then json_base.Add('typeOfPrice', gta_input.gta_typeOfPrice);
      if gta_input.gta_length >0 then json_base.Add('length', gta_input.gta_length);
      if gta_input.gta_deviation.gta_deviationMultiplier >0 then begin
         json_nested2.Add('nano', Trunc(Frac(gta_input.gta_deviation.gta_deviationMultiplier)*1000000000));
         json_nested2.Add('units', Trunc(gta_input.gta_deviation.gta_deviationMultiplier));
         json_nested1.Add('deviationMultiplier',json_nested2);
         json_base.Add('deviation', json_nested1);
      end;
      if ((gta_input.gta_smoothing.gta_fastLength >= 0) or (gta_input.gta_smoothing.gta_slowLength >= 0) or (gta_input.gta_smoothing.gta_signalSmoothing >= 0)) then begin
         json_nested3.Add('fastLength', gta_input.gta_smoothing.gta_fastLength);
         json_nested3.Add('slowLength', gta_input.gta_smoothing.gta_slowLength);
         json_nested3.Add('signalSmoothing', gta_input.gta_smoothing.gta_signalSmoothing);
         json_base.Add('smoothing', json_nested3);
      end;

      endpoint_url := url_tinvest + 'MarketDataService/GetTechAnalysis';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gta_input.gta_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.MarketDataService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gta_output.gta_error_code := JSN.FindPath('code').AsInt64;
            gta_output.gta_error_message := JSN.FindPath('message').AsString;
            gta_output.gta_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gta_output.gta_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('technicalIndicators'));

            indicators_count := json_output_array.Count;

            i := 0;

            SetLength(gta_output.gta_technicalIndicators, indicators_count);

            while i < indicators_count do  begin
               gta_output.gta_technicalIndicators[i].gta_timestamp := JSN.FindPath('technicalIndicators[' + inttostr(i) + '].timestamp').AsString;
               if JSN.FindPath('technicalIndicators[' + inttostr(i) + '].middleBand') <> nil then
                  gta_output.gta_technicalIndicators[i].gta_middleBand := UnitsNanoToDouble(JSN.FindPath('technicalIndicators[' + inttostr(i) + '].middleBand.units').AsInt64 , JSN.FindPath('technicalIndicators[' + inttostr(i) + '].middleBand.nano').AsInt64);
               if JSN.FindPath('technicalIndicators[' + inttostr(i) + '].upperBand') <> nil then
                  gta_output.gta_technicalIndicators[i].gta_upperBand := UnitsNanoToDouble(JSN.FindPath('technicalIndicators[' + inttostr(i) + '].upperBand.units').AsInt64 , JSN.FindPath('technicalIndicators[' + inttostr(i) + '].upperBand.nano').AsInt64);
               if JSN.FindPath('technicalIndicators[' + inttostr(i) + '].lowerBand') <> nil then
                  gta_output.gta_technicalIndicators[i].gta_lowerBand := UnitsNanoToDouble(JSN.FindPath('technicalIndicators[' + inttostr(i) + '].lowerBand.units').AsInt64 , JSN.FindPath('technicalIndicators[' + inttostr(i) + '].lowerBand.nano').AsInt64);

               if JSN.FindPath('technicalIndicators[' + inttostr(i) + '].signal') <> nil then
                  gta_output.gta_technicalIndicators[i].gta_signal := UnitsNanoToDouble(JSN.FindPath('technicalIndicators[' + inttostr(i) + '].signal.units').AsInt64 , JSN.FindPath('technicalIndicators[' + inttostr(i) + '].signal.nano').AsInt64);

               if JSN.FindPath('technicalIndicators[' + inttostr(i) + '].macd') <> nil then
                  gta_output.gta_technicalIndicators[i].gta_macd := UnitsNanoToDouble(JSN.FindPath('technicalIndicators[' + inttostr(i) + '].macd.units').AsInt64 , JSN.FindPath('technicalIndicators[' + inttostr(i) + '].macd.nano').AsInt64);
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetTradingStatus(gts_input : gts_request; out gts_output : gts_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.MarketDataService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.MarketDataService_limit.h_ratelimit_reset * 1000);
        requests_limit.MarketDataService_limit.h_ratelimit_remaining := requests_limit.MarketDataService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if gts_input.gts_instrumentId <> '' then json_base.Add('instrumentId', gts_input.gts_instrumentId);


      endpoint_url := url_tinvest + 'MarketDataService/GetTradingStatus';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gts_input.gts_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.MarketDataService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gts_output.gts_error_code := JSN.FindPath('code').AsInt64;
            gts_output.gts_error_message := JSN.FindPath('message').AsString;
            gts_output.gts_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gts_output.gts_error_description = 0 then begin
            gts_output.gts_figi := JSN.FindPath('figi').AsString;
            gts_output.gts_tradingStatus := JSN.FindPath('tradingStatus').AsString;
            gts_output.gts_limitOrderAvailableFlag := JSN.FindPath('limitOrderAvailableFlag').AsBoolean;
            gts_output.gts_marketOrderAvailableFlag := JSN.FindPath('marketOrderAvailableFlag').AsBoolean;
            gts_output.gts_apiTradeAvailableFlag := JSN.FindPath('apiTradeAvailableFlag').AsBoolean;
            gts_output.gts_instrumentUid := JSN.FindPath('instrumentUid').AsString;
            gts_output.gts_bestpriceOrderAvailableFlag := JSN.FindPath('bestpriceOrderAvailableFlag').AsBoolean;
            gts_output.gts_onlyBestPrice := JSN.FindPath('onlyBestPrice').AsBoolean;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetOrders(go_input : go_request; out go_output : go_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, orders_count, stages_count, i, j : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.OrdersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OrdersService_limit.h_ratelimit_reset * 1000);
        requests_limit.OrdersService_limit.h_ratelimit_remaining := requests_limit.OrdersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if go_input.go_accountId <> '' then json_base.Add('accountId', go_input.go_accountId);

      endpoint_url := url_tinvest + 'OrdersService/GetOrders';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + go_input.go_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OrdersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            go_output.go_error_code := JSN.FindPath('code').AsInt64;
            go_output.go_error_message := JSN.FindPath('message').AsString;
            go_output.go_error_description := JSN.FindPath('description').AsInt64;
         end;

         if go_output.go_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('orders'));
            orders_count := json_output_array.Count;

            i := 0;

            SetLength(go_output.go_orders, orders_count);

            while i < orders_count do  begin
               go_output.go_orders[i].go_orderId := JSN.FindPath('orders[' + inttostr(i) + '].orderId').AsString;
               go_output.go_orders[i].go_executionReportStatus := JSN.FindPath('orders[' + inttostr(i) + '].executionReportStatus').AsString;
               go_output.go_orders[i].go_lotsRequested := JSN.FindPath('orders[' + inttostr(i) + '].lotsRequested').AsInt64;
               go_output.go_orders[i].go_lotsExecuted := JSN.FindPath('orders[' + inttostr(i) + '].lotsExecuted').AsInt64;
               go_output.go_orders[i].go_initialOrderPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('orders[' + inttostr(i) + '].initialOrderPrice.units').AsInt64 , JSN.FindPath('orders[' + inttostr(i) + '].initialOrderPrice.nano').AsInt64);
               go_output.go_orders[i].go_initialOrderPrice.currency := JSN.FindPath('orders[' + inttostr(i) + '].initialOrderPrice.currency').AsString;
               go_output.go_orders[i].go_executedOrderPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('orders[' + inttostr(i) + '].executedOrderPrice.units').AsInt64 , JSN.FindPath('orders[' + inttostr(i) + '].executedOrderPrice.nano').AsInt64);
               go_output.go_orders[i].go_executedOrderPrice.currency := JSN.FindPath('orders[' + inttostr(i) + '].executedOrderPrice.currency').AsString;
               go_output.go_orders[i].go_totalOrderAmount.moneyval := UnitsNanoToDouble(JSN.FindPath('orders[' + inttostr(i) + '].totalOrderAmount.units').AsInt64 , JSN.FindPath('orders[' + inttostr(i) + '].totalOrderAmount.nano').AsInt64);
               go_output.go_orders[i].go_totalOrderAmount.currency := JSN.FindPath('orders[' + inttostr(i) + '].totalOrderAmount.currency').AsString;
               go_output.go_orders[i].go_averagePositionPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('orders[' + inttostr(i) + '].averagePositionPrice.units').AsInt64 , JSN.FindPath('orders[' + inttostr(i) + '].averagePositionPrice.nano').AsInt64);
               go_output.go_orders[i].go_averagePositionPrice.currency := JSN.FindPath('orders[' + inttostr(i) + '].averagePositionPrice.currency').AsString;
               go_output.go_orders[i].go_initialCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('orders[' + inttostr(i) + '].initialCommission.units').AsInt64 , JSN.FindPath('orders[' + inttostr(i) + '].initialCommission.nano').AsInt64);
               go_output.go_orders[i].go_initialCommission.currency := JSN.FindPath('orders[' + inttostr(i) + '].initialCommission.currency').AsString;
               go_output.go_orders[i].go_executedCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('orders[' + inttostr(i) + '].executedCommission.units').AsInt64 , JSN.FindPath('orders[' + inttostr(i) + '].executedCommission.nano').AsInt64);
               go_output.go_orders[i].go_executedCommission.currency := JSN.FindPath('orders[' + inttostr(i) + '].executedCommission.currency').AsString;
               go_output.go_orders[i].go_figi := JSN.FindPath('orders[' + inttostr(i) + '].figi').AsString;
               go_output.go_orders[i].go_direction := JSN.FindPath('orders[' + inttostr(i) + '].direction').AsString;
               go_output.go_orders[i].go_initialSecurityPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('orders[' + inttostr(i) + '].initialSecurityPrice.units').AsInt64 , JSN.FindPath('orders[' + inttostr(i) + '].initialSecurityPrice.nano').AsInt64);
               go_output.go_orders[i].go_initialSecurityPrice.currency := JSN.FindPath('orders[' + inttostr(i) + '].initialSecurityPrice.currency').AsString;
               json_output_array := TJSONArray(JSN.FindPath('orders[' + inttostr(i) + '].stages'));
               stages_count := json_output_array.Count;
               j := 0;

               SetLength(go_output.go_orders[i].go_stages, stages_count);

               while j < stages_count do  begin
                  go_output.go_orders[i].go_stages[j].go_price.moneyval := UnitsNanoToDouble(JSN.FindPath('orders[' + inttostr(i) + '].stages[' + inttostr(j) + '].price.units').AsInt64 , JSN.FindPath('orders[' + inttostr(i) + '].stages[' + inttostr(j) + '].price.nano').AsInt64);
                  go_output.go_orders[i].go_stages[j].go_price.currency := JSN.FindPath('orders[' + inttostr(i) + '].stages[' + inttostr(j) + '].price.currency').AsString;
                  go_output.go_orders[i].go_stages[j].go_quantity := JSN.FindPath('orders[' + inttostr(i) + '].stages[' + inttostr(j) + '].quantity').AsInt64;
                  go_output.go_orders[i].go_stages[j].go_tradeId := JSN.FindPath('orders[' + inttostr(i) + '].stages[' + inttostr(j) + '].tradeId').AsString;
                  go_output.go_orders[i].go_stages[j].go_executionTime := JSN.FindPath('orders[' + inttostr(i) + '].stages[' + inttostr(j) + '].executionTime').AsString;
                  inc(j);
               end;

               go_output.go_orders[i].go_serviceCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('orders[' + inttostr(i) + '].serviceCommission.units').AsInt64 , JSN.FindPath('orders[' + inttostr(i) + '].serviceCommission.nano').AsInt64);
               go_output.go_orders[i].go_serviceCommission.currency := JSN.FindPath('orders[' + inttostr(i) + '].serviceCommission.currency').AsString;
               go_output.go_orders[i].go_currency := JSN.FindPath('orders[' + inttostr(i) + '].currency').AsString;
               go_output.go_orders[i].go_orderType := JSN.FindPath('orders[' + inttostr(i) + '].orderType').AsString;
               go_output.go_orders[i].go_orderDate := JSN.FindPath('orders[' + inttostr(i) + '].orderDate').AsString;
               go_output.go_orders[i].go_instrumentUid := JSN.FindPath('orders[' + inttostr(i) + '].instrumentUid').AsString;
               go_output.go_orders[i].go_orderRequestId := JSN.FindPath('orders[' + inttostr(i) + '].orderRequestId').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetClosePrices(gcp_input : gcp_request; out gcp_output : gcp_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, numb_uids, i : int64;
   json_base : TJSONObject;
   json_input_array : TJSONArray;

begin
   try
      if requests_limit.MarketDataService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.MarketDataService_limit.h_ratelimit_reset * 1000);
        requests_limit.MarketDataService_limit.h_ratelimit_remaining := requests_limit.MarketDataService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_input_array := TJSONArray.Create;

      endpoint_url := url_tinvest + 'MarketDataService/GetClosePrices';

      numb_uids := high(gcp_input.gcp_instruments);

      for i := 0 to numb_uids do begin
         json_input_array.add(TJSONObject.Create(['instrumentId', gcp_input.gcp_instruments[i].gcp_instrumentId]));
      end;

      json_base.Add('instruments', json_input_array);

      if gcp_input.gcp_instrumentStatus <> '' then json_base.Add('accountId', gcp_input.gcp_instrumentStatus);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gcp_input.gcp_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.MarketDataService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gcp_output.gcp_error_code := JSN.FindPath('code').AsInt64;
            gcp_output.gcp_error_message := JSN.FindPath('message').AsString;
            gcp_output.gcp_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gcp_output.gcp_error_description = 0 then begin

            i := 0;

            SetLength(gcp_output.gcp_closePrices, numb_uids+1);

            while i <= numb_uids do  begin
               if JSN.FindPath('closePrices[' + inttostr(i) + '].figi') <> nil then
                  gcp_output.gcp_closePrices[i].gcp_figi := JSN.FindPath('closePrices[' + inttostr(i) + '].figi').AsString;
               if JSN.FindPath('closePrices[' + inttostr(i) + '].instrumentUid') <> nil then
                  gcp_output.gcp_closePrices[i].gcp_instrumentUid := JSN.FindPath('closePrices[' + inttostr(i) + '].instrumentUid').AsString;
               if JSN.FindPath('closePrices[' + inttostr(i) + '].price.units') <> nil then
                  gcp_output.gcp_closePrices[i].gcp_price := UnitsNanoToDouble(JSN.FindPath('closePrices[' + inttostr(i) + '].price.units').AsInt64 , JSN.FindPath('closePrices[' + inttostr(i) + '].price.nano').AsInt64);
               if JSN.FindPath('closePrices[' + inttostr(i) + '].eveningSessionPrice.units') <> nil then
                  gcp_output.gcp_closePrices[i].gcp_eveningSessionPrice := UnitsNanoToDouble(JSN.FindPath('closePrices[' + inttostr(i) + '].eveningSessionPrice.units').AsInt64 , JSN.FindPath('closePrices[' + inttostr(i) + '].eveningSessionPrice.nano').AsInt64);
               if JSN.FindPath('closePrices[' + inttostr(i) + '].time') <> nil then
                  gcp_output.gcp_closePrices[i].gcp_time := JSN.FindPath('closePrices[' + inttostr(i) + '].time').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;


procedure GetLastPrices(glp_input : glp_request; out glp_output : glp_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, numb_uids, i : int64;
   json_base : TJSONObject;
   json_input_array : TJSONArray;

begin
   try
      if requests_limit.MarketDataService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.MarketDataService_limit.h_ratelimit_reset * 1000);
        requests_limit.MarketDataService_limit.h_ratelimit_remaining := requests_limit.MarketDataService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_input_array := TJSONArray.Create;

      endpoint_url := url_tinvest + 'MarketDataService/GetLastPrices';

      numb_uids := high(glp_input.glp_instruments);

      for i := 0 to numb_uids do begin
         json_input_array.Add(glp_input.glp_instruments[i].glp_instrumentId);
      end;
      json_base.Add('instrumentId', json_input_array);

      json_base.Add('lastPriceType', glp_input.glp_lastPriceType);
      json_base.Add('instrumentStatus', glp_input.glp_instrumentStatus);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + glp_input.glp_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.MarketDataService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            glp_output.glp_error_code := JSN.FindPath('code').AsInt64;
            glp_output.glp_error_message := JSN.FindPath('message').AsString;
            glp_output.glp_error_description := JSN.FindPath('description').AsInt64;
         end;

         if glp_output.glp_error_description = 0 then begin

            i := 0;

            SetLength(glp_output.glp_lastPrices, numb_uids+1);

            while i <= numb_uids do  begin
               if JSN.FindPath('lastPrices[' + inttostr(i) + '].figi') <> nil then
                  glp_output.glp_lastPrices[i].glp_figi := JSN.FindPath('lastPrices[' + inttostr(i) + '].figi').AsString;
               if JSN.FindPath('lastPrices[' + inttostr(i) + '].instrumentUid') <> nil then
                  glp_output.glp_lastPrices[i].glp_instrumentUid := JSN.FindPath('lastPrices[' + inttostr(i) + '].instrumentUid').AsString;
               if JSN.FindPath('lastPrices[' + inttostr(i) + '].price.units') <> nil then
                  glp_output.glp_lastPrices[i].glp_price := UnitsNanoToDouble(JSN.FindPath('lastPrices[' + inttostr(i) + '].price.units').AsInt64 , JSN.FindPath('lastPrices[' + inttostr(i) + '].price.nano').AsInt64);
               if JSN.FindPath('lastPrices[' + inttostr(i) + '].lastPriceType') <> nil then
                  glp_output.glp_lastPrices[i].glp_lastPriceType := JSN.FindPath('lastPrices[' + inttostr(i) + '].lastPriceType').AsString;
               if JSN.FindPath('lastPrices[' + inttostr(i) + '].time') <> nil then
                  glp_output.glp_lastPrices[i].glp_time := JSN.FindPath('lastPrices[' + inttostr(i) + '].time').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
    end;
end;

procedure GetOrderState(gos_input : gos_request; out gos_output : gos_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, stages_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.OrdersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OrdersService_limit.h_ratelimit_reset * 1000);
        requests_limit.OrdersService_limit.h_ratelimit_remaining := requests_limit.OrdersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      json_base.Add('accountId', gos_input.gos_accountId);
      json_base.Add('orderId', gos_input.gos_orderId);
      if gos_input.gos_priceType <> '' then json_base.Add('priceType', gos_input.gos_priceType);
      if gos_input.gos_orderIdType <> '' then json_base.Add('orderIdType', gos_input.gos_orderIdType);

      endpoint_url := url_tinvest + 'OrdersService/GetOrderState';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gos_input.gos_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OrdersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gos_output.gos_error_code := JSN.FindPath('code').AsInt64;
            gos_output.gos_error_message := JSN.FindPath('message').AsString;
            gos_output.gos_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gos_output.gos_error_description = 0 then begin
            gos_output.gos_orderId := JSN.FindPath('orderId').AsString;
            gos_output.gos_executionReportStatus := JSN.FindPath('executionReportStatus').AsString;
            gos_output.gos_lotsRequested := JSN.FindPath('lotsRequested').AsInt64;
            gos_output.gos_lotsExecuted := JSN.FindPath('lotsExecuted').AsInt64;
            gos_output.gos_initialOrderPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('initialOrderPrice.units').AsInt64 , JSN.FindPath('initialOrderPrice.nano').AsInt64);
            gos_output.gos_initialOrderPrice.currency := JSN.FindPath('initialOrderPrice.currency').AsString;
            gos_output.gos_executedOrderPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('executedOrderPrice.units').AsInt64 , JSN.FindPath('executedOrderPrice.nano').AsInt64);
            gos_output.gos_executedOrderPrice.currency := JSN.FindPath('executedOrderPrice.currency').AsString;
            gos_output.gos_totalOrderAmount.moneyval := UnitsNanoToDouble(JSN.FindPath('totalOrderAmount.units').AsInt64 , JSN.FindPath('totalOrderAmount.nano').AsInt64);
            gos_output.gos_totalOrderAmount.currency := JSN.FindPath('totalOrderAmount.currency').AsString;
            gos_output.gos_averagePositionPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('averagePositionPrice.units').AsInt64 , JSN.FindPath('averagePositionPrice.nano').AsInt64);
            gos_output.gos_averagePositionPrice.currency := JSN.FindPath('averagePositionPrice.currency').AsString;
            gos_output.gos_initialCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('initialCommission.units').AsInt64 , JSN.FindPath('initialCommission.nano').AsInt64);
            gos_output.gos_initialCommission.currency := JSN.FindPath('initialCommission.currency').AsString;
            gos_output.gos_executedCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('executedCommission.units').AsInt64 , JSN.FindPath('executedCommission.nano').AsInt64);
            gos_output.gos_executedCommission.currency := JSN.FindPath('executedCommission.currency').AsString;
            gos_output.gos_figi := JSN.FindPath('figi').AsString;
            gos_output.gos_direction := JSN.FindPath('direction').AsString;
            gos_output.gos_initialSecurityPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('initialSecurityPrice.units').AsInt64 , JSN.FindPath('initialSecurityPrice.nano').AsInt64);
            gos_output.gos_initialSecurityPrice.currency := JSN.FindPath('initialSecurityPrice.currency').AsString;
            gos_output.gos_serviceCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('serviceCommission.units').AsInt64 , JSN.FindPath('serviceCommission.nano').AsInt64);
            gos_output.gos_serviceCommission.currency := JSN.FindPath('serviceCommission.currency').AsString;
            gos_output.gos_currency := JSN.FindPath('currency').AsString;
            gos_output.gos_orderType := JSN.FindPath('orderType').AsString;
            gos_output.gos_orderDate := JSN.FindPath('orderDate').AsString;
            gos_output.gos_instrumentUid := JSN.FindPath('instrumentUid').AsString;
            gos_output.gos_orderRequestId := JSN.FindPath('orderRequestId').AsString;

            json_output_array := TJSONArray(JSN.FindPath('stages'));
            stages_count := json_output_array.Count;

            i := 0;

            SetLength(gos_output.gos_stages, stages_count);

            while i < stages_count do  begin
               gos_output.gos_stages[i].gos_price := UnitsNanoToDouble(JSN.FindPath('stages[' + inttostr(i) + '].price.units').AsInt64 , JSN.FindPath('stages[' + inttostr(i) + '].price.nano').AsInt64);
               gos_output.gos_stages[i].gos_quantity := JSN.FindPath('stages[' + inttostr(i) + '].quantity').AsInt64;
               gos_output.gos_stages[i].gos_tradeId := JSN.FindPath('stages[' + inttostr(i) + '].tradeId').AsString;
               gos_output.gos_stages[i].gos_executionTime := JSN.FindPath('stages[' + inttostr(i) + '].executionTime').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure CancelOrder(co_input : co_request; out co_output : co_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.OrdersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OrdersService_limit.h_ratelimit_reset * 1000);
        requests_limit.OrdersService_limit.h_ratelimit_remaining := requests_limit.OrdersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      json_base.Add('accountId', co_input.co_accountId);
      json_base.Add('orderId', co_input.co_orderId);
      if co_input.co_orderId <> '' then json_base.Add('orderIdType', co_input.co_orderId);

      endpoint_url := url_tinvest + 'OrdersService/CancelOrder';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + co_input.co_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OrdersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            co_output.co_error_code := JSN.FindPath('code').AsInt64;
            co_output.co_error_message := JSN.FindPath('message').AsString;
            co_output.co_error_description := JSN.FindPath('description').AsInt64;
         end;

         if co_output.co_error_description = 0 then begin
            co_output.co_time := JSN.FindPath('time').AsString;
            co_output.co_responseMetadata.po_trackingId := JSN.FindPath('responseMetadata.trackingId').AsString;
            co_output.co_responseMetadata.po_serverTime := JSN.FindPath('responseMetadata.serverTime').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;


procedure GetMaxLots(gml_input : gml_request; out gml_output : gml_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base, json_nested : TJSONObject;

begin
   try
      if requests_limit.OrdersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OrdersService_limit.h_ratelimit_reset * 1000);
        requests_limit.OrdersService_limit.h_ratelimit_remaining := requests_limit.OrdersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested := TJSONObject.Create;

      json_base.Add('accountId', gml_input.gml_accountId);
      json_base.Add('instrumentId', gml_input.gml_instrumentId);
      if gml_input.gml_price >0 then begin
         json_nested.Add('nano', Trunc(Frac(gml_input.gml_price)*1000000000));
         json_nested.Add('units', Trunc(gml_input.gml_price));
         json_base.Add('price', json_nested);
      end;

      endpoint_url := url_tinvest + 'OrdersService/GetMaxLots';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gml_input.gml_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OrdersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gml_output.gml_error_code := JSN.FindPath('code').AsInt64;
            gml_output.gml_error_message := JSN.FindPath('message').AsString;
            gml_output.gml_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gml_output.gml_error_description = 0 then begin
            gml_output.gml_currency := JSN.FindPath('currency').AsString;
            gml_output.gml_buyLimits.gml_buyMoneyAmount := UnitsNanoToDouble(JSN.FindPath('buyLimits.buyMoneyAmount.units').AsInt64 , JSN.FindPath('buyLimits.buyMoneyAmount.nano').AsInt64);
            gml_output.gml_buyLimits.gml_buyMaxLots := JSN.FindPath('buyLimits.buyMaxLots').AsInt64;
            gml_output.gml_buyLimits.gml_buyMaxMarketLots := JSN.FindPath('buyLimits.buyMaxMarketLots').AsInt64;
            gml_output.gml_buyMarginLimits.gml_buyMoneyAmount := UnitsNanoToDouble(JSN.FindPath('buyMarginLimits.buyMoneyAmount.units').AsInt64 , JSN.FindPath('buyMarginLimits.buyMoneyAmount.nano').AsInt64);
            gml_output.gml_buyMarginLimits.gml_buyMaxLots := JSN.FindPath('buyMarginLimits.buyMaxLots').AsInt64;
            gml_output.gml_buyMarginLimits.gml_buyMaxMarketLots := JSN.FindPath('buyMarginLimits.buyMaxMarketLots').AsInt64;
            gml_output.gml_sellLimits.gml_sellMaxLots := JSN.FindPath('sellLimits.sellMaxLots').AsInt64;
            gml_output.gml_sellMarginLimits.gml_sellMaxLots := JSN.FindPath('sellMarginLimits.sellMaxLots').AsInt64;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;


procedure PostOrder(po_input : po_request; out po_output : po_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base, json_nested : TJSONObject;

begin
   try
      if requests_limit.OrdersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OrdersService_limit.h_ratelimit_reset * 1000);
        requests_limit.OrdersService_limit.h_ratelimit_remaining := requests_limit.OrdersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested := TJSONObject.Create;

      json_base.Add('quantity', po_input.po_quantity);
      if po_input.po_price >0 then begin
         json_nested.Add('nano', Trunc(Frac(po_input.po_price)*1000000000));
         json_nested.Add('units', Trunc(po_input.po_price));
         json_base.Add('price', json_nested);
      end;
      json_base.Add('direction', po_input.po_direction);
      json_base.Add('accountId', po_input.po_accountId);
      json_base.Add('orderType', po_input.po_orderType);
      json_base.Add('orderId', po_input.po_orderId);
      if po_input.po_instrumentId <> '' then json_base.Add('instrumentId', po_input.po_instrumentId);
      if po_input.po_timeInForce <> '' then json_base.Add('timeInForce', po_input.po_timeInForce);
      if po_input.po_priceType <> '' then json_base.Add('priceType', po_input.po_priceType);
      if po_input.po_confirmMarginTrade <> false then json_base.Add('confirmMarginTrade', po_input.po_confirmMarginTrade);

      endpoint_url := url_tinvest + 'OrdersService/PostOrder';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + po_input.po_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OrdersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

      if JSN.FindPath('description') <> nil then begin
         po_output.po_error_code := JSN.FindPath('code').AsInt64;
         po_output.po_error_message := JSN.FindPath('message').AsString;
         po_output.po_error_description := JSN.FindPath('description').AsInt64;
      end;

         if po_output.po_error_description = 0 then begin
            po_output.po_orderId := JSN.FindPath('orderId').AsString;
            po_output.po_executionReportStatus := JSN.FindPath('executionReportStatus').AsString;
            po_output.po_lotsRequested := JSN.FindPath('lotsRequested').AsInt64;
            po_output.po_lotsExecuted := JSN.FindPath('lotsExecuted').AsInt64;
            po_output.po_initialOrderPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('initialOrderPrice.units').AsInt64 , JSN.FindPath('initialOrderPrice.nano').AsInt64);
            po_output.po_initialOrderPrice.currency := JSN.FindPath('initialOrderPrice.currency').AsString;
            if JSN.FindPath('executedOrderPrice') <> nil then begin
               po_output.po_executedOrderPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('executedOrderPrice.units').AsInt64 , JSN.FindPath('executedOrderPrice.nano').AsInt64);
               po_output.po_executedOrderPrice.currency := JSN.FindPath('executedOrderPrice.currency').AsString;
            end;
            po_output.po_totalOrderAmount.moneyval := UnitsNanoToDouble(JSN.FindPath('totalOrderAmount.units').AsInt64 , JSN.FindPath('totalOrderAmount.nano').AsInt64);
            po_output.po_totalOrderAmount.currency := JSN.FindPath('totalOrderAmount.currency').AsString;
            if JSN.FindPath('initialCommission') <> nil then begin
               po_output.po_initialCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('initialCommission.units').AsInt64 , JSN.FindPath('initialCommission.nano').AsInt64);
               po_output.po_initialCommission.currency := JSN.FindPath('initialCommission.currency').AsString;
            end;
            if JSN.FindPath('executedCommission') <> nil then begin
               po_output.po_executedCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('executedCommission.units').AsInt64 , JSN.FindPath('executedCommission.nano').AsInt64);
               po_output.po_executedCommission.currency := JSN.FindPath('executedCommission.currency').AsString;
            end;
            if JSN.FindPath('aciValue') <> nil then begin
               po_output.po_aciValue.moneyval := UnitsNanoToDouble(JSN.FindPath('aciValue.units').AsInt64 , JSN.FindPath('aciValue.nano').AsInt64);
               po_output.po_aciValue.currency := JSN.FindPath('aciValue.currency').AsString;
            end;
            po_output.po_figi := JSN.FindPath('figi').AsString;
            po_output.po_direction := JSN.FindPath('direction').AsString;
            po_output.po_initialSecurityPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('initialSecurityPrice.units').AsInt64 , JSN.FindPath('initialSecurityPrice.nano').AsInt64);
            po_output.po_initialSecurityPrice.currency := JSN.FindPath('initialSecurityPrice.currency').AsString;
            po_output.po_orderType := JSN.FindPath('orderType').AsString;
            po_output.po_message := JSN.FindPath('message').AsString;
            if JSN.FindPath('initialOrderPricePt') <> nil then
               po_output.po_initialOrderPricePt := UnitsNanoToDouble(JSN.FindPath('initialOrderPricePt.units').AsInt64 , JSN.FindPath('initialOrderPricePt.nano').AsInt64);
            po_output.po_instrumentUid := JSN.FindPath('instrumentUid').AsString;
            po_output.po_orderRequestId := JSN.FindPath('orderRequestId').AsString;
            po_output.po_responseMetadata.po_trackingId := JSN.FindPath('responseMetadata.trackingId').AsString;
            po_output.po_responseMetadata.po_serverTime := JSN.FindPath('responseMetadata.serverTime').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure PostOrderAsync (poa_input : poa_request; out poa_output : poa_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base, json_nested : TJSONObject;

begin
   try
      if requests_limit.OrdersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OrdersService_limit.h_ratelimit_reset * 1000);
        requests_limit.OrdersService_limit.h_ratelimit_remaining := requests_limit.OrdersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested := TJSONObject.Create;

      json_base.Add('instrumentId', poa_input.poa_instrumentId);
      json_base.Add('quantity', poa_input.poa_quantity);
      if poa_input.poa_price >0 then begin
         json_nested.Add('nano', Trunc(Frac(poa_input.poa_price)*1000000000));
         json_nested.Add('units', Trunc(poa_input.poa_price));
         json_base.Add('price', json_nested);
      end;
      json_base.Add('direction', poa_input.poa_direction);
      json_base.Add('orderType', poa_input.poa_orderType);
      json_base.Add('orderId', poa_input.poa_orderId);
      if poa_input.poa_timeInForce <> '' then json_base.Add('timeInForce', poa_input.poa_timeInForce);
      if poa_input.poa_priceType <> '' then json_base.Add('priceType', poa_input.poa_priceType);
      if poa_input.poa_confirmMarginTrade <> false then json_base.Add('confirmMarginTrade', poa_input.poa_confirmMarginTrade);

      endpoint_url := url_tinvest + 'OrdersService/PostOrderAsync';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + poa_input.poa_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OrdersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

      if JSN.FindPath('description') <> nil then begin
         poa_output.poa_error_code := JSN.FindPath('code').AsInt64;
         poa_output.poa_error_message := JSN.FindPath('message').AsString;
         poa_output.poa_error_description := JSN.FindPath('description').AsInt64;
      end;

         if poa_output.poa_error_description = 0 then begin
            poa_output.poa_orderRequestId := JSN.FindPath('orderRequestId').AsString;
            poa_output.poa_executionReportStatus := JSN.FindPath('executionReportStatus').AsString;
            poa_output.poa_tradeIntentId := JSN.FindPath('tradeIntentId').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetOrderPrice(gop_input : gop_request; out gop_output : gop_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base, json_nested : TJSONObject;

begin
   try
      if requests_limit.OrdersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OrdersService_limit.h_ratelimit_reset * 1000);
        requests_limit.OrdersService_limit.h_ratelimit_remaining := requests_limit.OrdersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested := TJSONObject.Create;

      json_base.Add('accountId', gop_input.gop_accountId);
      json_base.Add('instrumentId', gop_input.gop_instrumentId);
      json_nested.Add('nano', Trunc(Frac(gop_input.gop_price)*1000000000));
      json_nested.Add('units', Trunc(gop_input.gop_price));
      json_base.Add('price', json_nested);
      json_base.Add('quantity', gop_input.gop_quantity);

      endpoint_url := url_tinvest + 'OrdersService/GetOrderPrice';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gop_input.gop_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OrdersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gop_output.gop_error_code := JSN.FindPath('code').AsInt64;
            gop_output.gop_error_message := JSN.FindPath('message').AsString;
            gop_output.gop_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gop_output.gop_error_description = 0 then begin
            gop_output.gop_totalOrderAmount.moneyval := UnitsNanoToDouble(JSN.FindPath('totalOrderAmount.units').AsInt64 , JSN.FindPath('totalOrderAmount.nano').AsInt64);
            gop_output.gop_totalOrderAmount.currency := JSN.FindPath('totalOrderAmount.currency').AsString;
            gop_output.gop_initialOrderAmount.moneyval := UnitsNanoToDouble(JSN.FindPath('initialOrderAmount.units').AsInt64 , JSN.FindPath('initialOrderAmount.nano').AsInt64);
            gop_output.gop_initialOrderAmount.currency := JSN.FindPath('initialOrderAmount.currency').AsString;
            gop_output.gop_lotsRequested := JSN.FindPath('lotsRequested').AsInt64;
            gop_output.gop_executedCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('executedCommission.units').AsInt64 , JSN.FindPath('executedCommission.nano').AsInt64);
            gop_output.gop_executedCommission.currency := JSN.FindPath('executedCommission.currency').AsString;
            gop_output.gop_executedCommissionRub.moneyval := UnitsNanoToDouble(JSN.FindPath('executedCommissionRub.units').AsInt64 , JSN.FindPath('executedCommissionRub.nano').AsInt64);
            gop_output.gop_executedCommissionRub.currency := JSN.FindPath('executedCommissionRub.currency').AsString;
            if JSN.FindPath('serviceCommission') <> nil then begin
               gop_output.gop_serviceCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('serviceCommission.units').AsInt64 , JSN.FindPath('serviceCommission.nano').AsInt64);
               gop_output.gop_serviceCommission.currency := JSN.FindPath('serviceCommission.currency').AsString;
            end;
            gop_output.gop_dealCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('dealCommission.units').AsInt64 , JSN.FindPath('dealCommission.nano').AsInt64);
            gop_output.gop_dealCommission.currency := JSN.FindPath('dealCommission.currency').AsString;
            if JSN.FindPath('extraBond') <> nil then begin
               gop_output.gop_extraBond.gop_aciValue.moneyval := UnitsNanoToDouble(JSN.FindPath('extraBond.aciValue.units').AsInt64 , JSN.FindPath('extraBond.aciValue.nano').AsInt64);
               gop_output.gop_extraBond.gop_aciValue.currency := JSN.FindPath('extraBond.aciValue.currency').AsString;
               gop_output.gop_extraBond.gop_nominalConversionRate := UnitsNanoToDouble(JSN.FindPath('extraBond.nominalConversionRate.units').AsInt64 , JSN.FindPath('extraBond.nominalConversionRate.nano').AsInt64);
            end;
            if JSN.FindPath('extraFuture') <> nil then begin
               gop_output.gop_extraFuture.gop_initialMargin.moneyval := UnitsNanoToDouble(JSN.FindPath('extraFuture.initialMargin.units').AsInt64 , JSN.FindPath('extraFuture.initialMargin.nano').AsInt64);
               gop_output.gop_extraFuture.gop_initialMargin.currency := JSN.FindPath('extraFuture.initialMargin.currency').AsString;
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure ReplaceOrder(ro_input : ro_request; out ro_output : ro_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base, json_nested : TJSONObject;

begin
   try
      if requests_limit.OrdersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OrdersService_limit.h_ratelimit_reset * 1000);
        requests_limit.OrdersService_limit.h_ratelimit_remaining := requests_limit.OrdersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested := TJSONObject.Create;

      json_base.Add('accountId', ro_input.ro_accountId);
      json_base.Add('orderId', ro_input.ro_orderId);
      json_base.Add('idempotencyKey', ro_input.ro_idempotencyKey);
      json_base.Add('quantity', ro_input.ro_quantity);
      json_nested.Add('nano', Trunc(Frac(ro_input.ro_price)*1000000000));
      json_nested.Add('units', Trunc(ro_input.ro_price));
      json_base.Add('price', json_nested);
      json_base.Add('priceType', ro_input.ro_priceType);
      json_base.Add('confirmMarginTrade', ro_input.ro_confirmMarginTrade);

      endpoint_url := url_tinvest + 'OrdersService/ReplaceOrder';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + ro_input.ro_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OrdersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            ro_output.ro_error_code := JSN.FindPath('code').AsInt64;
            ro_output.ro_error_message := JSN.FindPath('message').AsString;
            ro_output.ro_error_description := JSN.FindPath('description').AsInt64;
         end;

         if ro_output.ro_error_description = 0 then begin
            ro_output.ro_orderId := JSN.FindPath('orderId').AsString;
            ro_output.ro_executionReportStatus := JSN.FindPath('executionReportStatus').AsString;
            ro_output.ro_lotsRequested := JSN.FindPath('lotsRequested').AsInt64;
            ro_output.ro_lotsExecuted := JSN.FindPath('lotsExecuted').AsInt64;
            ro_output.ro_initialOrderPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('initialOrderPrice.units').AsInt64 , JSN.FindPath('initialOrderPrice.nano').AsInt64);
            ro_output.ro_initialOrderPrice.currency := JSN.FindPath('initialOrderPrice.currency').AsString;
            if JSN.FindPath('executedOrderPrice') <> nil then begin
               ro_output.ro_executedOrderPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('executedOrderPrice.units').AsInt64 , JSN.FindPath('executedOrderPrice.nano').AsInt64);
               ro_output.ro_executedOrderPrice.currency := JSN.FindPath('executedOrderPrice.currency').AsString;
            end;
            ro_output.ro_totalOrderAmount.moneyval := UnitsNanoToDouble(JSN.FindPath('totalOrderAmount.units').AsInt64 , JSN.FindPath('totalOrderAmount.nano').AsInt64);
            ro_output.ro_totalOrderAmount.currency := JSN.FindPath('totalOrderAmount.currency').AsString;
            if JSN.FindPath('initialCommission') <> nil then begin
               ro_output.ro_initialCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('initialCommission.units').AsInt64 , JSN.FindPath('initialCommission.nano').AsInt64);
               ro_output.ro_initialCommission.currency := JSN.FindPath('initialCommission.currency').AsString;
            end;
            if JSN.FindPath('executedCommission') <> nil then begin
               ro_output.ro_executedCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('executedCommission.units').AsInt64 , JSN.FindPath('executedCommission.nano').AsInt64);
               ro_output.ro_executedCommission.currency := JSN.FindPath('executedCommission.currency').AsString;
            end;
            if JSN.FindPath('aciValue') <> nil then begin
               ro_output.ro_aciValue.moneyval := UnitsNanoToDouble(JSN.FindPath('aciValue.units').AsInt64 , JSN.FindPath('aciValue.nano').AsInt64);
               ro_output.ro_aciValue.currency := JSN.FindPath('aciValue.currency').AsString;
            end;
            ro_output.ro_figi := JSN.FindPath('figi').AsString;
            ro_output.ro_direction := JSN.FindPath('direction').AsString;
            ro_output.ro_initialSecurityPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('initialSecurityPrice.units').AsInt64 , JSN.FindPath('initialSecurityPrice.nano').AsInt64);
            ro_output.ro_initialSecurityPrice.currency := JSN.FindPath('initialSecurityPrice.currency').AsString;
            ro_output.ro_orderType := JSN.FindPath('orderType').AsString;
            ro_output.ro_message := JSN.FindPath('message').AsString;
            if JSN.FindPath('initialOrderPricePt') <> nil then
               ro_output.ro_initialOrderPricePt := UnitsNanoToDouble(JSN.FindPath('initialOrderPricePt.units').AsInt64 , JSN.FindPath('initialOrderPricePt.nano').AsInt64);
            ro_output.ro_instrumentUid := JSN.FindPath('instrumentUid').AsString;
            ro_output.ro_orderRequestId := JSN.FindPath('orderRequestId').AsString;
            ro_output.ro_responseMetadata.ro_trackingId := JSN.FindPath('responseMetadata.trackingId').AsString;
            ro_output.ro_responseMetadata.ro_serverTime := JSN.FindPath('responseMetadata.serverTime').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure PostStopOrder(pso_input : pso_request; out pso_output : pso_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base, json_price, json_stopPrice, json_indent, json_trailingData, json_spread, json_nested1  : TJSONObject;

begin
   try
      if requests_limit.StopOrdersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.StopOrdersService_limit.h_ratelimit_reset * 1000);
        requests_limit.StopOrdersService_limit.h_ratelimit_remaining := requests_limit.StopOrdersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_price := TJSONObject.Create;
      json_stopPrice := TJSONObject.Create;
      json_indent := TJSONObject.Create;
      json_trailingData := TJSONObject.Create;
      json_spread := TJSONObject.Create;
      json_nested1 := TJSONObject.Create;

      if pso_input.pso_quantity > 0 then json_base.Add('quantity', pso_input.pso_quantity);
      if pso_input.pso_price >0 then begin
         json_price.Add('nano', (Trunc(Frac(pso_input.pso_price)*1000000000)));
         json_price.Add('units', Trunc(pso_input.pso_price));
         json_base.Add('price', json_price);
      end;
      if pso_input.pso_stopPrice >0 then begin
         json_stopPrice.Add('nano', (Trunc(Frac(pso_input.pso_stopPrice)*1000000000)));
         json_stopPrice.Add('units', Trunc(pso_input.pso_stopPrice));
         json_base.Add('stopPrice', json_stopPrice);
      end;
      json_base.Add('direction', pso_input.pso_direction);
      json_base.Add('accountId', pso_input.pso_accountId);
      json_base.Add('expirationType', pso_input.pso_expirationType);
      json_base.Add('stopOrderType', pso_input.pso_stopOrderType);
      if pso_input.pso_expireDate <> '' then json_base.Add('expireDate', pso_input.pso_expireDate);
      json_base.Add('instrumentId', pso_input.pso_instrumentId);
      if pso_input.pso_exchangeOrderType <> '' then json_base.Add('exchangeOrderType', pso_input.pso_exchangeOrderType);
      if pso_input.pso_takeProfitType <> '' then json_base.Add('takeProfitType', pso_input.pso_takeProfitType);
      json_indent.Add('nano', (Trunc(Frac(pso_input.pso_trailingData.pso_indent)*1000000000)));
      json_indent.Add('units', Trunc(pso_input.pso_trailingData.pso_indent));
      json_trailingData.Add('indent', json_indent);
      json_trailingData.Add('indentType', pso_input.pso_trailingData.pso_indentType);
      json_spread.Add('nano', (Trunc(Frac(pso_input.pso_trailingData.pso_spread)*1000000000)));
      json_spread.Add('units', Trunc(pso_input.pso_trailingData.pso_spread));
      json_trailingData.Add('spread', json_spread);
      json_trailingData.Add('spreadType', pso_input.pso_trailingData.pso_spreadType);
      json_nested1.Add('trailingData', json_trailingData);
      if pso_input.pso_orderId <> '' then json_base.Add('orderId', pso_input.pso_orderId);
      if pso_input.pso_confirmMarginTrade <> false then json_base.Add('confirmMarginTrade', pso_input.pso_confirmMarginTrade);

      json_request := json_base.AsJSON;

      endpoint_url := url_tinvest + 'StopOrdersService/PostStopOrder';

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + pso_input.pso_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.StopOrdersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            pso_output.pso_error_code := JSN.FindPath('code').AsInt64;
            pso_output.pso_error_message := JSN.FindPath('message').AsString;
            pso_output.pso_error_description := JSN.FindPath('description').AsInt64;
         end;

         if pso_output.pso_error_description = 0 then begin
            pso_output.pso_stopOrderId := JSN.FindPath('stopOrderId').AsString;
            pso_output.pso_orderRequestId := JSN.FindPath('orderRequestId').AsString;
            pso_output.pso_responseMetadata.pso_trackingId := JSN.FindPath('responseMetadata.trackingId').AsString;
            pso_output.pso_responseMetadata.pso_serverTime := JSN.FindPath('responseMetadata.serverTime').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetStopOrders(gso_input : gso_request; out gso_output : gso_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, stoporders_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.StopOrdersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.StopOrdersService_limit.h_ratelimit_reset * 1000);
        requests_limit.StopOrdersService_limit.h_ratelimit_remaining := requests_limit.StopOrdersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      json_base.Add('accountId', gso_input.gso_accountId);
      if gso_input.gso_status <> '' then json_base.Add('status', gso_input.gso_status);
      if gso_input.gso_from <> '' then json_base.Add('from', gso_input.gso_from);
      if gso_input.gso_to <> '' then json_base.Add('to', gso_input.gso_to);

      endpoint_url := url_tinvest + 'StopOrdersService/GetStopOrders';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gso_input.gso_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.StopOrdersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gso_output.gso_error_code := JSN.FindPath('code').AsInt64;
            gso_output.gso_error_message := JSN.FindPath('message').AsString;
            gso_output.gso_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gso_output.gso_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('stopOrders'));

            stoporders_count := json_output_array.Count;

            i := 0;

            SetLength(gso_output.gso_stopOrders, stoporders_count);

            while i < stoporders_count do  begin
               gso_output.gso_stopOrders[i].gso_stopOrderId := JSN.FindPath('stopOrders[' + inttostr(i) + '].stopOrderId').AsString;
               gso_output.gso_stopOrders[i].gso_lotsRequested := JSN.FindPath('stopOrders[' + inttostr(i) + '].lotsRequested').AsInt64;
               gso_output.gso_stopOrders[i].gso_figi := JSN.FindPath('stopOrders[' + inttostr(i) + '].figi').AsString;
               gso_output.gso_stopOrders[i].gso_direction := JSN.FindPath('stopOrders[' + inttostr(i) + '].direction').AsString;
               gso_output.gso_stopOrders[i].gso_currency := JSN.FindPath('stopOrders[' + inttostr(i) + '].currency').AsString;
               gso_output.gso_stopOrders[i].gso_orderType := JSN.FindPath('stopOrders[' + inttostr(i) + '].orderType').AsString;
               gso_output.gso_stopOrders[i].gso_createDate := JSN.FindPath('stopOrders[' + inttostr(i) + '].createDate').AsString;
               if JSN.FindPath('stopOrders[' + inttostr(i) + '].activationDateTime') <> nil then
                  gso_output.gso_stopOrders[i].gso_activationDateTime := JSN.FindPath('stopOrders[' + inttostr(i) + '].activationDateTime').AsString;
               if JSN.FindPath('stopOrders[' + inttostr(i) + '].expirationTime') <> nil then
                  gso_output.gso_stopOrders[i].gso_expirationTime := JSN.FindPath('stopOrders[' + inttostr(i) + '].expirationTime').AsString;
               gso_output.gso_stopOrders[i].gso_price.moneyval := UnitsNanoToDouble(JSN.FindPath('stopOrders[' + inttostr(i) + '].price.units').AsInt64 , JSN.FindPath('stopOrders[' + inttostr(i) + '].price.nano').AsInt64);
               gso_output.gso_stopOrders[i].gso_price.currency := JSN.FindPath('stopOrders[' + inttostr(i) + '].price.currency').AsString;
               gso_output.gso_stopOrders[i].gso_stopPrice.moneyval := UnitsNanoToDouble(JSN.FindPath('stopOrders[' + inttostr(i) + '].stopPrice.units').AsInt64 , JSN.FindPath('stopOrders[' + inttostr(i) + '].stopPrice.nano').AsInt64);
               gso_output.gso_stopOrders[i].gso_stopPrice.currency := JSN.FindPath('stopOrders[' + inttostr(i) + '].stopPrice.currency').AsString;
               gso_output.gso_stopOrders[i].gso_instrumentUid := JSN.FindPath('stopOrders[' + inttostr(i) + '].instrumentUid').AsString;
               gso_output.gso_stopOrders[i].gso_takeProfitType := JSN.FindPath('stopOrders[' + inttostr(i) + '].takeProfitType').AsString;
               if JSN.FindPath('stopOrders[' + inttostr(i) + '].trailingData.indent') <> nil then
                  gso_output.gso_stopOrders[i].gso_trailingData.gso_indent := UnitsNanoToDouble(JSN.FindPath('stopOrders[' + inttostr(i) + '].trailingData.indent.units').AsInt64 , JSN.FindPath('stopOrders[' + inttostr(i) + '].trailingData.indent.nano').AsInt64);
               if JSN.FindPath('stopOrders[' + inttostr(i) + '].trailingData.indentType') <> nil then
                  gso_output.gso_stopOrders[i].gso_trailingData.gso_indentType := JSN.FindPath('stopOrders[' + inttostr(i) + '].trailingData.indentType').AsString;
               if JSN.FindPath('stopOrders[' + inttostr(i) + '].trailingData.spread') <> nil then
                  gso_output.gso_stopOrders[i].gso_trailingData.gso_spread := UnitsNanoToDouble(JSN.FindPath('stopOrders[' + inttostr(i) + '].trailingData.spread.units').AsInt64 , JSN.FindPath('stopOrders[' + inttostr(i) + '].trailingData.spread.nano').AsInt64);
               if JSN.FindPath('stopOrders[' + inttostr(i) + '].trailingData.spreadType') <> nil then
                  gso_output.gso_stopOrders[i].gso_trailingData.gso_spreadType := JSN.FindPath('stopOrders[' + inttostr(i) + '].trailingData.spreadType').AsString;
               gso_output.gso_stopOrders[i].gso_status := JSN.FindPath('stopOrders[' + inttostr(i) + '].status').AsString;
               gso_output.gso_stopOrders[i].gso_exchangeOrderType := JSN.FindPath('stopOrders[' + inttostr(i) + '].exchangeOrderType').AsString;
               if JSN.FindPath('stopOrders[' + inttostr(i) + '].exchangeOrderId') <> nil then
                  gso_output.gso_stopOrders[i].gso_exchangeOrderId := JSN.FindPath('stopOrders[' + inttostr(i) + '].exchangeOrderId').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;


procedure CancelStopOrder(cso_input : cso_request; out cso_output : cso_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.StopOrdersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.StopOrdersService_limit.h_ratelimit_reset * 1000);
        requests_limit.StopOrdersService_limit.h_ratelimit_remaining := requests_limit.StopOrdersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_base.Add('accountId', cso_input.cso_accountId);
      json_base.Add('stopOrderId', cso_input.cso_stopOrderId);

      endpoint_url := url_tinvest + 'StopOrdersService/CancelStopOrder';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + cso_input.cso_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.StopOrdersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            cso_output.cso_error_code := JSN.FindPath('code').AsInt64;
            cso_output.cso_error_message := JSN.FindPath('message').AsString;
            cso_output.cso_error_description := JSN.FindPath('description').AsInt64;
         end;

         if cso_output.cso_error_description = 0 then begin
            cso_output.cso_time := JSN.FindPath('time').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetLastTrades (glt_input : glt_request; out glt_output : glt_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, trades_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.MarketDataService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.MarketDataService_limit.h_ratelimit_reset * 1000);
        requests_limit.MarketDataService_limit.h_ratelimit_remaining := requests_limit.MarketDataService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      json_base.Add('from', glt_input.glt_from);
      json_base.Add('to', glt_input.glt_to);
      json_base.Add('instrumentId', glt_input.glt_instrumentId);
      if glt_input.glt_tradeSource <> '' then json_base.Add('tradeSource', glt_input.glt_tradeSource);

      endpoint_url := url_tinvest + 'MarketDataService/GetLastTrades';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + glt_input.glt_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.MarketDataService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            glt_output.glt_error_code := JSN.FindPath('code').AsInt64;
            glt_output.glt_error_message := JSN.FindPath('message').AsString;
            glt_output.glt_error_description := JSN.FindPath('description').AsInt64;
         end;

         if glt_output.glt_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('trades'));

            trades_count := json_output_array.Count;

            i := 0;

            SetLength(glt_output.glt_trades, trades_count);

            while i < trades_count do  begin
               glt_output.glt_trades[i].glt_figi := JSN.FindPath('trades[' + inttostr(i) + '].figi').AsString;
               glt_output.glt_trades[i].glt_direction := JSN.FindPath('trades[' + inttostr(i) + '].direction').AsString;
               glt_output.glt_trades[i].glt_price := UnitsNanoToDouble(JSN.FindPath('trades[' + inttostr(i) + '].price.units').AsInt64 , JSN.FindPath('trades[' + inttostr(i) + '].price.nano').AsInt64);
               glt_output.glt_trades[i].glt_quantity := JSN.FindPath('trades[' + inttostr(i) + '].quantity').AsInt64;
               glt_output.glt_trades[i].glt_time := JSN.FindPath('trades[' + inttostr(i) + '].time').AsString;
               glt_output.glt_trades[i].glt_instrumentUid := JSN.FindPath('trades[' + inttostr(i) + '].instrumentUid').AsString;
               glt_output.glt_trades[i].glt_tradeSource := JSN.FindPath('trades[' + inttostr(i) + '].tradeSource').AsString;
               glt_output.glt_trades[i].glt_ticker := JSN.FindPath('trades[' + inttostr(i) + '].ticker').AsString;
               glt_output.glt_trades[i].glt_classCode := JSN.FindPath('trades[' + inttostr(i) + '].classCode').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetInfo (gi_input : gi_request; out gi_output : gi_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, instruments_count, i : int64;

begin
   try
      if requests_limit.UsersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.UsersService_limit.h_ratelimit_reset * 1000);
        requests_limit.UsersService_limit.h_ratelimit_remaining := requests_limit.UsersService_limit.h_ratelimit_limit - 1;
      end;

      endpoint_url := url_tinvest + 'UsersService/GetInfo';

      json_request := '{}';

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gi_input.gi_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.UsersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gi_output.gi_error_code := JSN.FindPath('code').AsInt64;
            gi_output.gi_error_message := JSN.FindPath('message').AsString;
            gi_output.gi_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gi_output.gi_error_description = 0 then begin
            gi_output.gi_premStatus := JSN.FindPath('premStatus').AsBoolean;
            gi_output.gi_qualStatus := JSN.FindPath('qualStatus').AsBoolean;
            gi_output.gi_tariff := JSN.FindPath('tariff').AsString;
            gi_output.gi_userId := JSN.FindPath('userId').AsString;
            gi_output.gi_riskLevelCode := JSN.FindPath('riskLevelCode').AsString;

            json_output_array := TJSONArray(JSN.FindPath('qualifiedForWorkWith'));

            instruments_count := json_output_array.Count;

            i := 0;

            SetLength(gi_output.gi_qualifiedForWorkWith, instruments_count);

            while i < instruments_count do  begin

               gi_output.gi_qualifiedForWorkWith[i] := JSN.FindPath('qualifiedForWorkWith[' + inttostr(i) + ']').AsString;

               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetMarginAttributes (gma_input : gma_request; out gma_output : gma_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.UsersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.UsersService_limit.h_ratelimit_reset * 1000);
        requests_limit.UsersService_limit.h_ratelimit_remaining := requests_limit.UsersService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      json_base.Add('accountId', gma_input.gma_accountId);

      endpoint_url := url_tinvest + 'UsersService/GetMarginAttributes';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gma_input.gma_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.UsersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gma_output.gma_error_code := JSN.FindPath('code').AsInt64;
            gma_output.gma_error_message := JSN.FindPath('message').AsString;
            gma_output.gma_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gma_output.gma_error_description = 0 then begin
            gma_output.gma_liquidPortfolio.moneyval := UnitsNanoToDouble(JSN.FindPath('liquidPortfolio.units').AsInt64 , JSN.FindPath('liquidPortfolio.nano').AsInt64);
            gma_output.gma_liquidPortfolio.currency := JSN.FindPath('liquidPortfolio.currency').AsString;
            gma_output.gma_startingMargin.moneyval := UnitsNanoToDouble(JSN.FindPath('startingMargin.units').AsInt64 , JSN.FindPath('startingMargin.nano').AsInt64);
            gma_output.gma_startingMargin.currency := JSN.FindPath('startingMargin.currency').AsString;
            gma_output.gma_minimalMargin.moneyval := UnitsNanoToDouble(JSN.FindPath('minimalMargin.units').AsInt64 , JSN.FindPath('minimalMargin.nano').AsInt64);
            gma_output.gma_minimalMargin.currency := JSN.FindPath('minimalMargin.currency').AsString;
            gma_output.gma_fundsSufficiencyLevel := UnitsNanoToDouble(JSN.FindPath('fundsSufficiencyLevel.units').AsInt64 , JSN.FindPath('fundsSufficiencyLevel.nano').AsInt64);
            gma_output.gma_amountOfMissingFunds.moneyval := UnitsNanoToDouble(JSN.FindPath('amountOfMissingFunds.units').AsInt64 , JSN.FindPath('amountOfMissingFunds.nano').AsInt64);
            gma_output.gma_amountOfMissingFunds.currency := JSN.FindPath('amountOfMissingFunds.currency').AsString;
            gma_output.gma_correctedMargin.moneyval := UnitsNanoToDouble(JSN.FindPath('correctedMargin.units').AsInt64 , JSN.FindPath('correctedMargin.nano').AsInt64);
            gma_output.gma_correctedMargin.currency := JSN.FindPath('correctedMargin.currency').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure CreateFavoriteGroup (cfg_input : cfg_request; out cfg_output : cfg_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      json_base.Add('groupName', cfg_input.cfg_groupName);
      json_base.Add('groupColor', cfg_input.cfg_groupColor);
      json_base.Add('note', cfg_input.cfg_note);

      endpoint_url := url_tinvest + 'InstrumentsService/CreateFavoriteGroup';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + cfg_input.cfg_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            cfg_output.cfg_error_code := JSN.FindPath('code').AsInt64;
            cfg_output.cfg_error_message := JSN.FindPath('message').AsString;
            cfg_output.cfg_error_description := JSN.FindPath('description').AsInt64;
         end;

         if cfg_output.cfg_error_description = 0 then begin
            cfg_output.cfg_groupId := JSN.FindPath('groupId').AsString;
            cfg_output.cfg_groupName := JSN.FindPath('groupName').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure DeleteFavoriteGroup (dfg_input : dfg_request; out dfg_output : dfg_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_base.Add('groupName', dfg_input.dfg_groupId);

      endpoint_url := url_tinvest + 'InstrumentsService/DeleteFavoriteGroup';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + dfg_input.dfg_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            dfg_output.dfg_error_code := JSN.FindPath('code').AsInt64;
            dfg_output.dfg_error_message := JSN.FindPath('message').AsString;
            dfg_output.dfg_error_description := JSN.FindPath('description').AsInt64;
         end;

         if dfg_output.dfg_error_description = 0 then begin
            // что сюда добавить?
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetFavoriteGroups (gfg_input : gfg_request; out gfg_output : gfg_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, instrumentId_count, excludedGroupId_count, groups_count, i : int64;
   json_base : TJSONObject;
   json_input_array_instrumentId, json_input_array_excludedGroupId : TJSONArray;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_input_array_instrumentId := TJSONArray.Create;
      json_input_array_excludedGroupId := TJSONArray.Create;

      instrumentId_count := high(gfg_input.gfg_instrumentId);
      for i := 0 to instrumentId_count do begin
         json_input_array_instrumentId.Add(gfg_input.gfg_instrumentId[i]);
      end;
      if instrumentId_count > 0 then json_base.Add('instrumentId', json_input_array_instrumentId);

      excludedGroupId_count := high(gfg_input.gfg_excludedGroupId);
      for i := 0 to excludedGroupId_count do begin
         json_input_array_excludedGroupId.Add(gfg_input.gfg_excludedGroupId[i]);
      end;
      if excludedGroupId_count > 0 then json_base.Add('excludedGroupId', json_input_array_excludedGroupId);

      endpoint_url := url_tinvest + 'InstrumentsService/GetFavoriteGroups';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gfg_input.gfg_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gfg_output.gfg_error_code := JSN.FindPath('code').AsInt64;
            gfg_output.gfg_error_message := JSN.FindPath('message').AsString;
            gfg_output.gfg_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gfg_output.gfg_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('groups'));

            groups_count := json_output_array.Count;

            i := 0;

            SetLength(gfg_output.gfg_groups, groups_count);

            while i < groups_count do  begin
               gfg_output.gfg_groups[i].gfg_groupId := JSN.FindPath('groups[' + inttostr(i) + '].groupId').AsString;
               gfg_output.gfg_groups[i].gfg_groupName := JSN.FindPath('groups[' + inttostr(i) + '].groupName').AsString;
               gfg_output.gfg_groups[i].gfg_color := JSN.FindPath('groups[' + inttostr(i) + '].color').AsString;
               gfg_output.gfg_groups[i].gfg_size := JSN.FindPath('groups[' + inttostr(i) + '].size').AsInt64;
               if JSN.FindPath('groups[' + inttostr(i) + '].containsInstrument') <> nil then
                  gfg_output.gfg_groups[i].gfg_containsInstrument := JSN.FindPath('groups[' + inttostr(i) + '].containsInstrument').AsBoolean;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetAccruedInterests (gai_input : gai_request; out gai_output : gai_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, accruedInterests_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      json_base.Add('from', gai_input.gai_from);
      json_base.Add('to', gai_input.gai_to);
      json_base.Add('instrumentId', gai_input.gai_instrumentId);

      endpoint_url := url_tinvest + 'InstrumentsService/GetAccruedInterests';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gai_input.gai_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gai_output.gai_error_code := JSN.FindPath('code').AsInt64;
            gai_output.gai_error_message := JSN.FindPath('message').AsString;
            gai_output.gai_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gai_output.gai_error_description = 0 then begin


            json_output_array := TJSONArray(JSN.FindPath('accruedInterests'));

            accruedInterests_count := json_output_array.Count;

            i := 0;

            SetLength(gai_output.gai_accruedInterests, accruedInterests_count);

            while i < accruedInterests_count do  begin
               gai_output.gai_accruedInterests[i].gai_date := JSN.FindPath('accruedInterests[' + inttostr(i) + '].date').AsString;
               gai_output.gai_accruedInterests[i].gai_value := UnitsNanoToDouble(JSN.FindPath('accruedInterests[' + inttostr(i) + '].value.units').AsInt64 , JSN.FindPath('accruedInterests[' + inttostr(i) + '].value.nano').AsInt64);
               gai_output.gai_accruedInterests[i].gai_valuePercent := UnitsNanoToDouble(JSN.FindPath('accruedInterests[' + inttostr(i) + '].valuePercent.units').AsInt64 , JSN.FindPath('accruedInterests[' + inttostr(i) + '].valuePercent.nano').AsInt64);
               gai_output.gai_accruedInterests[i].gai_nominal := UnitsNanoToDouble(JSN.FindPath('accruedInterests[' + inttostr(i) + '].nominal.units').AsInt64 , JSN.FindPath('accruedInterests[' + inttostr(i) + '].nominal.nano').AsInt64);
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure TradingSchedules (ts_input : ts_request; out ts_output : ts_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, exchanges_count, days_count, intervals_count, i, j, k : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if ts_input.ts_exchange <> '' then json_base.Add('exchange', ts_input.ts_exchange);
      if ts_input.ts_from <> '' then json_base.Add('from', ts_input.ts_from);
      if ts_input.ts_to <> '' then json_base.Add('to', ts_input.ts_to);

      endpoint_url := url_tinvest + 'InstrumentsService/TradingSchedules';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + ts_input.ts_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            ts_output.ts_error_code := JSN.FindPath('code').AsInt64;
            ts_output.ts_error_message := JSN.FindPath('message').AsString;
            ts_output.ts_error_description := JSN.FindPath('description').AsInt64;
         end;

         if ts_output.ts_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('exchanges'));

            exchanges_count := json_output_array.Count;

            i := 0;

            SetLength(ts_output.ts_exchanges, exchanges_count);

            while i < exchanges_count do  begin

               ts_output.ts_exchanges[i].ts_exchange := JSN.FindPath('exchanges[' + inttostr(i) + '].exchange').AsString;

               json_output_array := TJSONArray(JSN.FindPath('exchanges[' + inttostr(i) + '].days'));

               days_count := json_output_array.Count;

               j := 0;

               SetLength(ts_output.ts_exchanges[i].ts_days, days_count);

               while j < days_count do  begin
                  ts_output.ts_exchanges[i].ts_days[j].ts_date := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].date').AsString;
                  ts_output.ts_exchanges[i].ts_days[j].ts_isTradingDay := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].isTradingDay').AsBoolean;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].startTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_startTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].startTime').AsString;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].endTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_endTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].endTime').AsString;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].openingAuctionStartTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_openingAuctionStartTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].openingAuctionStartTime').AsString;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].closingAuctionEndTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_closingAuctionEndTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].closingAuctionEndTime').AsString;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].eveningOpeningAuctionStartTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_eveningOpeningAuctionStartTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].eveningOpeningAuctionStartTime').AsString;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].eveningStartTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_eveningStartTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].eveningStartTime').AsString;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].eveningEndTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_eveningEndTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].eveningEndTime').AsString;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].clearingStartTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_clearingStartTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].clearingStartTime').AsString;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].clearingEndTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_clearingEndTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].clearingEndTime').AsString;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].premarketStartTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_premarketStartTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].premarketStartTime').AsString;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].premarketEndTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_premarketEndTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].premarketEndTime').AsString;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].closingAuctionStartTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_closingAuctionStartTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].closingAuctionStartTime').AsString;
                  if JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].openingAuctionEndTime') <> nil then
                     ts_output.ts_exchanges[i].ts_days[j].ts_openingAuctionEndTime := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].openingAuctionEndTime').AsString;

                  json_output_array := TJSONArray(JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].intervals'));

                  intervals_count := json_output_array.Count;

                  k := 0;

                  SetLength(ts_output.ts_exchanges[i].ts_days[j].ts_intervals, intervals_count);

                     while k < intervals_count do  begin
                        ts_output.ts_exchanges[i].ts_days[j].ts_intervals[k].ts_type := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].intervals[' + inttostr(k) + '].type').AsString;
                        ts_output.ts_exchanges[i].ts_days[j].ts_intervals[k].ts_interval.ts_startTs := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].intervals[' + inttostr(k) + '].interval.startTs').AsString;
                        ts_output.ts_exchanges[i].ts_days[j].ts_intervals[k].ts_interval.ts_endTs := JSN.FindPath('exchanges[' + inttostr(i) + '].days[' + inttostr(j) + '].intervals[' + inttostr(k) + '].interval.endTs').AsString;
                        inc(k);
                     end;
                  inc(j);
               end;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetUserTariff (gut_input : gut_request; out gut_output : gut_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, unaryLimits_count, streamLimits_count, methods_count, streams_count, i, j, k ,l : int64;

begin
   try
      if requests_limit.UsersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.UsersService_limit.h_ratelimit_reset * 1000);
        requests_limit.UsersService_limit.h_ratelimit_remaining := requests_limit.UsersService_limit.h_ratelimit_limit - 1;
      end;

      endpoint_url := url_tinvest + 'UsersService/GetUserTariff';

      json_request := '{}';

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gut_input.gut_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.UsersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gut_output.gut_error_code := JSN.FindPath('code').AsInt64;
            gut_output.gut_error_message := JSN.FindPath('message').AsString;
            gut_output.gut_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gut_output.gut_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('unaryLimits'));

            unaryLimits_count := json_output_array.Count;

            i := 0;
            SetLength(gut_output.gut_unaryLimits, unaryLimits_count);

            while i < unaryLimits_count do  begin
               gut_output.gut_unaryLimits[i].gut_limitPerMinute := JSN.FindPath('unaryLimits[' + inttostr(i) + '].limitPerMinute').AsInt64;

               json_output_array := TJSONArray(JSN.FindPath('unaryLimits[' + inttostr(i) + '].methods'));

               j := 0;

               methods_count := json_output_array.Count;
               SetLength(gut_output.gut_unaryLimits[i].gut_methods, methods_count);

               while j < methods_count do  begin
                  gut_output.gut_unaryLimits[i].gut_methods[j] := JSN.FindPath('unaryLimits[' + inttostr(i) + '].methods[' + inttostr(j) + ']').AsString;
                  inc(j);
               end;

               if JSN.FindPath('unaryLimits[' + inttostr(i) + '].limitPerSecond') <> nil then
                  gut_output.gut_unaryLimits[i].gut_limitPerSecond := JSN.FindPath('unaryLimits[' + inttostr(i) + '].limitPerSecond').AsInt64;

               inc(i);
            end;

            json_output_array := TJSONArray(JSN.FindPath('streamLimits'));

            streamLimits_count := json_output_array.Count;

            k := 0;
            SetLength(gut_output.gut_streamLimits, streamLimits_count);

            while k < streamLimits_count do  begin
               if JSN.FindPath('streamLimits[' + inttostr(k) + '].limit') <> nil then
                  gut_output.gut_streamLimits[k].gut_limit := JSN.FindPath('streamLimits[' + inttostr(k) + '].limit').AsInt64;

               json_output_array := TJSONArray(JSN.FindPath('streamLimits[' + inttostr(k) + '].streams'));

               l := 0;

               streams_count := json_output_array.Count;
               SetLength(gut_output.gut_streamLimits[k].gut_streams, streams_count);

               while l < streams_count do  begin
                  gut_output.gut_streamLimits[k].gut_streams[l] := JSN.FindPath('streamLimits[' + inttostr(k) + '].streams[' + inttostr(l) + ']').AsString;
                  inc(l);
               end;

               gut_output.gut_streamLimits[k].gut_open := JSN.FindPath('streamLimits[' + inttostr(k) + '].open').AsInt64;

               inc(k);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetBankAccounts (gba_input : gba_request; out gba_output : gba_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, bankAccounts_count, money_count, i, j : int64;

begin
   try
      if requests_limit.UsersService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.UsersService_limit.h_ratelimit_reset * 1000);
        requests_limit.UsersService_limit.h_ratelimit_remaining := requests_limit.UsersService_limit.h_ratelimit_limit - 1;
      end;

      endpoint_url := url_tinvest + 'UsersService/GetBankAccounts';

      json_request := '{}';

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gba_input.gba_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.UsersService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gba_output.gba_error_code := JSN.FindPath('code').AsInt64;
            gba_output.gba_error_message := JSN.FindPath('message').AsString;
            gba_output.gba_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gba_output.gba_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('bankAccounts'));

            bankAccounts_count := json_output_array.Count;

            i := 0;

            SetLength(gba_output.gba_bankAccounts, bankAccounts_count);

            while i < bankAccounts_count do  begin
               gba_output.gba_bankAccounts[i].gba_id := JSN.FindPath('bankAccounts[' + inttostr(i) + '].id').AsString;
               gba_output.gba_bankAccounts[i].gba_name := JSN.FindPath('bankAccounts[' + inttostr(i) + '].name').AsString;

               json_output_array := TJSONArray(JSN.FindPath('bankAccounts[' + inttostr(i) + '].money'));

               money_count := json_output_array.Count;

               j := 0;

               SetLength(gba_output.gba_bankAccounts[i].gba_money, money_count);

               while j < money_count do  begin
                  gba_output.gba_bankAccounts[i].gba_money[j].moneyval := UnitsNanoToDouble(JSN.FindPath('bankAccounts[' + inttostr(i) + '].money[' + inttostr(j) + '].units').AsInt64 , JSN.FindPath('bankAccounts[' + inttostr(i) + '].money[' + inttostr(j) + '].nano').AsInt64);
                  gba_output.gba_bankAccounts[i].gba_money[j].currency := JSN.FindPath('bankAccounts[' + inttostr(i) + '].money[' + inttostr(j) + '].currency').AsString;
                  inc(j);
               end;

               gba_output.gba_bankAccounts[i].gba_openedDate := JSN.FindPath('bankAccounts[' + inttostr(i) + '].openedDate').AsString;
               gba_output.gba_bankAccounts[i].gba_type := JSN.FindPath('bankAccounts[' + inttostr(i) + '].type').AsString;

               inc(i);
            end;

         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure Currencies (c_input : c_request; out c_output : c_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, cur_count, tests_count, i, j : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if c_input.c_instrumentStatus <> '' then json_base.Add('instrumentStatus', c_input.c_instrumentStatus);
      if c_input.c_instrumentExchange <> '' then json_base.Add('instrumentExchange', c_input.c_instrumentExchange);

      endpoint_url := url_tinvest + 'InstrumentsService/Currencies';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + c_input.c_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            c_output.c_error_code := JSN.FindPath('code').AsInt64;
            c_output.c_error_message := JSN.FindPath('message').AsString;
            c_output.c_error_description := JSN.FindPath('description').AsInt64;
         end;

         if c_output.c_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('instruments'));
            cur_count := json_output_array.Count;
            SetLength(c_output.c_instruments, cur_count);

            i := 0;

            while i < cur_count do  begin
               c_output.c_instruments[i].c_figi := JSN.FindPath('instruments[' + inttostr(i) + '].figi').AsString;
               c_output.c_instruments[i].c_ticker := JSN.FindPath('instruments[' + inttostr(i) + '].ticker').AsString;
               c_output.c_instruments[i].c_classCode := JSN.FindPath('instruments[' + inttostr(i) + '].classCode').AsString;
               c_output.c_instruments[i].c_isin := JSN.FindPath('instruments[' + inttostr(i) + '].isin').AsString;
               c_output.c_instruments[i].c_lot := JSN.FindPath('instruments[' + inttostr(i) + '].lot').AsInt64;
               c_output.c_instruments[i].c_currency := JSN.FindPath('instruments[' + inttostr(i) + '].currency').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].klong') <> nil then
                  c_output.c_instruments[i].c_klong := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].klong.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].klong.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].kshort') <> nil then
                  c_output.c_instruments[i].c_kshort := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].kshort.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].kshort.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlong') <> nil then
                  c_output.c_instruments[i].c_dlong := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlong.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlong.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshort') <> nil then
                  c_output.c_instruments[i].c_dshort := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshort.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshort.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin') <> nil then
                  c_output.c_instruments[i].c_dlongMin := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin') <> nil then
                  c_output.c_instruments[i].c_dshortMin := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.nano').AsInt64);
               c_output.c_instruments[i].c_shortEnabledFlag := JSN.FindPath('instruments[' + inttostr(i) + '].shortEnabledFlag').AsBoolean;
               c_output.c_instruments[i].c_name := JSN.FindPath('instruments[' + inttostr(i) + '].name').AsString;
               c_output.c_instruments[i].c_exchange := JSN.FindPath('instruments[' + inttostr(i) + '].exchange').AsString;
               c_output.c_instruments[i].c_nominal.currency := JSN.FindPath('instruments[' + inttostr(i) + '].nominal.currency').AsString;
               c_output.c_instruments[i].c_nominal.moneyval := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].nominal.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].nominal.nano').AsInt64);
               c_output.c_instruments[i].c_countryOfRisk := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRisk').AsString;
               c_output.c_instruments[i].c_countryOfRiskName := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRiskName').AsString;
               c_output.c_instruments[i].c_tradingStatus := JSN.FindPath('instruments[' + inttostr(i) + '].tradingStatus').AsString;
               c_output.c_instruments[i].c_otcFlag := JSN.FindPath('instruments[' + inttostr(i) + '].otcFlag').AsBoolean;
               c_output.c_instruments[i].c_buyAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].buyAvailableFlag').AsBoolean;
               c_output.c_instruments[i].c_sellAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].sellAvailableFlag').AsBoolean;
               c_output.c_instruments[i].c_isoCurrencyName := JSN.FindPath('instruments[' + inttostr(i) + '].isoCurrencyName').AsString;
               c_output.c_instruments[i].c_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.nano').AsInt64);
               c_output.c_instruments[i].c_apiTradeAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].apiTradeAvailableFlag').AsBoolean;
               c_output.c_instruments[i].c_uid := JSN.FindPath('instruments[' + inttostr(i) + '].uid').AsString;
               c_output.c_instruments[i].c_realExchange := JSN.FindPath('instruments[' + inttostr(i) + '].realExchange').AsString;
               c_output.c_instruments[i].c_positionUid := JSN.FindPath('instruments[' + inttostr(i) + '].positionUid').AsString;

               json_output_array := TJSONArray(JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests'));
               tests_count := json_output_array.Count;
               SetLength(c_output.c_instruments[i].c_requiredTests, tests_count);

               j := 0;

               while j < tests_count do  begin
                  c_output.c_instruments[i].c_requiredTests[j] := JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests[' + inttostr(j) + ']').AsString;
                  inc(j);
               end;

               c_output.c_instruments[i].c_forIisFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forIisFlag').AsBoolean;
               c_output.c_instruments[i].c_forQualInvestorFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forQualInvestorFlag').AsBoolean;
               c_output.c_instruments[i].c_weekendFlag := JSN.FindPath('instruments[' + inttostr(i) + '].weekendFlag').AsBoolean;
               c_output.c_instruments[i].c_blockedTcaFlag := JSN.FindPath('instruments[' + inttostr(i) + '].blockedTcaFlag').AsBoolean;
               if JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate') <> nil then
                  c_output.c_instruments[i].c_first1minCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate') <> nil then
                  c_output.c_instruments[i].c_first1dayCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate').AsString;
               c_output.c_instruments[i].c_brand.c_logoName := JSN.FindPath('instruments[' + inttostr(i) + '].brand.logoName').AsString;
               c_output.c_instruments[i].c_brand.c_logoBaseColor := JSN.FindPath('instruments[' + inttostr(i) + '].brand.logoBaseColor').AsString;
               c_output.c_instruments[i].c_brand.c_textColor := JSN.FindPath('instruments[' + inttostr(i) + '].brand.textColor').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient') <> nil then
                  c_output.c_instruments[i].c_dlongClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient') <> nil then
                  c_output.c_instruments[i].c_dshortClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.nano').AsInt64);

               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure CurrencyBy (cb_input : cb_request; out cb_output : cb_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, tests_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      json_base.Add('idType', cb_input.cb_idType);
      if cb_input.cb_idType = 'INSTRUMENT_ID_TYPE_TICKER' then json_base.Add('classCode', cb_input.cb_classCode);
      json_base.Add('id', cb_input.cb_id);

      endpoint_url := url_tinvest + 'InstrumentsService/CurrencyBy';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + cb_input.cb_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            cb_output.cb_error_code := JSN.FindPath('code').AsInt64;
            cb_output.cb_error_message := JSN.FindPath('message').AsString;
            cb_output.cb_error_description := JSN.FindPath('description').AsInt64;
         end;

         if cb_output.cb_error_description = 0 then begin

            cb_output.cb_instrument.c_figi := JSN.FindPath('instrument.figi').AsString;
            cb_output.cb_instrument.c_ticker := JSN.FindPath('instrument.ticker').AsString;
            cb_output.cb_instrument.c_classCode := JSN.FindPath('instrument.classCode').AsString;
            cb_output.cb_instrument.c_isin := JSN.FindPath('instrument.isin').AsString;
            cb_output.cb_instrument.c_lot := JSN.FindPath('instrument.lot').AsInt64;
            cb_output.cb_instrument.c_currency := JSN.FindPath('instrument.currency').AsString;
            if JSN.FindPath('instrument.klong') <> nil then
               cb_output.cb_instrument.c_klong := UnitsNanoToDouble(JSN.FindPath('instrument.klong.units').AsInt64 , JSN.FindPath('instrument.klong.nano').AsInt64);
            if JSN.FindPath('instrument.kshort') <> nil then
               cb_output.cb_instrument.c_kshort := UnitsNanoToDouble(JSN.FindPath('instrument.kshort.units').AsInt64 , JSN.FindPath('instrument.kshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlong') <> nil then
               cb_output.cb_instrument.c_dlong := UnitsNanoToDouble(JSN.FindPath('instrument.dlong.units').AsInt64 , JSN.FindPath('instrument.dlong.nano').AsInt64);
            if JSN.FindPath('instrument.dshort') <> nil then
               cb_output.cb_instrument.c_dshort := UnitsNanoToDouble(JSN.FindPath('instrument.dshort.units').AsInt64 , JSN.FindPath('instrument.dshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlongMin') <> nil then
               cb_output.cb_instrument.c_dlongMin := UnitsNanoToDouble(JSN.FindPath('instrument.dlongMin.units').AsInt64 , JSN.FindPath('instrument.dlongMin.nano').AsInt64);
            if JSN.FindPath('instrument.dshortMin') <> nil then
               cb_output.cb_instrument.c_dshortMin := UnitsNanoToDouble(JSN.FindPath('instrument.dshortMin.units').AsInt64 , JSN.FindPath('instrument.dshortMin.nano').AsInt64);
            cb_output.cb_instrument.c_shortEnabledFlag := JSN.FindPath('instrument.shortEnabledFlag').AsBoolean;
            cb_output.cb_instrument.c_name := JSN.FindPath('instrument.name').AsString;
            cb_output.cb_instrument.c_exchange := JSN.FindPath('instrument.exchange').AsString;
            cb_output.cb_instrument.c_nominal.currency := JSN.FindPath('instrument.nominal.currency').AsString;
            cb_output.cb_instrument.c_nominal.moneyval := UnitsNanoToDouble(JSN.FindPath('instrument.nominal.units').AsInt64 , JSN.FindPath('instrument.nominal.nano').AsInt64);
            cb_output.cb_instrument.c_countryOfRisk := JSN.FindPath('instrument.countryOfRisk').AsString;
            cb_output.cb_instrument.c_countryOfRiskName := JSN.FindPath('instrument.countryOfRiskName').AsString;
            cb_output.cb_instrument.c_tradingStatus := JSN.FindPath('instrument.tradingStatus').AsString;
            cb_output.cb_instrument.c_otcFlag := JSN.FindPath('instrument.otcFlag').AsBoolean;
            cb_output.cb_instrument.c_buyAvailableFlag := JSN.FindPath('instrument.buyAvailableFlag').AsBoolean;
            cb_output.cb_instrument.c_sellAvailableFlag := JSN.FindPath('instrument.sellAvailableFlag').AsBoolean;
            cb_output.cb_instrument.c_isoCurrencyName := JSN.FindPath('instrument.isoCurrencyName').AsString;
            cb_output.cb_instrument.c_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instrument.minPriceIncrement.units').AsInt64 , JSN.FindPath('instrument.minPriceIncrement.nano').AsInt64);
            cb_output.cb_instrument.c_apiTradeAvailableFlag := JSN.FindPath('instrument.apiTradeAvailableFlag').AsBoolean;
            cb_output.cb_instrument.c_uid := JSN.FindPath('instrument.uid').AsString;
            cb_output.cb_instrument.c_realExchange := JSN.FindPath('instrument.realExchange').AsString;
            cb_output.cb_instrument.c_positionUid := JSN.FindPath('instrument.positionUid').AsString;

            json_output_array := TJSONArray(JSN.FindPath('instrument.requiredTests'));
            tests_count := json_output_array.Count;
            SetLength(cb_output.cb_instrument.c_requiredTests, tests_count);

            i := 0;

            while i < tests_count do  begin
               cb_output.cb_instrument.c_requiredTests[i] := JSN.FindPath('instrument.requiredTests[' + inttostr(i) + ']').AsString;
               inc(i);
            end;

            cb_output.cb_instrument.c_forIisFlag := JSN.FindPath('instrument.forIisFlag').AsBoolean;
            cb_output.cb_instrument.c_forQualInvestorFlag := JSN.FindPath('instrument.forQualInvestorFlag').AsBoolean;
            cb_output.cb_instrument.c_weekendFlag := JSN.FindPath('instrument.weekendFlag').AsBoolean;
            cb_output.cb_instrument.c_blockedTcaFlag := JSN.FindPath('instrument.blockedTcaFlag').AsBoolean;
            if JSN.FindPath('instrument.first1minCandleDate') <> nil then
               cb_output.cb_instrument.c_first1minCandleDate := JSN.FindPath('instrument.first1minCandleDate').AsString;
            if JSN.FindPath('instrument.first1dayCandleDate') <> nil then
               cb_output.cb_instrument.c_first1dayCandleDate := JSN.FindPath('instrument.first1dayCandleDate').AsString;
            cb_output.cb_instrument.c_brand.c_logoName := JSN.FindPath('instrument.brand.logoName').AsString;
            cb_output.cb_instrument.c_brand.c_logoBaseColor := JSN.FindPath('instrument.brand.logoBaseColor').AsString;
            cb_output.cb_instrument.c_brand.c_textColor := JSN.FindPath('instrument.brand.textColor').AsString;
            if JSN.FindPath('instrument.dlongClient') <> nil then
               cb_output.cb_instrument.c_dlongClient := UnitsNanoToDouble(JSN.FindPath('instrument.dlongClient.units').AsInt64 , JSN.FindPath('instrument.dlongClient.nano').AsInt64);
            if JSN.FindPath('instrument.dshortClient') <> nil then
               cb_output.cb_instrument.c_dshortClient := UnitsNanoToDouble(JSN.FindPath('instrument.dshortClient.units').AsInt64 , JSN.FindPath('instrument.dshortClient.nano').AsInt64);

         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetBondCoupons (gbc_input : gbc_request; out gbc_output : gbc_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, events_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if gbc_input.gbc_from <> '' then json_base.Add('from', gbc_input.gbc_from);
      if gbc_input.gbc_to <> '' then json_base.Add('to', gbc_input.gbc_to);
      json_base.Add('instrumentId', gbc_input.gbc_instrumentId);

      endpoint_url := url_tinvest + 'InstrumentsService/GetBondCoupons';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gbc_input.gbc_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gbc_output.gbc_error_code := JSN.FindPath('code').AsInt64;
            gbc_output.gbc_error_message := JSN.FindPath('message').AsString;
            gbc_output.gbc_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gbc_output.gbc_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('events'));

            events_count := json_output_array.Count;
            SetLength(gbc_output.gbc_events, events_count);

            i := 0;

            while i < events_count do  begin
               gbc_output.gbc_events[i].gbc_figi := JSN.FindPath('events[' + inttostr(i) + '].figi').AsString;
               gbc_output.gbc_events[i].gbc_couponDate := JSN.FindPath('events[' + inttostr(i) + '].couponDate').AsString;
               gbc_output.gbc_events[i].gbc_couponNumber := JSN.FindPath('events[' + inttostr(i) + '].couponNumber').AsInt64;
               gbc_output.gbc_events[i].gbc_fixDate := JSN.FindPath('events[' + inttostr(i) + '].fixDate').AsString;
               gbc_output.gbc_events[i].gbc_payOneBond.currency := JSN.FindPath('events[' + inttostr(i) + '].payOneBond.currency').AsString;
               gbc_output.gbc_events[i].gbc_payOneBond.moneyval := UnitsNanoToDouble(JSN.FindPath('events[' + inttostr(i) + '].payOneBond.units').AsInt64 , JSN.FindPath('events[' + inttostr(i) + '].payOneBond.nano').AsInt64);
               gbc_output.gbc_events[i].gbc_couponType := JSN.FindPath('events[' + inttostr(i) + '].couponType').AsString;
               gbc_output.gbc_events[i].gbc_couponStartDate := JSN.FindPath('events[' + inttostr(i) + '].couponStartDate').AsString;
               gbc_output.gbc_events[i].gbc_couponEndDate := JSN.FindPath('events[' + inttostr(i) + '].couponEndDate').AsString;
               gbc_output.gbc_events[i].gbc_couponPeriod := JSN.FindPath('events[' + inttostr(i) + '].couponPeriod').AsInt64;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetBondEvents (gbe_input : gbe_request; out gbe_output : gbe_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, events_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if gbe_input.gbe_from <> '' then json_base.Add('from', gbe_input.gbe_from);
      if gbe_input.gbe_to <> '' then json_base.Add('to', gbe_input.gbe_to);
      if gbe_input.gbe_type <> '' then json_base.Add('type', gbe_input.gbe_type);
      json_base.Add('instrumentId', gbe_input.gbe_instrumentId);

      endpoint_url := url_tinvest + 'InstrumentsService/GetBondEvents';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gbe_input.gbe_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gbe_output.gbe_error_code := JSN.FindPath('code').AsInt64;
            gbe_output.gbe_error_message := JSN.FindPath('message').AsString;
            gbe_output.gbe_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gbe_output.gbe_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('events'));
            events_count := json_output_array.Count;
            SetLength(gbe_output.gbe_events, events_count);

            i := 0;

            while i < events_count do  begin
               gbe_output.gbe_events[i].gbe_instrumentId := JSN.FindPath('events[' + inttostr(i) + '].instrumentId').AsString;
               gbe_output.gbe_events[i].gbe_eventNumber := JSN.FindPath('events[' + inttostr(i) + '].eventNumber').AsInt64;
               gbe_output.gbe_events[i].gbe_eventDate := JSN.FindPath('events[' + inttostr(i) + '].eventDate').AsString;
               gbe_output.gbe_events[i].gbe_eventType := JSN.FindPath('events[' + inttostr(i) + '].eventType').AsString;
               if JSN.FindPath('events[' + inttostr(i) + '].eventTotalVol.units') <> nil then
                  gbe_output.gbe_events[i].gbe_eventTotalVol := UnitsNanoToDouble(JSN.FindPath('events[' + inttostr(i) + '].eventTotalVol.units').AsInt64 , JSN.FindPath('events[' + inttostr(i) + '].eventTotalVol.nano').AsInt64);
               gbe_output.gbe_events[i].gbe_fixDate := JSN.FindPath('events[' + inttostr(i) + '].fixDate').AsString;
               gbe_output.gbe_events[i].gbe_rateDate := JSN.FindPath('events[' + inttostr(i) + '].rateDate').AsString;
               if JSN.FindPath('events[' + inttostr(i) + '].defaultDate') <> nil then
                  gbe_output.gbe_events[i].gbe_defaultDate := JSN.FindPath('events[' + inttostr(i) + '].defaultDate').AsString;
               if JSN.FindPath('events[' + inttostr(i) + '].realPayDate') <> nil then
                  gbe_output.gbe_events[i].gbe_realPayDate := JSN.FindPath('events[' + inttostr(i) + '].realPayDate').AsString;
               gbe_output.gbe_events[i].gbe_payDate := JSN.FindPath('events[' + inttostr(i) + '].payDate').AsString;
               if JSN.FindPath('events[' + inttostr(i) + '].payOneBond') <> nil then
                  gbe_output.gbe_events[i].gbe_payOneBond.currency := JSN.FindPath('events[' + inttostr(i) + '].payOneBond.currency').AsString;
               if JSN.FindPath('events[' + inttostr(i) + '].payOneBond') <> nil then
                  gbe_output.gbe_events[i].gbe_payOneBond.moneyval := UnitsNanoToDouble(JSN.FindPath('events[' + inttostr(i) + '].payOneBond.units').AsInt64 , JSN.FindPath('events[' + inttostr(i) + '].payOneBond.nano').AsInt64);
               if JSN.FindPath('events[' + inttostr(i) + '].moneyFlowVal') <> nil then
                  gbe_output.gbe_events[i].gbe_moneyFlowVal.currency := JSN.FindPath('events[' + inttostr(i) + '].moneyFlowVal.currency').AsString;
               if JSN.FindPath('events[' + inttostr(i) + '].moneyFlowVal') <> nil then
                  gbe_output.gbe_events[i].gbe_moneyFlowVal.moneyval := UnitsNanoToDouble(JSN.FindPath('events[' + inttostr(i) + '].moneyFlowVal.units').AsInt64 , JSN.FindPath('events[' + inttostr(i) + '].moneyFlowVal.nano').AsInt64);
               gbe_output.gbe_events[i].gbe_execution := JSN.FindPath('events[' + inttostr(i) + '].execution').AsString;
               gbe_output.gbe_events[i].gbe_operationType := JSN.FindPath('events[' + inttostr(i) + '].operationType').AsString;
               if JSN.FindPath('events[' + inttostr(i) + '].value') <> nil then
                  gbe_output.gbe_events[i].gbe_value := UnitsNanoToDouble(JSN.FindPath('events[' + inttostr(i) + '].value.units').AsInt64 , JSN.FindPath('events[' + inttostr(i) + '].value.nano').AsInt64);
               gbe_output.gbe_events[i].gbe_note := JSN.FindPath('events[' + inttostr(i) + '].note').AsString;
               gbe_output.gbe_events[i].gbe_convertToFinToolId := JSN.FindPath('events[' + inttostr(i) + '].convertToFinToolId').AsString;
               gbe_output.gbe_events[i].gbe_couponStartDate := JSN.FindPath('events[' + inttostr(i) + '].couponStartDate').AsString;
               gbe_output.gbe_events[i].gbe_couponEndDate := JSN.FindPath('events[' + inttostr(i) + '].couponEndDate').AsString;
               gbe_output.gbe_events[i].gbe_couponPeriod := JSN.FindPath('events[' + inttostr(i) + '].couponPeriod').AsInt64;
               if JSN.FindPath('events[' + inttostr(i) + '].couponInterestRate') <> nil then
                  gbe_output.gbe_events[i].gbe_couponInterestRate := UnitsNanoToDouble(JSN.FindPath('events[' + inttostr(i) + '].couponInterestRate.units').AsInt64 , JSN.FindPath('events[' + inttostr(i) + '].couponInterestRate.nano').AsInt64);

               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetAssetFundamentals (gaf_input : gaf_request; out gaf_output : gaf_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, numb_assets, i : int64;
   json_base : TJSONObject;
   json_input_array : TJSONArray;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_input_array := TJSONArray.Create;

      endpoint_url := url_tinvest + 'InstrumentsService/GetAssetFundamentals';

      numb_assets := high(gaf_input.gaf_assets);

      for i := 0 to numb_assets do begin
         json_input_array.Add(gaf_input.gaf_assets[i]);
      end;
      json_base.Add('assets', json_input_array);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gaf_input.gaf_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gaf_output.gaf_error_code := JSN.FindPath('code').AsInt64;
            gaf_output.gaf_error_message := JSN.FindPath('message').AsString;
            gaf_output.gaf_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gaf_output.gaf_error_description = 0 then begin

            i := 0;

            SetLength(gaf_output.gaf_fundamentals, numb_assets);

            while i < numb_assets do  begin
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].assetUid') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_assetUid := JSN.FindPath('fundamentals[' + inttostr(i) + '].assetUid').AsString;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].currency') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_currency := JSN.FindPath('fundamentals[' + inttostr(i) + '].currency').AsString;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].marketCapitalization') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_marketCapitalization := JSN.FindPath('fundamentals[' + inttostr(i) + '].marketCapitalization').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].highPriceLast52Weeks') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_highPriceLast52Weeks := JSN.FindPath('fundamentals[' + inttostr(i) + '].highPriceLast52Weeks').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].lowPriceLast52Weeks') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_lowPriceLast52Weeks := JSN.FindPath('fundamentals[' + inttostr(i) + '].lowPriceLast52Weeks').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].averageDailyVolumeLast10Days') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_averageDailyVolumeLast10Days := JSN.FindPath('fundamentals[' + inttostr(i) + '].averageDailyVolumeLast10Days').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].averageDailyVolumeLast4Weeks') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_averageDailyVolumeLast4Weeks := JSN.FindPath('fundamentals[' + inttostr(i) + '].averageDailyVolumeLast4Weeks').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].beta') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_beta := JSN.FindPath('fundamentals[' + inttostr(i) + '].beta').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].freeFloat') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_freeFloat := JSN.FindPath('fundamentals[' + inttostr(i) + '].freeFloat').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].forwardAnnualDividendYield') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_forwardAnnualDividendYield := JSN.FindPath('fundamentals[' + inttostr(i) + '].forwardAnnualDividendYield').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].sharesOutstanding') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_sharesOutstanding := JSN.FindPath('fundamentals[' + inttostr(i) + '].sharesOutstanding').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].revenueTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_revenueTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].revenueTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].ebitdaTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_ebitdaTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].ebitdaTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].netIncomeTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_netIncomeTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].netIncomeTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].epsTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_epsTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].epsTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].dilutedEpsTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_dilutedEpsTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].dilutedEpsTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].freeCashFlowTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_freeCashFlowTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].freeCashFlowTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].fiveYearAnnualRevenueGrowthRate') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_fiveYearAnnualRevenueGrowthRate := JSN.FindPath('fundamentals[' + inttostr(i) + '].fiveYearAnnualRevenueGrowthRate').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].threeYearAnnualRevenueGrowthRate') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_threeYearAnnualRevenueGrowthRate := JSN.FindPath('fundamentals[' + inttostr(i) + '].threeYearAnnualRevenueGrowthRate').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].peRatioTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_peRatioTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].peRatioTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].priceToSalesTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_priceToSalesTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].priceToSalesTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].priceToBookTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_priceToBookTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].priceToBookTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].priceToFreeCashFlowTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_priceToFreeCashFlowTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].priceToFreeCashFlowTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].totalEnterpriseValueMrq') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_totalEnterpriseValueMrq := JSN.FindPath('fundamentals[' + inttostr(i) + '].totalEnterpriseValueMrq').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].evToEbitdaMrq') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_evToEbitdaMrq := JSN.FindPath('fundamentals[' + inttostr(i) + '].evToEbitdaMrq').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].netMarginMrq') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_netMarginMrq := JSN.FindPath('fundamentals[' + inttostr(i) + '].netMarginMrq').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].netInterestMarginMrq') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_netInterestMarginMrq := JSN.FindPath('fundamentals[' + inttostr(i) + '].netInterestMarginMrq').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].roe') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_roe := JSN.FindPath('fundamentals[' + inttostr(i) + '].roe').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].roa') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_roa := JSN.FindPath('fundamentals[' + inttostr(i) + '].roa').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].roic') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_roic := JSN.FindPath('fundamentals[' + inttostr(i) + '].roic').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].totalDebtMrq') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_totalDebtMrq := JSN.FindPath('fundamentals[' + inttostr(i) + '].totalDebtMrq').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].totalDebtToEquityMrq') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_totalDebtToEquityMrq := JSN.FindPath('fundamentals[' + inttostr(i) + '].totalDebtToEquityMrq').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].totalDebtToEbitdaMrq') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_totalDebtToEbitdaMrq := JSN.FindPath('fundamentals[' + inttostr(i) + '].totalDebtToEbitdaMrq').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].freeCashFlowToPrice') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_freeCashFlowToPrice := JSN.FindPath('fundamentals[' + inttostr(i) + '].freeCashFlowToPrice').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].netDebtToEbitda') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_netDebtToEbitda := JSN.FindPath('fundamentals[' + inttostr(i) + '].netDebtToEbitda').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].currentRatioMrq') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_currentRatioMrq := JSN.FindPath('fundamentals[' + inttostr(i) + '].currentRatioMrq').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].fixedChargeCoverageRatioFy') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_fixedChargeCoverageRatioFy := JSN.FindPath('fundamentals[' + inttostr(i) + '].fixedChargeCoverageRatioFy').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].dividendYieldDailyTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_dividendYieldDailyTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].dividendYieldDailyTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].dividendRateTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_dividendRateTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].dividendRateTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].dividendsPerShare') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_dividendsPerShare := JSN.FindPath('fundamentals[' + inttostr(i) + '].dividendsPerShare').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].fiveYearsAverageDividendYield') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_fiveYearsAverageDividendYield := JSN.FindPath('fundamentals[' + inttostr(i) + '].fiveYearsAverageDividendYield').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].fiveYearAnnualDividendGrowthRate') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_fiveYearAnnualDividendGrowthRate := JSN.FindPath('fundamentals[' + inttostr(i) + '].fiveYearAnnualDividendGrowthRate').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].dividendPayoutRatioFy') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_dividendPayoutRatioFy := JSN.FindPath('fundamentals[' + inttostr(i) + '].dividendPayoutRatioFy').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].buyBackTtm') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_buyBackTtm := JSN.FindPath('fundamentals[' + inttostr(i) + '].buyBackTtm').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].oneYearAnnualRevenueGrowthRate') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_oneYearAnnualRevenueGrowthRate := JSN.FindPath('fundamentals[' + inttostr(i) + '].oneYearAnnualRevenueGrowthRate').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].domicileIndicatorCode') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_domicileIndicatorCode := JSN.FindPath('fundamentals[' + inttostr(i) + '].domicileIndicatorCode').AsString;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].adrToCommonShareRatio') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_adrToCommonShareRatio := JSN.FindPath('fundamentals[' + inttostr(i) + '].adrToCommonShareRatio').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].numberOfEmployees') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_numberOfEmployees := JSN.FindPath('fundamentals[' + inttostr(i) + '].numberOfEmployees').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].exDividendDate') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_exDividendDate := JSN.FindPath('fundamentals[' + inttostr(i) + '].exDividendDate').AsString;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].fiscalPeriodStartDate') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_fiscalPeriodStartDate := JSN.FindPath('fundamentals[' + inttostr(i) + '].fiscalPeriodStartDate').AsString;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].fiscalPeriodEndDate') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_fiscalPeriodEndDate := JSN.FindPath('fundamentals[' + inttostr(i) + '].fiscalPeriodEndDate').AsString;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].revenueChangeFiveYears') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_revenueChangeFiveYears := JSN.FindPath('fundamentals[' + inttostr(i) + '].revenueChangeFiveYears').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].epsChangeFiveYears') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_epsChangeFiveYears := JSN.FindPath('fundamentals[' + inttostr(i) + '].epsChangeFiveYears').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].ebitdaChangeFiveYears') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_ebitdaChangeFiveYears := JSN.FindPath('fundamentals[' + inttostr(i) + '].ebitdaChangeFiveYears').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].totalDebtChangeFiveYears') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_totalDebtChangeFiveYears := JSN.FindPath('fundamentals[' + inttostr(i) + '].totalDebtChangeFiveYears').AsFloat;
               if JSN.FindPath('fundamentals[' + inttostr(i) + '].evToSales') <> nil then
                  gaf_output.gaf_fundamentals[i].gaf_evToSales := JSN.FindPath('fundamentals[' + inttostr(i) + '].evToSales').AsFloat;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
    end;
end;

procedure GetAssets (gas_input : gas_request; out gas_output : gas_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, assets_count, instruments_count, links_count, i, j, k : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if gas_input.gas_instrumentType <> '' then json_base.Add('instrumentType', gas_input.gas_instrumentType);
      if gas_input.gas_instrumentStatus <> '' then json_base.Add('instrumentStatus', gas_input.gas_instrumentStatus);

      endpoint_url := url_tinvest + 'InstrumentsService/GetAssets';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gas_input.gas_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gas_output.gas_error_code := JSN.FindPath('code').AsInt64;
            gas_output.gas_error_message := JSN.FindPath('message').AsString;
            gas_output.gas_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gas_output.gas_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('assets'));
            assets_count := json_output_array.Count;

            SetLength(gas_output.gas_assets, assets_count);

            i := 0;

            while i < assets_count do  begin
               gas_output.gas_assets[i].gas_uid := JSN.FindPath('assets[' + inttostr(i) + '].uid').AsString;
               gas_output.gas_assets[i].gas_type := JSN.FindPath('assets[' + inttostr(i) + '].type').AsString;
               gas_output.gas_assets[i].gas_name := JSN.FindPath('assets[' + inttostr(i) + '].name').AsString;

               json_output_array := TJSONArray(JSN.FindPath('assets[' + inttostr(i) + '].instruments' ));
               instruments_count := json_output_array.Count;

               SetLength(gas_output.gas_assets[i].gas_instruments, instruments_count);

               j := 0;

               while j < instruments_count do  begin
                  gas_output.gas_assets[i].gas_instruments[j].gas_uid := JSN.FindPath('assets[' + inttostr(i) + '].instruments[' + inttostr(j) + '].uid').AsString;
                  gas_output.gas_assets[i].gas_instruments[j].gas_figi := JSN.FindPath('assets[' + inttostr(i) + '].instruments[' + inttostr(j) + '].figi').AsString;
                  gas_output.gas_assets[i].gas_instruments[j].gas_instrumentType := JSN.FindPath('assets[' + inttostr(i) + '].instruments[' + inttostr(j) + '].instrumentType').AsString;
                  gas_output.gas_assets[i].gas_instruments[j].gas_ticker := JSN.FindPath('assets[' + inttostr(i) + '].instruments[' + inttostr(j) + '].ticker').AsString;
                  gas_output.gas_assets[i].gas_instruments[j].gas_classCode := JSN.FindPath('assets[' + inttostr(i) + '].instruments[' + inttostr(j) + '].classCode').AsString;

                  json_output_array := TJSONArray(JSN.FindPath('assets[' + inttostr(i) + '].instruments[' + inttostr(j) + '].links'));
                  links_count := json_output_array.Count;

                  SetLength(gas_output.gas_assets[i].gas_instruments[j].gas_links, links_count);

                  k := 0;

                  while k < links_count do  begin
                     gas_output.gas_assets[i].gas_instruments[j].gas_links[k].gas_type := JSN.FindPath('assets[' + inttostr(i) + '].instruments[' + inttostr(j) + '].links[' + inttostr(k) + '].type').AsString;
                     gas_output.gas_assets[i].gas_instruments[j].gas_links[k].gas_instrumentUid := JSN.FindPath('assets[' + inttostr(i) + '].instruments[' + inttostr(j) + '].links[' + inttostr(k) + '].instrumentUid').AsString;
                     inc(k);
                  end;

                  gas_output.gas_assets[i].gas_instruments[j].gas_instrumentKind := JSN.FindPath('assets[' + inttostr(i) + '].instruments[' + inttostr(j) + '].instrumentKind').AsString;
                  gas_output.gas_assets[i].gas_instruments[j].gas_positionUid := JSN.FindPath('assets[' + inttostr(i) + '].instruments[' + inttostr(j) + '].positionUid').AsString;
                  inc(j);
               end;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetAssetReports (gar_input : gar_request; out gar_output : gar_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, events_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if gar_input.gar_from <> '' then json_base.Add('from', gar_input.gar_from);
      if gar_input.gar_to <> '' then json_base.Add('to', gar_input.gar_to);
      json_base.Add('instrumentId', gar_input.gar_instrumentId);

      endpoint_url := url_tinvest + 'InstrumentsService/GetAssetReports';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gar_input.gar_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gar_output.gar_error_code := JSN.FindPath('code').AsInt64;
            gar_output.gar_error_message := JSN.FindPath('message').AsString;
            gar_output.gar_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gar_output.gar_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('events'));
            events_count := json_output_array.Count;

            SetLength(gar_output.gar_events, events_count);

            i := 0;

            while i < events_count do  begin
               gar_output.gar_events[i].gar_instrumentId := JSN.FindPath('events[' + inttostr(i) + '].instrumentId').AsString;
               gar_output.gar_events[i].gar_reportDate := JSN.FindPath('events[' + inttostr(i) + '].reportDate').AsString;
               gar_output.gar_events[i].gar_periodYear := JSN.FindPath('events[' + inttostr(i) + '].periodYear').AsInt64;
               gar_output.gar_events[i].gar_periodNum := JSN.FindPath('events[' + inttostr(i) + '].periodNum').AsInt64;
               gar_output.gar_events[i].gar_periodType := JSN.FindPath('events[' + inttostr(i) + '].periodType').AsString;
               gar_output.gar_events[i].gar_createdAt := JSN.FindPath('events[' + inttostr(i) + '].createdAt').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetPositions (gep_input : gep_request; out gep_output : gep_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, money_count, blocked_count, securities_count, futures_count, options_count, i, j, k , l, m : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.OperationsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OperationsService_limit.h_ratelimit_reset * 1000);
        requests_limit.OperationsService_limit.h_ratelimit_remaining := requests_limit.OperationsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      json_base.Add('accountId', gep_input.gep_accountId);

      endpoint_url := url_tinvest + 'OperationsService/GetPositions';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gep_input.gep_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OperationsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gep_output.gep_error_code := JSN.FindPath('code').AsInt64;
            gep_output.gep_error_message := JSN.FindPath('message').AsString;
            gep_output.gep_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gep_output.gep_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('money'));
            money_count := json_output_array.Count;
            SetLength(gep_output.gep_money, money_count);

            i := 0;

            while i < money_count do begin
               gep_output.gep_money[i].currency := JSN.FindPath('money[' + inttostr(i) + '].currency').AsString;
               gep_output.gep_money[i].moneyval := UnitsNanoToDouble(JSN.FindPath('money[' + inttostr(i) + '].units').AsInt64 , JSN.FindPath('money[' + inttostr(i) + '].nano').AsInt64);
               inc(i);
            end;

            json_output_array := TJSONArray(JSN.FindPath('blocked'));
            blocked_count := json_output_array.Count;
            SetLength(gep_output.gep_blocked, blocked_count);

            j := 0;

            while j < money_count do begin
               if JSN.FindPath('blocked[' + inttostr(j) + ']') <> nil then begin
                  gep_output.gep_blocked[j].currency := JSN.FindPath('blocked[' + inttostr(j) + '].currency').AsString;
                  gep_output.gep_blocked[j].moneyval := UnitsNanoToDouble(JSN.FindPath('blocked[' + inttostr(j) + '].units').AsInt64 , JSN.FindPath('blocked[' + inttostr(j) + '].nano').AsInt64);
               end;
               inc(j);
            end;

            json_output_array := TJSONArray(JSN.FindPath('securities'));
            securities_count := json_output_array.Count;
            SetLength(gep_output.gep_securities, securities_count);

            k := 0;

            while k < securities_count do begin
               gep_output.gep_securities[k].gep_figi := JSN.FindPath('securities[' + inttostr(k) + '].figi').AsString;
               gep_output.gep_securities[k].gep_blocked := JSN.FindPath('securities[' + inttostr(k) + '].blocked').AsInt64;
               gep_output.gep_securities[k].gep_balance := JSN.FindPath('securities[' + inttostr(k) + '].balance').AsInt64;
               gep_output.gep_securities[k].gep_positionUid := JSN.FindPath('securities[' + inttostr(k) + '].positionUid').AsString;
               gep_output.gep_securities[k].gep_instrumentUid := JSN.FindPath('securities[' + inttostr(k) + '].instrumentUid').AsString;
               gep_output.gep_securities[k].gep_ticker := JSN.FindPath('securities[' + inttostr(k) + '].ticker').AsString;
               gep_output.gep_securities[k].gep_classCode := JSN.FindPath('securities[' + inttostr(k) + '].classCode').AsString;
               gep_output.gep_securities[k].gep_exchangeBlocked := JSN.FindPath('securities[' + inttostr(k) + '].exchangeBlocked').AsBoolean;
               gep_output.gep_securities[k].gep_instrumentType := JSN.FindPath('securities[' + inttostr(k) + '].instrumentType').AsString;
               inc(k);
            end;

            gep_output.gep_limitsLoadingInProgress := JSN.FindPath('limitsLoadingInProgress').AsBoolean;


            json_output_array := TJSONArray(JSN.FindPath('futures'));
            futures_count := json_output_array.Count;
            SetLength(gep_output.gep_futures, futures_count);

            l := 0;

            while l < futures_count do begin
               gep_output.gep_futures[l].gep_figi := JSN.FindPath('futures[' + inttostr(l) + '].figi').AsString;
               gep_output.gep_futures[l].gep_blocked := JSN.FindPath('futures[' + inttostr(l) + '].blocked').AsInt64;
               gep_output.gep_futures[l].gep_balance := JSN.FindPath('futures[' + inttostr(l) + '].balance').AsInt64;
               gep_output.gep_futures[l].gep_positionUid := JSN.FindPath('futures[' + inttostr(l) + '].positionUid').AsString;
               gep_output.gep_futures[l].gep_instrumentUid := JSN.FindPath('futures[' + inttostr(l) + '].instrumentUid').AsString;
               gep_output.gep_futures[l].gep_ticker := JSN.FindPath('futures[' + inttostr(l) + '].ticker').AsString;
               gep_output.gep_futures[l].gep_classCode := JSN.FindPath('futures[' + inttostr(l) + '].classCode').AsString;
               inc(l);
            end;

            json_output_array := TJSONArray(JSN.FindPath('options'));
            options_count := json_output_array.Count;
            SetLength(gep_output.gep_options, options_count);

            m := 0;

            while m < options_count do begin
               gep_output.gep_options[m].gep_positionUid := JSN.FindPath('options[' + inttostr(l) + '].positionUid').AsString;
               gep_output.gep_options[m].gep_instrumentUid := JSN.FindPath('options[' + inttostr(l) + '].instrumentUid').AsString;
               gep_output.gep_options[m].gep_ticker := JSN.FindPath('options[' + inttostr(l) + '].ticker').AsString;
               gep_output.gep_options[m].gep_classCode := JSN.FindPath('options[' + inttostr(l) + '].classCode').AsString;
               gep_output.gep_options[m].gep_blocked := JSN.FindPath('options[' + inttostr(l) + '].blocked').AsInt64;
               gep_output.gep_options[m].gep_balance := JSN.FindPath('options[' + inttostr(l) + '].balance').AsInt64;
               inc(m);
            end;

            gep_output.gep_accountId := JSN.FindPath('accountId').AsString;

         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetBrands (gb_input : gb_request; out gb_output : gb_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, brands_count, i : int64;
   json_base, json_nested : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested := TJSONObject.Create;

      if gb_input.gb_paging.gb_limit > 0 then json_nested.Add('limit', gb_input.gb_paging.gb_limit);
      if gb_input.gb_paging.gb_pageNumber >= 0 then json_nested.Add('pageNumber', gb_input.gb_paging.gb_pageNumber);
      json_base.Add('paging', json_nested);



      endpoint_url := url_tinvest + 'InstrumentsService/GetBrands';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gb_input.gb_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gb_output.gb_error_code := JSN.FindPath('code').AsInt64;
            gb_output.gb_error_message := JSN.FindPath('message').AsString;
            gb_output.gb_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gb_output.gb_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('brands'));

            brands_count := json_output_array.Count;

            i := 0;

            SetLength(gb_output.gb_brands, brands_count);

            while i < brands_count do  begin
               gb_output.gb_brands[i].gb_uid := JSN.FindPath('brands[' + inttostr(i) + '].uid').AsString;
               gb_output.gb_brands[i].gb_name := JSN.FindPath('brands[' + inttostr(i) + '].name').AsString;
               gb_output.gb_brands[i].gb_description := JSN.FindPath('brands[' + inttostr(i) + '].description').AsString;
               gb_output.gb_brands[i].gb_info := JSN.FindPath('brands[' + inttostr(i) + '].info').AsString;
               gb_output.gb_brands[i].gb_company := JSN.FindPath('brands[' + inttostr(i) + '].company').AsString;
               gb_output.gb_brands[i].gb_sector := JSN.FindPath('brands[' + inttostr(i) + '].sector').AsString;
               gb_output.gb_brands[i].gb_countryOfRisk := JSN.FindPath('brands[' + inttostr(i) + '].countryOfRisk').AsString;
               gb_output.gb_brands[i].gb_countryOfRiskName := JSN.FindPath('brands[' + inttostr(i) + '].countryOfRiskName').AsString;
               inc(i);
            end;

            gb_output.gb_paging.gb_limit := JSN.FindPath('paging.limit').AsInt64;
            gb_output.gb_paging.gb_pageNumber := JSN.FindPath('paging.pageNumber').AsInt64;
            gb_output.gb_paging.gb_totalCount := JSN.FindPath('paging.totalCount').AsInt64;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetBrandBy (gbb_input : gbb_request; out gbb_output : gbb_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      json_base.Add('id', gbb_input.gbb_id);

      endpoint_url := url_tinvest + 'InstrumentsService/GetBrandBy';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gbb_input.gbb_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            if JSN.FindPath('code') <> nil then gbb_output.gbb_error_code := JSN.FindPath('code').AsInt64;
            if JSN.FindPath('message') <> nil then gbb_output.gbb_error_message := JSN.FindPath('message').AsString;
            if JSN.FindPath('message') <> nil then gbb_output.gbb_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gbb_output.gbb_error_description = 0 then begin
            gbb_output.gbb_uid := JSN.FindPath('uid').AsString;
            gbb_output.gbb_name := JSN.FindPath('name').AsString;
            gbb_output.gbb_description := JSN.FindPath('description').AsString;
            gbb_output.gbb_info := JSN.FindPath('info').AsString;
            gbb_output.gbb_company := JSN.FindPath('company').AsString;
            gbb_output.gbb_sector := JSN.FindPath('sector').AsString;
            gbb_output.gbb_countryOfRisk := JSN.FindPath('countryOfRisk').AsString;
            gbb_output.gbb_countryOfRiskName := JSN.FindPath('countryOfRiskName').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetTradingStatuses (gtss_input : gtss_request; out gtss_output : gtss_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, tradingStatuses_count, i : int64;
   json_base : TJSONObject;
   json_input_array : TJSONArray;

begin
   try
      if requests_limit.MarketDataService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.MarketDataService_limit.h_ratelimit_reset * 1000);
        requests_limit.MarketDataService_limit.h_ratelimit_remaining := requests_limit.MarketDataService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_input_array := TJSONArray.Create;

      endpoint_url := url_tinvest + 'MarketDataService/GetTradingStatuses';

      tradingStatuses_count := high(gtss_input.gtss_instrumentId);

      for i := 0 to tradingStatuses_count do begin
         json_input_array.Add(gtss_input.gtss_instrumentId[i]);
      end;
      json_base.Add('instrumentId', json_input_array);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gtss_input.gtss_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.MarketDataService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gtss_output.gtss_error_code := JSN.FindPath('code').AsInt64;
            gtss_output.gtss_error_message := JSN.FindPath('message').AsString;
            gtss_output.gtss_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gtss_output.gtss_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('tradingStatuses'));
            tradingStatuses_count := json_output_array.Count;

            i := 0;

            SetLength(gtss_output.gtss_tradingStatuses, tradingStatuses_count);

            while i < tradingStatuses_count do  begin
               gtss_output.gtss_tradingStatuses[i].gtss_figi := JSN.FindPath('tradingStatuses[' + inttostr(i) + '].figi').AsString;
               gtss_output.gtss_tradingStatuses[i].gtss_tradingStatus := JSN.FindPath('tradingStatuses[' + inttostr(i) + '].tradingStatus').AsString;
               gtss_output.gtss_tradingStatuses[i].gtss_limitOrderAvailableFlag := JSN.FindPath('tradingStatuses[' + inttostr(i) + '].limitOrderAvailableFlag').AsBoolean;
               gtss_output.gtss_tradingStatuses[i].gtss_marketOrderAvailableFlag := JSN.FindPath('tradingStatuses[' + inttostr(i) + '].marketOrderAvailableFlag').AsBoolean;
               gtss_output.gtss_tradingStatuses[i].gtss_apiTradeAvailableFlag := JSN.FindPath('tradingStatuses[' + inttostr(i) + '].apiTradeAvailableFlag').AsBoolean;
               gtss_output.gtss_tradingStatuses[i].gtss_instrumentUid := JSN.FindPath('tradingStatuses[' + inttostr(i) + '].instrumentUid').AsString;
               gtss_output.gtss_tradingStatuses[i].gtss_bestpriceOrderAvailableFlag := JSN.FindPath('tradingStatuses[' + inttostr(i) + '].bestpriceOrderAvailableFlag').AsBoolean;
               gtss_output.gtss_tradingStatuses[i].gtss_onlyBestPrice := JSN.FindPath('tradingStatuses[' + inttostr(i) + '].onlyBestPrice').AsBoolean;
               gtss_output.gtss_tradingStatuses[i].gtss_ticker := JSN.FindPath('tradingStatuses[' + inttostr(i) + '].ticker').AsString;
               gtss_output.gtss_tradingStatuses[i].gtss_classCode := JSN.FindPath('tradingStatuses[' + inttostr(i) + '].classCode').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
    end;
end;

procedure GetStrategies (ges_input : ges_request; out ges_output : ges_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, strategies_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.SignalService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.SignalService_limit.h_ratelimit_reset * 1000);
        requests_limit.SignalService_limit.h_ratelimit_remaining := requests_limit.SignalService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      endpoint_url := url_tinvest + 'SignalService/GetStrategies';

      if ges_input.ges_strategyId <> '' then json_base.Add('strategyId', ges_input.ges_strategyId);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + ges_input.ges_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.SignalService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            ges_output.ges_error_code := JSN.FindPath('code').AsInt64;
            ges_output.ges_error_message := JSN.FindPath('message').AsString;
            ges_output.ges_error_description := JSN.FindPath('description').AsInt64;
         end;

         if ges_output.ges_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('strategies'));
            strategies_count := json_output_array.Count;

            i := 0;

            SetLength(ges_output.ges_strategies, strategies_count);

            while i < strategies_count do  begin
               ges_output.ges_strategies[i].ges_strategyId := JSN.FindPath('strategies[' + inttostr(i) + '].strategyId').AsString;
               ges_output.ges_strategies[i].ges_strategyName := JSN.FindPath('strategies[' + inttostr(i) + '].strategyName').AsString;
               ges_output.ges_strategies[i].ges_strategyDescription := JSN.FindPath('strategies[' + inttostr(i) + '].strategyDescription').AsString;
               ges_output.ges_strategies[i].ges_strategyendpoint_url := JSN.FindPath('strategies[' + inttostr(i) + '].strategyendpoint_url').AsString;
               ges_output.ges_strategies[i].ges_strategyType := JSN.FindPath('strategies[' + inttostr(i) + '].strategyType').AsString;
               ges_output.ges_strategies[i].ges_activeSignals := JSN.FindPath('strategies[' + inttostr(i) + '].activeSignals').AsInt64;
               ges_output.ges_strategies[i].ges_totalSignals := JSN.FindPath('strategies[' + inttostr(i) + '].totalSignals').AsInt64;
               ges_output.ges_strategies[i].ges_timeInPosition := JSN.FindPath('strategies[' + inttostr(i) + '].timeInPosition').AsInt64;
               ges_output.ges_strategies[i].ges_averageSignalYield := UnitsNanoToDouble(JSN.FindPath('strategies[' + inttostr(i) + '].averageSignalYield.units').AsInt64 , JSN.FindPath('strategies[' + inttostr(i) + '].averageSignalYield.nano').AsInt64);
               ges_output.ges_strategies[i].ges_averageSignalYieldYear := UnitsNanoToDouble(JSN.FindPath('strategies[' + inttostr(i) + '].averageSignalYieldYear.units').AsInt64 , JSN.FindPath('strategies[' + inttostr(i) + '].averageSignalYieldYear.nano').AsInt64);
               ges_output.ges_strategies[i].ges_yield := UnitsNanoToDouble(JSN.FindPath('strategies[' + inttostr(i) + '].yield.units').AsInt64 , JSN.FindPath('strategies[' + inttostr(i) + '].yield.nano').AsInt64);
               ges_output.ges_strategies[i].ges_yieldYear := UnitsNanoToDouble(JSN.FindPath('strategies[' + inttostr(i) + '].yieldYear.units').AsInt64 , JSN.FindPath('strategies[' + inttostr(i) + '].yieldYear.nano').AsInt64);
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
    end;
end;

procedure GetSignals (gsi_input : gsi_request; out gsi_output : gsi_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, signals_count, i : int64;
   json_base, json_nested : TJSONObject;

begin
   try
      if requests_limit.SignalService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.SignalService_limit.h_ratelimit_reset * 1000);
        requests_limit.SignalService_limit.h_ratelimit_remaining := requests_limit.SignalService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested := TJSONObject.Create;

      endpoint_url := url_tinvest + 'SignalService/GetSignals';

      if gsi_input.gsi_signalId <> '' then json_base.Add('signalId', gsi_input.gsi_signalId);
      if gsi_input.gsi_strategyId <> '' then json_base.Add('strategyId', gsi_input.gsi_strategyId);
      if gsi_input.gsi_strategyType <> '' then json_base.Add('strategyType', gsi_input.gsi_strategyType);
      if gsi_input.gsi_instrumentUid <> '' then json_base.Add('instrumentUid', gsi_input.gsi_instrumentUid);
      if gsi_input.gsi_from <> '' then json_base.Add('from', gsi_input.gsi_from);
      if gsi_input.gsi_to <> '' then json_base.Add('to', gsi_input.gsi_to);
      if gsi_input.gsi_direction <> '' then json_base.Add('direction', gsi_input.gsi_direction);
      if gsi_input.gsi_active <> '' then json_base.Add('active', gsi_input.gsi_active);
      if gsi_input.gsi_paging.gsi_limit > 0 then json_nested.Add('limit', gsi_input.gsi_paging.gsi_limit);
      if gsi_input.gsi_paging.gsi_pageNumber >= 0 then json_nested.Add('pageNumber', gsi_input.gsi_paging.gsi_pageNumber);
      json_base.Add('paging', json_nested);


      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gsi_input.gsi_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.SignalService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gsi_output.gsi_error_code := JSN.FindPath('code').AsInt64;
            gsi_output.gsi_error_message := JSN.FindPath('message').AsString;
            gsi_output.gsi_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gsi_output.gsi_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('signals'));
            signals_count := json_output_array.Count;

            i := 0;

            SetLength(gsi_output.gsi_signals, signals_count);

            while i < signals_count do  begin
               gsi_output.gsi_signals[i].gsi_signalId := JSN.FindPath('signals[' + inttostr(i) + '].signalId').AsString;
               gsi_output.gsi_signals[i].gsi_strategyId := JSN.FindPath('signals[' + inttostr(i) + '].strategyId').AsString;
               gsi_output.gsi_signals[i].gsi_strategyName := JSN.FindPath('signals[' + inttostr(i) + '].strategyName').AsString;
               gsi_output.gsi_signals[i].gsi_instrumentUid := JSN.FindPath('signals[' + inttostr(i) + '].instrumentUid').AsString;
               gsi_output.gsi_signals[i].gsi_createDt := JSN.FindPath('signals[' + inttostr(i) + '].createDt').AsString;
               gsi_output.gsi_signals[i].gsi_direction := JSN.FindPath('signals[' + inttostr(i) + '].direction').AsString;
               gsi_output.gsi_signals[i].gsi_initialPrice := UnitsNanoToDouble(JSN.FindPath('signals[' + inttostr(i) + '].initialPrice.units').AsInt64 , JSN.FindPath('signals[' + inttostr(i) + '].initialPrice.nano').AsInt64);
               if JSN.FindPath('signals[' + inttostr(i) + '].info') <> nil then
                  gsi_output.gsi_signals[i].gsi_info := JSN.FindPath('signals[' + inttostr(i) + '].info').AsString;
               gsi_output.gsi_signals[i].gsi_name := JSN.FindPath('signals[' + inttostr(i) + '].name').AsString;
               gsi_output.gsi_signals[i].gsi_targetPrice := UnitsNanoToDouble(JSN.FindPath('signals[' + inttostr(i) + '].targetPrice.units').AsInt64 , JSN.FindPath('signals[' + inttostr(i) + '].targetPrice.nano').AsInt64);
               gsi_output.gsi_signals[i].gsi_endDt := JSN.FindPath('signals[' + inttostr(i) + '].endDt').AsString;
               gsi_output.gsi_signals[i].gsi_probability := JSN.FindPath('signals[' + inttostr(i) + '].probability').AsInt64;
               gsi_output.gsi_signals[i].gsi_stoploss := UnitsNanoToDouble(JSN.FindPath('signals[' + inttostr(i) + '].stoploss.units').AsInt64 , JSN.FindPath('signals[' + inttostr(i) + '].stoploss.nano').AsInt64);
               if JSN.FindPath('signals[' + inttostr(i) + '].closePrice') <> nil then
                  gsi_output.gsi_signals[i].gsi_closePrice := UnitsNanoToDouble(JSN.FindPath('signals[' + inttostr(i) + '].closePrice.units').AsInt64 , JSN.FindPath('signals[' + inttostr(i) + '].closePrice.nano').AsInt64);
               if JSN.FindPath('signals[' + inttostr(i) + '].closeDt') <> nil then
                  gsi_output.gsi_signals[i].gsi_closeDt := JSN.FindPath('signals[' + inttostr(i) + '].closeDt').AsString;
               inc(i);
            end;

            gsi_output.gsi_paging.gsi_limit := JSN.FindPath('paging.limit').AsInt64;
            gsi_output.gsi_paging.gsi_pageNumber := JSN.FindPath('paging.pageNumber').AsInt64;
            gsi_output.gsi_paging.gsi_totalCount := JSN.FindPath('paging.totalCount').AsInt64;

         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure CurrencyTransfer (cut_input : cut_request; out cut_output : cut_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base, json_nested : TJSONObject;

begin
   try
      if requests_limit.Currency_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.Currency_limit.h_ratelimit_reset * 1000);
        requests_limit.Currency_limit.h_ratelimit_remaining := requests_limit.Currency_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested := TJSONObject.Create;

      endpoint_url := url_tinvest + 'UsersService/CurrencyTransfer';

      json_base.Add('fromAccountId', cut_input.cut_fromAccountId);
      json_base.Add('toAccountId', cut_input.cut_toAccountId);
      if cut_input.cut_amount.moneyval >0 then begin
         json_nested.Add('nano', Trunc(Frac(cut_input.cut_amount.moneyval)*1000000000));
         json_nested.Add('units', Trunc(cut_input.cut_amount.moneyval));
         json_nested.Add('currency', cut_input.cut_amount.currency);
         json_base.Add('amount', json_nested);
      end;
      if cut_input.cut_transactionId <> '' then json_base.Add('transactionId', cut_input.cut_transactionId);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + cut_input.cut_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.Currency_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            cut_output.cut_error_code := JSN.FindPath('code').AsInt64;
            cut_output.cut_error_message := JSN.FindPath('message').AsString;
            cut_output.cut_error_description := JSN.FindPath('description').AsInt64;
         end;

         if cut_output.cut_error_description = 0 then begin
            //
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure PayIn (pi_input : pi_request; out pi_output : pi_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base, json_nested : TJSONObject;

begin
   try
      if requests_limit.Currency_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.Currency_limit.h_ratelimit_reset * 1000);
        requests_limit.Currency_limit.h_ratelimit_remaining := requests_limit.Currency_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested := TJSONObject.Create;

      endpoint_url := url_tinvest + 'UsersService/PayIn';

      json_base.Add('fromAccountId', pi_input.pi_fromAccountId);
      json_base.Add('toAccountId', pi_input.pi_toAccountId);
      if pi_input.pi_amount.moneyval >0 then begin
         json_nested.Add('nano', Trunc(Frac(pi_input.pi_amount.moneyval)*1000000000));
         json_nested.Add('units', Trunc(pi_input.pi_amount.moneyval));
         json_nested.Add('currency', pi_input.pi_amount.currency);
         json_base.Add('amount', json_nested);
      end;

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + pi_input.pi_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.Currency_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            pi_output.pi_error_code := JSN.FindPath('code').AsInt64;
            pi_output.pi_error_message := JSN.FindPath('message').AsString;
            pi_output.pi_error_description := JSN.FindPath('description').AsInt64;
         end;

         if pi_output.pi_error_description = 0 then begin
            //
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetWithdrawLimits (gwl_input : gwl_request; out gwl_output : gwl_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, money_count, blocked_count, blockedGuarantee_count, i, j, k : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.OperationsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OperationsService_limit.h_ratelimit_reset * 1000);
        requests_limit.OperationsService_limit.h_ratelimit_remaining := requests_limit.OperationsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      endpoint_url := url_tinvest + 'OperationsService/GetWithdrawLimits';

      json_base.Add('accountId', gwl_input.gwl_accountId);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gwl_input.gwl_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OperationsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gwl_output.gwl_error_code := JSN.FindPath('code').AsInt64;
            gwl_output.gwl_error_message := JSN.FindPath('message').AsString;
            gwl_output.gwl_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gwl_output.gwl_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('money'));
            money_count := json_output_array.Count;

            i := 0;

            SetLength(gwl_output.gwl_money, money_count);

            while i < money_count do  begin
               gwl_output.gwl_money[i].moneyval := UnitsNanoToDouble(JSN.FindPath('money[' + inttostr(i) + '].units').AsInt64 , JSN.FindPath('money[' + inttostr(i) + '].nano').AsInt64);
               gwl_output.gwl_money[i].currency := JSN.FindPath('money[' + inttostr(i) + '].currency').AsString;
               inc(i);
            end;

            json_output_array := TJSONArray(JSN.FindPath('blocked'));
            blocked_count := json_output_array.Count;

            j := 0;

            SetLength(gwl_output.gwl_blocked, blocked_count);

            while j < blocked_count do  begin
               gwl_output.gwl_blocked[j].moneyval := UnitsNanoToDouble(JSN.FindPath('blocked[' + inttostr(j) + '].units').AsInt64 , JSN.FindPath('blocked[' + inttostr(j) + '].nano').AsInt64);
               gwl_output.gwl_blocked[j].currency := JSN.FindPath('blocked[' + inttostr(j) + '].currency').AsString;
               inc(j);
            end;

            json_output_array := TJSONArray(JSN.FindPath('blockedGuarantee'));
            blockedGuarantee_count := json_output_array.Count;

            k := 0;

            SetLength(gwl_output.gwl_blockedGuarantee, blockedGuarantee_count);

            while k < blockedGuarantee_count do  begin
               gwl_output.gwl_blocked[k].moneyval := UnitsNanoToDouble(JSN.FindPath('blockedGuarantee[' + inttostr(k) + '].units').AsInt64 , JSN.FindPath('blockedGuarantee[' + inttostr(k) + '].nano').AsInt64);
               gwl_output.gwl_blocked[k].currency := JSN.FindPath('blockedGuarantee[' + inttostr(k) + '].currency').AsString;
               inc(k);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetBrokerReport (gbr_input : gbr_request; out gbr_output : gbr_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, brokerReport_count, i : int64;
   json_base, json_nested1, json_nested2 : TJSONObject;

begin
   try
      if requests_limit.Report_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.Report_limit.h_ratelimit_reset * 1000);
        requests_limit.Report_limit.h_ratelimit_remaining := requests_limit.Report_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested1 := TJSONObject.Create;

      endpoint_url := url_tinvest + 'OperationsService/GetBrokerReport';

      json_nested1.Add('accountId', gbr_input.gbr_generateBrokerReportRequest.gbr_accountId);
      json_nested1.Add('from', gbr_input.gbr_generateBrokerReportRequest.gbr_from);
      json_nested1.Add('to', gbr_input.gbr_generateBrokerReportRequest.gbr_to);
      json_base.Add('generateBrokerReportRequest', json_nested1);

      if (gbr_input.gbr_getBrokerReportRequest.gbr_taskId <> '') and (gbr_input.gbr_getBrokerReportRequest.gbr_page > 0) then begin
         json_nested2 := TJSONObject.Create;
         json_nested2.Add('taskId', gbr_input.gbr_getBrokerReportRequest.gbr_taskId);
         json_nested2.Add('page', gbr_input.gbr_getBrokerReportRequest.gbr_page);
         json_base.Add('getBrokerReportRequest', json_nested2);
      end;

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gbr_input.gbr_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.Report_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gbr_output.gbr_error_code := JSN.FindPath('code').AsInt64;
            gbr_output.gbr_error_message := JSN.FindPath('message').AsString;
            gbr_output.gbr_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gbr_output.gbr_error_description = 0 then begin

            if JSN.FindPath('generateBrokerReportResponse.taskId') <> nil then
               gbr_output.gbr_generateBrokerReportResponse.gbr_taskId := JSN.FindPath('generateBrokerReportResponse.taskId').AsString;

            brokerReport_count := 0;

            if JSN.FindPath('getBrokerReportResponse.brokerReport') <> nil then begin
               json_output_array := TJSONArray(JSN.FindPath('getBrokerReportResponse.brokerReport'));
               brokerReport_count := json_output_array.Count;
            end;

            i := 0;

            SetLength(gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport, brokerReport_count);

            while i < brokerReport_count do  begin
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_tradeId := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].tradeId').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_orderId := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].orderId').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_figi := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].figi').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_executeSign := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].executeSign').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_tradeDatetime := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].tradeDatetime').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_exchange := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].exchange').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_classCode := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].classCode').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_direction := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].direction').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_name := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].name').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_ticker := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].ticker').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_price.moneyval := UnitsNanoToDouble(JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].price.units').AsInt64 , JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].price.nano').AsInt64);
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_price.currency := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].price.currency').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_quantity := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].quantity').AsInt64;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_orderAmount.moneyval := UnitsNanoToDouble(JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].orderAmount.units').AsInt64 , JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].orderAmount.nano').AsInt64);
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_orderAmount.currency := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].orderAmount.currency').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_aciValue := UnitsNanoToDouble(JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].aciValue.units').AsInt64 , JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].aciValue.nano').AsInt64);
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_totalOrderAmount.moneyval := UnitsNanoToDouble(JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].totalOrderAmount.units').AsInt64 , JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].totalOrderAmount.nano').AsInt64);
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_totalOrderAmount.currency := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].totalOrderAmount.currency').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_brokerCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].brokerCommission.units').AsInt64 , JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].brokerCommission.nano').AsInt64);
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_brokerCommission.currency := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].brokerCommission.currency').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_exchangeCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].exchangeCommission.units').AsInt64 , JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].exchangeCommission.nano').AsInt64);
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_exchangeCommission.currency := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].exchangeCommission.currency').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_exchangeClearingCommission.moneyval := UnitsNanoToDouble(JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].exchangeClearingCommission.units').AsInt64 , JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].exchangeClearingCommission.nano').AsInt64);
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_exchangeClearingCommission.currency := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].exchangeClearingCommission.currency').AsString;
               if JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].repoRate') <> nil then
                  gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_repoRate := UnitsNanoToDouble(JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].repoRate.units').AsInt64 , JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].repoRate.nano').AsInt64);
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_party := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].party').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_clearValueDate := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].clearValueDate').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_secValueDate := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].secValueDate').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_brokerStatus := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].brokerStatus').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_separateAgreementType := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].separateAgreementType').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_separateAgreementNumber := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].separateAgreementNumber').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_separateAgreementDate := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].separateAgreementDate').AsString;
               gbr_output.gbr_getBrokerReportResponse.gbr_brokerReport[i].gbr_deliveryType := JSN.FindPath('getBrokerReportResponse.brokerReport[' + inttostr(i) + '].deliveryType').AsString;
               inc(i);
            end;

            if JSN.FindPath('getBrokerReportResponse.itemsCount') <> nil then
               gbr_output.gbr_getBrokerReportResponse.gbr_itemsCount := JSN.FindPath('getBrokerReportResponse.itemsCount').AsInt64;
            if JSN.FindPath('getBrokerReportResponse.pagesCount') <> nil then
               gbr_output.gbr_getBrokerReportResponse.gbr_pagesCount := JSN.FindPath('getBrokerReportResponse.pagesCount').AsInt64;
            if JSN.FindPath('getBrokerReportResponse.page') <> nil then
               gbr_output.gbr_getBrokerReportResponse.gbr_page := JSN.FindPath('getBrokerReportResponse.page').AsInt64;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure Indicatives (ind_input : ind_request; out ind_output : ind_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, instruments_count, i : int64;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      endpoint_url := url_tinvest + 'InstrumentsService/Indicatives';

      json_request := '{}';

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + ind_input.ind_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            ind_output.ind_error_code := JSN.FindPath('code').AsInt64;
            ind_output.ind_error_message := JSN.FindPath('message').AsString;
            ind_output.ind_error_description := JSN.FindPath('description').AsInt64;
         end;

         if ind_output.ind_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('instruments'));

            instruments_count := json_output_array.Count;

            SetLength(ind_output.ind_instruments, instruments_count);

            i := 0;

            while i < instruments_count do  begin
               ind_output.ind_instruments[i].ind_figi := JSN.FindPath('instruments[' + inttostr(i) + '].figi').AsString;
               ind_output.ind_instruments[i].ind_ticker := JSN.FindPath('instruments[' + inttostr(i) + '].ticker').AsString;
               ind_output.ind_instruments[i].ind_classCode := JSN.FindPath('instruments[' + inttostr(i) + '].classCode').AsString;
               ind_output.ind_instruments[i].ind_currency := JSN.FindPath('instruments[' + inttostr(i) + '].currency').AsString;
               ind_output.ind_instruments[i].ind_instrumentKind := JSN.FindPath('instruments[' + inttostr(i) + '].instrumentKind').AsString;
               ind_output.ind_instruments[i].ind_name := JSN.FindPath('instruments[' + inttostr(i) + '].name').AsString;
               ind_output.ind_instruments[i].ind_exchange := JSN.FindPath('instruments[' + inttostr(i) + '].exchange').AsString;
               ind_output.ind_instruments[i].ind_uid := JSN.FindPath('instruments[' + inttostr(i) + '].uid').AsString;
               ind_output.ind_instruments[i].ind_buyAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].buyAvailableFlag').AsBoolean;
               ind_output.ind_instruments[i].ind_sellAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].sellAvailableFlag').AsBoolean;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetCountries (gco_input : gco_request; out gco_output : gco_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, countries_count, i : int64;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      endpoint_url := url_tinvest + 'InstrumentsService/GetCountries';

      json_request := '{}';

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gco_input.gco_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gco_output.gco_error_code := JSN.FindPath('code').AsInt64;
            gco_output.gco_error_message := JSN.FindPath('message').AsString;
            gco_output.gco_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gco_output.gco_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('countries'));

            countries_count := json_output_array.Count;

            SetLength(gco_output.gco_countries, countries_count);

            i := 0;

            while i < countries_count do  begin
               gco_output.gco_countries[i].gco_alfaTwo := JSN.FindPath('countries[' + inttostr(i) + '].alfaTwo').AsString;
               gco_output.gco_countries[i].gco_alfaThree := JSN.FindPath('countries[' + inttostr(i) + '].alfaThree').AsString;
               gco_output.gco_countries[i].gco_name := JSN.FindPath('countries[' + inttostr(i) + '].name').AsString;
               gco_output.gco_countries[i].gco_nameBrief := JSN.FindPath('countries[' + inttostr(i) + '].nameBrief').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetFuturesMargin (gfm_input : gfm_request; out gfm_output : gfm_response);
var
   JSN: TJSONData;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      endpoint_url := url_tinvest + 'InstrumentsService/GetFuturesMargin';

      json_base.Add('instrumentId', gfm_input.gfm_instrumentId);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gfm_input.gfm_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gfm_output.gfm_error_code := JSN.FindPath('code').AsInt64;
            gfm_output.gfm_error_message := JSN.FindPath('message').AsString;
            gfm_output.gfm_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gfm_output.gfm_error_description = 0 then begin
            gfm_output.gfm_initialMarginOnBuy.moneyval := UnitsNanoToDouble(JSN.FindPath('initialMarginOnBuy.units').AsInt64 , JSN.FindPath('initialMarginOnBuy.nano').AsInt64);
            gfm_output.gfm_initialMarginOnBuy.currency := JSN.FindPath('initialMarginOnBuy.currency').AsString;
            gfm_output.gfm_initialMarginOnSell.moneyval := UnitsNanoToDouble(JSN.FindPath('initialMarginOnSell.units').AsInt64 , JSN.FindPath('initialMarginOnSell.nano').AsInt64);
            gfm_output.gfm_initialMarginOnSell.currency := JSN.FindPath('initialMarginOnSell.currency').AsString;
            gfm_output.gfm_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('minPriceIncrement.units').AsInt64 , JSN.FindPath('minPriceIncrement.nano').AsInt64);
            gfm_output.gfm_minPriceIncrementAmount := UnitsNanoToDouble(JSN.FindPath('minPriceIncrementAmount.units').AsInt64 , JSN.FindPath('minPriceIncrementAmount.nano').AsInt64);
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetForecastBy (gfb_input : gfb_request; out gfb_output : gfb_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, targets_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      endpoint_url := url_tinvest + 'InstrumentsService/GetForecastBy';

      json_base.Add('instrumentId', gfb_input.gfb_instrumentId);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gfb_input.gfb_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gfb_output.gfb_error_code := JSN.FindPath('code').AsInt64;
            gfb_output.gfb_error_message := JSN.FindPath('message').AsString;
            gfb_output.gfb_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gfb_output.gfb_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('targets'));
            targets_count := json_output_array.Count;

            i := 0;

            SetLength(gfb_output.gfb_targets, targets_count);

            while i < targets_count do  begin
               gfb_output.gfb_targets[i].gfb_uid := JSN.FindPath('targets[' + inttostr(i) + '].uid').AsString;
               gfb_output.gfb_targets[i].gfb_ticker := JSN.FindPath('targets[' + inttostr(i) + '].ticker').AsString;
               gfb_output.gfb_targets[i].gfb_company := JSN.FindPath('targets[' + inttostr(i) + '].company').AsString;
               gfb_output.gfb_targets[i].gfb_recommendation := JSN.FindPath('targets[' + inttostr(i) + '].recommendation').AsString;
               gfb_output.gfb_targets[i].gfb_recommendationDate := JSN.FindPath('targets[' + inttostr(i) + '].recommendationDate').AsString;
               gfb_output.gfb_targets[i].gfb_currency := JSN.FindPath('targets[' + inttostr(i) + '].currency').AsString;
               gfb_output.gfb_targets[i].gfb_currentPrice := UnitsNanoToDouble(JSN.FindPath('targets[' + inttostr(i) + '].currentPrice.units').AsInt64 , JSN.FindPath('targets[' + inttostr(i) + '].currentPrice.nano').AsInt64);
               gfb_output.gfb_targets[i].gfb_targetPrice := UnitsNanoToDouble(JSN.FindPath('targets[' + inttostr(i) + '].targetPrice.units').AsInt64 , JSN.FindPath('targets[' + inttostr(i) + '].targetPrice.nano').AsInt64);
               gfb_output.gfb_targets[i].gfb_priceChange := UnitsNanoToDouble(JSN.FindPath('targets[' + inttostr(i) + '].priceChange.units').AsInt64 , JSN.FindPath('targets[' + inttostr(i) + '].priceChange.nano').AsInt64);
               gfb_output.gfb_targets[i].gfb_priceChangeRel := UnitsNanoToDouble(JSN.FindPath('targets[' + inttostr(i) + '].priceChangeRel.units').AsInt64 , JSN.FindPath('targets[' + inttostr(i) + '].priceChangeRel.nano').AsInt64);
               gfb_output.gfb_targets[i].gfb_showName := JSN.FindPath('targets[' + inttostr(i) + '].showName').AsString;
               inc(i);
            end;


            gfb_output.gfb_consensus.gfb_uid := JSN.FindPath('consensus.uid').AsString;
            gfb_output.gfb_consensus.gfb_ticker := JSN.FindPath('consensus.ticker').AsString;
            gfb_output.gfb_consensus.gfb_recommendation := JSN.FindPath('consensus.recommendation').AsString;
            gfb_output.gfb_consensus.gfb_currency := JSN.FindPath('consensus.currency').AsString;
            gfb_output.gfb_consensus.gfb_currentPrice := UnitsNanoToDouble(JSN.FindPath('consensus.currentPrice.units').AsInt64 , JSN.FindPath('consensus.currentPrice.nano').AsInt64);
            gfb_output.gfb_consensus.gfb_consensus := UnitsNanoToDouble(JSN.FindPath('consensus.consensus.units').AsInt64 , JSN.FindPath('consensus.consensus.nano').AsInt64);
            gfb_output.gfb_consensus.gfb_minTarget := UnitsNanoToDouble(JSN.FindPath('consensus.minTarget.units').AsInt64 , JSN.FindPath('consensus.minTarget.nano').AsInt64);
            gfb_output.gfb_consensus.gfb_maxTarget := UnitsNanoToDouble(JSN.FindPath('consensus.maxTarget.units').AsInt64 , JSN.FindPath('consensus.maxTarget.nano').AsInt64);
            gfb_output.gfb_consensus.gfb_priceChange := UnitsNanoToDouble(JSN.FindPath('consensus.priceChange.units').AsInt64 , JSN.FindPath('consensus.priceChange.nano').AsInt64);
            gfb_output.gfb_consensus.gfb_priceChangeRel := UnitsNanoToDouble(JSN.FindPath('consensus.priceChangeRel.units').AsInt64 , JSN.FindPath('consensus.priceChangeRel.nano').AsInt64);

         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetRiskRates (grr_input : grr_request; out grr_output : grr_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, numb_uids, instrumentRiskRates_count, shortRiskRates_count, longRiskRates_count, i, j, k : int64;
   json_base : TJSONObject;
   json_input_array : TJSONArray;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_input_array := TJSONArray.Create;

      endpoint_url := url_tinvest + 'InstrumentsService/GetRiskRates';

      numb_uids := high(grr_input.grr_instrumentId);

      for i := 0 to numb_uids do begin
         json_input_array.add(grr_input.grr_instrumentId[i]);
      end;

      json_base.Add('instrumentId', json_input_array);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + grr_input.grr_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            grr_output.grr_error_code := JSN.FindPath('code').AsInt64;
            grr_output.grr_error_message := JSN.FindPath('message').AsString;
            grr_output.grr_error_description := JSN.FindPath('description').AsInt64;
         end;

         if grr_output.grr_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('instrumentRiskRates'));
            instrumentRiskRates_count := json_output_array.Count;

            i := 0;

            SetLength(grr_output.grr_instrumentRiskRates, instrumentRiskRates_count);

            while i < instrumentRiskRates_count do  begin
               grr_output.grr_instrumentRiskRates[i].grr_instrumentUid := JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].instrumentUid').AsString;
               grr_output.grr_instrumentRiskRates[i].grr_shortRiskRate.grr_riskLevelCode := JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].shortRiskRate.riskLevelCode').AsString;
               grr_output.grr_instrumentRiskRates[i].grr_shortRiskRate.grr_value := UnitsNanoToDouble(JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].shortRiskRate.value.units').AsInt64 , JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].shortRiskRate.value.nano').AsInt64);
               grr_output.grr_instrumentRiskRates[i].grr_longRiskRate.grr_riskLevelCode := JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].longRiskRate.riskLevelCode').AsString;
               grr_output.grr_instrumentRiskRates[i].grr_longRiskRate.grr_value := UnitsNanoToDouble(JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].longRiskRate.value.units').AsInt64 , JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].longRiskRate.value.nano').AsInt64);

               json_output_array := TJSONArray(JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].shortRiskRates'));
               shortRiskRates_count := json_output_array.Count;

               j := 0;

               SetLength(grr_output.grr_instrumentRiskRates[i].grr_shortRiskRates, shortRiskRates_count);

               while j < shortRiskRates_count do  begin
                  grr_output.grr_instrumentRiskRates[i].grr_shortRiskRates[j].grr_riskLevelCode := JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].shortRiskRates[' + inttostr(j) + '].riskLevelCode').AsString;
                  grr_output.grr_instrumentRiskRates[i].grr_shortRiskRates[j].grr_value := UnitsNanoToDouble(JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].shortRiskRates[' + inttostr(j) + '].value.units').AsInt64 , JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].shortRiskRates[' + inttostr(j) + '].value.nano').AsInt64);
                  inc(j);
               end;

               json_output_array := TJSONArray(JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].longRiskRates'));
               longRiskRates_count := json_output_array.Count;

               k := 0;

               SetLength(grr_output.grr_instrumentRiskRates[i].grr_longRiskRates, longRiskRates_count);

               while k < longRiskRates_count do  begin
                  grr_output.grr_instrumentRiskRates[i].grr_longRiskRates[k].grr_riskLevelCode := JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].longRiskRates[' + inttostr(k) + '].riskLevelCode').AsString;
                  grr_output.grr_instrumentRiskRates[i].grr_longRiskRates[k].grr_value := UnitsNanoToDouble(JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].longRiskRates[' + inttostr(k) + '].value.units').AsInt64 , JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].longRiskRates[' + inttostr(k) + '].value.nano').AsInt64);
                  inc(k);
               end;

               grr_output.grr_instrumentRiskRates[i].grr_error := JSN.FindPath('instrumentRiskRates[' + inttostr(i) + '].error').AsString;

               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetConsensusForecasts (gcf_input : gcf_request; out gcf_output : gcf_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, items_count, i : int64;
   json_base, json_nested : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested := TJSONObject.Create;

      endpoint_url := url_tinvest + 'InstrumentsService/GetConsensusForecasts';

      if gcf_input.gcf_paging.gcf_limit > 0 then json_nested.Add('limit', gcf_input.gcf_paging.gcf_limit);
      if gcf_input.gcf_paging.gcf_pageNumber >= 0 then json_nested.Add('pageNumber', gcf_input.gcf_paging.gcf_pageNumber);
      json_base.Add('paging', json_nested);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gcf_input.gcf_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gcf_output.gcf_error_code := JSN.FindPath('code').AsInt64;
            gcf_output.gcf_error_message := JSN.FindPath('message').AsString;
            gcf_output.gcf_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gcf_output.gcf_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('items'));
            items_count := json_output_array.Count;

            i := 0;

            SetLength(gcf_output.gcf_items, items_count);

            while i < items_count do  begin
               gcf_output.gcf_items[i].gcf_uid := JSN.FindPath('items[' + inttostr(i) + '].uid').AsString;
               gcf_output.gcf_items[i].gcf_assetUid := JSN.FindPath('items[' + inttostr(i) + '].assetUid').AsString;
               gcf_output.gcf_items[i].gcf_createdAt := JSN.FindPath('items[' + inttostr(i) + '].createdAt').AsString;
               gcf_output.gcf_items[i].gcf_bestTargetPrice := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].bestTargetPrice.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].bestTargetPrice.nano').AsInt64);
               gcf_output.gcf_items[i].gcf_bestTargetLow := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].bestTargetLow.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].bestTargetLow.nano').AsInt64);
               gcf_output.gcf_items[i].gcf_bestTargetHigh := UnitsNanoToDouble(JSN.FindPath('items[' + inttostr(i) + '].bestTargetHigh.units').AsInt64 , JSN.FindPath('items[' + inttostr(i) + '].bestTargetHigh.nano').AsInt64);
               gcf_output.gcf_items[i].gcf_totalBuyRecommend := JSN.FindPath('items[' + inttostr(i) + '].totalBuyRecommend').AsInt64;
               gcf_output.gcf_items[i].gcf_totalHoldRecommend := JSN.FindPath('items[' + inttostr(i) + '].totalHoldRecommend').AsInt64;
               gcf_output.gcf_items[i].gcf_totalSellRecommend := JSN.FindPath('items[' + inttostr(i) + '].totalSellRecommend').AsInt64;
               gcf_output.gcf_items[i].gcf_currency := JSN.FindPath('items[' + inttostr(i) + '].currency').AsString;
               gcf_output.gcf_items[i].gcf_consensus := JSN.FindPath('items[' + inttostr(i) + '].consensus').AsString;
               gcf_output.gcf_items[i].gcf_prognosisDate := JSN.FindPath('items[' + inttostr(i) + '].prognosisDate').AsString;
               inc(i);
            end;
            gcf_output.gcf_page.gcf_limit := JSN.FindPath('page.limit').AsInt64;
            gcf_output.gcf_page.gcf_pageNumber := JSN.FindPath('page.pageNumber').AsInt64;
            gcf_output.gcf_page.gcf_totalCount := JSN.FindPath('page.totalCount').AsInt64;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetStructuredNotes (sn_input : sn_request; out sn_output : sn_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, notes_count, basicAssets_count, yield_count, tests_count, i, j, k, l : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if sn_input.sn_instrumentStatus <> '' then json_base.Add('instrumentStatus', sn_input.sn_instrumentStatus);
      if sn_input.sn_instrumentExchange <> '' then json_base.Add('instrumentExchange', sn_input.sn_instrumentExchange);

      endpoint_url := url_tinvest + 'InstrumentsService/StructuredNotes';
      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + sn_input.sn_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            sn_output.sn_error_code := JSN.FindPath('code').AsInt64;
            sn_output.sn_error_message := JSN.FindPath('message').AsString;
            sn_output.sn_error_description := JSN.FindPath('description').AsInt64;
         end;

         if sn_output.sn_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('instruments'));

            notes_count := json_output_array.Count;
            SetLength(sn_output.sn_instruments, notes_count);

            i := 0;

            while i < notes_count do  begin
               sn_output.sn_instruments[i].sn_uid := JSN.FindPath('instruments[' + inttostr(i) + '].uid').AsString;
               sn_output.sn_instruments[i].sn_figi := JSN.FindPath('instruments[' + inttostr(i) + '].figi').AsString;
               sn_output.sn_instruments[i].sn_ticker := JSN.FindPath('instruments[' + inttostr(i) + '].ticker').AsString;
               sn_output.sn_instruments[i].sn_classCode := JSN.FindPath('instruments[' + inttostr(i) + '].classCode').AsString;
               sn_output.sn_instruments[i].sn_isin := JSN.FindPath('instruments[' + inttostr(i) + '].isin').AsString;
               sn_output.sn_instruments[i].sn_name := JSN.FindPath('instruments[' + inttostr(i) + '].name').AsString;
               sn_output.sn_instruments[i].sn_assetUid := JSN.FindPath('instruments[' + inttostr(i) + '].assetUid').AsString;
               sn_output.sn_instruments[i].sn_positionUid := JSN.FindPath('instruments[' + inttostr(i) + '].positionUid').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement') <> nil then
                  sn_output.sn_instruments[i].sn_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.nano').AsInt64);
               sn_output.sn_instruments[i].sn_lot := JSN.FindPath('instruments[' + inttostr(i) + '].lot').AsInt64;
               sn_output.sn_instruments[i].sn_nominal.moneyval := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].nominal.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].nominal.nano').AsInt64);
               sn_output.sn_instruments[i].sn_nominal.currency := JSN.FindPath('instruments[' + inttostr(i) + '].nominal.currency').AsString;
               sn_output.sn_instruments[i].sn_currency := JSN.FindPath('instruments[' + inttostr(i) + '].currency').AsString;
               sn_output.sn_instruments[i].sn_maturityDate := JSN.FindPath('instruments[' + inttostr(i) + '].maturityDate').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].placementDate') <> nil then
                  sn_output.sn_instruments[i].sn_placementDate := JSN.FindPath('instruments[' + inttostr(i) + '].placementDate').AsString;
               sn_output.sn_instruments[i].sn_issueKind := JSN.FindPath('instruments[' + inttostr(i) + '].issueKind').AsString;
               sn_output.sn_instruments[i].sn_issueSize := JSN.FindPath('instruments[' + inttostr(i) + '].issueSize').AsInt64;
               sn_output.sn_instruments[i].sn_issueSizePlan := JSN.FindPath('instruments[' + inttostr(i) + '].issueSizePlan').AsInt64;
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient') <> nil then
                  sn_output.sn_instruments[i].sn_dlongClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient') <> nil then
                  sn_output.sn_instruments[i].sn_dshortClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.nano').AsInt64);
               sn_output.sn_instruments[i].sn_shortEnabledFlag := JSN.FindPath('instruments[' + inttostr(i) + '].shortEnabledFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_exchange := JSN.FindPath('instruments[' + inttostr(i) + '].exchange').AsString;
               sn_output.sn_instruments[i].sn_tradingStatus := JSN.FindPath('instruments[' + inttostr(i) + '].tradingStatus').AsString;
               sn_output.sn_instruments[i].sn_apiTradeAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].apiTradeAvailableFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_buyAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].buyAvailableFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_sellAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].sellAvailableFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_limitOrderAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].limitOrderAvailableFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_marketOrderAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].marketOrderAvailableFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_bestpriceOrderAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].bestpriceOrderAvailableFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_weekendFlag := JSN.FindPath('instruments[' + inttostr(i) + '].weekendFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_liquidityFlag := JSN.FindPath('instruments[' + inttostr(i) + '].liquidityFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_forIisFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forIisFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_forQualInvestorFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forQualInvestorFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_pawnshopListFlag := JSN.FindPath('instruments[' + inttostr(i) + '].pawnshopListFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_realExchange := JSN.FindPath('instruments[' + inttostr(i) + '].realExchange').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate') <> nil then
                  sn_output.sn_instruments[i].sn_first1minCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate') <> nil then
                  sn_output.sn_instruments[i].sn_first1dayCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate').AsString;
               sn_output.sn_instruments[i].sn_borrowName := JSN.FindPath('instruments[' + inttostr(i) + '].borrowName').AsString;
               sn_output.sn_instruments[i].sn_type := JSN.FindPath('instruments[' + inttostr(i) + '].type').AsString;
               sn_output.sn_instruments[i].sn_logicPortfolio := JSN.FindPath('instruments[' + inttostr(i) + '].logicPortfolio').AsString;
               sn_output.sn_instruments[i].sn_assetType := JSN.FindPath('instruments[' + inttostr(i) + '].assetType').AsString;

               json_output_array := TJSONArray(JSN.FindPath('instruments[' + inttostr(i) + '].basicAssets'));
               basicAssets_count := json_output_array.Count;
               SetLength(sn_output.sn_instruments[i].sn_basicAssets, basicAssets_count);
               j := 0;

               while j < basicAssets_count do  begin
                  sn_output.sn_instruments[i].sn_basicAssets[j].sn_uid := JSN.FindPath('instruments[' + inttostr(i) + '].basicAssets[' + inttostr(j) + '].uid').AsString;
                  sn_output.sn_instruments[i].sn_basicAssets[j].sn_type := JSN.FindPath('instruments[' + inttostr(i) + '].basicAssets[' + inttostr(j) + '].type').AsString;
                  sn_output.sn_instruments[i].sn_basicAssets[j].sn_initialPrice := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].basicAssets[' + inttostr(j) + '].initialPrice.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].basicAssets[' + inttostr(j) + '].initialPrice.nano').AsInt64);
                  inc(j);
               end;

               sn_output.sn_instruments[i].sn_safetyBarrier := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].safetyBarrier.units').AsInt64 , JSN.FindPath('instruments[' + inttostr(i) + '].safetyBarrier.nano').AsInt64);
               sn_output.sn_instruments[i].sn_couponPeriodBase := JSN.FindPath('instruments[' + inttostr(i) + '].couponPeriodBase').AsString;
               sn_output.sn_instruments[i].sn_observationPrinciple := JSN.FindPath('instruments[' + inttostr(i) + '].observationPrinciple').AsString;
               sn_output.sn_instruments[i].sn_observationFrequency := JSN.FindPath('instruments[' + inttostr(i) + '].observationFrequency').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].initialPriceFixingDate') <> nil then
                  sn_output.sn_instruments[i].sn_initialPriceFixingDate := JSN.FindPath('instruments[' + inttostr(i) + '].initialPriceFixingDate').AsString;

               json_output_array := TJSONArray(JSN.FindPath('instruments[' + inttostr(i) + '].yield'));
               yield_count := json_output_array.Count;
               SetLength(sn_output.sn_instruments[i].sn_yield, yield_count);
               k := 0;

               while k < yield_count do  begin
                  sn_output.sn_instruments[i].sn_yield[k].sn_type := JSN.FindPath('instruments[' + inttostr(i) + '].yield[' + inttostr(k) + '].type').AsString;
                  sn_output.sn_instruments[i].sn_yield[k].sn_value := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].yield[' + inttostr(k) + '].value.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].yield[' + inttostr(k) + '].value.nano').AsInt64);
                  inc(k);
               end;

               sn_output.sn_instruments[i].sn_couponSavingFlag := JSN.FindPath('instruments[' + inttostr(i) + '].couponSavingFlag').AsBoolean;
               sn_output.sn_instruments[i].sn_sector := JSN.FindPath('instruments[' + inttostr(i) + '].sector').AsString;
               sn_output.sn_instruments[i].sn_countryOfRisk := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRisk').AsString;
               sn_output.sn_instruments[i].sn_countryOfRiskName := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRiskName').AsString;
               sn_output.sn_instruments[i].sn_logoName := JSN.FindPath('instruments[' + inttostr(i) + '].logoName').AsString;

               json_output_array := TJSONArray(JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests'));
               tests_count := json_output_array.Count;
               SetLength(sn_output.sn_instruments[i].sn_requiredTests, tests_count);
               l := 0;

               while l < tests_count do  begin
                  sn_output.sn_instruments[i].sn_requiredTests[l] := JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests[' + inttostr(l) + ']').AsString;
                  inc(l);
               end;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetStructuredNoteBy (snb_input : snb_request; out snb_output : snb_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, basicAssets_count, yield_count, tests_count, i, j, k : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if snb_input.snb_idType <> '' then json_base.Add('idType', snb_input.snb_idType);
      if snb_input.snb_classCode <> '' then json_base.Add('classCode', snb_input.snb_classCode);
      if snb_input.snb_id <> '' then json_base.Add('id', snb_input.snb_id);

      endpoint_url := url_tinvest + 'InstrumentsService/StructuredNoteBy';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + snb_input.snb_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            snb_output.snb_error_code := JSN.FindPath('code').AsInt64;
            snb_output.snb_error_message := JSN.FindPath('message').AsString;
            snb_output.snb_error_description := JSN.FindPath('description').AsInt64;
         end;

         if snb_output.snb_error_description = 0 then begin
            snb_output.snb_instrument.sn_uid := JSN.FindPath('instrument.uid').AsString;
            snb_output.snb_instrument.sn_figi := JSN.FindPath('instrument.figi').AsString;
            snb_output.snb_instrument.sn_ticker := JSN.FindPath('instrument.ticker').AsString;
            snb_output.snb_instrument.sn_classCode := JSN.FindPath('instrument.classCode').AsString;
            snb_output.snb_instrument.sn_isin := JSN.FindPath('instrument.isin').AsString;
            snb_output.snb_instrument.sn_name := JSN.FindPath('instrument.name').AsString;
            snb_output.snb_instrument.sn_assetUid := JSN.FindPath('instrument.assetUid').AsString;
            snb_output.snb_instrument.sn_positionUid := JSN.FindPath('instrument.positionUid').AsString;
            if JSN.FindPath('instrument.minPriceIncrement') <> nil then
               snb_output.snb_instrument.sn_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instrument.minPriceIncrement.units').AsInt64 , JSN.FindPath('instrument.minPriceIncrement.nano').AsInt64);
            snb_output.snb_instrument.sn_lot := JSN.FindPath('instrument.lot').AsInt64;
            snb_output.snb_instrument.sn_nominal.moneyval := UnitsNanoToDouble(JSN.FindPath('instrument.nominal.units').AsInt64 , JSN.FindPath('instrument.nominal.nano').AsInt64);
            snb_output.snb_instrument.sn_nominal.currency := JSN.FindPath('instrument.nominal.currency').AsString;
            snb_output.snb_instrument.sn_currency := JSN.FindPath('instrument.currency').AsString;
            snb_output.snb_instrument.sn_maturityDate := JSN.FindPath('instrument.maturityDate').AsString;
            if JSN.FindPath('instrument.placementDate') <> nil then
               snb_output.snb_instrument.sn_placementDate := JSN.FindPath('instrument.placementDate').AsString;
            snb_output.snb_instrument.sn_issueKind := JSN.FindPath('instrument.issueKind').AsString;
            snb_output.snb_instrument.sn_issueSize := JSN.FindPath('instrument.issueSize').AsInt64;
            snb_output.snb_instrument.sn_issueSizePlan := JSN.FindPath('instrument.issueSizePlan').AsInt64;
            if JSN.FindPath('instrument.dlongClient') <> nil then
               snb_output.snb_instrument.sn_dlongClient := UnitsNanoToDouble(JSN.FindPath('instrument.dlongClient.units').AsInt64 , JSN.FindPath('instrument.dlongClient.nano').AsInt64);
            if JSN.FindPath('instrument.dshortClient') <> nil then
               snb_output.snb_instrument.sn_dshortClient := UnitsNanoToDouble(JSN.FindPath('instrument.dshortClient.units').AsInt64 , JSN.FindPath('instrument.dshortClient.nano').AsInt64);
            snb_output.snb_instrument.sn_shortEnabledFlag := JSN.FindPath('instrument.shortEnabledFlag').AsBoolean;
            snb_output.snb_instrument.sn_exchange := JSN.FindPath('instrument.exchange').AsString;
            snb_output.snb_instrument.sn_tradingStatus := JSN.FindPath('instrument.tradingStatus').AsString;
            snb_output.snb_instrument.sn_apiTradeAvailableFlag := JSN.FindPath('instrument.apiTradeAvailableFlag').AsBoolean;
            snb_output.snb_instrument.sn_buyAvailableFlag := JSN.FindPath('instrument.buyAvailableFlag').AsBoolean;
            snb_output.snb_instrument.sn_sellAvailableFlag := JSN.FindPath('instrument.sellAvailableFlag').AsBoolean;
            snb_output.snb_instrument.sn_limitOrderAvailableFlag := JSN.FindPath('instrument.limitOrderAvailableFlag').AsBoolean;
            snb_output.snb_instrument.sn_marketOrderAvailableFlag := JSN.FindPath('instrument.marketOrderAvailableFlag').AsBoolean;
            snb_output.snb_instrument.sn_bestpriceOrderAvailableFlag := JSN.FindPath('instrument.bestpriceOrderAvailableFlag').AsBoolean;
            snb_output.snb_instrument.sn_weekendFlag := JSN.FindPath('instrument.weekendFlag').AsBoolean;
            snb_output.snb_instrument.sn_liquidityFlag := JSN.FindPath('instrument.liquidityFlag').AsBoolean;
            snb_output.snb_instrument.sn_forIisFlag := JSN.FindPath('instrument.forIisFlag').AsBoolean;
            snb_output.snb_instrument.sn_forQualInvestorFlag := JSN.FindPath('instrument.forQualInvestorFlag').AsBoolean;
            snb_output.snb_instrument.sn_pawnshopListFlag := JSN.FindPath('instrument.pawnshopListFlag').AsBoolean;
            snb_output.snb_instrument.sn_realExchange := JSN.FindPath('instrument.realExchange').AsString;
            if JSN.FindPath('instrument.first1minCandleDate') <> nil then
               snb_output.snb_instrument.sn_first1minCandleDate := JSN.FindPath('instrument.first1minCandleDate').AsString;
            if JSN.FindPath('instrument.first1dayCandleDate') <> nil then
               snb_output.snb_instrument.sn_first1dayCandleDate := JSN.FindPath('instrument.first1dayCandleDate').AsString;
            snb_output.snb_instrument.sn_borrowName := JSN.FindPath('instrument.borrowName').AsString;
            snb_output.snb_instrument.sn_type := JSN.FindPath('instrument.type').AsString;
            snb_output.snb_instrument.sn_logicPortfolio := JSN.FindPath('instrument.logicPortfolio').AsString;
            snb_output.snb_instrument.sn_assetType := JSN.FindPath('instrument.assetType').AsString;

            json_output_array := TJSONArray(JSN.FindPath('instrument.basicAssets'));
            basicAssets_count := json_output_array.Count;
            SetLength(snb_output.snb_instrument.sn_basicAssets, basicAssets_count);
            i := 0;

            while i < basicAssets_count do  begin
               snb_output.snb_instrument.sn_basicAssets[i].sn_uid := JSN.FindPath('instrument.basicAssets[' + inttostr(i) + '].uid').AsString;
               snb_output.snb_instrument.sn_basicAssets[i].sn_type := JSN.FindPath('instrument.basicAssets[' + inttostr(i) + '].type').AsString;
               snb_output.snb_instrument.sn_basicAssets[i].sn_initialPrice := UnitsNanoToDouble(JSN.FindPath('instrument.basicAssets[' + inttostr(i) + '].initialPrice.units').AsInt64, JSN.FindPath('instrument.basicAssets[' + inttostr(i) + '].initialPrice.nano').AsInt64);
               inc(i);
            end;

            snb_output.snb_instrument.sn_safetyBarrier := UnitsNanoToDouble(JSN.FindPath('instrument.safetyBarrier.units').AsInt64 , JSN.FindPath('instrument.safetyBarrier.nano').AsInt64);
            snb_output.snb_instrument.sn_couponPeriodBase := JSN.FindPath('instrument.couponPeriodBase').AsString;
            snb_output.snb_instrument.sn_observationPrinciple := JSN.FindPath('instrument.observationPrinciple').AsString;
            snb_output.snb_instrument.sn_observationFrequency := JSN.FindPath('instrument.observationFrequency').AsString;
            if JSN.FindPath('instrument.initialPriceFixingDate') <> nil then
               snb_output.snb_instrument.sn_initialPriceFixingDate := JSN.FindPath('instrument.initialPriceFixingDate').AsString;

            json_output_array := TJSONArray(JSN.FindPath('instrument.yield'));
            yield_count := json_output_array.Count;
            SetLength(snb_output.snb_instrument.sn_yield, yield_count);
            j := 0;

            while j < yield_count do  begin
               snb_output.snb_instrument.sn_yield[j].sn_type := JSN.FindPath('instrument.yield[' + inttostr(j) + '].type').AsString;
               snb_output.snb_instrument.sn_yield[j].sn_value := UnitsNanoToDouble(JSN.FindPath('instrument.yield[' + inttostr(j) + '].value.units').AsInt64, JSN.FindPath('instrument.yield[' + inttostr(j) + '].value.nano').AsInt64);
               inc(j);
            end;

            snb_output.snb_instrument.sn_couponSavingFlag := JSN.FindPath('instrument.couponSavingFlag').AsBoolean;
            snb_output.snb_instrument.sn_sector := JSN.FindPath('instrument.sector').AsString;
            snb_output.snb_instrument.sn_countryOfRisk := JSN.FindPath('instrument.countryOfRisk').AsString;
            snb_output.snb_instrument.sn_countryOfRiskName := JSN.FindPath('instrument.countryOfRiskName').AsString;
            snb_output.snb_instrument.sn_logoName := JSN.FindPath('instrument.logoName').AsString;

            json_output_array := TJSONArray(JSN.FindPath('instrument.requiredTests'));
            tests_count := json_output_array.Count;
            SetLength(snb_output.snb_instrument.sn_requiredTests, tests_count);
            k := 0;

            while k < tests_count do  begin
               snb_output.snb_instrument.sn_requiredTests[k] := JSN.FindPath('instrument.requiredTests[' + inttostr(k) + ']').AsString;
               inc(k);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetDividendsForeignIssuer (gdfi_input : gdfi_request; out gdfi_output : gdfi_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, dividendsForeignIssuerReport_count, i : int64;
   json_base, json_nested1, json_nested2 : TJSONObject;

begin
   try
      if requests_limit.Report_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.Report_limit.h_ratelimit_reset * 1000);
        requests_limit.Report_limit.h_ratelimit_remaining := requests_limit.Report_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_nested1 := TJSONObject.Create;

      endpoint_url := url_tinvest + 'OperationsService/GetDividendsForeignIssuer';


      json_nested1.Add('accountId', gdfi_input.gdfi_generateDivForeignIssuerReport.gdfi_accountId);
      json_nested1.Add('from', gdfi_input.gdfi_generateDivForeignIssuerReport.gdfi_from);
      json_nested1.Add('to', gdfi_input.gdfi_generateDivForeignIssuerReport.gdfi_to);
      json_base.Add('generateDivForeignIssuerReport', json_nested1);

      if (gdfi_input.gdfi_getDivForeignIssuerReport.gdfi_taskId <> '') and (gdfi_input.gdfi_getDivForeignIssuerReport.gdfi_page > 0) then begin
         json_nested2 := TJSONObject.Create;
         json_nested2.Add('taskId', gdfi_input.gdfi_getDivForeignIssuerReport.gdfi_taskId);
         json_nested2.Add('page', gdfi_input.gdfi_getDivForeignIssuerReport.gdfi_page);
         json_base.Add('getDivForeignIssuerReport', json_nested2);
      end;

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gdfi_input.gdfi_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.Report_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gdfi_output.gdfi_error_code := JSN.FindPath('code').AsInt64;
            gdfi_output.gdfi_error_message := JSN.FindPath('message').AsString;
            gdfi_output.gdfi_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gdfi_output.gdfi_error_description = 0 then begin

            if JSN.FindPath('generateDivForeignIssuerReportResponse.taskId') <> nil then
               gdfi_output.gdfi_generateDivForeignIssuerReportResponse.gdfi_taskId := JSN.FindPath('generateDivForeignIssuerReportResponse.taskId').AsString;

            dividendsForeignIssuerReport_count := 0;

            if JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport') <> nil then begin
               json_output_array := TJSONArray(JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport'));
               dividendsForeignIssuerReport_count := json_output_array.Count;
            end;

            i := 0;

            SetLength(gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport, dividendsForeignIssuerReport_count);

            while i < dividendsForeignIssuerReport_count do  begin
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport[i].gdfi_recordDate := JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].recordDate').AsString;
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport[i].gdfi_paymentDate := JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].paymentDate').AsString;
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport[i].gdfi_securityName := JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].securityName').AsString;
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport[i].gdfi_isin := JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].isin').AsString;
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport[i].gdfi_issuerCountry := JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].issuerCountry').AsString;
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport[i].gdfi_quantity := JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].quantity').AsInt64;
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport[i].gdfi_dividend := UnitsNanoToDouble(JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].dividend.units').AsInt64, JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].dividend.nano').AsInt64);
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport[i].gdfi_externalCommission := UnitsNanoToDouble(JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].externalCommission.units').AsInt64, JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].externalCommission.nano').AsInt64);
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport[i].gdfi_dividendGross := UnitsNanoToDouble(JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].dividendGross.units').AsInt64, JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].dividendGross.nano').AsInt64);
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport[i].gdfi_tax := UnitsNanoToDouble(JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].tax.units').AsInt64, JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].tax.nano').AsInt64);
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport[i].gdfi_dividendAmount := UnitsNanoToDouble(JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].dividendAmount.units').AsInt64, JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].dividendAmount.nano').AsInt64);
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_dividendsForeignIssuerReport[i].gdfi_currency := JSN.FindPath('divForeignIssuerReport.dividendsForeignIssuerReport[' + inttostr(i) + '].currency').AsString;
               inc(i);
            end;

            if JSN.FindPath('divForeignIssuerReport.itemsCount') <> nil then
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_itemsCount := JSN.FindPath('divForeignIssuerReport.itemsCount').AsInt64;
            if JSN.FindPath('divForeignIssuerReport.pagesCount') <> nil then
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_pagesCount := JSN.FindPath('divForeignIssuerReport.pagesCount').AsInt64;
            if JSN.FindPath('divForeignIssuerReport.page') <> nil then
               gdfi_output.gdfi_divForeignIssuerReport.gdfi_page := JSN.FindPath('divForeignIssuerReport.page').AsInt64;
         end;
      end;



   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetOptionsBy (o_input : o_request; out o_output : o_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, options_count, tests_count, i, j : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if o_input.o_basicAssetUid <> '' then json_base.Add('basicAssetUid', o_input.o_basicAssetUid);
      if o_input.o_basicAssetPositionUid <> '' then json_base.Add('basicAssetPositionUid', o_input.o_basicAssetPositionUid);
      if o_input.o_basicInstrumentId <> '' then json_base.Add('basicInstrumentId', o_input.o_basicInstrumentId);


      endpoint_url := url_tinvest + 'InstrumentsService/OptionsBy';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + o_input.o_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            o_output.o_error_code := JSN.FindPath('code').AsInt64;
            o_output.o_error_message := JSN.FindPath('message').AsString;
            o_output.o_error_description := JSN.FindPath('description').AsInt64;
         end;

         if o_output.o_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('instruments'));

            options_count := json_output_array.Count;
            SetLength(o_output.o_instruments, options_count);

            i := 0;

            while i < options_count do  begin
               o_output.o_instruments[i].o_uid := JSN.FindPath('instruments[' + inttostr(i) + '].uid').AsString;
               o_output.o_instruments[i].o_positionUid := JSN.FindPath('instruments[' + inttostr(i) + '].positionUid').AsString;
               o_output.o_instruments[i].o_ticker := JSN.FindPath('instruments[' + inttostr(i) + '].ticker').AsString;
               o_output.o_instruments[i].o_classCode := JSN.FindPath('instruments[' + inttostr(i) + '].classCode').AsString;
               o_output.o_instruments[i].o_basicAssetPositionUid := JSN.FindPath('instruments[' + inttostr(i) + '].basicAssetPositionUid').AsString;
               o_output.o_instruments[i].o_tradingStatus := JSN.FindPath('instruments[' + inttostr(i) + '].tradingStatus').AsString;
               o_output.o_instruments[i].o_realExchange := JSN.FindPath('instruments[' + inttostr(i) + '].realExchange').AsString;
               o_output.o_instruments[i].o_direction := JSN.FindPath('instruments[' + inttostr(i) + '].direction').AsString;
               o_output.o_instruments[i].o_paymentType := JSN.FindPath('instruments[' + inttostr(i) + '].paymentType').AsString;
               o_output.o_instruments[i].o_style := JSN.FindPath('instruments[' + inttostr(i) + '].style').AsString;
               o_output.o_instruments[i].o_settlementType := JSN.FindPath('instruments[' + inttostr(i) + '].settlementType').AsString;
               o_output.o_instruments[i].o_name := JSN.FindPath('instruments[' + inttostr(i) + '].name').AsString;
               o_output.o_instruments[i].o_currency := JSN.FindPath('instruments[' + inttostr(i) + '].currency').AsString;
               o_output.o_instruments[i].o_settlementCurrency := JSN.FindPath('instruments[' + inttostr(i) + '].settlementCurrency').AsString;
               o_output.o_instruments[i].o_assetType := JSN.FindPath('instruments[' + inttostr(i) + '].assetType').AsString;
               o_output.o_instruments[i].o_basicAsset := JSN.FindPath('instruments[' + inttostr(i) + '].basicAsset').AsString;
               o_output.o_instruments[i].o_exchange := JSN.FindPath('instruments[' + inttostr(i) + '].exchange').AsString;
               o_output.o_instruments[i].o_countryOfRisk := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRisk').AsString;
               o_output.o_instruments[i].o_countryOfRiskName := JSN.FindPath('instruments[' + inttostr(i) + '].countryOfRiskName').AsString;
               o_output.o_instruments[i].o_sector := JSN.FindPath('instruments[' + inttostr(i) + '].sector').AsString;
               o_output.o_instruments[i].o_brand.o_logoName := JSN.FindPath('instruments[' + inttostr(i) + '].brand.logoName').AsString;
               o_output.o_instruments[i].o_brand.o_logoBaseColor := JSN.FindPath('instruments[' + inttostr(i) + '].brand.logoBaseColor').AsString;
               o_output.o_instruments[i].o_brand.o_textColor := JSN.FindPath('instruments[' + inttostr(i) + '].brand.textColor').AsString;
               o_output.o_instruments[i].o_lot := JSN.FindPath('instruments[' + inttostr(i) + '].lot').AsInt64;
               o_output.o_instruments[i].o_basicAssetSize := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].basicAssetSize.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].basicAssetSize.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].klong.units') <> nil then
                  o_output.o_instruments[i].o_klong := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].klong.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].klong.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].kshort.units') <> nil then
                  o_output.o_instruments[i].o_kshort := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].kshort.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].kshort.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlong.units') <> nil then
                  o_output.o_instruments[i].o_dlong := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlong.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].dlong.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshort.units') <> nil then
                  o_output.o_instruments[i].o_dshort := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshort.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].dshort.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.units') <> nil then
                  o_output.o_instruments[i].o_dlongMin := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].dlongMin.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.units') <> nil then
                  o_output.o_instruments[i].o_dshortMin := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].dshortMin.nano').AsInt64);
               o_output.o_instruments[i].o_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].minPriceIncrement.nano').AsInt64);
               o_output.o_instruments[i].o_strikePrice.moneyval := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].strikePrice.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].strikePrice.nano').AsInt64);
               o_output.o_instruments[i].o_strikePrice.currency := JSN.FindPath('instruments[' + inttostr(i) + '].strikePrice.currency').AsString;
               if JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.units') <> nil then
                  o_output.o_instruments[i].o_dlongClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].dlongClient.nano').AsInt64);
               if JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.units') <> nil then
                  o_output.o_instruments[i].o_dshortClient := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.units').AsInt64, JSN.FindPath('instruments[' + inttostr(i) + '].dshortClient.nano').AsInt64);
               o_output.o_instruments[i].o_expirationDate := JSN.FindPath('instruments[' + inttostr(i) + '].expirationDate').AsString;
               o_output.o_instruments[i].o_firstTradeDate := JSN.FindPath('instruments[' + inttostr(i) + '].firstTradeDate').AsString;
               o_output.o_instruments[i].o_lastTradeDate := JSN.FindPath('instruments[' + inttostr(i) + '].lastTradeDate').AsString;
               o_output.o_instruments[i].o_first1minCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1minCandleDate').AsString;
               o_output.o_instruments[i].o_first1dayCandleDate := JSN.FindPath('instruments[' + inttostr(i) + '].first1dayCandleDate').AsString;
               o_output.o_instruments[i].o_shortEnabledFlag := JSN.FindPath('instruments[' + inttostr(i) + '].shortEnabledFlag').AsBoolean;
               o_output.o_instruments[i].o_forIisFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forIisFlag').AsBoolean;
               o_output.o_instruments[i].o_otcFlag := JSN.FindPath('instruments[' + inttostr(i) + '].otcFlag').AsBoolean;
               o_output.o_instruments[i].o_buyAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].buyAvailableFlag').AsBoolean;
               o_output.o_instruments[i].o_sellAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].sellAvailableFlag').AsBoolean;
               o_output.o_instruments[i].o_forQualInvestorFlag := JSN.FindPath('instruments[' + inttostr(i) + '].forQualInvestorFlag').AsBoolean;
               o_output.o_instruments[i].o_weekendFlag := JSN.FindPath('instruments[' + inttostr(i) + '].weekendFlag').AsBoolean;
               o_output.o_instruments[i].o_blockedTcaFlag := JSN.FindPath('instruments[' + inttostr(i) + '].blockedTcaFlag').AsBoolean;
               o_output.o_instruments[i].o_apiTradeAvailableFlag := JSN.FindPath('instruments[' + inttostr(i) + '].apiTradeAvailableFlag').AsBoolean;

               json_output_array := TJSONArray(JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests'));
               tests_count := json_output_array.Count;
               SetLength(o_output.o_instruments[i].o_requiredTests, tests_count);
               j := 0;

               while j < tests_count do  begin
                  o_output.o_instruments[i].o_requiredTests[j] := JSN.FindPath('instruments[' + inttostr(i) + '].requiredTests[' + inttostr(j) + ']').AsString;
                  inc(j);
               end;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetOptionBy (ob_input : ob_request; out ob_output : ob_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, tests_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      json_base.Add('idType', ob_input.ob_idType);
      if ob_input.ob_classCode <> '' then json_base.Add('classCode', ob_input.ob_classCode);
      json_base.Add('id', ob_input.ob_id);


      endpoint_url := url_tinvest + 'InstrumentsService/OptionBy';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + ob_input.ob_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            ob_output.ob_error_code := JSN.FindPath('code').AsInt64;
            ob_output.ob_error_message := JSN.FindPath('message').AsString;
            ob_output.ob_error_description := JSN.FindPath('description').AsInt64;
         end;

         if ob_output.ob_error_description = 0 then begin
            ob_output.ob_instrument.o_uid := JSN.FindPath('instrument.uid').AsString;
            ob_output.ob_instrument.o_positionUid := JSN.FindPath('instrument.positionUid').AsString;
            ob_output.ob_instrument.o_ticker := JSN.FindPath('instrument.ticker').AsString;
            ob_output.ob_instrument.o_classCode := JSN.FindPath('instrument.classCode').AsString;
            ob_output.ob_instrument.o_basicAssetPositionUid := JSN.FindPath('instrument.basicAssetPositionUid').AsString;
            ob_output.ob_instrument.o_tradingStatus := JSN.FindPath('instrument.tradingStatus').AsString;
            ob_output.ob_instrument.o_realExchange := JSN.FindPath('instrument.realExchange').AsString;
            ob_output.ob_instrument.o_direction := JSN.FindPath('instrument.direction').AsString;
            ob_output.ob_instrument.o_paymentType := JSN.FindPath('instrument.paymentType').AsString;
            ob_output.ob_instrument.o_style := JSN.FindPath('instrument.style').AsString;
            ob_output.ob_instrument.o_settlementType := JSN.FindPath('instrument.settlementType').AsString;
            ob_output.ob_instrument.o_name := JSN.FindPath('instrument.name').AsString;
            ob_output.ob_instrument.o_currency := JSN.FindPath('instrument.currency').AsString;
            ob_output.ob_instrument.o_settlementCurrency := JSN.FindPath('instrument.settlementCurrency').AsString;
            ob_output.ob_instrument.o_assetType := JSN.FindPath('instrument.assetType').AsString;
            ob_output.ob_instrument.o_basicAsset := JSN.FindPath('instrument.basicAsset').AsString;
            ob_output.ob_instrument.o_exchange := JSN.FindPath('instrument.exchange').AsString;
            ob_output.ob_instrument.o_countryOfRisk := JSN.FindPath('instrument.countryOfRisk').AsString;
            ob_output.ob_instrument.o_countryOfRiskName := JSN.FindPath('instrument.countryOfRiskName').AsString;
            ob_output.ob_instrument.o_sector := JSN.FindPath('instrument.sector').AsString;
            ob_output.ob_instrument.o_brand.o_logoName := JSN.FindPath('instrument.brand.logoName').AsString;
            ob_output.ob_instrument.o_brand.o_logoBaseColor := JSN.FindPath('instrument.brand.logoBaseColor').AsString;
            ob_output.ob_instrument.o_brand.o_textColor := JSN.FindPath('instrument.brand.textColor').AsString;
            ob_output.ob_instrument.o_lot := JSN.FindPath('instrument.lot').AsInt64;
            ob_output.ob_instrument.o_basicAssetSize := UnitsNanoToDouble(JSN.FindPath('instrument.basicAssetSize.units').AsInt64, JSN.FindPath('instrument.basicAssetSize.nano').AsInt64);
            if JSN.FindPath('instrument.klong.units') <> nil then
               ob_output.ob_instrument.o_klong := UnitsNanoToDouble(JSN.FindPath('instrument.klong.units').AsInt64, JSN.FindPath('instrument.klong.nano').AsInt64);
            if JSN.FindPath('instrument.kshort.units') <> nil then
               ob_output.ob_instrument.o_kshort := UnitsNanoToDouble(JSN.FindPath('instrument.kshort.units').AsInt64, JSN.FindPath('instrument.kshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlong.units') <> nil then
               ob_output.ob_instrument.o_dlong := UnitsNanoToDouble(JSN.FindPath('instrument.dlong.units').AsInt64, JSN.FindPath('instrument.dlong.nano').AsInt64);
            if JSN.FindPath('instrument.dshort.units') <> nil then
               ob_output.ob_instrument.o_dshort := UnitsNanoToDouble(JSN.FindPath('instrument.dshort.units').AsInt64, JSN.FindPath('instrument.dshort.nano').AsInt64);
            if JSN.FindPath('instrument.dlongMin.units') <> nil then
               ob_output.ob_instrument.o_dlongMin := UnitsNanoToDouble(JSN.FindPath('instrument.dlongMin.units').AsInt64, JSN.FindPath('instrument.dlongMin.nano').AsInt64);
            if JSN.FindPath('instrument.dshortMin.units') <> nil then
               ob_output.ob_instrument.o_dshortMin := UnitsNanoToDouble(JSN.FindPath('instrument.dshortMin.units').AsInt64, JSN.FindPath('instrument.dshortMin.nano').AsInt64);
            ob_output.ob_instrument.o_minPriceIncrement := UnitsNanoToDouble(JSN.FindPath('instrument.minPriceIncrement.units').AsInt64, JSN.FindPath('instrument.minPriceIncrement.nano').AsInt64);
            ob_output.ob_instrument.o_strikePrice.moneyval := UnitsNanoToDouble(JSN.FindPath('instrument.strikePrice.units').AsInt64, JSN.FindPath('instrument.strikePrice.nano').AsInt64);
            ob_output.ob_instrument.o_strikePrice.currency := JSN.FindPath('instrument.strikePrice.currency').AsString;
            if JSN.FindPath('instrument.dlongClient.units') <> nil then
               ob_output.ob_instrument.o_dlongClient := UnitsNanoToDouble(JSN.FindPath('instrument.dlongClient.units').AsInt64, JSN.FindPath('instrument.dlongClient.nano').AsInt64);
            if JSN.FindPath('instrument.dshortClient.units') <> nil then
               ob_output.ob_instrument.o_dshortClient := UnitsNanoToDouble(JSN.FindPath('instrument.dshortClient.units').AsInt64, JSN.FindPath('instrument.dshortClient.nano').AsInt64);
            ob_output.ob_instrument.o_expirationDate := JSN.FindPath('instrument.expirationDate').AsString;
            ob_output.ob_instrument.o_firstTradeDate := JSN.FindPath('instrument.firstTradeDate').AsString;
            ob_output.ob_instrument.o_lastTradeDate := JSN.FindPath('instrument.lastTradeDate').AsString;
            ob_output.ob_instrument.o_first1minCandleDate := JSN.FindPath('instrument.first1minCandleDate').AsString;
            ob_output.ob_instrument.o_first1dayCandleDate := JSN.FindPath('instrument.first1dayCandleDate').AsString;
            ob_output.ob_instrument.o_shortEnabledFlag := JSN.FindPath('instrument.shortEnabledFlag').AsBoolean;
            ob_output.ob_instrument.o_forIisFlag := JSN.FindPath('instrument.forIisFlag').AsBoolean;
            ob_output.ob_instrument.o_otcFlag := JSN.FindPath('instrument.otcFlag').AsBoolean;
            ob_output.ob_instrument.o_buyAvailableFlag := JSN.FindPath('instrument.buyAvailableFlag').AsBoolean;
            ob_output.ob_instrument.o_sellAvailableFlag := JSN.FindPath('instrument.sellAvailableFlag').AsBoolean;
            ob_output.ob_instrument.o_forQualInvestorFlag := JSN.FindPath('instrument.forQualInvestorFlag').AsBoolean;
            ob_output.ob_instrument.o_weekendFlag := JSN.FindPath('instrument.weekendFlag').AsBoolean;
            ob_output.ob_instrument.o_blockedTcaFlag := JSN.FindPath('instrument.blockedTcaFlag').AsBoolean;
            ob_output.ob_instrument.o_apiTradeAvailableFlag := JSN.FindPath('instrument.apiTradeAvailableFlag').AsBoolean;

            json_output_array := TJSONArray(JSN.FindPath('instrument.requiredTests'));
            tests_count := json_output_array.Count;
            SetLength(ob_output.ob_instrument.o_requiredTests, tests_count);
            i := 0;

            while i < tests_count do  begin
               ob_output.ob_instrument.o_requiredTests[i] := JSN.FindPath('instrument.requiredTests[' + inttostr(i) + ']').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetInsiderDeals (gid_input : gid_request; out gid_output : gid_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, deals_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if gid_input.gid_instrumentId <> '' then json_base.Add('instrumentId', gid_input.gid_instrumentId);
      if gid_input.gid_limit > 0 then json_base.Add('limit', gid_input.gid_limit);
      if gid_input.gid_nextCursor <> '' then json_base.Add('nextCursor', gid_input.gid_nextCursor);

      endpoint_url := url_tinvest + 'InstrumentsService/GetInsiderDeals';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gid_input.gid_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gid_output.gid_error_code := JSN.FindPath('code').AsInt64;
            gid_output.gid_error_message := JSN.FindPath('message').AsString;
            gid_output.gid_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gid_output.gid_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('insiderDeals'));

            deals_count := json_output_array.Count;

            SetLength(gid_output.gid_insiderDeals, deals_count);

            i := 0;

            while i < deals_count do  begin
               gid_output.gid_insiderDeals[i].gid_tradeId := JSN.FindPath('insiderDeals[' + inttostr(i) + '].tradeId').AsString;
               gid_output.gid_insiderDeals[i].gid_direction := JSN.FindPath('insiderDeals[' + inttostr(i) + '].direction').AsString;
               gid_output.gid_insiderDeals[i].gid_currency := JSN.FindPath('insiderDeals[' + inttostr(i) + '].currency').AsString;
               gid_output.gid_insiderDeals[i].gid_date := JSN.FindPath('insiderDeals[' + inttostr(i) + '].date').AsString;
               gid_output.gid_insiderDeals[i].gid_quantity := JSN.FindPath('insiderDeals[' + inttostr(i) + '].quantity').AsInt64;
               gid_output.gid_insiderDeals[i].gid_price := UnitsNanoToDouble(JSN.FindPath('insiderDeals[' + inttostr(i) + '].price.units').AsInt64, JSN.FindPath('insiderDeals[' + inttostr(i) + '].price.nano').AsInt64);
               gid_output.gid_insiderDeals[i].gid_instrumentUid := JSN.FindPath('insiderDeals[' + inttostr(i) + '].instrumentUid').AsString;
               gid_output.gid_insiderDeals[i].gid_ticker := JSN.FindPath('insiderDeals[' + inttostr(i) + '].ticker').AsString;
               gid_output.gid_insiderDeals[i].gid_investorName := JSN.FindPath('insiderDeals[' + inttostr(i) + '].investorName').AsString;
               gid_output.gid_insiderDeals[i].gid_investorPosition := JSN.FindPath('insiderDeals[' + inttostr(i) + '].investorPosition').AsString;
               gid_output.gid_insiderDeals[i].gid_percentage := JSN.FindPath('insiderDeals[' + inttostr(i) + '].percentage').AsFloat;
               gid_output.gid_insiderDeals[i].gid_isOptionExecution := JSN.FindPath('insiderDeals[' + inttostr(i) + '].isOptionExecution').AsBoolean;
               gid_output.gid_insiderDeals[i].gid_disclosureDate := JSN.FindPath('insiderDeals[' + inttostr(i) + '].disclosureDate').AsString;
               inc(i);
            end;
            gid_output.gid_nextCursor := JSN.FindPath('nextCursor').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure EditFavorites (ef_input : ef_request; out ef_output : ef_response);
var
   JSN: TJSONData;
   json_output_array, json_input_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, instruments_count, favoriteInstruments_count, i, j : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      json_input_array := TJSONArray.Create;

      endpoint_url := url_tinvest + 'InstrumentsService/EditFavorites';

      instruments_count := high(ef_input.ef_instruments);

      for i := 0 to instruments_count do begin
         json_input_array.add(TJSONObject.Create(['instrumentId', ef_input.ef_instruments[i].ef_instrumentId]));
      end;

      json_base.Add('instruments', json_input_array);
      json_base.Add('actionType', ef_input.ef_actionType);
      if ef_input.ef_groupId <> '' then json_base.Add('groupId', ef_input.ef_groupId);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + ef_input.ef_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            ef_output.ef_error_code := JSN.FindPath('code').AsInt64;
            ef_output.ef_error_message := JSN.FindPath('message').AsString;
            ef_output.ef_error_description := JSN.FindPath('description').AsInt64;
         end;

         if ef_output.ef_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('favoriteInstruments'));

            favoriteInstruments_count := json_output_array.Count;

            SetLength(ef_output.ef_favoriteInstruments, favoriteInstruments_count);

            j := 0;

            while j < favoriteInstruments_count do  begin
               ef_output.ef_favoriteInstruments[j].ef_figi := JSN.FindPath('favoriteInstruments[' + inttostr(j) + '].figi').AsString;
               ef_output.ef_favoriteInstruments[j].ef_ticker := JSN.FindPath('favoriteInstruments[' + inttostr(j) + '].ticker').AsString;
               ef_output.ef_favoriteInstruments[j].ef_classCode := JSN.FindPath('favoriteInstruments[' + inttostr(j) + '].classCode').AsString;
               ef_output.ef_favoriteInstruments[j].ef_isin := JSN.FindPath('favoriteInstruments[' + inttostr(j) + '].isin').AsString;
               ef_output.ef_favoriteInstruments[j].ef_instrumentType := JSN.FindPath('favoriteInstruments[' + inttostr(j) + '].instrumentType').AsString;
               ef_output.ef_favoriteInstruments[j].ef_name := JSN.FindPath('favoriteInstruments[' + inttostr(j) + '].name').AsString;
               ef_output.ef_favoriteInstruments[j].ef_uid := JSN.FindPath('favoriteInstruments[' + inttostr(j) + '].uid').AsString;
               ef_output.ef_favoriteInstruments[j].ef_otcFlag := JSN.FindPath('favoriteInstruments[' + inttostr(j) + '].otcFlag').AsBoolean;
               ef_output.ef_favoriteInstruments[j].ef_apiTradeAvailableFlag := JSN.FindPath('favoriteInstruments[' + inttostr(j) + '].apiTradeAvailableFlag').AsBoolean;
               ef_output.ef_favoriteInstruments[j].ef_instrumentKind := JSN.FindPath('favoriteInstruments[' + inttostr(j) + '].instrumentKind').AsString;

               inc(j);
            end;
            ef_output.ef_groupId := JSN.FindPath('groupId').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetFavorites (gf_input : gf_request; out gf_output : gf_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, favoriteInstruments_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      endpoint_url := url_tinvest + 'InstrumentsService/GetFavorites';

      if gf_input.gf_groupId <> '' then json_base.Add('groupId', gf_input.gf_groupId);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gf_input.gf_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gf_output.gf_error_code := JSN.FindPath('code').AsInt64;
            gf_output.gf_error_message := JSN.FindPath('message').AsString;
            gf_output.gf_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gf_output.gf_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('favoriteInstruments'));

            favoriteInstruments_count := json_output_array.Count;

            SetLength(gf_output.gf_favoriteInstruments, favoriteInstruments_count);

            i := 0;

            while i < favoriteInstruments_count do  begin
               gf_output.gf_favoriteInstruments[i].ef_figi := JSN.FindPath('favoriteInstruments[' + inttostr(i) + '].figi').AsString;
               gf_output.gf_favoriteInstruments[i].ef_ticker := JSN.FindPath('favoriteInstruments[' + inttostr(i) + '].ticker').AsString;
               gf_output.gf_favoriteInstruments[i].ef_classCode := JSN.FindPath('favoriteInstruments[' + inttostr(i) + '].classCode').AsString;
               gf_output.gf_favoriteInstruments[i].ef_isin := JSN.FindPath('favoriteInstruments[' + inttostr(i) + '].isin').AsString;
               gf_output.gf_favoriteInstruments[i].ef_instrumentType := JSN.FindPath('favoriteInstruments[' + inttostr(i) + '].instrumentType').AsString;
               gf_output.gf_favoriteInstruments[i].ef_name := JSN.FindPath('favoriteInstruments[' + inttostr(i) + '].name').AsString;
               gf_output.gf_favoriteInstruments[i].ef_uid := JSN.FindPath('favoriteInstruments[' + inttostr(i) + '].uid').AsString;
               gf_output.gf_favoriteInstruments[i].ef_otcFlag := JSN.FindPath('favoriteInstruments[' + inttostr(i) + '].otcFlag').AsBoolean;
               gf_output.gf_favoriteInstruments[i].ef_apiTradeAvailableFlag := JSN.FindPath('favoriteInstruments[' + inttostr(i) + '].apiTradeAvailableFlag').AsBoolean;
               gf_output.gf_favoriteInstruments[i].ef_instrumentKind := JSN.FindPath('favoriteInstruments[' + inttostr(i) + '].instrumentKind').AsString;

               inc(i);
            end;
            if JSN.FindPath('groupId') <> nil then gf_output.gf_groupId := JSN.FindPath('groupId').AsString;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetAssetBy (gab_input : gab_request; out gab_output : gab_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, tests_count, rebalancingDates_count, instruments_count, links_count, i, j, k, l : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      endpoint_url := url_tinvest + 'InstrumentsService/GetAssetBy';

      json_base.Add('id', gab_input.gab_id);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gab_input.gab_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gab_output.gab_error_code := JSN.FindPath('code').AsInt64;
            gab_output.gab_error_message := JSN.FindPath('message').AsString;
            gab_output.gab_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gab_output.gab_error_description = 0 then begin
            gab_output.gab_asset.gab_uid := JSN.FindPath('asset.uid').AsString;
            gab_output.gab_asset.gab_type := JSN.FindPath('asset.type').AsString;
            gab_output.gab_asset.gab_name := JSN.FindPath('asset.name').AsString;
            gab_output.gab_asset.gab_nameBrief := JSN.FindPath('asset.nameBrief').AsString;
            gab_output.gab_asset.gab_description := JSN.FindPath('asset.description').AsString;
            if JSN.FindPath('asset.deletedAt') <> nil then
               gab_output.gab_asset.gab_deletedAt := JSN.FindPath('asset.deletedAt').AsString;

            json_output_array := TJSONArray(JSN.FindPath('asset.requiredTests'));
            tests_count := json_output_array.Count;
            SetLength(gab_output.gab_asset.gab_requiredTests, tests_count);
            i := 0;

            while i < tests_count do  begin
               gab_output.gab_asset.gab_requiredTests[i] := JSN.FindPath('asset.requiredTests[' + inttostr(i) + ']').AsString;
               inc(i);
            end;

            if JSN.FindPath('asset.currency.baseCurrency') <> nil then
               gab_output.gab_asset.gab_currency.gab_baseCurrency := JSN.FindPath('asset.currency.baseCurrency').AsString;
            gab_output.gab_asset.gab_security.gab_isin := JSN.FindPath('asset.security.isin').AsString;
            gab_output.gab_asset.gab_security.gab_type := JSN.FindPath('asset.security.type').AsString;
            gab_output.gab_asset.gab_security.gab_instrumentKind := JSN.FindPath('asset.security.instrumentKind').AsString;

            gab_output.gab_asset.gab_security.gab_share.gab_type := JSN.FindPath('asset.security.share.type').AsString;
            gab_output.gab_asset.gab_security.gab_share.gab_issueSize := UnitsNanoToDouble(JSN.FindPath('asset.security.share.issueSize.units').AsInt64, JSN.FindPath('asset.security.share.issueSize.nano').AsInt64);
            gab_output.gab_asset.gab_security.gab_share.gab_nominal := UnitsNanoToDouble(JSN.FindPath('asset.security.share.nominal.units').AsInt64, JSN.FindPath('asset.security.share.nominal.nano').AsInt64);
            gab_output.gab_asset.gab_security.gab_share.gab_nominalCurrency := JSN.FindPath('asset.security.share.nominalCurrency').AsString;
            gab_output.gab_asset.gab_security.gab_share.gab_primaryIndex := JSN.FindPath('asset.security.share.primaryIndex').AsString;
            if JSN.FindPath('asset.security.share.dividendRate') <> nil then
               gab_output.gab_asset.gab_security.gab_share.gab_dividendRate := UnitsNanoToDouble(JSN.FindPath('asset.security.share.dividendRate.units').AsInt64, JSN.FindPath('asset.security.share.dividendRate.nano').AsInt64);
            gab_output.gab_asset.gab_security.gab_share.gab_preferredShareType := JSN.FindPath('asset.security.share.preferredShareType').AsString;
            gab_output.gab_asset.gab_security.gab_share.gab_ipoDate := JSN.FindPath('asset.security.share.ipoDate').AsString;
            gab_output.gab_asset.gab_security.gab_share.gab_registryDate := JSN.FindPath('asset.security.share.registryDate').AsString;
            gab_output.gab_asset.gab_security.gab_share.gab_divYieldFlag := JSN.FindPath('asset.security.share.divYieldFlag').AsBoolean;
            gab_output.gab_asset.gab_security.gab_share.gab_issueKind := JSN.FindPath('asset.security.share.issueKind').AsString;
            gab_output.gab_asset.gab_security.gab_share.gab_placementDate := JSN.FindPath('asset.security.share.placementDate').AsString;
            gab_output.gab_asset.gab_security.gab_share.gab_represIsin := JSN.FindPath('asset.security.share.represIsin').AsString;
            gab_output.gab_asset.gab_security.gab_share.gab_issueSizePlan := UnitsNanoToDouble(JSN.FindPath('asset.security.share.issueSizePlan.units').AsInt64, JSN.FindPath('asset.security.share.issueSizePlan.nano').AsInt64);
            gab_output.gab_asset.gab_security.gab_share.gab_totalFloat := UnitsNanoToDouble(JSN.FindPath('asset.security.share.totalFloat.units').AsInt64, JSN.FindPath('asset.security.share.totalFloat.nano').AsInt64);

            if JSN.FindPath('asset.security.bond') <> nil then begin
               gab_output.gab_asset.gab_security.gab_bond.gab_currentNominal := UnitsNanoToDouble(JSN.FindPath('asset.security.bond.currentNominal.units').AsInt64, JSN.FindPath('asset.security.bond.currentNominal.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_bond.gab_borrowName := JSN.FindPath('asset.security.bond.borrowName').AsString;
               gab_output.gab_asset.gab_security.gab_bond.gab_issueSize := UnitsNanoToDouble(JSN.FindPath('asset.security.bond.issueSize.units').AsInt64, JSN.FindPath('asset.security.bond.issueSize.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_bond.gab_nominal := UnitsNanoToDouble(JSN.FindPath('asset.security.bond.nominal.units').AsInt64, JSN.FindPath('asset.security.bond.nominal.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_bond.gab_nominalCurrency := JSN.FindPath('asset.security.bond.nominalCurrency').AsString;
               gab_output.gab_asset.gab_security.gab_bond.gab_issueKind := JSN.FindPath('asset.security.bond.issueKind').AsString;
               gab_output.gab_asset.gab_security.gab_bond.gab_interestKind := JSN.FindPath('asset.security.bond.interestKind').AsString;
               gab_output.gab_asset.gab_security.gab_bond.gab_couponQuantityPerYear := JSN.FindPath('asset.security.bond.couponQuantityPerYear').AsInt64;
               gab_output.gab_asset.gab_security.gab_bond.gab_indexedNominalFlag := JSN.FindPath('asset.security.bond.indexedNominalFlag').AsBoolean;
               gab_output.gab_asset.gab_security.gab_bond.gab_subordinatedFlag := JSN.FindPath('asset.security.bond.subordinatedFlag').AsBoolean;
               gab_output.gab_asset.gab_security.gab_bond.gab_collateralFlag := JSN.FindPath('asset.security.bond.collateralFlag').AsBoolean;
               gab_output.gab_asset.gab_security.gab_bond.gab_taxFreeFlag := JSN.FindPath('asset.security.bond.taxFreeFlag').AsBoolean;
               gab_output.gab_asset.gab_security.gab_bond.gab_amortizationFlag := JSN.FindPath('asset.security.bond.amortizationFlag').AsBoolean;
               gab_output.gab_asset.gab_security.gab_bond.gab_floatingCouponFlag := JSN.FindPath('asset.security.bond.floatingCouponFlag').AsBoolean;
               gab_output.gab_asset.gab_security.gab_bond.gab_perpetualFlag := JSN.FindPath('asset.security.bond.perpetualFlag').AsBoolean;
               gab_output.gab_asset.gab_security.gab_bond.gab_maturityDate := JSN.FindPath('asset.security.bond.maturityDate').AsString;
               gab_output.gab_asset.gab_security.gab_bond.gab_returnCondition := JSN.FindPath('asset.security.bond.returnCondition').AsString;
               gab_output.gab_asset.gab_security.gab_bond.gab_stateRegDate := JSN.FindPath('asset.security.bond.stateRegDate').AsString;
               gab_output.gab_asset.gab_security.gab_bond.gab_placementDate := JSN.FindPath('asset.security.bond.placementDate').AsString;
               gab_output.gab_asset.gab_security.gab_bond.gab_placementPrice := UnitsNanoToDouble(JSN.FindPath('asset.security.bond.placementPrice.units').AsInt64, JSN.FindPath('asset.security.bond.placementPrice.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_bond.gab_issueSizePlan := UnitsNanoToDouble(JSN.FindPath('asset.security.bond.issueSizePlan.units').AsInt64, JSN.FindPath('asset.security.bond.issueSizePlan.nano').AsInt64);
            end;

            if JSN.FindPath('asset.security.sp') <> nil then begin
               gab_output.gab_asset.gab_security.gab_sp.gab_borrowName := JSN.FindPath('asset.security.sp.borrowName').AsString;
               gab_output.gab_asset.gab_security.gab_sp.gab_nominal := UnitsNanoToDouble(JSN.FindPath('asset.security.sp.nominal.units').AsInt64, JSN.FindPath('asset.security.sp.nominal.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_sp.gab_nominalCurrency := JSN.FindPath('asset.security.sp.nominalCurrency').AsString;
               gab_output.gab_asset.gab_security.gab_sp.gab_type := JSN.FindPath('asset.security.sp.type').AsString;
               gab_output.gab_asset.gab_security.gab_sp.gab_logicPortfolio := JSN.FindPath('asset.security.sp.logicPortfolio').AsString;
               gab_output.gab_asset.gab_security.gab_sp.gab_assetType := JSN.FindPath('asset.security.sp.assetType').AsString;
               gab_output.gab_asset.gab_security.gab_sp.gab_basicAsset := JSN.FindPath('asset.security.sp.basicAsset').AsString;
               gab_output.gab_asset.gab_security.gab_sp.gab_safetyBarrier := UnitsNanoToDouble(JSN.FindPath('asset.security.sp.safetyBarrier.units').AsInt64, JSN.FindPath('asset.security.sp.safetyBarrier.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_sp.gab_maturityDate := JSN.FindPath('asset.security.sp.maturityDate').AsString;
               gab_output.gab_asset.gab_security.gab_sp.gab_issueSizePlan := UnitsNanoToDouble(JSN.FindPath('asset.security.sp.issueSizePlan.units').AsInt64, JSN.FindPath('asset.security.sp.issueSizePlan.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_sp.gab_issueSize := UnitsNanoToDouble(JSN.FindPath('asset.security.sp.issueSize.units').AsInt64, JSN.FindPath('asset.security.sp.issueSize.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_sp.gab_placementDate := JSN.FindPath('asset.security.sp.placementDate').AsString;
               gab_output.gab_asset.gab_security.gab_sp.gab_issueKind := JSN.FindPath('asset.security.sp.issueKind').AsString;
            end;

            if JSN.FindPath('asset.security.etf') <> nil then begin
               gab_output.gab_asset.gab_security.gab_etf.gab_totalExpense := UnitsNanoToDouble(JSN.FindPath('asset.security.etf.totalExpense.units').AsInt64, JSN.FindPath('asset.security.etf.totalExpense.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_etf.gab_hurdleRate := UnitsNanoToDouble(JSN.FindPath('asset.security.etf.hurdleRate.units').AsInt64, JSN.FindPath('asset.security.etf.hurdleRate.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_etf.gab_performanceFee := UnitsNanoToDouble(JSN.FindPath('asset.security.etf.performanceFee.units').AsInt64, JSN.FindPath('asset.security.etf.performanceFee.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_etf.gab_fixedCommission := UnitsNanoToDouble(JSN.FindPath('asset.security.etf.fixedCommission.units').AsInt64, JSN.FindPath('asset.security.etf.fixedCommission.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_etf.gab_paymentType := JSN.FindPath('asset.security.etf.paymentType').AsString;
               gab_output.gab_asset.gab_security.gab_etf.gab_watermarkFlag := JSN.FindPath('asset.security.etf.watermarkFlag').AsBoolean;
               gab_output.gab_asset.gab_security.gab_etf.gab_buyPremium := UnitsNanoToDouble(JSN.FindPath('asset.security.etf.buyPremium.units').AsInt64, JSN.FindPath('asset.security.etf.buyPremium.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_etf.gab_sellDiscount := UnitsNanoToDouble(JSN.FindPath('asset.security.etf.sellDiscount.units').AsInt64, JSN.FindPath('asset.security.etf.sellDiscount.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_etf.gab_rebalancingFlag := JSN.FindPath('asset.security.etf.rebalancingFlag').AsBoolean;
               gab_output.gab_asset.gab_security.gab_etf.gab_rebalancingFreq := JSN.FindPath('asset.security.etf.rebalancingFreq').AsString;
               gab_output.gab_asset.gab_security.gab_etf.gab_managementType := JSN.FindPath('asset.security.etf.managementType').AsString;
               gab_output.gab_asset.gab_security.gab_etf.gab_primaryIndex := JSN.FindPath('asset.security.etf.primaryIndex').AsString;
               gab_output.gab_asset.gab_security.gab_etf.gab_focusType := JSN.FindPath('asset.security.etf.focusType').AsString;
               gab_output.gab_asset.gab_security.gab_etf.gab_leveragedFlag := JSN.FindPath('asset.security.etf.leveragedFlag').AsBoolean;
               gab_output.gab_asset.gab_security.gab_etf.gab_numShare := UnitsNanoToDouble(JSN.FindPath('asset.security.etf.numShare.units').AsInt64, JSN.FindPath('asset.security.etf.numShare.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_etf.gab_ucitsFlag := JSN.FindPath('asset.security.etf.ucitsFlag').AsBoolean;
               gab_output.gab_asset.gab_security.gab_etf.gab_releasedDate := JSN.FindPath('asset.security.etf.releasedDate').AsString;
               gab_output.gab_asset.gab_security.gab_etf.gab_description := JSN.FindPath('asset.security.etf.description').AsString;
               gab_output.gab_asset.gab_security.gab_etf.gab_primaryIndexDescription := JSN.FindPath('asset.security.etf.primaryIndexDescription').AsString;
               gab_output.gab_asset.gab_security.gab_etf.gab_primaryIndexCompany := JSN.FindPath('asset.security.etf.primaryIndexCompany').AsString;
               gab_output.gab_asset.gab_security.gab_etf.gab_indexRecoveryPeriod := UnitsNanoToDouble(JSN.FindPath('asset.security.etf.indexRecoveryPeriod.units').AsInt64, JSN.FindPath('asset.security.etf.indexRecoveryPeriod.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_etf.gab_inavCode := JSN.FindPath('asset.security.etf.inavCode').AsString;
               gab_output.gab_asset.gab_security.gab_etf.gab_divYieldFlag := JSN.FindPath('asset.security.etf.divYieldFlag').AsBoolean;
               gab_output.gab_asset.gab_security.gab_etf.gab_expenseCommission := UnitsNanoToDouble(JSN.FindPath('asset.security.etf.expenseCommission.units').AsInt64, JSN.FindPath('asset.security.etf.expenseCommission.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_etf.gab_primaryIndexTrackingError := UnitsNanoToDouble(JSN.FindPath('asset.security.etf.primaryIndexTrackingError.units').AsInt64, JSN.FindPath('asset.security.etf.primaryIndexTrackingError.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_etf.gab_rebalancingPlan := JSN.FindPath('asset.security.etf.rebalancingPlan').AsString;
               gab_output.gab_asset.gab_security.gab_etf.gab_taxRate := JSN.FindPath('asset.security.etf.taxRate').AsString;


               json_output_array := TJSONArray(JSN.FindPath('asset.security.etf.rebalancingDates'));
               rebalancingDates_count := json_output_array.Count;
               SetLength(gab_output.gab_asset.gab_security.gab_etf.gab_rebalancingDates, rebalancingDates_count);
               j := 0;

               while j < rebalancingDates_count do  begin
                  gab_output.gab_asset.gab_security.gab_etf.gab_rebalancingDates[j] := JSN.FindPath('asset.security.etf.rebalancingDates[' + inttostr(j) + ']').AsString;
                  inc(j);
               end;

               gab_output.gab_asset.gab_security.gab_etf.gab_issueKind := JSN.FindPath('asset.security.etf.issueKind').AsString;
               gab_output.gab_asset.gab_security.gab_etf.gab_nominal := UnitsNanoToDouble(JSN.FindPath('asset.security.etf.nominal.units').AsInt64, JSN.FindPath('asset.security.etf.nominal.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_etf.gab_nominalCurrency := JSN.FindPath('asset.security.etf.nominalCurrency').AsString;
            end;

            if JSN.FindPath('asset.security.clearingCertificate') <> nil then begin
               gab_output.gab_asset.gab_security.gab_clearingCertificate.gab_nominal := UnitsNanoToDouble(JSN.FindPath('asset.security.clearingCertificate.nominal.units').AsInt64, JSN.FindPath('asset.security.clearingCertificate.nominal.nano').AsInt64);
               gab_output.gab_asset.gab_security.gab_clearingCertificate.gab_nominalCurrency := JSN.FindPath('asset.security.clearingCertificate.nominalCurrency').AsString;
            end;

            gab_output.gab_asset.gab_gosRegCode := JSN.FindPath('asset.gosRegCode').AsString;
            gab_output.gab_asset.gab_cfi := JSN.FindPath('asset.cfi').AsString;
            gab_output.gab_asset.gab_codeNsd := JSN.FindPath('asset.codeNsd').AsString;
            gab_output.gab_asset.gab_status := JSN.FindPath('asset.status').AsString;

            gab_output.gab_asset.gab_brand.gab_uid := JSN.FindPath('asset.brand.uid').AsString;
            gab_output.gab_asset.gab_brand.gab_name := JSN.FindPath('asset.brand.name').AsString;
            gab_output.gab_asset.gab_brand.gab_description := JSN.FindPath('asset.brand.description').AsString;
            gab_output.gab_asset.gab_brand.gab_info := JSN.FindPath('asset.brand.info').AsString;
            gab_output.gab_asset.gab_brand.gab_company := JSN.FindPath('asset.brand.company').AsString;
            gab_output.gab_asset.gab_brand.gab_sector := JSN.FindPath('asset.brand.sector').AsString;
            gab_output.gab_asset.gab_brand.gab_countryOfRisk := JSN.FindPath('asset.brand.countryOfRisk').AsString;
            gab_output.gab_asset.gab_brand.gab_countryOfRiskName := JSN.FindPath('asset.brand.countryOfRiskName').AsString;

            gab_output.gab_asset.gab_updatedAt := JSN.FindPath('asset.updatedAt').AsString;
            gab_output.gab_asset.gab_brCode := JSN.FindPath('asset.brCode').AsString;
            gab_output.gab_asset.gab_brCodeName := JSN.FindPath('asset.brCodeName').AsString;

            json_output_array := TJSONArray(JSN.FindPath('asset.instruments'));
            instruments_count := json_output_array.Count;
            SetLength(gab_output.gab_asset.gab_instruments, instruments_count);
            k := 0;

            while k < instruments_count do  begin
               gab_output.gab_asset.gab_instruments[k].gab_uid := JSN.FindPath('asset.instruments[' + inttostr(k) + '].uid').AsString;
               gab_output.gab_asset.gab_instruments[k].gab_figi := JSN.FindPath('asset.instruments[' + inttostr(k) + '].figi').AsString;
               gab_output.gab_asset.gab_instruments[k].gab_instrumentType := JSN.FindPath('asset.instruments[' + inttostr(k) + '].instrumentType').AsString;
               gab_output.gab_asset.gab_instruments[k].gab_ticker := JSN.FindPath('asset.instruments[' + inttostr(k) + '].ticker').AsString;
               gab_output.gab_asset.gab_instruments[k].gab_classCode := JSN.FindPath('asset.instruments[' + inttostr(k) + '].classCode').AsString;

               json_output_array := TJSONArray(JSN.FindPath('asset.instruments[' + inttostr(k) + '].links'));
               links_count := json_output_array.Count;
               SetLength(gab_output.gab_asset.gab_instruments[k].gab_links, links_count);
               l := 0;

               while l < links_count do  begin
                  gab_output.gab_asset.gab_instruments[k].gab_links[l].gab_type := JSN.FindPath('asset.instruments[' + inttostr(k) + '].links[' + inttostr(l) + '].type').AsString;
                  gab_output.gab_asset.gab_instruments[k].gab_links[l].gab_instrumentUid := JSN.FindPath('asset.instruments[' + inttostr(k) + '].links[' + inttostr(l) + '].instrumentUid').AsString;
                  inc(l);
               end;

               gab_output.gab_asset.gab_instruments[k].gab_instrumentKind := JSN.FindPath('asset.instruments[' + inttostr(k) + '].instrumentKind').AsString;
               gab_output.gab_asset.gab_instruments[k].gab_positionUid := JSN.FindPath('asset.instruments[' + inttostr(k) + '].positionUid').AsString;
               inc(k);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetDividends (gd_input : gd_request; out gd_output : gd_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, dividends_count, i : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.InstrumentsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.InstrumentsService_limit.h_ratelimit_reset * 1000);
        requests_limit.InstrumentsService_limit.h_ratelimit_remaining := requests_limit.InstrumentsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      if gd_input.gd_from <> '' then json_base.Add('from', gd_input.gd_from);
      if gd_input.gd_to <> '' then json_base.Add('to', gd_input.gd_to);
      json_base.Add('instrumentId', gd_input.gd_instrumentId);

      endpoint_url := url_tinvest + 'InstrumentsService/GetDividends';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gd_input.gd_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.InstrumentsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gd_output.gd_error_code := JSN.FindPath('code').AsInt64;
            gd_output.gd_error_message := JSN.FindPath('message').AsString;
            gd_output.gd_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gd_output.gd_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('dividends'));

            dividends_count := json_output_array.Count;

            SetLength(gd_output.gd_dividends, dividends_count);

            i := 0;

            while i < dividends_count do  begin
               gd_output.gd_dividends[i].gd_dividendNet.moneyval := UnitsNanoToDouble(JSN.FindPath('dividends[' + inttostr(i) + '].dividendNet.units').AsInt64 , JSN.FindPath('dividends[' + inttostr(i) + '].dividendNet.nano').AsInt64);
               gd_output.gd_dividends[i].gd_dividendNet.currency := JSN.FindPath('dividends[' + inttostr(i) + '].dividendNet.currency').AsString;
               gd_output.gd_dividends[i].gd_paymentDate := JSN.FindPath('dividends[' + inttostr(i) + '].paymentDate').AsString;
               gd_output.gd_dividends[i].gd_declaredDate := JSN.FindPath('dividends[' + inttostr(i) + '].declaredDate').AsString;
               gd_output.gd_dividends[i].gd_lastBuyDate := JSN.FindPath('dividends[' + inttostr(i) + '].lastBuyDate').AsString;
               gd_output.gd_dividends[i].gd_dividendType := JSN.FindPath('dividends[' + inttostr(i) + '].dividendType').AsString;
               gd_output.gd_dividends[i].gd_recordDate := JSN.FindPath('dividends[' + inttostr(i) + '].recordDate').AsString;
               gd_output.gd_dividends[i].gd_regularity := JSN.FindPath('dividends[' + inttostr(i) + '].regularity').AsString;
               gd_output.gd_dividends[i].gd_closePrice.moneyval := UnitsNanoToDouble(JSN.FindPath('dividends[' + inttostr(i) + '].closePrice.units').AsInt64 , JSN.FindPath('dividends[' + inttostr(i) + '].closePrice.nano').AsInt64);
               gd_output.gd_dividends[i].gd_closePrice.currency := JSN.FindPath('dividends[' + inttostr(i) + '].closePrice.currency').AsString;
               gd_output.gd_dividends[i].gd_yieldValue := UnitsNanoToDouble(JSN.FindPath('dividends[' + inttostr(i) + '].yieldValue.units').AsInt64 , JSN.FindPath('dividends[' + inttostr(i) + '].yieldValue.nano').AsInt64);
               gd_output.gd_dividends[i].gd_createdAt := JSN.FindPath('dividends[' + inttostr(i) + '].createdAt').AsString;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetOperations (geo_input : geo_request; out geo_output : geo_response);
var
   JSN: TJSONData;
   json_output_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, operations_count, trades_count, childOperations_count, i, j, k : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.OperationsService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.OperationsService_limit.h_ratelimit_reset * 1000);
        requests_limit.OperationsService_limit.h_ratelimit_remaining := requests_limit.OperationsService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;

      json_base.Add('accountId', geo_input.geo_accountId);
      if geo_input.geo_from <> '' then json_base.Add('from', geo_input.geo_from);
      if geo_input.geo_to <> '' then json_base.Add('to', geo_input.geo_to);
      if geo_input.geo_state <> '' then json_base.Add('state', geo_input.geo_state);
      if geo_input.geo_figi <> '' then json_base.Add('figi', geo_input.geo_figi);

      endpoint_url := url_tinvest + 'OperationsService/GetOperations';

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + geo_input.geo_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.OperationsService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            geo_output.geo_error_code := JSN.FindPath('code').AsInt64;
            geo_output.geo_error_message := JSN.FindPath('message').AsString;
            geo_output.geo_error_description := JSN.FindPath('description').AsInt64;
         end;

         if geo_output.geo_error_description = 0 then begin

            json_output_array := TJSONArray(JSN.FindPath('operations'));
            operations_count := json_output_array.Count;
            SetLength(geo_output.geo_operations, operations_count);
            i := 0;

            while i < operations_count do  begin
               geo_output.geo_operations[i].geo_id := JSN.FindPath('operations[' + inttostr(i) + '].id').AsString;
               geo_output.geo_operations[i].geo_parentOperationId := JSN.FindPath('operations[' + inttostr(i) + '].parentOperationId').AsString;
               geo_output.geo_operations[i].geo_currency := JSN.FindPath('operations[' + inttostr(i) + '].currency').AsString;
               geo_output.geo_operations[i].geo_payment.moneyval := UnitsNanoToDouble(JSN.FindPath('operations[' + inttostr(i) + '].payment.units').AsInt64 , JSN.FindPath('operations[' + inttostr(i) + '].payment.nano').AsInt64);
               geo_output.geo_operations[i].geo_payment.currency := JSN.FindPath('operations[' + inttostr(i) + '].payment.currency').AsString;
               geo_output.geo_operations[i].geo_price.moneyval := UnitsNanoToDouble(JSN.FindPath('operations[' + inttostr(i) + '].price.units').AsInt64 , JSN.FindPath('operations[' + inttostr(i) + '].price.nano').AsInt64);
               geo_output.geo_operations[i].geo_price.currency := JSN.FindPath('operations[' + inttostr(i) + '].price.currency').AsString;
               geo_output.geo_operations[i].geo_state := JSN.FindPath('operations[' + inttostr(i) + '].state').AsString;
               geo_output.geo_operations[i].geo_quantity := JSN.FindPath('operations[' + inttostr(i) + '].quantity').AsInt64;
               geo_output.geo_operations[i].geo_quantityRest := JSN.FindPath('operations[' + inttostr(i) + '].quantityRest').AsInt64;
               geo_output.geo_operations[i].geo_figi := JSN.FindPath('operations[' + inttostr(i) + '].figi').AsString;
               geo_output.geo_operations[i].geo_instrumentType := JSN.FindPath('operations[' + inttostr(i) + '].instrumentType').AsString;
               geo_output.geo_operations[i].geo_date := JSN.FindPath('operations[' + inttostr(i) + '].date').AsString;
               geo_output.geo_operations[i].geo_type := JSN.FindPath('operations[' + inttostr(i) + '].type').AsString;
               geo_output.geo_operations[i].geo_operationType := JSN.FindPath('operations[' + inttostr(i) + '].operationType').AsString;

               json_output_array := TJSONArray(JSN.FindPath('operations[' + inttostr(i) + '].trades'));
               trades_count := json_output_array.Count;
               SetLength(geo_output.geo_operations[i].geo_trades, trades_count);
               j := 0;

               while j < trades_count do  begin
                  geo_output.geo_operations[i].geo_trades[j].geo_tradeId := JSN.FindPath('operations[' + inttostr(i) + '].trades[' + inttostr(j) + '].tradeId').AsString;
                  geo_output.geo_operations[i].geo_trades[j].geo_dateTime := JSN.FindPath('operations[' + inttostr(i) + '].trades[' + inttostr(j) + '].dateTime').AsString;
                  geo_output.geo_operations[i].geo_trades[j].geo_quantity := JSN.FindPath('operations[' + inttostr(i) + '].trades[' + inttostr(j) + '].quantity').AsInt64;
                  geo_output.geo_operations[i].geo_trades[j].geo_price.moneyval := UnitsNanoToDouble(JSN.FindPath('operations[' + inttostr(i) + '].trades[' + inttostr(j) + '].price.units').AsInt64 , JSN.FindPath('operations[' + inttostr(i) + '].trades[' + inttostr(j) + '].price.nano').AsInt64);
                  geo_output.geo_operations[i].geo_trades[j].geo_price.currency := JSN.FindPath('operations[' + inttostr(i) + '].trades[' + inttostr(j) + '].price.currency').AsString;
                  inc(j);
               end;

               geo_output.geo_operations[i].geo_assetUid := JSN.FindPath('operations[' + inttostr(i) + '].assetUid').AsString;
               geo_output.geo_operations[i].geo_positionUid := JSN.FindPath('operations[' + inttostr(i) + '].positionUid').AsString;
               geo_output.geo_operations[i].geo_instrumentUid := JSN.FindPath('operations[' + inttostr(i) + '].instrumentUid').AsString;

               json_output_array := TJSONArray(JSN.FindPath('operations[' + inttostr(i) + '].childOperations'));
               childOperations_count := json_output_array.Count;
               SetLength(geo_output.geo_operations[i].geo_childOperations, childOperations_count);
               k := 0;

               while k < childOperations_count do  begin
                  geo_output.geo_operations[i].geo_childOperations[k].geo_instrumentUid := JSN.FindPath('operations[' + inttostr(i) + '].childOperations[' + inttostr(k) + '].instrumentUid').AsString;
                  geo_output.geo_operations[i].geo_childOperations[k].geo_payment.moneyval := UnitsNanoToDouble(JSN.FindPath('operations[' + inttostr(i) + '].childOperations[' + inttostr(k) + '].payment.units').AsInt64 , JSN.FindPath('operations[' + inttostr(i) + '].childOperations[' + inttostr(k) + '].payment.nano').AsInt64);
                  geo_output.geo_operations[i].geo_childOperations[k].geo_payment.currency := JSN.FindPath('operations[' + inttostr(i) + '].childOperations[' + inttostr(k) + '].payment.currency').AsString;
                  inc(k);
               end;
               inc(i);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;

procedure GetMarketValues (gmv_input : gmv_request; out gmv_output : gmv_response);
var
   JSN: TJSONData;
   json_output_array, instrumentId_input_array, values_input_array : TJSONArray;
   endpoint_url, json_output_struct, json_request : string;
   Client: TFPHttpClient;
   Response: TStringStream;
   status_code, instrumentId_count, values_req_count, instruments_count, values_count, i, j, k, l : int64;
   json_base : TJSONObject;

begin
   try
      if requests_limit.MarketDataService_limit.h_ratelimit_remaining <= 1 then
      begin
        Sleep(requests_limit.MarketDataService_limit.h_ratelimit_reset * 1000);
        requests_limit.MarketDataService_limit.h_ratelimit_remaining := requests_limit.MarketDataService_limit.h_ratelimit_limit - 1;
      end;

      json_base := TJSONObject.Create;
      instrumentId_input_array := TJSONArray.Create;
      values_input_array := TJSONArray.Create;

      endpoint_url := url_tinvest + 'MarketDataService/GetMarketValues';

      instrumentId_count := high(gmv_input.gmv_instrumentId);
      values_req_count := high(gmv_input.gmv_values);

      for i := 0 to instrumentId_count do begin
         instrumentId_input_array.add(gmv_input.gmv_instrumentId[i]);
      end;
      json_base.Add('instrumentId', instrumentId_input_array);

      for j := 0 to values_req_count do begin
         values_input_array.add(gmv_input.gmv_values[j]);
      end;
      json_base.Add('values', values_input_array);

      json_request := json_base.AsJSON;

      InitSSLInterface;
      Client := TFPHttpClient.Create(nil);
      Client.AllowRedirect:=true;
      Client.AddHeader('Content-Type', 'application/json');
      Client.AddHeader('Accept', 'application/json');
      Client.AddHeader('Authorization', 'Bearer ' + gmv_input.gmv_token);

      Client.AllowRedirect := true;
      Client.RequestBody := TRawByteStringStream.Create(json_request);
      Response := TStringStream.Create('');

      try
         Client.Post(endpoint_url, Response);
      except on E: Exception do

      end;

      requests_limit.MarketDataService_limit := ParseHeaders(Client.ResponseHeaders.Text);

      status_code := Client.ResponseStatusCode;
      if status_code <> 0 then begin

         SetString(json_output_struct,pchar(Response.Bytes),high(Response.Bytes));

         JSN := GetJSON(json_output_struct);

         if JSN.FindPath('description') <> nil then begin
            gmv_output.gmv_error_code := JSN.FindPath('code').AsInt64;
            gmv_output.gmv_error_message := JSN.FindPath('message').AsString;
            gmv_output.gmv_error_description := JSN.FindPath('description').AsInt64;
         end;

         if gmv_output.gmv_error_description = 0 then begin
            json_output_array := TJSONArray(JSN.FindPath('instruments'));
            instruments_count := json_output_array.Count;
            SetLength(gmv_output.gmv_instruments, instruments_count);
            k := 0;

            while k < instruments_count do  begin
               gmv_output.gmv_instruments[k].gmv_instrumentUid := JSN.FindPath('instruments[' + inttostr(k) + '].instrumentUid').AsString;

               json_output_array := TJSONArray(JSN.FindPath('instruments[' + inttostr(k) + '].values'));
               values_count := json_output_array.Count;
               SetLength(gmv_output.gmv_instruments[k].gmv_values, values_count);
               l := 0;

               while l < values_count do  begin
                  gmv_output.gmv_instruments[k].gmv_values[l].gmv_type := JSN.FindPath('instruments[' + inttostr(k) + '].values[' + inttostr(l) + '].type').AsString;
                  gmv_output.gmv_instruments[k].gmv_values[l].gmv_value := UnitsNanoToDouble(JSN.FindPath('instruments[' + inttostr(k) + '].values[' + inttostr(l) + '].value.units').AsInt64, JSN.FindPath('instruments[' + inttostr(k) + '].values[' + inttostr(l) + '].value.nano').AsInt64);
                  gmv_output.gmv_instruments[k].gmv_values[l].gmv_time := JSN.FindPath('instruments[' + inttostr(k) + '].values[' + inttostr(l) + '].time').AsString;
                  inc(l);
               end;

               gmv_output.gmv_instruments[k].gmv_ticker := JSN.FindPath('instruments[' + inttostr(k) + '].ticker').AsString;
               gmv_output.gmv_instruments[k].gmv_classCode := JSN.FindPath('instruments[' + inttostr(k) + '].classCode').AsString;

               inc(k);
            end;
         end;
      end;
   finally
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
      json_base.Free;
      if status_code <> 0 then JSN.Free;
   end;
end;



end.

