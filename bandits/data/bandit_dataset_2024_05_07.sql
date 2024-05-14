USE WAREHOUSE BI_QUERY_MEDIUM;
USE SCHEMA SANDBOX.SSIMS;
/*
 0) Pull infotron datasets for ads exposed to users
 */

CREATE OR REPLACE TABLE SANDBOX.SSIMS.DRAFT_IMPRESSIONS_SUBSET AS
SELECT *
FROM RAW.INFOTRON_PROD.IMPRESSION
WHERE TIMESTAMP > TIMESTAMPADD(day, -7, CURRENT_TIMESTAMP());

CREATE OR REPLACE TABLE SANDBOX.SSIMS.DRAFT_ENRICHED_CLICK_EVENTS AS

/*
1) Get the click events for the impressions from GA4 data and any metadata that comes through with click events from GA4
*/
SELECT EVENT_ID
     , SESSION_ID
     , DATETIME_UTC
     , EVENT_NAME
     , USER_ID
     , FEATURES
     , EVENT_FEATURES
     , EVENT_FEATURES:impression_id::VARCHAR(100)          AS IMPRESSION_ID
     , EVENT_FEATURES:ftm_derby                            AS FTM_DERBY
     , EVENT_FEATURES:ftm_pit                              AS FTM_PIT
     , EVENT_FEATURES:ftm_heat                             AS FTM_HEAT
     , EVENT_FEATURES:ftm_heat                             AS GA_SESSION_ID
     , EVENT_FEATURES:ftm_heat                             AS GA_SESSION_GUID
     , FEATURES:language                                   AS LANGUAGE
     , FEATURES:medium::VARCHAR                            AS MEDIUM
     , FEATURES:metro::VARCHAR                             AS METRO
     , FEATURES:mobile_brand_name::VARCHAR                 AS MOBILE_BRAND_NAME
     , FEATURES:mobile_marketing_name::VARCHAR             AS MOBILE_MARKETING_NAME
     , FEATURES:mobile_model_name::VARCHAR                 AS MOBILE_MODEL_NAME
     , FEATURES:mobile_os_hardware_model::VARCHAR          AS MOBILE_OS_HARDWARE_MODEL
     , FEATURES:name::VARCHAR                              AS TRAFFIC_SOURCE
     , FEATURES:operating_system::VARCHAR                  AS operating_system
     , FEATURES:operating_system_version::VARCHAR          AS operating_system_version
     , FEATURES:platform::VARCHAR                          AS platform
     , FEATURES:privacy_info:ads_storage::VARCHAR          AS ads_storage
     , FEATURES:privacy_info:analytics_storage::VARCHAR    AS analytics_storage
     , FEATURES:privacy_info:uses_transient_token::VARCHAR AS uses_transient_token
     , FEATURES:region::VARCHAR                            AS region
     , FEATURES:source::VARCHAR                            AS source
     , FEATURES:stream_id                                  AS stream_id
     , FEATURES:sub_continent::VARCHAR                     AS sub_continent
     , FEATURES:time_zone_offset_seconds::INTEGER          AS time_zone_offset_seconds
     , FEATURES:user_first_touch_timestamp                 AS user_first_touch_timestamp
     , FEATURES:user_properties:visitor_guid:string_value  AS VISITOR_GUID
     , FEATURES:user_properties:is_ecapped:string_value    AS EVENT_FEATURES_IS_ECAPPED
     , FEATURES:user_properties:user_pseudo_id             AS USER_PSEUDO_ID
     , FEATURES:version                                    AS version
     , FEATURES:web_info_browser                           AS web_info_browser
     , FEATURES:web_info_browser_version                   AS web_info_browser_version
     , USER_FEATURES:uid                                   AS uid
     , USER_FEATURES:account_guid::VARCHAR                 AS account_guid
     , USER_FEATURES:is_ecapped::VARCHAR                   AS USER_FEATURES_is_ecapped
FROM PROCESSED.ACTIVITY.EVENT
WHERE EVENT_NAME = 'infotron_pitch_click'
  AND DATETIME_UTC > TIMESTAMPADD(DAY, -7, CURRENT_TIMESTAMP);

/*
2) Get Orders connected to events and refunding
*/

CREATE OR REPLACE TABLE SANDBOX.SSIMS.DRAFT_ORDERS AS
SELECT EVENT_ID
     , SESSION_ID
     , DATETIME_UTC
     , EVENT_NAME
     , PLATFORM
     , USER_ID

-- user features
     , USER_FEATURES:is_ecapped::VARCHAR(10)              AS IS_ECAPPED
     , USER_FEATURES:uid                                  AS UID
     , USER_FEATURES:visitor_guid::VARCHAR(100)           AS VISITOR_GUID

-- GEO Features
     , FEATURES:city::VARCHAR(100)                        AS CITY
     , FEATURES:continent::VARCHAR(100)                   AS CONTINENT
     , FEATURES:country::VARCHAR(100)                     AS COUNTRY

-- Device Features
     , FEATURES:device_category::VARCHAR(100)             AS DEVICE_CATEGORY

-- Monetary features
     , FEATURES:ecommerce:purchase_revenue::FLOAT         AS purchase_revenue
     , FEATURES:ecommerce:purchase_revenue_in_usd::FLOAT  AS purchase_revenue_in_usd
     , features:ecommerce:refund_value::FLOAT             AS refund_value
     , features:ecommerce:refund_value_in_usd::FLOAT      AS refund_value_in_usd
     , COMMERCE_FEATURES:shipping_value::FLOAT            AS shipping_value
     , COMMERCE_FEATURES:tax_value::FLOAT                 AS tax_value
     , COMMERCE_FEATURES:tax_value_in_usd::FLOAT          AS tax_value_in_usd
     , EVENT_FEATURES:order_discount_amount::FLOAT        as ORDER_DISCOUNT_AMOUNT
     , EVENT_FEATURES:tax::FLOAT                          as tax
     , EVENT_FEATURES:coupon::FLOAT                       as COUPON
     , EVENT_FEATURES:unique_items::INTEGER               AS UNIQUE_ITEMS
     , EVENT_FEATURES:total_item_quantity::INTEGER        AS TOTAL_ITEM_QUANTITY
     , EVENT_FEATURES:value::FLOAT                        as VALUE
     , COMMERCE_FEATURES:item_revenue_in_usd::FLOAT       AS ITEM_REVENUE_USD
     , COMMERCE_FEATURES:price_in_usd::FLOAT              AS PRICE_IN_USD
     , ROUND(DIV0NULL(ITEM_REVENUE_USD, PRICE_IN_USD), 4) AS PCT_OF_LIST_PRICE_PAID

