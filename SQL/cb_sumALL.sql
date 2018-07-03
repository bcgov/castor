Create TAble cb_sum As
SELECT SUM(t.areaha) AS sumarea, t.herd_name ,t.harvestyr
    FROM (
      SELECT b.areaha, b.harvestyr, y.herd_name
      FROM public.cns_cut_bl_polygon b, (SELECT * FROM public.gcbp_carib_polygon) y
      WHERE ST_INTERSECTS(b.wkb_geometry, y.geom))t 
      GROUP BY harvestyr, herd_name
      ORDER BY  herd_name, harvestyr;