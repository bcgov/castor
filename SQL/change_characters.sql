update  bc_caribou_core_matrix_habitat_v20190904_1
set herd_name = REPLACE(LTRIM(RTRIM(herd_name)), '-', '_')
where herd_name like '%-%';