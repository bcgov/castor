CREATE TABLE public.vdyp_err
(
  error text
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.vdyp_err
  OWNER TO clus_project;
/*Import the data*/
Alter TAble vdyp_err Add Column feature_id integer;
UPDATE vdyp_err SET feature_id = CAST(substring(error, position(': ' in error) + 2, position(' ) ' in error) - position(': ' in error)-2) AS integer );

SELECT distinct (feature_id) from vdyp_err;

/*DELETE FROM vdyp*/
DELETE FROM vdyp WHERE feature_id IN
(SELECT distinct (feature_id) from vdyp_err);