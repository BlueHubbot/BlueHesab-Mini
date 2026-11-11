# lib/fixtures — `app_fixtures` (wave 0, T-022)

Synthetic reference data of ui-spec §10-2 (DS-01…DS-07) for tests and the Style Guide. Owner: Tester hat (AGR-05; SE-05 accepted in `docs/agents/tasks/T-022.md`). Pure Dart, no Flutter import; release code never imports it. Import: `package:bluehesab_mini/fixtures/app_fixtures.dart`.

## Rules
- Money is `FixtureAmount`: `BigInt` minor units + currency code (MN-01, DD-02). Tables give toman; storage is rial (`FixtureAmount.toman`, ×10, DD-01). Amounts are written as decimal text, never `int` literals (16–18 digits do not fit a JavaScript number).
- No `double`: fractions are `FixtureRatio` (numerator/denominator).
- Dates carry the Jalali and the Gregorian day (`FixtureDate`); 1 Aban 1405 = 2026-10-23.
- **Text:** every name, title and label is an English key; its Persian text is in `FixtureTextFa` (`src/fixture_text_fa.dart`, T-025), grouped by kind (`accounts`, `transactions`, `categories`, `arcLabels`, `arcValueTexts`, `upcoming`, `market`, `carReminders`, `tasks`, `habits`) plus `ringSemantics`, `monthSpendingComparison`, `w05Title` and the four `w07…` labels. Each value is the spec cell byte for byte; `test/fixtures/fixture_text_fa_test.dart` finds it in §10-2 (or in SE-09 for the Mehr rows). MC-17 allows these literals only in `lib/fixtures/`, and only `lib/fixtures/` and `lib/style_guide/` may import the package (SE-15).

## `normal` (DS-03) — key → spec row
| Key | Spec row |
|---|---|
| accounts `cash`, `bank_melli`, `savings` | table 10-2-الف rows 1–3 (displayed balances); opening balances 2 265 000 / 645 000 / 30 000 000 toman derived by DD-06 so the displayed balances hold with the Mehr rows (SE-09) |
| `lunch_with_colleagues`, `snapp_ride`, `weekly_supermarket`, `electricity_bill`, `gasoline`, `salary_aban` | table 10-2-ب rows 1–6, same order |
| `coffee` (draft, not stored) | table 10-2-ب row 7 (DS-03, MO-11) |
| `weekly_supermarket_mehr`, `gas_bill_mehr`, `gasoline_mehr` | SE-09 proposed table «۱۰-۲-ب۲»: 1 Mehr 1 200 000 food bank; 2 Mehr 800 000 bills bank; 15 Mehr 900 000 car cash |
| arcs `budget` 68/100, `tasks` 4/6, `habits` 2/5 | table 10-2-پ rows 1–3 |
| upcoming `team_meeting` (3 Aban), `loan_installment` (4 Aban, 4 200 000), `car_periodic_service` (5 Aban) | table 10-2-پ `upcoming` |
| market `usd` 105 500, `gold_18k_per_gram` 7 200 000, `emami_coin` 80 000 000 (fictitious) | table 10-2-پ `marketWatch` |
| car `periodic_service_40000_km` (5 Aban), `body_insurance_renewal` (20 Aban) | table 10-2-پ `carReminders` |
| tasks done `buy_bread`, `pay_electricity_bill`, `call_bank`, `send_report`; open `dentist_appointment`, `oil_change` | table 10-2-پ «کارها» |
| habits done `morning_exercise`, `reading`; open `drink_water`, `meditation`, `early_sleep` | table 10-2-پ `habitsToday` |
| categories `food`, `transport`, `home`, `bills`, `health`, `education`, `clothing`, `entertainment`, `gifts`, `car`, `online_shopping`, `other`; frequent `food`, `transport`, `bills`, `car`, `home`; income `salary` | table 10-2-پ «دسته‌های هزینه» |

## `worst` (DS-04, table 10-2-ت)
In: W-01, W-02, W-03, W-04, W-05 and W-07 (text, `FixtureTextFa`), W-06, W-08 (Latin parts), W-09 chart 1 (DS-06), W-09 charts 2–4 and W-12 (SE-16 interim rule = ADVISOR_REPLY-007 Decision 1–4, T-028: `w09Chart2`, `w09Chart3`, `w09Chart4`, `w12Rows` of `FixtureListRow`; the W-05 title has text key `w05_title`), W-11. Not here: W-10 (assistant card, v0.4). DS-06 is implemented as written; its series do not cross (SE-15, recorded by a test).

## `empty`
No account, transaction or arc (DS-02).

## Tests
`test/fixtures/app_fixtures_test.dart` derives every total from the rows (DS-03, DD-06, DD-11 with SE-09, DS-06, DS-07) instead of copying expected numbers.
