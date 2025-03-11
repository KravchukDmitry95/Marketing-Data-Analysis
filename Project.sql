
---CTE
with FB as (select ad_date, campaign_name, adset_name, spend, impressions, reach, clicks, leads, value,'Facebook' as media_source from facebook_ads_basic_daily
join facebook_adset on facebook_ads_basic_daily. adset_id = facebook_adset. adset_id 
join facebook_campaign on facebook_ads_basic_daily. campaign_id = facebook_campaign. campaign_id
union all
select ad_date, campaign_name, adset_name, spend, impressions, reach, clicks, leads, value, 'Google' from  google_ads_basic_daily)
select ad_date, media_source, campaign_name, adset_name, sum(spend) spend, sum(impressions) impressions, sum(clicks) clicks, sum(value) value from FB
group by ad_date, media_source, campaign_name, adset_name
order by ad_date asc

---The campaign with the highest ROMI among all campaigns with a total spend of more than 500,000
with FB as (select ad_date, campaign_name, adset_name, spend, impressions, reach, clicks, leads, value,'Facebook' as media_source from facebook_ads_basic_daily
join facebook_adset on facebook_ads_basic_daily. adset_id = facebook_adset. adset_id 
join facebook_campaign on facebook_ads_basic_daily. campaign_id = facebook_campaign. campaign_id
union all
select ad_date, campaign_name, adset_name, spend, impressions, reach, clicks, leads, value, 'Google' from  google_ads_basic_daily)
select campaign_name, ((sum(value)-sum(spend))/sum(spend :: numeric))*100  as ROMI from FB
group by campaign_name
having sum(spend) > 500000
order by romi desc



---Group of ads (adset_name) with the highest ROMI
with FB as (select ad_date, campaign_name, adset_name, spend, impressions, reach, clicks, leads, value,'Facebook' as media_source from facebook_ads_basic_daily
join facebook_adset on facebook_ads_basic_daily. adset_id = facebook_adset. adset_id 
join facebook_campaign on facebook_ads_basic_daily. campaign_id = facebook_campaign. campaign_id
union all
select ad_date, campaign_name, adset_name, spend, impressions, reach, clicks, leads, value, 'Google' from  google_ads_basic_daily),
Top1 AS (select campaign_name, ((sum(value)-sum(spend))/sum(spend :: numeric))*100  as ROMI from FB
group by campaign_name
having sum(spend) > 500000
order by romi desc
limit 1)
select  adset_name, ((sum(value)-sum(spend))/sum(spend :: numeric))*100 as ROMI from FB
where  campaign_name = (select campaign_name FROM Top1)
group by adset_name
order by romi desc 
LIMIT 1



----Dynamic analysis of advertising effectiveness by month (changes in CPM, CTR, ROMI). 
WITH DFW AS ( SELECT 
        ad_date, 
        campaign_name, 
        adset_name, 
        url_parameters, 
        COALESCE(spend, '0') AS spend, 
        COALESCE(impressions, '0') AS impressions, 
        COALESCE(reach, '0') AS reach, 
        COALESCE(clicks, '0') AS clicks, 
        COALESCE(leads, '0') AS leads, 
        COALESCE(value, '0') AS value 
    FROM facebook_ads_basic_daily 
    JOIN facebook_adset ON facebook_ads_basic_daily.adset_id = facebook_adset.adset_id  
    JOIN facebook_campaign ON facebook_ads_basic_daily.campaign_id = facebook_campaign.campaign_id 
    UNION ALL  
    SELECT 
        ad_date, 
        campaign_name, 
        adset_name, 
        url_parameters, 
        COALESCE(spend, '0') AS spend, 
        COALESCE(impressions, '0') AS impressions, 
        COALESCE(reach, '0') AS reach, 
        COALESCE(clicks, '0') AS clicks, 
        COALESCE(leads, '0') AS leads, 
        COALESCE(value, '0') AS value 
    FROM google_ads_basic_daily
),
AggregatedData AS (
    SELECT 
        DATE_TRUNC('month', ad_date) AS ad_month, 
        NULLIF(LOWER(SUBSTRING(url_parameters, 'utm_campaign=([^&#$]+)')), 'nan') AS utm_campaign, 
        campaign_name, 
        adset_name,
        SUM(spend) AS spend,  
        SUM(impressions) AS impressions, 
        SUM(reach) AS reach, 
        SUM(clicks) AS clicks, 
        SUM(leads) AS leads, 
        SUM(value) AS value, 
        CASE WHEN SUM(clicks) != 0 THEN SUM(spend) / SUM(clicks) ELSE 0 END AS CPC, 
        CASE WHEN SUM(impressions) != 0 THEN SUM(clicks)::FLOAT / SUM(impressions) ELSE 0 END AS CTR, 
        CASE WHEN SUM(impressions) != 0 THEN SUM(spend)::FLOAT / SUM(impressions) * 1000 ELSE 0 END AS CPM, 
        CASE WHEN SUM(spend) != 0 THEN (SUM(value) - SUM(spend)) / SUM(spend) * 100 ELSE 0 END AS ROMI 
    FROM DFW  
    GROUP BY ad_month, campaign_name, utm_campaign, adset_name 
), 
PreviousMonthData AS (
    SELECT 
        ad_month,
        utm_campaign,
        CPM AS prev_CPM,
        CTR AS prev_CTR,
        ROMI AS prev_ROMI
    FROM AggregatedData)
SELECT 
    a.ad_month,
    a.utm_campaign,
    a.spend,
    a.impressions,
    a.clicks,
    a.value,
    a.CTR,
    a.CPC,
    a.CPM,
    a.ROMI,
    CASE WHEN p.prev_CPM IS NOT NULL AND p.prev_CPM != 0 THEN ((a.CPM - p.prev_CPM) / p.prev_CPM) * 100 ELSE NULL END AS CPM_diff_pct,
    CASE WHEN p.prev_CTR IS NOT NULL AND p.prev_CTR != 0 THEN ((a.CTR - p.prev_CTR) / p.prev_CTR) * 100 ELSE NULL END AS CTR_diff_pct,
    CASE WHEN p.prev_ROMI IS NOT NULL AND p.prev_ROMI != 0 THEN ((a.ROMI - p.prev_ROMI) / p.prev_ROMI) * 100 ELSE NULL END AS ROMI_diff_pct
FROM 
    AggregatedData as a
LEFT JOIN 
    PreviousMonthData as p 
ON 
    a.utm_campaign = p.utm_campaign 
    AND DATE_TRUNC('month', a.ad_month) = DATE_TRUNC('month', p.ad_month + INTERVAL '1 month')
ORDER BY 
    a.ad_month, 
    a.utm_campaign;

