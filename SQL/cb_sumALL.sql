Create TAble cb_sum As
SELECT SUM(t.areaha) AS sumarea, t.herd_name ,t.harvestyr
    FROM (
      SELECT b.areaha, b.harvestyr, y.herd_name
      FROM public.cns_cut_bl_polygon b, (SELECT * FROM public.gcbp_carib_polygon) y
      WHERE ST_INTERSECTS(b.wkb_geometry, y.geom))t 
      GROUP BY harvestyr, herd_name
      ORDER BY  herd_name, harvestyr;

Create TAble fire_sum As
SELECT SUM(ST_Area(ST_Intersection(y.geom, b.wkb_geometry ))) AS sumarea, herd_name ,fire_year
      FROM public.h_fire_ply_polygon b, public.gcbp_carib_polygon y
      WHERE ST_INTERSECTS(b.wkb_geometry, y.geom) 
      GROUP BY fire_year, herd_name
      ORDER BY  herd_name, fire_year;

