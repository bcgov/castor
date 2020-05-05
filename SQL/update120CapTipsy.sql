update yc_tipsy set height = a.height, tvol = a.tvol from 
(select ycid, tvol, height from yc_tipsy where age = 120) a
where age > 120 and yc_tipsy.ycid = a.ycid;

select * from yc_tipsy order by ycid, age limit 200;