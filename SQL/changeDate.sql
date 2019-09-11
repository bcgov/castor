ALTER TABLE public.ftn_c_b_pl_polygon ALTER COLUMN blk_st_dt TYPE timestamp
USING to_timestamp(blk_st_dt, 'YYYYMMDDHH24MISS');