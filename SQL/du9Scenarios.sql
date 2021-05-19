select avg(volume_harvest)/5,area_name from kootenaylake_tsa.volumebyarea  
where scenario = 'kootenaylake_centselk_scen3b' group by area_name;

select avg(volume_harvest)/5,area_name from arrow_tsa.volumebyarea  
where scenario = 'arrow_centselk_scen3c' group by area_name;

select avg(volume_harvest)/5,area_name from williams_lake_tsa.volumebyarea  
where scenario = 'williams_lake_wells_gray_north_scen3c' group by area_name;

select avg(volume) from williams_lake_tsa.harvest 
where scenario = 'williams_lake_wells_gray_north_scen3c';

select avg(volume) from arrow_tsa.harvest 
where scenario = 'arrow_centselk_scen3c';

select avg(volume) from kootenaylake_tsa.harvest 
where scenario in ('kootenaylake_centselk_scen3b');