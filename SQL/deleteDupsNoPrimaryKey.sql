DELETE   FROM zone_constraints T1
  USING       zone_constraints T2
WHERE  T1.ctid    < T2.ctid       -- select the "older" ones
  AND T1.zoneid  = T2.zoneid 
  AND  T1.reference_zone    = T2.reference_zone       -- list columns that define duplicates
  AND  T1.ndt = T2.ndt
  AND  T1.variable = T2.variable
  AND  T1.threshold = T2.threshold
  AND  T1.type = T2.type
  AND  T1.percentage = T2.percentage
  ;