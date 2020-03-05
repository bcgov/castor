INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU7', 'A', 'int', 'Y', -1.485817205, NULL, 'rast.du7_bounds', NULL, NULL, NULL);	
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU7', 'A', 'dt_rd', 'N', 0.058681294, 'DT', 'rast.du7_bounds', NULL, 'roadyear > 0', NULL);
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU7', 'A', 'dt_cut_1_4', 'N', -0.003598675 , 'DT', 'rast.du7_bounds', NULL, 'blockid > 0 and age BETWEEN 0 and 4', NULL);
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU7', 'A', 'dt_cut_5_40', 'N', 0.007959815, 'DT', 'rast.du7_bounds', NULL, 'blockid > 0 and age BETWEEN 5 and 40', NULL);

--re
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU7', 'A', 're_int', 'Y', 1, 'RE', 'rast.du7_bounds', NULL, 'rast.caribou_herd', NULL);
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU7', 'A', 're_dt_rd', 'N', 1, 'RE', 'rast.du7_bounds', NULL, 'rast.caribou_herd', 'dt_rd');
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU7', 'A', 're_dt_cut_1_4', 'N', 1, 'RE', 'rast.du7_bounds', NULL, 'rast.caribou_herd', 'dt_cut_1_4');
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU7', 'A', 're_dt_cut_5_40', 'N', 1, 'RE', 'rast.du7_bounds', NULL, 'rast.caribou_herd', 'dt_cut_5_40');

---re table

INSERT INTO rsf_re_coeff VALUES
    ('Telkwa',48, -1.611815439, -0.009079608, 0.048956751, 0.09384182);
INSERT INTO rsf_re_coeff VALUES
    ('Tweedsmuir',51, -1.510645378, -0.015089313, 0.011451174, 0.008652695);
INSERT INTO rsf_re_coeff VALUES
    ('Tsenaglode',50,-1.409971817, 0.001034101,	-0.003527299, 0.039946472);
INSERT INTO rsf_re_coeff VALUES
    ('Spatsizi',45,-1.778323093,-0.003495634,0.018444262,0.030932044);
INSERT INTO rsf_re_coeff VALUES
    ('Rainbows',40,-0.694064407,-0.002182792,0.064217717,-0.006273924);
INSERT INTO rsf_re_coeff VALUES
    ('Pink_Mountain',35,-2.452414486,0.018002063,-0.025157982,0.130381937);
INSERT INTO rsf_re_coeff VALUES
    ('Muskwa',31,-3.014417372,0.00400182,0.011437863,0.016999406);
INSERT INTO rsf_re_coeff VALUES
    ('Itcha_Ilgachuz',23,-0.860111617,-0.015708616,0.015034977,0.029160317);
INSERT INTO rsf_re_coeff VALUES
    ('Graham',19,-1.694706446,-0.019755355,0.017995979,0.126579535);	
INSERT INTO rsf_re_coeff VALUES
    ('Frog', 16,-1.230904684,-0.001040063,-0.008641252,0.024839213);
INSERT INTO rsf_re_coeff VALUES
    ('Finlay', 14,-0.834871344,-0.003528678,-0.010281767,0.01966928);
INSERT INTO rsf_re_coeff VALUES
    ('Chase', 9,-1.213880508,-0.002781645,0.00376463,0.049108733);
INSERT INTO rsf_re_coeff VALUES
    ('Charlotte_Alplands',8 ,-0.994400978,0.002916703,-0.039693002,0.199083439);
	select * from rsf_re_coeff;
	
update rsf_re_coeff set re_int = re_int + 1.485817205;
update rsf_re_coeff set re_dt_rd = re_dt_rd - 0.058681294;
update rsf_re_coeff set re_dt_cut_1_4 = re_dt_cut_1_4 + 0.003598675;
update rsf_re_coeff set re_dt_cut_5_40 = re_dt_cut_5_40 - 0.007959815;

---DU 8

INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU8', 'A', 'int', 'Y', -1.674823619, NULL, 'rast.du8_bounds', NULL, NULL, NULL);
	
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU8', 'A', 'dt_rd', 'N', 0.14269371, 'DT', 'rast.du8_bounds', NULL, 'roadyear > 0', NULL);
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU8', 'A', 'dt_cut_1_4', 'N', -0.00111749 , 'DT', 'rast.du8_bounds', NULL, 'blockid > 0 and age BETWEEN 0 and 4', NULL);
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU8', 'A', 'dt_cut_5_9', 'N', -0.025071038, 'DT', 'rast.du8_bounds', NULL, 'blockid > 0 and age BETWEEN 5 and 9', NULL);
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU8', 'A', 'dt_cut_10_40', 'N', -0.060621903, 'DT', 'rast.du8_bounds', NULL, 'blockid > 0 and age BETWEEN 10 and 40', NULL);

