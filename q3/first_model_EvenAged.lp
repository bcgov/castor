/* Objective function */
max: +16 YC_R1 +23 x12 +33 x13 +24 x21 +32 x22 +45 x23;

/* Constraints */
+YC_R1 +x12 +x13 = 120;
+x21 +x22 +x23 = 180;
+YC_R1 +x21 = 100;
+x12 +x22 = 100;
+x13 +x23 = 100;