-- payment details
     , EVENT_FEATURES:payment_method::VARCHAR(100)        as payment_method

-- product features
     , FEATURES:event_params:product_term:string_value    AS PRODUCT_TERM
     , COMMERCE_FEATURES:item_id::INTEGER                 as ITEM_ID
     , COMMERCE_FEATURES:item_name::VARCHAR(100)          as ITEM_NAME

-- order attribution features
     , EVENT_FEATURES:impression_id::VARCHAR(100)         AS IMPRESSION_ID
     , EVENT_FEATURES:transaction_id::INTEGER             AS TRANSACTION_ID
     , FEATURES:event_params:ftm_heat:ga_session_id       AS GA_SESSION_ID
     , FEATURES:event_params:ftm_heat:ga_session_guid     AS GA_SESSION_GUID
     , EVENT_FEATURES:promotion_name::VARCHAR(240)        AS PROMOTION_NAME
     , EVENT_FEATURES:promotion_id::VARCHAR(100)          AS PROMOTION_ID
     , EVENT_FEATURES:source_code::VARCHAR(100)           AS SOURCE_CODE
     , EVENT_FEATURES:ftm_cam::VARCHAR(100)               AS FTM_CAMPAIGN
     , EVENT_FEATURES:ftm_derby                           AS FTM_DERBY
     , EVENT_FEATURES:ftm_pitch                           AS FTM_pitch
     , EVENT_FEATURES:ftm_heat                            AS ftm_heat
     , EVENT_FEATURES:ftm_veh::VARCHAR(100)               AS ftm_vehicle

-- Experimentation
     , EVENT_FEATURES:ga_session_number                   as ga_session_number
     , EVENT_FEATURES:test_id::VARCHAR(240)               as TEST_ID
     , EVENT_FEATURES:cell_id                             as CELL_ID

-- privacy features
     , features:is_limited_ad_tracking::VARCHAR(10)       AS IS_LIMITED_AD_TRACKING
FROM PROCESSED.ACTIVITY.EVENT
WHERE EVENT_NAME = 'purchase'
ORDER BY ftm_pitch DESC;

CREATE OR REPLACE TABLE SANDBOX.SSIMS.DRAFT_ORDERS_ENRICHED AS
SELECT IFF(VOO.OUTCOME_GROUP = 'Canceled', 1, 0) AS CANCELED
     , IFF(AUTO_REBILL_CHANGED_DATE_ID IS NOT NULL, 1,
           0)                                    AS AUTOREBILL_ADJUSTED
     , VOO.UID
     , VOO.OUTCOME_GROUP
     , VOO.OUTCOME_DETAIL
     , VOO.SUB_PURCHASE_ACTIVITY
     , VOO.ORDER_DATE
     , VOO.SUB_START_DATE
     , VOO.EXPECTED_END_DATE
     , VOO.OUTCOME_DATE
     , VOO.SUBSCRIPTION_TERM
     , VOO.BUDGET_CHANNEL
     , VOO.SUB_AREA_PARTNER
     , VOO.VEHICLE
     , VOO.COMP
     , VOO.SUBSCRIPTION_MARKETING
     , VOO.ACTIVE_PRODUCT
     , VOO.NET_RENEWAL_RATE_NUMERATOR
     , VOO.NET_RENEWAL_RATE_DENOMINATOR
     , VOO.RET_RENEWAL_RATE_NUMERATOR
     , VOO.MIDTENTION_NUMERATOR
     , VOO.MIDTENTION_DENOMINATOR
     , VOO.RET_RENEWAL_RATE_DENOMINATOR
     , VOO.PRODUCT_ID
     , VOO.CUSTOMER_ID
     , VOO.ORDER_DATE_ID
     , VOO.EXPECTED_END_DATE_ID
     , VOO.SUB_START_DATE_ID
     , VOO.ORDER_ITEM_ID
     , VOO.ORDER_SOURCE_ID
     , VOO.ORDER_PROMO_ID
     , VOO.SUB_DETAIL_ID
     , VOO.TERM_ID
     , VOO.OUTCOME_ID
     , VOO.OUTCOME_DATE_ID
     , VOO.ORDER_COUNT
     , VOO.DAYS_TO_OUTCOME
     , VOO.MONTHS_TO_OUTCOME
     , VOO.PURCHASE_PRICE
     , VOO.EXPECTED_RENEWAL_PRICE
     , VOO.EXPECTED_RENEWAL_TERM_ID
     , VOO.EXPECTED_RENEWAL_TERM
     , VOO.ELIGIBLE
     , VOO.ACTIVE_45DAYS_FROM_START
     , VOO.ACTIVE_31DAYS_FROM_ORDER
     , VOO.ACTIVE_61DAYS_FROM_ORDER
     , VOO.ACTIVE_91DAYS_FROM_ORDER
     , VOO.AUTO_REBILL
     , VOO.AUTO_REBILL_CHANGED_DATE_ID
     , VOO.BRAND
     , VOO.AUTO_REBILL_CHANGE_DATE
     , VOO.PROMO_DESCRIPTION
     , VOO.MONEY_BACK_GUARANTEE_TIME_PERIOD
     , VOO.ACQUISITION_PRICE
     , VOO.PRODUCT_NAME
     , VOO.ORIGINAL_OUTCOME_DATE_ID
     , VOO.ORIGINAL_OUTCOME_ID
     , VOO.ORIGINAL_OUTCOME_DETAIL
     , VOO.ORIGINAL_OUTCOME_GROUP
     , VOO.ORIGINAL_OUTCOME_DATE
     , VOO.STORE_ID
     , VOO.UPGRADE_TYPE
     , VOO.OFFER_TIER
     , VOO.SUB_PURCHASE_TYPE
     , VOO.FORECAST_PRODUCT
     , VOO.SUB_PURCHASE_DETAIL
     , VOO.SOURCE_CODE
     , VOO.DW_TRANSACTION_ID
     , VOO.COMMERCE_PROMOCODE
     , VOO.SUBSCRIPTION_PERIOD_ID
     , VOO.NRR_NUMERATOR_FOR_FORECAST
     , VOO.NRR_DENOMINATOR_FOR_FORECAST
     , VOO.EARLY_ERS_FOR_FORECAST
     , VOO.STANDARD_ERS_FOR_FORECAST
     , VOO.FIRST_GRACE_RESPONSE_CODE
     , VOO.FIRST_GRACE_RESPONSE_MESSAGE
     , VOO.CREDIT_CARD_TYPE
     , VOO.ISSUING_ORGANIZATION
     , O.EVENT_ID
     , O.SESSION_ID
     , O.DATETIME_UTC
     , O.EVENT_NAME
     , O.PLATFORM
     , O.USER_ID
     , O.IS_ECAPPED
     , O.UID                                     AS EVENT_UID
     , O.VISITOR_GUID
     , O.CITY
     , O.CONTINENT
     , O.COUNTRY
     , O.DEVICE_CATEGORY
     , O.PURCHASE_REVENUE
     , O.PURCHASE_REVENUE_IN_USD
     , O.REFUND_VALUE
     , O.REFUND_VALUE_IN_USD
     , O.SHIPPING_VALUE
     , O.TAX_VALUE
     , O.TAX_VALUE_IN_USD
     , O.ORDER_DISCOUNT_AMOUNT
     , O.TAX
     , O.COUPON
     , O.UNIQUE_ITEMS
     , O.TOTAL_ITEM_QUANTITY
     , O.VALUE
     , O.ITEM_REVENUE_USD
     , O.PRICE_IN_USD
     , O.PCT_OF_LIST_PRICE_PAID
     , O.PAYMENT_METHOD
     , O.PRODUCT_TERM
     , O.ITEM_ID
     , O.ITEM_NAME
     , O.IMPRESSION_ID
     , O.TRANSACTION_ID
     , O.GA_SESSION_ID
     , O.GA_SESSION_GUID
     , O.PROMOTION_NAME
     , O.PROMOTION_ID
