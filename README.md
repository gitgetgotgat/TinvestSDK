# T-Invest API FPC (Free Pascal) SDK

![pascal](https://img.shields.io/badge/test-100%25-green?label=pascal)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/gitgetgotgat/test/latest/total)

Данный проект представляет собой инструментарий на языке Free Pascal (FPC) для работы с REST-интерфейсом торговой
платформы [Т Инвестиции](https://www.tinkoff.ru/invest/).

## Ключевые особенности

+ Реализованы только унарные запросы. Поддержка [стрим-соединений](https://developer.tbank.ru/invest/intro/developer/stream) **отсутствует** .
+ Предусмотрена работа только в продовом контуре. Методы для работы с [песочницей](https://developer.tbank.ru/invest/intro/developer/sandbox/) **отсутствуют**.
+ В передаваемых и возвращаемых параметрах предусмотрено автоматическое конвертирование типов данных [units/nano](https://developer.tbank.ru/invest/intro/intro/faq_custom_types) в double и обратно.
+ Во всех методах присутствует проверка на превышение [лимитов](https://developer.tbank.ru/invest/intro/intro/limits).

## Описание

Исходный код разработан на FPC. Компиляция и тестирование проводились в среде разработки [Lazarus](https://www.lazarus-ide.org/). Модуль **tinvest_api_unit.pas** 
содержит все необходимые структуры и методы API. Каждое поле структур для удобства дополнительно прокомментировано в соответствии с [официальной документацией](https://developer.tbank.ru/invest/api). 
Все названия структур и их полей имеют префиксы по первым буквам соответствующих методов. Общая схема вызова любого метода: **Метод_API (входные параметры; выходные параметры)**. Пример вызова:

```pascal
var
   ga_in  : ga_request;
   ga_out : ga_response;

begin

   // код инициализации входной структуры  
   
   GetAccounts(ga_in, ga_out);
   
   // обработка выходных данных
   
```

При этом, в запросе для каждого метода необходимо обязательно передавать токен.

В модуле **additional_unit.pas** содержатся дополнительные структуры и процедуры для облегчения разработки робота, такие как:

+ функция генерирования UUID (применяется в некоторых методах, например в [PostOrder](https://developer.tbank.ru/invest/api/orders-service-post-order));
+ функция-фильтр для получения только биржевых свечек;
+ функции перевода времени из московского в UTC и обратно;
+ функции некоторых индикаторов (некоторые из них присутствуют в методе [GetTechAnalysis](https://developer.tbank.ru/invest/api/market-data-service-get-tech-analysis));


## Документация

Подробную документацию по T-Invest API можно найти по [ссылке](https://developer.tbank.ru/invest/intro/intro).

## Начало работы

Для работы с T-Invest API необходимо выпустить соответствующий [токен](https://developer.tbank.ru/invest/intro/intro/token#получить-токен). В новых версиях API есть поддержка перевода средств между счетами, 
поэтому необходим токен с поддержкой торговли и переводов.

Все методы API работают по безопасному соединению через HTTPS, поэтому необходимо [скачать](https://github.com/IndySockets/OpenSSL-Binaries/tree/master/openssl-3_x) самую актуальную версию библиотеки для работы с SSL 
в соответствии с разряднойстью рабочей платформы и поместить все .dll-файлы в папку с проектом.

### Использование SDK
Для работы с SDK необходимо добавить модули в раздел `uses` своего проекта.

## Пример работы с SDK 

В каталоге [example](/example/) находится пример для работы с SDK в среде Lazarus.




