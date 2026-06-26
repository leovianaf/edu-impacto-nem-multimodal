select *
from {{ ref('stg_saeb_resultados_municipios') }}
where
    coalesce(media_5_lp, 0) < 0
    or coalesce(media_5_mt, 0) < 0
    or coalesce(media_9_lp, 0) < 0
    or coalesce(media_9_mt, 0) < 0
    or coalesce(media_12_lp, 0) < 0
    or coalesce(media_12_mt, 0) < 0
    or coalesce(media_5_lp, 0) > 1000
    or coalesce(media_5_mt, 0) > 1000
    or coalesce(media_9_lp, 0) > 1000
    or coalesce(media_9_mt, 0) > 1000
    or coalesce(media_12_lp, 0) > 1000
    or coalesce(media_12_mt, 0) > 1000