--                                                                     O. , SOURCE_CODE
     , O.FTM_CAMPAIGN
     , O.FTM_DERBY
     , O.FTM_PITCH
     , O.FTM_HEAT
     , O.FTM_VEHICLE
     , O.GA_SESSION_NUMBER
     , O.TEST_ID
     , O.CELL_ID
     , O.IS_LIMITED_AD_TRACKING
FROM DRAFT_ORDERS O
         INNER JOIN PROCESSED.SALES.V_ORDER_OUTCOME VOO
                    ON O.TRANSACTION_ID = VOO.DW_TRANSACTION_ID;

CREATE OR REPLACE TABLE SANDBOX.SSIMS.BANDIT_TESTING_DATASET_2024_05_07 AS
/*
 Select a dataset of impression data, metadata about that impression
 */
SELECT
     -- impression id and tracking
    I.USER___UID                                                            AS UID
     , I.IMPRESSION_ID
     , I.TIMESTAMP                                                          AS IMPRESSION_DATETIME

     -- data about the ad copy that was served
     , I.MARKETING_EXPERIENCE___PITCH_ID
     , I.MARKETING_EXPERIENCE___DERBY_ID
     , I.MARKETING_EXPERIENCE___HEAT_ID

     -- Click ID and Tracking
     , IFF(C.DATETIME_UTC IS NULL, 0, 1)                                    AS CLICKED
     , C.DATETIME_UTC                                                       AS CLICK_DATETIME_UTC
     , C.EVENT_ID                                                           AS CLICK_EVENT_ID

     -- order id and tracking
     , IFF(O.DATETIME_UTC IS NULL, 0, 1)                                    AS ORDERED
     , O.DATETIME_UTC                                                       AS ORDER_DATETIME_UTC
     , O.EVENT_ID                                                           AS ORDER_EVENT_ID
     , O.CANCELED
     , O.PURCHASE_REVENUE_IN_USD
     , O.ORDER_DISCOUNT_AMOUNT
     , IFF(CANCELED = 1, (-1 * PURCHASE_REVENUE_IN_USD), 0)                 AS CANCEL_REVENUE_IN_USD

     -- user characteristics as of the day of the impression datetime
     , M.AGE
     , M.ALL_OP_VIEWS_1
     , M.ALL_OP_VIEWS_30 - ALL_OP_VIEWS_7                                   as ALL_OP_VIEWS_8_to_30
     , M.ALL_OP_VIEWS_7 - ALL_OP_VIEWS_1                                    as ALL_OP_VIEWS_2_to_7
     , M.ALL_OP_VIEWS_90 - ALL_OP_VIEWS_30                                  as ALL_OP_VIEWS_31_to_90
     , M.ARTICLES_30                                                        AS ARTICLES_1_to_30
     , M.ARTICLES_365 - ARTICLES_90                                         AS ARTICLES_91_to_365
     , M.ARTICLES_60 - ARTICLES_30                                          AS ARTICLES_31_to_60
     , M.ARTICLES_90 - ARTICLES_60                                          AS ARTICLES_61_to_90
     , M.ARTICLES_CANNABIS_60
     , M.ARTICLES_CONSUMER_GOODS_60
     , M.ARTICLES_ENERGY_MATERIALS_UTILITIES_60
     , M.ARTICLES_FINANCIALS_60
     , M.ARTICLES_HEALTHCARE_60
     , M.ARTICLES_INDUSTRIALS_60
     , M.ARTICLES_INVESTMENT_PLANNING_60
     , M.ARTICLES_MARKETS_60
     , M.ARTICLES_TECH_TELECOM_60
     , M.ASCENT_CONVERSIONS_30
     , M.ASCENT_CONVERSIONS_365 - ASCENT_CONVERSIONS_90                     as ASCENT_CONVERSIONS_91_to_365
     , M.ASCENT_CONVERSIONS_60 - ascent_conversions_30                      AS ASCENT_CONVERSIONS_31_to_60
     , M.ASCENT_CONVERSIONS_90 - ASCENT_CONVERSIONS_60                      AS ASCENT_CONVERSIONS_61_to_90
     , M.ASCENT_VISITS_30                                                   AS ASCENT_VISITS_1_to_30
     , M.ASCENT_VISITS_365 - ASCENT_VISITS_90                               as ASCENT_VISITS_91_to_365
     , M.ASCENT_VISITS_60 - ASCENT_VISITS_30                                as ASCENT_VISITS_31_to_60
     , M.ASCENT_VISITS_90 - ASCENT_VISITS_60                                as ASCENT_VISITS_61_to_90
     , M.BE_OP_VIEWS_365 - BE_OP_VIEW_90                                    AS BE_OP_VIEWS_91_to_365
     , M.BE_OP_VIEW_30                                                      AS BE_OP_VIEW_1_to_30
     , M.BE_OP_VIEW_60 - BE_OP_VIEW_30                                      AS BE_OP_VIEW_31_to_60
     , M.BE_OP_VIEW_90 - BE_OP_VIEW_60                                      AS BE_OP_VIEW_61_to_90
     , M.CANCELED_LAST396DAYS - CANCELED_LAST90DAYS                         as CANCELED_LAST_91_to_396_DAYS
     , M.CANCELED_LAST90DAYS                                                AS CANCELED_1_to_90_days
     , M.CANCELLATIONS_PAST4YEARS - M.CANCELED_LAST396DAYS                  AS CANCELLATIONS_396_DAYS_to_1460_years
     , M.CARD_BANK
     , M.CARD_BRAND
     , M.CARD_TYPE
     , M.DAYS_SINCE_LAST_ARTICLE
     , M.DAYS_SINCE_LAST_ASCENT_CONVERSION
     , M.DAYS_SINCE_LAST_BE_OP_VIEW
     , M.DAYS_SINCE_LAST_CANNABIS_ARTICLE
     , M.DAYS_SINCE_LAST_CONSUMER_GOODS_ARTICLE
     , M.DAYS_SINCE_LAST_ECAP
     , M.DAYS_SINCE_LAST_EMAIL_MKT_CLICK
     , M.DAYS_SINCE_LAST_EMAIL_MKT_OPEN
     , M.DAYS_SINCE_LAST_ENERGY_MATERIALS_UTILITIES_ARTICLE
     , M.DAYS_SINCE_LAST_FE_OP_VIEW
     , M.DAYS_SINCE_LAST_FINANCIAL_ARTICLE
     , M.DAYS_SINCE_LAST_FREE_VISIT
     , M.DAYS_SINCE_LAST_HEALTHCARE_ARTICLE
     , M.DAYS_SINCE_LAST_INDUSTRIALS_ARTICLE
     , M.DAYS_SINCE_LAST_INVESTMENT_PLANNING_ARTICLE
     , M.DAYS_SINCE_LAST_LISTBUILD
     , M.DAYS_SINCE_LAST_MARKETS_ARTICLE
     , M.DAYS_SINCE_LAST_MOBILE
     , M.DAYS_SINCE_LAST_PREMIUM_VISIT
     , M.DAYS_SINCE_LAST_SESSION
     , M.DAYS_SINCE_LAST_SESSION_DESKTOP
     , M.DAYS_SINCE_LAST_SESSION_TABLET
     , M.DAYS_SINCE_LAST_TECHNOLOGY_AND_TELECOM_ARTICLE
     , M.DAY_SINCE_LAST_ACQUISITION
     , M.DSN_LAST_ACTIVE
     , M.DSN_LAST_CANCEL
     , M.DSN_LAST_EXPIRE
     , M.DSN_LAST_RENEWAL
     , M.EARLY_RENEWALS_BE_PAST4YEARS
     , M.EARLY_RENEWALS_FE_PAST4YEARS
     , M.ECAPS_1
     , M.ECAPS_30
     , M.ECAPS_365 - ECAPS_90                                               AS ECAPS_91_to_365
     , M.ECAPS_60 - ECAPS_30                                                AS ECAPS_31_to_60
     , M.ECAPS_7 - ECAPS_1                                                  as ECAPS_1_to_7
     , M.ECAPS_90 - ECAPS_60                                                AS ECAPS_61_to_90
     , M.EMAIL_ANY_CLICKS_1
     , M.EMAIL_ANY_CLICKS_14 - EMAIL_ANY_CLICKS_7                           as EMAIL_ANY_CLICKS_7_to_14
     , M.EMAIL_ANY_CLICKS_30 - EMAIL_ANY_CLICKS_14                          as EMAIL_ANY_CLICKS_15_to_30
     , M.EMAIL_ANY_CLICKS_60 - EMAIL_ANY_CLICKS_30                          as EMAIL_ANY_CLICKS_31_to_60
     , M.EMAIL_ANY_CLICKS_7 - EMAIL_ANY_CLICKS_1                            as EMAIL_ANY_CLICKS_2_to_7
     , M.EMAIL_ANY_CLICKS_90 - EMAIL_ANY_CLICKS_60                          as EMAIL_ANY_CLICKS_61_to_90
     , M.EMAIL_ANY_CLICK_RATIO_14
     , M.EMAIL_ANY_CLICK_RATIO_30
     , M.EMAIL_ANY_CLICK_RATIO_60
     , M.EMAIL_ANY_OPENS_1
     , M.EMAIL_ANY_OPENS_14 - EMAIL_ANY_OPENS_7                             as EMAIL_ANY_OPENS_8_to_14
     , M.EMAIL_ANY_OPENS_30 - EMAIL_ANY_OPENS_14                            as EMAIL_ANY_OPENS_15_to_30
     , M.EMAIL_ANY_OPENS_60 - EMAIL_ANY_OPENS_30                            as EMAIL_ANY_OPENS_31_to_60
     , M.EMAIL_ANY_OPENS_7 - EMAIL_ANY_OPENS_1                              as EMAIL_ANY_OPENS_2_to_7
     , M.EMAIL_ANY_OPENS_90 - EMAIL_ANY_OPENS_60                            as EMAIL_ANY_OPENS_61_to_90
     , M.EMAIL_ANY_SENDS_14                                                 as EMAIL_ANY_SENDS_1_to_14
     , M.EMAIL_ANY_SENDS_30 - EMAIL_ANY_SENDS_14                            as EMAIL_ANY_SENDS_15_to_30
     , M.EMAIL_ANY_SENDS_60 - EMAIL_ANY_SENDS_30                            as EMAIL_ANY_SENDS_31_to_60
     , M.EMAIL_ASCENT_CLICKS_14                                             AS EMAIL_ASCENT_CLICKS_1_to_14
     , M.EMAIL_ASCENT_CLICKS_30 - EMAIL_ASCENT_CLICKS_14                    as EMAIL_ASCENT_CLICKS_15_to_30
     , M.EMAIL_ASCENT_CLICKS_60 - EMAIL_ASCENT_CLICKS_30                    aS EMAIL_ASCENT_CLICKS_31_to_60
     , M.EMAIL_ASCENT_CLICK_RATIO_14
     , M.EMAIL_ASCENT_CLICK_RATIO_30
     , M.EMAIL_ASCENT_CLICK_RATIO_60
     , M.EMAIL_ASCENT_OPENS_14                                              as EMAIL_ASCENT_OPENS_1_to_14
     , M.EMAIL_ASCENT_OPENS_30 - EMAIL_ASCENT_OPENS_14                      as EMAIL_ASCENT_OPENS_15_to_30
     , M.EMAIL_ASCENT_OPENS_60 - EMAIL_ASCENT_OPENS_30                      AS EMAIL_ASCENT_OPENS_31_to_60
     , M.EMAIL_ASCENT_SENDS_14                                              as EMAIL_ASCENT_SENDS_1_to_14
     , M.EMAIL_ASCENT_SENDS_30 - EMAIL_ASCENT_SENDS_14                      as EMAIL_ASCENT_SENDS_15_to_30
     , M.EMAIL_ASCENT_SENDS_60 - EMAIL_ASCENT_SENDS_30                      as EMAIL_ASCENT_SENDS_31_to_60
     , M.EMAIL_DOMAIN
     , M.EMAIL_MKT_CLICKS_14                                                as email_mkt_clicks_1_to_14
     , M.EMAIL_MKT_CLICKS_30 - EMAIL_MKT_CLICKS_14                          as EMAIL_MKT_CLICKS_15_to_30
     , M.EMAIL_MKT_CLICKS_365 - EMAIL_MKT_CLICKS_90                         AS EMAIL_MKT_CLICKS_91_to_365
     , M.EMAIL_MKT_CLICKS_60 - EMAIL_MKT_CLICKS_30                          AS EMAIL_MKT_CLICKS_31_to_60
     , M.EMAIL_MKT_CLICKS_90 - EMAIL_MKT_CLICKS_60                          AS EMAIL_MKT_CLICKS_61_to_90
     , M.EMAIL_MKT_OPENS_14                                                 as EMAIL_MKT_OPENS_1_to_14
     , M.EMAIL_MKT_OPENS_30 - EMAIL_MKT_OPENS_14                            as EMAIL_MKT_OPENS_15_to_30
     , M.EMAIL_MKT_OPENS_365 - EMAIL_MKT_OPENS_90                           AS EMAIL_MKT_OPENS_91_to_365
     , M.EMAIL_MKT_OPENS_60 - EMAIL_MKT_OPENS_30                            AS EMAIL_MKT_OPENS_31_to_60
     , M.EMAIL_MKT_OPENS_90 - EMAIL_MKT_OPENS_60                            as EMAIL_MKT_OPENS_61_to_90
     , M.EMAIL_SERVICE_CLICKS_14                                            as email_service_clicks_1_to_14
     , M.EMAIL_SERVICE_CLICKS_30 - EMAIL_SERVICE_CLICKS_14                  AS EMAIL_SERVICE_CLICKS_15_to_30
     , M.EMAIL_SERVICE_CLICKS_60 - EMAIL_SERVICE_CLICKS_30                  as EMAIL_SERVICE_CLICKS_31_to_60
     , M.EMAIL_SERVICE_CLICK_RATIO_14
     , M.EMAIL_SERVICE_CLICK_RATIO_30
     , M.EMAIL_SERVICE_CLICK_RATIO_60
     , M.EMAIL_SERVICE_OPENS_14                                             as EMAIL_SERVICE_OPENS_1_to_14
     , M.EMAIL_SERVICE_OPENS_30 - M.EMAIL_SERVICE_OPENS_14                  AS EMAIL_SERVICE_OPENS_15_to_30
     , M.EMAIL_SERVICE_OPENS_60 - EMAIL_SERVICE_OPENS_30                    as EMAIL_SERVICE_OPENS_31_to_60
     , M.EMAIL_SERVICE_SENDS_14                                             as email_service_sends_1_to_14
     , M.EMAIL_SERVICE_SENDS_30 - EMAIL_SERVICE_SENDS_14                    as EMAIL_SERVICE_SENDS_15_to_30
     , M.EMAIL_SERVICE_SENDS_60 - EMAIL_SERVICE_SENDS_30                    as EMAIL_SERVICE_SENDS_31_to_60
     , M.EXPIRED_LAST396DAYS - EXPIRED_LAST90DAYS                           as EXPIRED_LAST_91_to_396_DAYS
     , M.EXPIRED_LAST90DAYS                                                 as expired_Last_0_to_90_days
     , M.FE_OP_VIEWS_365 - FE_OP_VIEW_90                                    AS FE_OP_VIEWS_91_to_365
     , M.FE_OP_VIEW_30                                                      as FE_OP_VIEW_1_to_30
     , M.FE_OP_VIEW_60 - FE_OP_VIEW_30                                      AS FE_OP_VIEW_31_to_60
     , M.FE_OP_VIEW_90 - FE_OP_VIEW_60                                      AS FE_OP_VIEW_60_to_90
     , M.FIRST_ECAP_DATE
     , M.FIRST_PRODUCT_EVER
     , M.FIRST_PRODUCT_MOST_RECENT
     , M.FIRST_PRODUCT_MOST_RECENT_ORDER_ID
     , M.FIRST_PRODUCT_TERM_EVER
     , M.FIRST_PRODUCT_TERM_MOST_RECENT
     , M.FOOLS_GOLD_365                                                     as FOOLS_GOLD_1_to_365
     , M.FOOLS_GOLD_EVER - FOOLS_GOLD_365                                   AS FOOLS_GOLD_366_and_older
     , M.FOOL_COM_PAGES_1
     , M.FOOL_COM_PAGES_30 - FOOL_COM_PAGES_7                               as FOOL_COM_PAGES_8_to_30
     , M.FOOL_COM_PAGES_7 - FOOL_COM_PAGES_1                                AS FOOL_COM_PAGES_2_to_7
     , M.FOOL_COM_PAGES_90 - FOOL_COM_PAGES_30                              as FOOL_COM_PAGES_31_to_90
     , M.FREE_VISITS_30                                                     as free_visits_1_to_30
     , M.FREE_VISITS_365 - FREE_VISITS_90                                   AS FREE_VISITS_91_to_365
     , M.FREE_VISITS_60 - FREE_VISITS_30                                    AS FREE_VISITS_31_to_60
     , M.FREE_VISITS_90 - FREE_VISITS_60                                    AS FREE_VISITS_61_to_90
     , M.GENDER
     , M.HIGHEST_ACTIVE_SUB
     , M.HOUSEHOLD_INCOME
     , M.LATEST_ECAP_DATE
     , M.LEVEL
     , M.LEVEL_COMMERCE
     , M.LEVEL_NUMBER
     , M.LISTBUILDS_30
     , M.LISTBUILDS_365 - LISTBUILDS_90                                     AS LISTBUILDS_91_to_365
     , M.LISTBUILDS_60 - LISTBUILDS_30                                      AS LISTBUILDS_31_to_60
     , M.LISTBUILDS_90 - LISTBUILDS_60                                      AS LISTBUILDS_61_to_90
     , M.MARKETING_PAGES_1
     , M.MARKETING_PAGES_30 - MARKETING_PAGES_7                             as MARKETING_PAGES_7_to_30
     , M.MARKETING_PAGES_7 - MARKETING_PAGES_1                              as MARKETING_PAGES_2_to_7
     , M.MARKETING_PAGES_90 - MARKETING_PAGES_30                            as MARKETING_PAGES_31_to_90
     , M.MEMBER_BE
     , M.MEMBER_FE
     , M.MEMBER_LEVEL
     , M.MEMBER_RELATIONSHIP
     , M.MODEL_DATE
     , M.NETWORTH
     , M.NEVERMAIL
     , M.NEW_STRAIGHT_SALES_EVER_BE
     , M.NEW_STRAIGHT_SALES_EVER_FE
     , M.ORDERS_IN_GP_PAST4YEARS
     , M.OWNED_SUB_LAST396DAYS - OWNED_SUB_LAST90DAYS                       AS OWNED_SUB_LAST_90_to_396_DAYS
     , M.OWNED_SUB_LAST90DAYS                                               aS OWNED_SUB_LAST_1_to_90_DAYS
     , M.PORTFOLIO
     , M.PREMIUM_EMAIL_CLICKS_30                                            AS PREMIUM_EMAIL_CLICKS_1_to_30
     , M.PREMIUM_EMAIL_CLICKS_365 - PREMIUM_EMAIL_CLICKS_90                 as PREMIUM_EMAIL_CLICKS_91_to_365
     , M.PREMIUM_EMAIL_CLICKS_60 - PREMIUM_EMAIL_CLICKS_30                  as PREMIUM_EMAIL_CLICKS_31_to_60
     , M.PREMIUM_EMAIL_CLICKS_90 - PREMIUM_EMAIL_CLICKS_60                  as PREMIUM_EMAIL_CLICKS_61_to_90
     , M.PREMIUM_EMAIL_OPENS_30                                             as premium_email_opens_1_to_30
     , M.PREMIUM_EMAIL_OPENS_365 - PREMIUM_EMAIL_OPENS_90                   as PREMIUM_EMAIL_OPENS_91_to_365
     , M.PREMIUM_EMAIL_OPENS_60 - PREMIUM_EMAIL_OPENS_30                    AS PREMIUM_EMAIL_OPENS_31_to_60
     , M.PREMIUM_EMAIL_OPENS_90 - PREMIUM_EMAIL_OPENS_60                    AS PREMIUM_EMAIL_OPENS_61_to_90
     , M.PREMIUM_EMAIL_SENDS_30                                             as PREMIUM_EMAIL_SENDS_1_to_30
     , M.PREMIUM_EMAIL_SENDS_365 - PREMIUM_EMAIL_SENDS_90                   as PREMIUM_EMAIL_SENDS_91_to_365
     , M.PREMIUM_EMAIL_SENDS_60 - PREMIUM_EMAIL_SENDS_30                    as PREMIUM_EMAIL_SENDS_31_to_60
     , M.PREMIUM_EMAIL_SENDS_90 - PREMIUM_EMAIL_SENDS_60                    as PREMIUM_EMAIL_SENDS_61_to_90
     , M.PREMIUM_PAGES_30                                                   as premium_pages_1_to_30
     , M.PREMIUM_PAGES_365 - PREMIUM_PAGES_90                               as PREMIUM_PAGES_91_to_365
     , M.PREMIUM_PAGES_60 - PREMIUM_PAGES_30                                AS PREMIUM_PAGES_31_to_60
     , M.PREMIUM_PAGES_90 - PREMIUM_PAGES_60                                AS PREMIUM_PAGES_61_to_90
     , M.PREMIUM_VISITS_30                                                  as premium_visits_1_to_30
     , M.PREMIUM_VISITS_365 - PREMIUM_VISITS_90                             aS PREMIUM_VISITS_91_to_365
     , M.PREMIUM_VISITS_60 - PREMIUM_VISITS_30                              as PREMIUM_VISITS_31_to_60
     , M.PREMIUM_VISITS_90 - PREMIUM_VISITS_60                              AS PREMIUM_VISITS_61_to_90
     , M.PRIOR_EXPIRES_PAST4YEARS
     , M.PVS_PREMIUM_ACCOUNT_180 - PVS_PREMIUM_ACCOUNT_90                   as PVS_PREMIUM_ACCOUNT_91_to_180
     , M.PVS_PREMIUM_ACCOUNT_30                                             as pvs_premium_account_1_to_30
     , M.PVS_PREMIUM_ACCOUNT_60 - PVS_PREMIUM_ACCOUNT_30                    as PVS_PREMIUM_ACCOUNT_31_to_60
     , M.PVS_PREMIUM_ACCOUNT_90 - PVS_PREMIUM_ACCOUNT_60                    as PVS_PREMIUM_ACCOUNT_61_to_90
     , M.PVS_PREMIUM_ARTICLE_180 - PVS_PREMIUM_ARTICLE_90                   as PVS_PREMIUM_ARTICLE_91_to_180
     , M.PVS_PREMIUM_ARTICLE_30                                             AS PVS_PREMIUM_ARTICLE_1_to_30
     , M.PVS_PREMIUM_ARTICLE_60 - PVS_PREMIUM_ARTICLE_30                    as PVS_PREMIUM_ARTICLE_31_to_60
     , M.PVS_PREMIUM_ARTICLE_90 - PVS_PREMIUM_ARTICLE_60                    as PVS_PREMIUM_ARTICLE_61_to_90
     , M.PVS_PREMIUM_COMMUNITY_180 - PVS_PREMIUM_COMMUNITY_90               as PVS_PREMIUM_COMMUNITY_91_to_180
     , M.PVS_PREMIUM_COMMUNITY_30                                           as PVS_PREMIUM_COMMUNITY_1_to_30
     , M.PVS_PREMIUM_COMMUNITY_60 - PVS_PREMIUM_COMMUNITY_30                as PVS_PREMIUM_COMMUNITY_31_to_60
     , M.PVS_PREMIUM_COMMUNITY_90 - PVS_PREMIUM_COMMUNITY_60                as PVS_PREMIUM_COMMUNITY_61_to_90
     , M.PVS_PREMIUM_COMPANY_180 - PVS_PREMIUM_COMPANY_90                   as PVS_PREMIUM_COMPANY_91_to_180
     , M.PVS_PREMIUM_COMPANY_30                                             as PVS_PREMIUM_COMPANY_1_to_30
     , M.PVS_PREMIUM_COMPANY_60 - PVS_PREMIUM_COMPANY_30                    as PVS_PREMIUM_COMPANY_31_to_60
     , M.PVS_PREMIUM_COMPANY_90 - PVS_PREMIUM_COMPANY_60                    as PVS_PREMIUM_COMPANY_61_to_90
     , M.PVS_PREMIUM_FOOL_LIVE_180 - PVS_PREMIUM_FOOL_LIVE_90               as PVS_PREMIUM_FOOL_LIVE_91_to_180
     , M.PVS_PREMIUM_FOOL_LIVE_30                                           as PVS_PREMIUM_FOOL_LIVE_1_to_30
     , M.PVS_PREMIUM_FOOL_LIVE_60 - PVS_PREMIUM_FOOL_LIVE_30                as PVS_PREMIUM_FOOL_LIVE_31_to_60
     , M.PVS_PREMIUM_FOOL_LIVE_90 - PVS_PREMIUM_FOOL_LIVE_60                as PVS_PREMIUM_FOOL_LIVE_61_to_90
     , M.PVS_PREMIUM_HELP_AND_SUPPORT_180 - PVS_PREMIUM_HELP_AND_SUPPORT_90 as PVS_PREMIUM_HELP_AND_SUPPORT_91_to_180
     , M.PVS_PREMIUM_HELP_AND_SUPPORT_30                                    as PVS_PREMIUM_HELP_AND_SUPPORT_1_to_30
     , M.PVS_PREMIUM_HELP_AND_SUPPORT_60 - PVS_PREMIUM_HELP_AND_SUPPORT_30  as PVS_PREMIUM_HELP_AND_SUPPORT_31_to_60
     , M.PVS_PREMIUM_HELP_AND_SUPPORT_90 - PVS_PREMIUM_HELP_AND_SUPPORT_60  as PVS_PREMIUM_HELP_AND_SUPPORT_61_to_90
     , M.PVS_PREMIUM_ONBOARDING_180 - PVS_PREMIUM_ONBOARDING_90             as PVS_PREMIUM_ONBOARDING_91_to_180
     , M.PVS_PREMIUM_ONBOARDING_30                                          as PVS_PREMIUM_ONBOARDING_1_to_30
     , M.PVS_PREMIUM_ONBOARDING_60 - PVS_PREMIUM_ONBOARDING_30              as PVS_PREMIUM_ONBOARDING_31_to_60
     , M.PVS_PREMIUM_ONBOARDING_90 - PVS_PREMIUM_ONBOARDING_60              as PVS_PREMIUM_ONBOARDING_61_to_90
     , M.PVS_PREMIUM_PODCAST_180 - PVS_PREMIUM_PODCAST_90                   as PVS_PREMIUM_PODCAST_91_to_180
     , M.PVS_PREMIUM_PODCAST_30                                             as PVS_PREMIUM_PODCAST_1_to_30
     , M.PVS_PREMIUM_PODCAST_60 - PVS_PREMIUM_PODCAST_30                    as PVS_PREMIUM_PODCAST_31_to_60
     , M.PVS_PREMIUM_PODCAST_90 - PVS_PREMIUM_PODCAST_60                    as PVS_PREMIUM_PODCAST_61_to_90
     , M.PVS_PREMIUM_PRODUCT_LANDING_PAGE_180 -
       PVS_PREMIUM_PRODUCT_LANDING_PAGE_90                                  as
                                                                               PVS_PREMIUM_PRODUCT_LANDING_PAGE_91_to_180
     , M.PVS_PREMIUM_PRODUCT_LANDING_PAGE_30                                as PVS_PREMIUM_PRODUCT_LANDING_PAGE_1_to_30
     , M.PVS_PREMIUM_PRODUCT_LANDING_PAGE_60 -
       PVS_PREMIUM_PRODUCT_LANDING_PAGE_30                                  as PVS_PREMIUM_PRODUCT_LANDING_PAGE_31_to_60
     , M.PVS_PREMIUM_PRODUCT_LANDING_PAGE_90 -
       PVS_PREMIUM_PRODUCT_LANDING_PAGE_60                                  as PVS_PREMIUM_PRODUCT_LANDING_PAGE_61_to_90
     , M.PVS_PREMIUM_REPORT_180 - PVS_PREMIUM_REPORT_90                     as PVS_PREMIUM_REPORT_91_to_180
     , M.PVS_PREMIUM_REPORT_30                                              as PVS_PREMIUM_REPORT_1_to_30
     , M.PVS_PREMIUM_REPORT_60 - PVS_PREMIUM_REPORT_30                      as PVS_PREMIUM_REPORT_31_to_60
     , M.PVS_PREMIUM_REPORT_90 - PVS_PREMIUM_REPORT_60                      as PVS_PREMIUM_REPORT_61_to_90
     , M.PVS_PREMIUM_TOOLS_180 - PVS_PREMIUM_TOOLS_90                       as PVS_PREMIUM_TOOLS_91_to_180
     , M.PVS_PREMIUM_TOOLS_30                                               as PVS_PREMIUM_TOOLS_1_to_30
     , M.PVS_PREMIUM_TOOLS_60 - PVS_PREMIUM_TOOLS_30                        as PVS_PREMIUM_TOOLS_31_to_60
     , M.PVS_PREMIUM_TOOLS_90 - PVS_PREMIUM_TOOLS_60                        as PVS_PREMIUM_TOOLS_61_to_90
     , M.RENEWAL_COUNT_PAST4YEARS
     , M.SESSIONS_63
     , M.SESSIONS_DESKTOP_63
     , M.SESSIONS_MOBILE_63
     , M.SESSIONS_MOBILE_APPLE_63
     , M.SESSIONS_MOBILE_NONAPPLE_63
     , M.SESSIONS_NONMOBILE_APPLE_63
     , M.SESSIONS_NONMOBILE_NONAPPLE_63
     , M.SESSIONS_TABLET_63
     , M.SESSIONS_WEEKDAY_63
     , M.SESSIONS_WEEKEND_63
     , M.SESSIONS_WEEKNIGHT_63
     , M.SOURCECODE_EVER
     , M.SOURCECODE_FIRST_PRODUCT_MOST_RECENT
     , M.TENURE_DAYS_CURRENT_ACTIVE
     , M.TENURE_DAYS_EVER
     , M.TOTAL_BE_PRODUCTS_ACCESSIBLE
     , M.TOTAL_BE_PRODUCTS_OWNED
     , M.TOTAL_DISTINCT_PRODUCTS_OWNED
     , M.TOTAL_FE_PRODUCTS_ACCESSIBLE
     , M.TOTAL_FE_PRODUCTS_OWNED
     , M.ZIPCODE
     , M.ZIP_AVG_HOME_VALUE
     , M.ZIP_INCOME_PER_HOUSEHOLD