--re
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU8', 'A', 're_int', 'Y', 1, 'RE', 'rast.du8_bounds', NULL, 'rast.caribou_herd', NULL);
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU8', 'A', 're_dt_rd', 'N', 1, 'RE', 'rast.du8_bounds', NULL, 'rast.caribou_herd', 'dt_rd');
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU8', 'A', 're_dt_cut_1_4', 'N', 1, 'RE', 'rast.du8_bounds', NULL, 'rast.caribou_herd', 'dt_cut_1_4');
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU8', 'A', 're_dt_cut_5_9', 'N', 1, 'RE', 'rast.du8_bounds', NULL, 'rast.caribou_herd', 'dt_cut_5_9');
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU8', 'A', 're_dt_cut_10_40', 'N', 1, 'RE', 'rast.du8_bounds', NULL, 'rast.caribou_herd', 'dt_cut_10_40');

---re table
Alter table rsf_re_coeff add column re_dt_cut_5_9 double precision;
Alter table rsf_re_coeff add column re_dt_cut_10_40 double precision;

INSERT INTO rsf_re_coeff VALUES
    ('Burnt_Pine',3,-1.757817821,0.045717843,NULL,0.043963225,-0.08866491,-0.017075518);
INSERT INTO rsf_re_coeff VALUES
    ('Kennedy_Siding',24,-1.654779108,-0.007518377,NULL,0.267778933,-0.02096594,-0.196453289);
INSERT INTO rsf_re_coeff VALUES
    ('Moberly',29,-1.671651073,-0.002790391,NULL,0.182789283,-0.056448581,-0.09476151);	
INSERT INTO rsf_re_coeff VALUES
    ('Narraway',32,-1.649650512,-0.049859603,NULL,0.239219716,0.0202318,-0.037418807);	
INSERT INTO rsf_re_coeff VALUES
    ('Quintette',38,-1.850885858,0.007659977,NULL,0.115387456,0.009824958,-0.009059679);	
INSERT INTO rsf_re_coeff VALUES
    ('Scott',42,-1.45938125,0.000543494,NULL,0.005323671,-0.013659582,-0.005672115);	
					
	
update rsf_re_coeff set re_int = re_int + 1.6748236195 where herd_no in(3,24,29,32,38,42);
update rsf_re_coeff set re_dt_rd = re_dt_rd - 0.14269371 where herd_no in(3,24,29,32,38,42);
update rsf_re_coeff set re_dt_cut_1_4 = re_dt_cut_1_4 + 0.00111749 where herd_no in(3,24,29,32,38,42);
update rsf_re_coeff set re_dt_cut_5_9 = re_dt_cut_5_9 + 0.025071038 where herd_no in(3,24,29,32,38,42);
update rsf_re_coeff set re_dt_cut_10_40 = re_dt_cut_10_40 + 0.060621903 where herd_no in(3,24,29,32,38,42);

---DU9

INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU9', 'A', 'int', 'Y', -2.410293425, NULL, 'rast.du9_bounds', NULL, NULL, NULL);
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU9', 'A', 'dt_rd', 'N', 0.149903142, 'DT', 'rast.du9_bounds', NULL, 'roadyear > 0', NULL);
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU9', 'A', 'dt_cut_1_4', 'N',0.001644972 , 'DT', 'rast.du9_bounds', NULL, 'blockid > 0 and age BETWEEN 0 and 4', NULL);
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU9', 'A', 'dt_cut_5_9', 'N', -0.025707916, 'DT', 'rast.du9_bounds', NULL, 'blockid > 0 and age BETWEEN 5 and 9', NULL);
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU9', 'A', 're_int', 'Y', 1, 'RE', 'rast.du9_bounds', NULL, 'rast.caribou_herd', NULL);
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU9', 'A', 're_dt_rd', 'N', 1, 'RE', 'rast.du9_bounds', NULL, 'rast.caribou_herd', 'dt_rd');
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU9', 'A', 're_dt_cut_1_4', 'N', 1, 'RE', 'rast.du9_bounds', NULL, 'rast.caribou_herd', 'dt_cut_1_4');
INSERT INTO rsf_model_coeff VALUES
    ('caribou', 'DU9', 'A', 're_dt_cut_5_9', 'N', 1, 'RE', 'rast.du9_bounds', NULL, 'rast.caribou_herd', 'dt_cut_5_9');

-- re table
INSERT INTO rsf_re_coeff VALUES
    ('Hart_Ranges',21,-2.16364404,0.007307419,NULL,0.054743662,-0.025707916,NULL);
INSERT INTO rsf_re_coeff VALUES
    ('Nakusp',7,-2.734982477,0.040330704,NULL,0.101994525,-0.025707916,NULL);
INSERT INTO rsf_re_coeff VALUES
    ('South_Selkirks',44,-2.323586506,-0.042907134,NULL,0.292656461,-0.025707916,NULL);

update rsf_re_coeff set re_int = re_int + 2.410293425 where herd_no in(21,7,44);
update rsf_re_coeff set re_dt_rd = re_dt_rd - 0.149903142 where herd_no in(21,7,44);
update rsf_re_coeff set re_dt_cut_1_4 = re_dt_cut_1_4 - 0.001644972 where herd_no in(21,7,44);
update rsf_re_coeff set re_dt_cut_5_9 = re_dt_cut_5_9 + 0.025707916 where herd_no in(21,7,44);



select * from rsf_re_coeff;