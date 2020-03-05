update caribou_avoid_coeff set reclass = '''''1:0,2:0,3:-1.806522343,4:-1.1105315730964,5:0,6:0,7:-2.424005425,8:-0.758437387653276,9:-1.30490388587564,10:-1.61344918557149,11:0,12:0,13:0,14:-0.933538102455396,15:0,16:-0.673125620676623,17:0,18:0,19:-1.80111359004312,20:0,21:-0.962806568,22:0,23:-1.04098980191728,24:-1.72024071,25:0,26:0,27:0,28:-1.52603713536291,29:-1.810153601,30:0,31:-2.8062986729339,32:-1.818634767,33:0,34:0,35:-2.17406458580718,36:0,37:0,38:-1.758106017,39:0,40:-0.656362586057691,41:0,42:-1.243523595,43:-1.65385459882272,44:-2.539434073,45:-1.37879765526585,46:0,47:0,48:-1.7505470553362,49:0,50:-0.926668688362199,51:-1.63150650631181,52:0,53:0,54:0,55:0'''''
where layer = 'herd_re_intercept';
update caribou_avoid_coeff set type = 'RC' where layer = 'herd_re_intercept';

update caribou_avoid_coeff set reclass = '''''1:0,2:0,3:-0.036318799,4:-0.00533123716465756,5:0,6:0,7:0.167632166,8:-0.0396534772958528,9:0.00343634702579539,10:-0.00210849731027482,11:0,12:0,13:0,14:-0.015060088760427,15:0,16:-0.00806923644428433,17:0,18:0,19:-0.010902529823099,20:0,21:-0.02449203,22:0,23:0.00178054999683576,24:-0.169617992,25:0,26:0,27:0,28:0.0155847850857728,29:-0.148094873,30:0,31:0.0171144353269091,32:-0.065910989,33:0,34:0,35:-0.00901211259238406,36:0,37:0,38:0.011676969,39:0,40:0.064341694291747,41:0,42:-0.062681267,43:0.00911256798234332,44:-0.011249926,45:-0.00194446727854553,46:0,47:0,48:0.0427672501422123,49:0,50:-0.000800564812143227,51:-0.0015607239753661,52:0,53:0,54:0,55:0''''' 
where layer = 'herd_re_dist_cut';

update caribou_avoid_coeff set reclass = '''''1:0,2:0,3:0.132461104,4:0.354290170226561,5:0,6:0,7:0.007383807,8:0.207113181637876,9:0.0748827105631625,10:0.374798916859291,11:0,12:0,13:0,14:0.0512846251649174,15:0,16:0.085127460151006,17:0,18:0,19:0.146690756122206,20:0,21:0.083057801,22:0,23:0.0175811637725341,24:0.35071811,25:0,26:0,27:0,28:0.335495878886056,29:0.30365598,30:0,31:0.0416058505421997,32:0.291372466,33:0,34:0,35:0.146641917857697,36:0,37:0,38:0.19286076,39:0,40:0.023566888444451,41:0,42:0.163445968,43:0.315803420252097,44:0.262386318,45:0.0570879960144307,46:0,47:0,48:0.0970437525963996,49:0,50:0.0828854776396467,51:0.0270335317844938,52:0,53:0,54:0,55:0'''''
where layer = 'herd_re_dist_rd';


update caribou_avoid_coeff set sql = 'roadyear > 0' where layer = 'dt_resource_road';

update caribou_avoid_coeff set sql = 'blockid >0 and age BETWEEN 0 and 60' where layer = 'blocks_0_60';

update caribou_avoid_coeff set static = 'Y' where layer = 'herd_re_intercept';

update caribou_avoid_coeff set sql = 'rast.caribou_herd' where sql = 'rast.herd';

Alter table caribou_avoid_coeff add column re_variable text; --need to know what variable the re applys
update caribou_avoid_coeff set re_variable = 'blocks_0_60' where layer = 'herd_re_dist_cut';
update caribou_avoid_coeff set re_variable = 'dt_resource_road' where layer = 'herd_re_dist_rd';


update caribou_avoid_coeff set re_variable = 'dt_resource_road' where layer = 'hr_dt_resource_road' ;

update caribou_avoid_coeff set sql = '12538' where layer = 'hr_dt_resource_road' and population = 'DU7';
update caribou_avoid_coeff set sql = '10518' where layer = 'hr_dt_resource_road' and population = 'DU6';
update caribou_avoid_coeff set sql = '5836' where layer = 'hr_dt_resource_road' and population = 'DU8';
update caribou_avoid_coeff set sql = '4895' where layer = 'hr_dt_resource_road' and population = 'DU9';

update caribou_avoid_coeff set re_variable = 'dt_resource_road,hr_dt_resource_road' where type = 'I';

select * from caribou_avoid_coeff where population = 'DU7';