FROM DRAFT_IMPRESSIONS_SUBSET I
         LEFT JOIN DRAFT_ENRICHED_CLICK_EVENTS C
                   ON I.IMPRESSION_ID = C.IMPRESSION_ID
                       AND I.USER___UID = C.UID
                       AND I.MARKETING_EXPERIENCE___DERBY_ID = C.FTM_DERBY
                       AND I.MARKETING_EXPERIENCE___PITCH_ID = C.FTM_PIT
                       AND I.MARKETING_EXPERIENCE___HEAT_ID = C.FTM_HEAT
         LEFT JOIN DRAFT_ORDERS_ENRICHED O
                   ON I.IMPRESSION_ID = O.IMPRESSION_ID -- order associated with the impression
                       AND I.USER___UID = O.EVENT_UID
                       AND O.FTM_HEAT = I.MARKETING_EXPERIENCE___HEAT_ID::INTEGER
                       and O.FTM_DERBY = I.MARKETING_EXPERIENCE___DERBY_ID::INTEGER
                       -- todo: Join on pitch as well? or no?
                       AND TIMESTAMPDIFF('hour', O.DATETIME_UTC, I.TIMESTAMP) < 25 -- and within 24 hours
         LEFT JOIN REPORTING.SAT.MEMBER_CENTRIC_MART_FLAT M
                   ON I.USER___UID = M.UID
                       and I.TIMESTAMP::DATE = M.MODEL_DATE
ORDER BY ORDER_DATETIME_UTC DESC NULLS LAST;

SELECT * FROM SANDBOX.SSIMS.BANDIT_TESTING_DATASET_2024_05_07;

