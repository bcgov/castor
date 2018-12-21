---
title: "Caribou Forestry Cutblock Resource Selection Function Report"
output: 
    html_document:
      keep_md: TRUE
      self_contained: FALSE
---



## Introduction
Here I describe a data exploration and model selection process completed to identify distance to cutblock covariates to include in caribou resource selection function (RSF) models. RSF models are a form of binomial logistic regression models that are used to statistically estimate habitat selection by animals (Boyce et al. 1999; Manly et al. 2007). RSFs were calculated for three seasons (early winter, late winter and summer), and across four caribou designatable units (DUs), i.e., ecological designations, of caribou. Caribou DU's  in British Columbia include DU 6 (boreal), DU7 (northern mountain), DU8 (central mountain) and DU9 (sourthern mountain) [see COSEWIC 2011](https://www.canada.ca/content/dam/eccc/migration/cosewic-cosepac/4e5136bf-f3ef-4b7a-9a79-6d70ba15440f/cosewic_caribou_du_report_23dec2011.pdf)

I had data that estimated the distance of approximately 500,000 caribou telemetry locations collected across Brtisish Columbia, and approximately two million randomly sampled locations within caribou home ranges (i.e., 'available' locations), to the nearest cutblock, by cutblock age, from one year old cutblocks up to greater than 50 year old cutblocks. I hypothesized that caribou selection for cutblocks would change as cutblocks age. Specifically, I predicted that caribou would be less likely to select younger cutblocks than older cutblocks, as younger cutblocks are typically associated with forage for other ungulates (i.e., moose and deer) and thus higher ungulate and predator (e.g., wolf) densities, resulting in higher mortality and predation risk for caribou (Wittmer et al. 2005; DeCesare et al. 2010).  

In addition, I hypothesized that distance to cutblock covariates would be correlated across years (e.g., distance to one year old cutblocks would be correlated with distance to two year old cutblocks). RSF models with highly correlated covariates (i.e., multicollinearity) can inflate  standard error coefficients of regression model covariates and make it difficult to interpret the contribution of covariates to estimating caribou resource selection. Therefore it would be necessary to simplify the number of covariates. I predicted that annual distance to cutblock covariates would need to be grouped to avoid multicollinearity. 

After temporally grouping the distance to cutblock data, I did further data exploration and correlation analyses of covariates by season and DU. I then fit distance to cutblock RSF models using functional responses (Matthiopolous et al. 2010) to test whether caribou selection of cutblocks is a function of the available distance to cutblocks within the caribou's home range. Specifically, I tested the hypothesis that caribou are more likely to avoid cutblocks in home ranges located closer to cutblocks. 

## Methods
### Correlation of Distance to Cutblock Across Years
Here I tested whether distance to cutblocks of different ages, from one year old to greater than 50 years old were correlated. I used a Spearman ($\rho$) correlation and correlated distance to cutblock between years in 10 year increments. Data were divided by designatable unit (DU). The following is an example of the R code used to calculate and display the correlation plots:

```r
# data
rsf.data.cut.age <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_cutblock_age.csv")

# Correlations
# Example code for first 10 years
dist.cut.1.10.corr <- rsf.data.cut.age [c (10:19)] # sub-sample 10 year periods
corr.1.10 <- round (cor (dist.cut.1.10.corr, method = "spearman"), 3)
p.mat.1.10 <- round (cor_pmat (dist.cut.1.10.corr), 2)
ggcorrplot (corr.1.10, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation Years 1 to 10")
```

### Generalized Linear Models (GLMs) of Distance to Cutblock across Years
Here I tested whether caribou selection of distance to cutblock changed as cublocks aged. This helped with temporally grouping distance to cutblock data by age, by illustrating if and when caribou consistently selected or avoided cutblocks of similar ages. 

I compared how caribou selected distance to cutblock across years by fitting seperate caribou RSFs, where each RSF had a single covariate for distance to cublock for each cutblock age. RSFs were fit using binomial generalized linear models (GLMs) with a logit link (i.e., comparing used to available caribou locations, where used locations are caribou telmetry locations and available locations are randomly sampled locations within the extent of estimated caribou home ranges). RSFs were fit for each season and DU. The following is an example of the R code used to calculate these RSFs:

```r
dist.cut.data.du.6.ew <- dist.cut.data %>% # sub-sample the data by season and DU
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "EarlyWinter")
glm.du.6.ew.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                        data = dist.cut.data.du.6.ew,
                        family = binomial (link = 'logit'))
glm.du.6.ew.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                        data = dist.cut.data.du.6.ew,
                        family = binomial (link = 'logit'))
....
....
....
glm.du.6.ew.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
```

The beta coefficients of distance to cutblock covariates were outputted from each model and plotted against  cutblock age to illustrate how caribou selection changed as the cutblock aged.  

### Resource Selection Function (RSF) Model Selection of Distance to Cutblock Covariates by Cutblock Age
Based on the results of the analysis described above, I grouped distance to cutblock into four age categories: one to four years old, five to nine years old, 10 to 29 years old and over 29 years old (see Results and Conclusion, below, for details). I then tested for correlation between these covariates using a Spearman-rank ($\rho$) correlation and by calculating variance inflation factors (VIFs) from GLMs. If covariates had a $\rho$ > 0.7 or VIF > 10 (Montgomery and Peck 1992; Manly et al. 2007; DeCesare et al. 2012), then distance to cutblock covariates were further grouped into larger age classes. VIFs were calculated using the vif() function from the 'car' package in R. 


```r
model.glm.du6.ew <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                          distance_to_cut_10yoorOver, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
vif (model.glm.du6.ew) 
```

I fit RSF models as mixed effect regressions using the glmer() function in the lme4 package of R. I fit models with correlated random effect intercepts and slopes for each distance to cutblock covariate by each unique indivdual cariobu and year in the model (i.e., a unique identifier). I fit models with all combinations of distance to cutblock covariates and compared them using Akaike Information Criterion (AIC). To faciliate model convergence, I standardized the distance to cutblock covaraites by subtracting the mean and dividing by the standard deviation of the covariate.


```r
# Generalized Linear Mixed Models (GLMMs)
# standardize covariates  (helps with model convergence)
dist.cut.data.du.6.ew$std.distance_to_cut_1to4yo <- (dist.cut.data.du.6.ew$distance_to_cut_1to4yo - mean (dist.cut.data.du.6.ew$distance_to_cut_1to4yo)) / sd (dist.cut.data.du.6.ew$distance_to_cut_1to4yo)
dist.cut.data.du.6.ew$std.distance_to_cut_5to9yo <- (dist.cut.data.du.6.ew$distance_to_cut_5to9yo - mean (dist.cut.data.du.6.ew$distance_to_cut_5to9yo)) / sd (dist.cut.data.du.6.ew$distance_to_cut_5to9yo)
dist.cut.data.du.6.ew$std.distance_to_cut_10yoorOver <- (dist.cut.data.du.6.ew$distance_to_cut_10yoorOver - mean (dist.cut.data.du.6.ew$distance_to_cut_10yoorOver)) / sd (dist.cut.data.du.6.ew$distance_to_cut_10yoorOver)

# fit correlated random effects model
model.lme.du6.ew <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                            std.distance_to_cut_10yoorOver + 
                            (std.distance_to_cut_1to4yo | uniqueID) + 
                            (std.distance_to_cut_5to9yo | uniqueID) +
                            (std.distance_to_cut_10yoorOver | uniqueID) , 
                          data = dist.cut.data.du.6.ew, 
                          family = binomial,
                          REML = F, 
                          verbose = T)
AIC (model.lme.du6.ew)
# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc <- performance (pr.temp, measure = "auc")
auc <- auc@y.values[[1]]
```

Next, I tested whether models with a functional repsonse (*sensu* Matthiplolus et al. 2010) improved model fit by comparing the above models to models that included interaction terms for available distance to cutblock, by age class. Available distance to cublock was calculated as the mean distance to cutblock (for each age class) sampled at all available locations within each individual caribou's seasonal home range. 


```r
### Fit model with functional responses
# Calculating dataframe with covariate expectations
sub <- subset (dist.cut.data.du.6.ew, pttype == 0)
std.distance_to_cut_1to4yo_E <- tapply (sub$std.distance_to_cut_1to4yo, sub$uniqueID, mean)
std.distance_to_cut_5to9yo_E <- tapply (sub$std.distance_to_cut_5to9yo, sub$uniqueID, mean)
std.distance_to_cut_10yoorOver_E <- tapply (sub$std.distance_to_cut_10yoorOver, sub$uniqueID, mean)
inds <- as.character (dist.cut.data.du.6.ew$uniqueID)
dist.cut.data.du.6.ew <- cbind (dist.cut.data.du.6.ew, 
                                "std.distance_to_cut_1to4yo_E" = std.distance_to_cut_1to4yo_E [inds],
                                "std.distance_to_cut_5to9yo_E" = std.distance_to_cut_5to9yo_E [inds],
                                "std.distance_to_cut_10yoorOver_E" = std.distance_to_cut_10yoorOver_E [inds])

model.lme.fxn.du6.ew <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                               std.distance_to_cut_10yoorOver + std.distance_to_cut_1to4yo_E +
                               std.distance_to_cut_5to9yo_E + std.distance_to_cut_10yoorOver_E +
                               std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                               std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                               std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                               (1 | uniqueID), 
                               data = dist.cut.data.du.6.ew, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, 
                                                       optimizer = "nloptwrap",
                                                       optCtrl = list (maxfun = 2e5)))
```


I calculated the AIC for each model and compared them to asses the most parsimonious model fit. I also calculated area under the curve (AUC) of Receiver Operating Characteristic (ROC) curves for each model using the ROCR package in R to test the accuracy of predictions. The model with the highest AIC weight and a reasonably high AUC score (i.e., the abiliy of the accurately predict caribou locations) was considered the best distance to cutblock model for a particular season and DU combination. This model, and covaraites from this model will be included in a broader RSF model fittign adn selction porcess to identify a comprehensive, parsimonious and robust caribou habitat model for each season and DU. 

## Results
### Correlation Plots of Distance to Cutblock by Year for Designatable Unit (DU) 6
In the first 10 years (i.e., correlations between distance to cutblocks 1 to 10 years old), distance to cublock at locations in caribou home ranges were generally correlated. Correlations were relatively strong within two to three years ($\rho$ > 0.45). Correlations generally became weaker ($\rho$ < 0.4) after three to four years. Correlation between distance to cutblock 11 to 20, 21 to 30 and 31 to 40 years old were correlated across all 10 years ($\rho$ > 0.45). Correlation between distance to cutblock in years 41 to 50 were generally weaker, but also highly variable ($\rho$ = -0.07 to 0.86). 

![](R/caribou_habitat/plots/plot_dist_cut_corr_1_10_du6.png)

![](plots/plot_dist_cut_corr_1_10_du6.png)

![](plots/plot_dist_cut_corr_11_20_du6.png)

![](plots/plot_dist_cut_corr_21_30_du6.png)

![](plots/plot_dist_cut_corr_31_40_du6.png)

![](plots/plot_dist_cut_corr_41_50_du6.png)

### Correlation Plots of Distance to Cutblock by Year for Designatable Unit (DU) 7
Distance to cutblock was consistently correlated across years within all the 10 years periods (\rho > 0.5), and generally highly correlated (\rho > 0.7) across ten year periods for older cutblocks (older than ten years). In general, proximate years (i.e., three to four years apart) tended to be highly correlated (\rho > 0.7) for newer cutblocks (one to ten yeas old).

![](plots/plot_dist_cut_corr_1_10_du7.png)

![](plots/plot_dist_cut_corr_11_20_du7.png)

![](plots/plot_dist_cut_corr_21_30_du7.png)

![](plots/plot_dist_cut_corr_31_40_du7.png)

![](plots/plot_dist_cut_corr_41_50_du7.png)

### Correlation Plots of Distance to Cutblock by Year for Designatable Unit (DU) 8
In the first 10 years, distance to cublock at locations in caribou home ranges were generally correlated. Correlations were typically stronger within two to three years ($\rho$ > 0.35) and weaker after three to four years. In years 11 to 20, 21 to 30 and 31 to 40, distance to cutblock was correlated within one year ($\rho$ > 0.41), but less correlated when greater than one year apart. In years 41 to greater than 50 years, correlations were generally weak between years.

![](plots/plot_dist_cut_corr_1_10_du8.png)

![](plots/plot_dist_cut_corr_11_20_du8.png)

![](plots/plot_dist_cut_corr_21_30_du8.png)

![](plots/plot_dist_cut_corr_31_40_du8.png)

![](plots/plot_dist_cut_corr_41_50_du8.png)

### Correlation Plots of Distance to Cutblock by Year for Designatable Unit (DU) 9
In the first 10 years, distance to cublock at locations in caribou home ranges were generally correlated within one year ($\rho$ > 0.44), but less correlated when over one year apart. Correlation between distance to cutblock 11 to 20, 21 to 30, 31 to 40 and 41 to greater than 50 years old were generally highly correlated across all 10 years ($\rho$ > 0.7), but with some exceptions.

![](plots/plot_dist_cut_corr_1_10_du9.png)

![](plots/plot_dist_cut_corr_11_20_du9.png)

![](plots/plot_dist_cut_corr_21_30_du9.png)

![](plots/plot_dist_cut_corr_31_40_du9.png)

![](plots/plot_dist_cut_corr_41_50_du9.png)

### Resource Selection Function (RSF) Distance to Cutblock Beta Coefficients by Year, Season and Designatable Unit (DU)
In DU6, distance to cutblock generally had a weak effect on caribou resource selection across years. There was not a clear pattern in selection of cutblocks across years, and this lack of  pattern was consistent across seasons. In general, caribou in DU6, across all seasons, appeared to avoid cutblocks less than three years old, select cutblocks four to ten years old and then avoid cutblocks over seven to ten years old.  
![](report_caribou_forest_cutblock_RSF_files/figure-html/DU6 single covariate RSF model output-1.png)<!-- -->

In DU7, there was a more distinct pattern in caribou selection of cutblocks, and this pattern was different among seasons. The early and late winter seasons were generally consistent. The effect of distacne to cutblock was relatively weak across years, but the effect shifted from little or no selection of more recent cutblocks (cutblocks less than 25 years old), to avoidance of older cutblocks (greater than 25 years old). In the summer, cutblocks less than four years old appeared to have little effect on caribou. However, there was relatively strong selection of cutblcoks five to 30 years old and general avoidance of cutblocks older than 30 to 35 years old. 
![](report_caribou_forest_cutblock_RSF_files/figure-html/DU7 single covariate RSF model output-1.png)<!-- -->

In DU8, selection of cutblocks was relatively strong and consistent across all seasons, but the pattern of selction was highly variable. However, in general, caribou selected younger cutblocks (approximately one to 20 years old) and avoided older cutblocks (greater than 20 years old). 
![](report_caribou_forest_cutblock_RSF_files/figure-html/DU8 single covariate RSF model output-1.png)<!-- -->
  
In DU9, the effect of cutblocks was relatively strong and consistent across seasons. In general, caribou avoided cutblocks, although avoidance of younger (less than 10 year old) cutblocks was weaker than older cutlbocks. 
![](report_caribou_forest_cutblock_RSF_files/figure-html/DU9 single covariate RSF model output-1.png)<!-- -->

### Resource Selection Function (RSF) Model Selection
#### DU6
##### Early Winter
The correlation plot indicated that distance to cutblocks 10 to 29 years old and 30 years old or over were highly correlated ($\rho$ = 0.85), therefore, I grouped these two age categories together (i.e., distance to cutblocks greater than 10 years old).

![](plots/plot_dist_cut_corr_du_6_ew.png)

The maximum VIF from the simple GLM covariate model (i.e., including distance to cutblock 1 to 4, 5 to 9 and over 10 years old) was <1.7, indicating these covariates were not highly correlated. 

The top-ranked model included covariates of distance to cutblock ages five to nine years old and over nine years, but no functional response, and had an AIC weight (AIC*~w~*) of 1.00 (Table 1). In addition, the top model had the second highest AUC (AUC = 0.604), which was very close to the highest AUC value in the model set (AUC = 0.607).

##### Late Winter
The correlation plot indicated that distance to cutblocks 10 to 29 years old and 30 years old or over were highly correlated ($\rho$ = 0.79), therefore, I grouped these two age categories together (i.e., disatnce to cutblcoks greater than 10 years old).

![](plots/plot_dist_cut_corr_du_6_lw.png)

The maximum VIF from the simple GLM covariate model was <1.6, indicating these covariates were not highly correlated. The top-ranked model included covariates of distance to cutblock for each cutblock age class, but no functional response, and had an AIC*~w~* of 1.00 (Table 1). In addition, the top model had the highest AUC (AUC = 0.665).

##### Summer
The correlation plot indicated that distance to cutblocks 10 to 29 years old and 30 years old or over were highly correlated ($\rho$ = 0.82), therefore, I grouped these two age categories together (i.e., disatnce to cutblcoks greater than 10 years old).

![](plots/plot_dist_cut_corr_du_6_s.png)

The maximum VIF from the simple GLM covariate model was <1.7, indicating these covariates were not highly correlated. The top-ranked model included covariates of distance to cutblock for each cutblock age class, but no functional response, and had an AIC*~w~* of 1.00 (Table 1). In addition, the top model had the highest AUC (AUC = 0.698).

#### DU7
##### Early Winter
The correlation plot indicated that distance to cutblocks 10 to 29 years old and 30 years old or over were highly correlated ($\rho$ = 0.81), therefore, I grouped these two age categories together (i.e., distance to cutblocks greater than 10 years old).

![](plots/plot_dist_cut_corr_du_7_ew.png)

The maximum VIF from the simple GLM covariate model (i.e., including distance to cutblock 1 to 4, 5 to 9 and over 10 years old) was <4.1, indicating these covaraites were not highly correlated. The AIC*~w~* of the top model was 1.00 (Table 1). It included all distance to cutblock covariates, but not a functional response in caribou selection for cutblocks. The AUC of the top model (AUC = 0.679) was better than all other models.

##### Late Winter
The correlation plot indicated that distance to cutblocks 10 to 29 years old and 30 years old or over were highly correlated ($\rho$ = 0.82) and distance to cutblocks 5 to 9 years old and 10 to 29 years old were highly correlated ($\rho$ = 0.71) therefore, I grouped these three age categories together (i.e., distance to cutblocks greater than 5 years old).

![](plots/plot_dist_cut_corr_du_7_lw.png)

The maximum VIF from the simple GLM covariate model (i.e., including distance to cutblock 1 to 4, over 5 years old) was <1.8, indicating these covariates were not highly correlated. The AIC*~w~* of the top model was 1.00 (Table 1). It included all distance to cutblock covariates, but not a functional response in caribou selection for cutblocks. The AUC of the top model (AUC = 0.690) was better than all other models.

##### Summer
The correlation plot indicated that distance to cutblocks 10 to 29 years old and 30 years old or over were highly correlated ($\rho$ = 0.80) and distance to cutblocks 5 to 9 years old and 10 to 29 years old were highly correlated ($\rho$ = 0.87) therefore, I grouped these three age category covariates together (i.e., distance to cutblocks greater than 5 years old).

![](plots/plot_dist_cut_corr_du_7_s.png)

The maximum VIF from the simple GLM covariate model (i.e., including distance to cutblock 1 to 4, over 5 years old) was <1.6, indicating these covariates were not highly correlated. The AIC*~w~* of the top model was 1.00 (Table 1). It included all distance to cutblock covariates, but not a functional response in caribou selection for cutblocks. The AUC of the top model (AUC = 0.694) was better than all other models.

#### DU8
##### Early Winter
The correlation plot indicated that none of the distance to cutblock covariates were highly correlated ($\rho$ < 0.61). Therefore, I did not group any of the age covariates together.

![](plots/plot_dist_cut_corr_du_8_ew.png)

The maximum VIF from the simple GLM covariate model was <1.9, indicating the covariates were not highly correlated. The AIC*~w~* of the top model was 1.00 (Table 1). It included all distance to cutblock covariates, but not a functional response in caribou selection for cutblocks. The AUC of the top model (AUC = 0.698) was better than all other models.

##### Late Winter
The correlation plot indicated that none of the distance to cutblock covariates were highly correlated ($\rho$ < 0.57). Therefore, I did not group any of the age covariates together.

![](plots/plot_dist_cut_corr_du_8_lw.png)

The maximum VIF from the simple GLM covariate model was <1.7, indicating the covariates were not highly correlated. The AIC*~w~* of the top model was 1.00 (Table 1). It included all distance to cutblock covariates, but not a functional response in caribou selection for cutblocks. The AUC of the top model (AUC = 0.715) was better than all other models.

##### Summer
The correlation plot indicated that none of the distance to cutblock covariates were highly correlated ($\rho$ < 0.54). Therefore, I did not group any of the age covariates together.

![](plots/plot_dist_cut_corr_du_8_s.png)

The maximum VIF from the simple GLM covariate model was <1.8, indicating the covariates were not highly correlated. The AIC*~w~* of the top model was 1.00 (Table 1). It included all distance to cutblock covariates, but not a functional response in caribou selection for cutblocks. The AUC of the top model (AUC = 0.701) was better than all other models.

#### DU9
##### Early Winter
The correlation plot indicated that none of the distance to cutblock covariates were highly correlated ($\rho$ < 0.67). Therefore, I did not group any of the age covariates together.

![](plots/plot_dist_cut_corr_du_9_ew.png)

The maximum VIF from the simple GLM covariate model was <6.6, indicating covariates were not highly correlated. The AIC*~w~* of the top model was 0.90 (Table 1). It included all temporal distance to cutblock covariates with a functional response in caribou selection for cutblocks for each covariate. The AUC of the top model (AUC = 0.636) was about average for the model set, and slightly less than the most predictive model (i.e., AUC = 0.648).

##### Late Winter
The correlation plot indicated that none of the distance to cutblock covariates were highly correlated ($\rho$ < 0.57). Therefore, I did not group any of the age covariates together.

![](plots/plot_dist_cut_corr_du_9_lw.png)

The maximum VIF from the simple GLM covariate model was <3.5, indicating covariates were not highly correlated. The AIC*~w~* of the top model was 0.986 (Table 1). It included all temporal distance to cutblock covariates, but no functional response in caribou selection for cutblocks. The AUC of the top model (AUC = 0.681) was better than all other models.

##### Summer
The correlation plot indicated that none of the distance to cutblock covariates were highly correlated ($\rho$ < 0.64). Therefore, I did not group any of the age covariates together.

![](plots/plot_dist_cut_corr_du_9_s.png)

The maximum VIF from the simple GLM covariate model was <2.2, indicating covariates were not highly correlated. The AIC*~w~* of the top model was 1.00 (Table 1). It included all temporal distance to cutblock covariates, but no functional response in caribou selection for cutblocks. The AUC of the top model (AUC = 0.694) was better than all other models.

Table 1. AIC, AIC*~w~* and AUC values from DU and seasonal sets of distance to cutblock resoruce selection models for caribou. 
<table class="table table-striped table-condensed" style="margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> DU </th>
   <th style="text-align:left;"> Season </th>
   <th style="text-align:left;"> Model.Type </th>
   <th style="text-align:left;"> Fixed.Effects.Covariates </th>
   <th style="text-align:left;"> Random.Effects.Covariates </th>
   <th style="text-align:right;"> AIC </th>
   <th style="text-align:right;"> AICw </th>
   <th style="text-align:right;"> AUC </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 219570.594 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6069125 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID) </td>
   <td style="text-align:right;"> 219770.472 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.5937545 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 219655.915 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.5986322 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DCover9 </td>
   <td style="text-align:left;"> (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 219680.649 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.5991059 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 219665.960 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.5991413 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DCover9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 219643.992 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6036803 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DCover9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 219543.927 </td>
   <td style="text-align:right;"> 1.000 </td>
   <td style="text-align:right;"> 0.6036803 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover9, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 219759.887 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.5919242 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, A_DC1to4, DC1to4*A_DC1to4 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 219766.007 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6036803 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, A_DC5to9, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 219788.578 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.5914720 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DCover9, A_DCover9, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 219767.932 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.5914720 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 219771.400 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.5917261 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DCover9, A_DC1to4, A_DCover9, DC1to4*A_DC1to4, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 219761.994 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.5918944 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DCover9, A_DC5to9, A_DCover9, DC5to9*A_DC5to9, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 219765.450 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.5916762 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 380908.091 </td>
   <td style="text-align:right;"> 1.000 </td>
   <td style="text-align:right;"> 0.6653907 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID) </td>
   <td style="text-align:right;"> 383349.458 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6478508 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 382911.177 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6489808 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DCover9 </td>
   <td style="text-align:left;"> (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 382830.429 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6491990 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 381949.115 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6491990 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DCover9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 381760.138 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6588841 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DCover9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 381949.115 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6577028 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover9, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 385132.898 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6299152 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, A_DC1to4, DC1to4*A_DC1to4 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 385197.315 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6293981 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, A_DC5to9, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 385170.093 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6298724 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DCover9, A_DCover9, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 385164.575 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6296997 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 385161.153 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6298100 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DCover9, A_DC1to4, A_DCover9, DC1to4*A_DC1to4, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 385150.627 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6295634 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DCover9, A_DC5to9, A_DCover9, DC5to9*A_DC5to9, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 385146.930 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6299700 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 426565.386 </td>
   <td style="text-align:right;"> 1.000 </td>
   <td style="text-align:right;"> 0.6975474 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID) </td>
   <td style="text-align:right;"> 432125.101 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6748133 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 431383.922 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6730889 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DCover9 </td>
   <td style="text-align:left;"> (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 430372.475 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6770102 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 429136.717 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6867359 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DCover9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 427978.547 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6902663 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DCover9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 428097.461 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6881320 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover9, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 435823.782 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6488822 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, A_DC1to4, DC1to4*A_DC1to4 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 436081.158 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6469039 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, A_DC5to9, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 435864.565 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6491104 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DCover9, A_DCover9, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 435965.517 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6470590 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 435853.075 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6492180 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DCover9, A_DC1to4, A_DCover9, DC1to4*A_DC1to4, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 435951.860 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6475110 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU6 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DCover9, A_DC5to9, A_DCover9, DC5to9*A_DC5to9, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 435823.701 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6487732 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 134484.792 </td>
   <td style="text-align:right;"> 1.000 </td>
   <td style="text-align:right;"> 0.6785259 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID) </td>
   <td style="text-align:right;"> 134750.397 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6715706 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 134623.558 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6736243 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DCover9 </td>
   <td style="text-align:left;"> (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 134667.478 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6731335 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 134566.469 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6757624 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DCover9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 134590.305 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6758017 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DCover9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DCover9 | UniqueID) </td>
   <td style="text-align:right;"> 134563.620 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6762069 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover9, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 134855.008 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6676513 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, A_DC1to4, DC1to4*A_DC1to4 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 134872.530 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6677218 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, A_DC5to9, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 134877.488 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6674779 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DCover9, A_DCover9, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 134864.874 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6676152 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 134877.230 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6676896 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DCover9, A_DC1to4, A_DCover9, DC1to4*A_DC1to4, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 134867.788 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6677862 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DCover9, A_DC5to9, A_DCover9, DC5to9*A_DC5to9, DCover9*A_DCover9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 134853.886 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6675454 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DCover5 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DCover5 | UniqueID) </td>
   <td style="text-align:right;"> 261751.898 </td>
   <td style="text-align:right;"> 1.000 </td>
   <td style="text-align:right;"> 0.6901078 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID) </td>
   <td style="text-align:right;"> 262605.002 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6827657 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DCover5 </td>
   <td style="text-align:left;"> (DCover5 | UniqueID) </td>
   <td style="text-align:right;"> 262788.832 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6820883 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DCover5, A_DC1to4, A_DCover5, DC1to4*A_DC1to4, DCover5*A_DCover5 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 263471.255 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6747590 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, A_DC1to4, DC1to4*A_DC1to4 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 263470.135 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6746544 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DCover5, A_DCover5, DCover5*A_DCover5 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 263470.135 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6746544 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DCover5 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DCover5 | UniqueID) </td>
   <td style="text-align:right;"> 254657.814 </td>
   <td style="text-align:right;"> 1.000 </td>
   <td style="text-align:right;"> 0.6943307 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID) </td>
   <td style="text-align:right;"> 256004.615 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6852690 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DCover5 </td>
   <td style="text-align:left;"> (DCover5 | UniqueID) </td>
   <td style="text-align:right;"> 255401.137 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6884055 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DCover5, A_DC1to4, A_DCover5, DC1to4*A_DC1to4, DCover5*A_DCover5 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 256854.514 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6782352 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, A_DC1to4, DC1to4*A_DC1to4 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 257153.254 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6768409 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU7 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DCover5, A_DCover5, DCover5*A_DCover5 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 256871.472 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6781573 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 169165.913 </td>
   <td style="text-align:right;"> 1.000 </td>
   <td style="text-align:right;"> 0.6984592 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID) </td>
   <td style="text-align:right;"> 171143.776 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6763776 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 170983.210 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6768742 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC10to29 </td>
   <td style="text-align:left;"> (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 170650.481 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6788544 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DCover30 </td>
   <td style="text-align:left;"> (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 171314.739 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6746474 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 170429.664 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6856307 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC10to29 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 170219.682 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6862134 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 170651.047 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6838681 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DC10to29 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 170085.763 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6866272 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DCover30 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 170523.143 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6851130 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 170182.845 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6866402 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 169492.478 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6932058 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 170046.102 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6908469 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 169816.246 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6916868 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 169764.695 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6926306 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, DCover30, A_DC1to4, A_DC5to9, A_DC10to29, A_DCover30, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171689.571 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6659708 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, A_DC1to4, DC1to4*A_DC1to4 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 172046.068 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6622205 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, A_DC5to9, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171957.667 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6625220 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC10to29, A_DC10to29, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 172153.722 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6613438 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DCover30, A_DCover30, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171916.985 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6636456 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171943.417 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6628815 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, A_DC1to4, A_DC10to29, DC1to4*A_DC1to4, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171978.000 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6630951 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DCover30, A_DC1to4, A_DCover30, DC1to4*A_DC1to4, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171831.666 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6645972 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DC10to29, A_DC5to9, A_DC10to29, DC5to9*A_DC5to9, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171855.991 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6636403 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DCover30, A_DC5to9, A_DCover30, DC5to9*A_DC5to9, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171768.884 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6646900 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC10to29, DCover30, A_DC10to29, A_DCover30, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171872.710 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6641337 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, A_DC1to4, A_DC5to9, A_DC10to29, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171845.255 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6640307 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover30, A_DC1to4, A_DC5to9, A_DCover30, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171769.520 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6648524 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, DCover30, A_DC1to4, A_DC10to29, A_DCover30, DC1to4*A_DC1to4, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171785.381 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6652730 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DC10to29, DCover30, A_DC5to9, A_DC10to29, A_DCover30, DC5to9*A_DC5to9, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 171689.222 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6657521 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 254338.194 </td>
   <td style="text-align:right;"> 1.000 </td>
   <td style="text-align:right;"> 0.7154196 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID) </td>
   <td style="text-align:right;"> 258523.184 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6818131 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 258348.920 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6825417 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC10to29 </td>
   <td style="text-align:left;"> (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 258090.503 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6837166 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DCover30 </td>
   <td style="text-align:left;"> (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 257635.408 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6874427 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 257194.925 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6939387 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC10to29 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 256814.516 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6952917 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 256530.819 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6971946 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DC10to29 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 256704.490 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6961360 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DCover30 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 256572.779 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6969591 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 256458.500 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6969174 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 255644.489 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.7058054 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 255558.430 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.7064405 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 255361.909 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.7064563 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 255318.276 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.7071663 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, DCover30, A_DC1to4, A_DC5to9, A_DC10to29, A_DCover30, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259316.194 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6724429 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, A_DC1to4, DC1to4*A_DC1to4 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259754.731 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6688364 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, A_DC5to9, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259813.330 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6686219 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC10to29, A_DC10to29, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259565.160 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6709280 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DCover30, A_DCover30, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259713.445 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6691556 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259741.881 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6689372 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, A_DC1to4, A_DC10to29, DC1to4*A_DC1to4, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259501.522 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6712424 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DCover30, A_DC1to4, A_DCover30, DC1to4*A_DC1to4, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259637.220 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6696592 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DC10to29, A_DC5to9, A_DC10to29, DC5to9*A_DC5to9, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259495.864 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6711626 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DCover30, A_DC5to9, A_DCover30, DC5to9*A_DC5to9, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259688.419 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6694994 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC10to29, DCover30, A_DC10to29, A_DCover30, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259402.539 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6722030 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, A_DC1to4, A_DC5to9, A_DC10to29, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259452.813 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6713664 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover30, A_DC1to4, A_DC5to9, A_DCover30, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259628.662 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6697536 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, DCover30, A_DC1to4, A_DC10to29, A_DCover30, DC1to4*A_DC1to4, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259343.500 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6723146 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DC10to29, DCover30, A_DC5to9, A_DC10to29, A_DCover30, DC5to9*A_DC5to9, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 259351.169 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6724220 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 233968.687 </td>
   <td style="text-align:right;"> 1.000 </td>
   <td style="text-align:right;"> 0.7005032 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID) </td>
   <td style="text-align:right;"> 237217.376 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6751287 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 236986.527 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6760052 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC10to29 </td>
   <td style="text-align:left;"> (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 237219.522 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6749546 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DCover30 </td>
   <td style="text-align:left;"> (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 237098.319 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6749995 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 235862.925 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6859174 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC10to29 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 236128.042 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6848767 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 235819.499 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6858648 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DC10to29 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 235783.024 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6857185 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DCover30 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 235785.140 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6858670 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 235941.720 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6852542 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 234847.283 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6939453 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 234700.873 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6946089 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 235046.896 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6928040 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 234787.418 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6935790 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, DCover30, A_DC1to4, A_DC5to9, A_DC10to29, A_DCover30, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238373.066 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6626646 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, A_DC1to4, DC1to4*A_DC1to4 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238682.615 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6596239 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, A_DC5to9, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238687.240 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6594053 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC10to29, A_DC10to29, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238676.317 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6601272 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DCover30, A_DCover30, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238514.323 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6612101 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238655.688 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6600671 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, A_DC1to4, A_DC10to29, DC1to4*A_DC1to4, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238627.588 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6603809 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DCover30, A_DC1to4, A_DCover30, DC1to4*A_DC1to4, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238460.843 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6615939 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DC10to29, A_DC5to9, A_DC10to29, DC5to9*A_DC5to9, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238606.706 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6605742 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DCover30, A_DC5to9, A_DCover30, DC5to9*A_DC5to9, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238485.093 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6612081 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC10to29, DCover30, A_DC10to29, A_DCover30, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238459.281 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6620050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, A_DC1to4, A_DC5to9, A_DC10to29, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238459.281 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6620050 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover30, A_DC1to4, A_DC5to9, A_DCover30, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238433.835 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6619105 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, DCover30, A_DC1to4, A_DC10to29, A_DCover30, DC1to4*A_DC1to4, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238422.485 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6620542 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU8 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DC10to29, DCover30, A_DC5to9, A_DC10to29, A_DCover30, DC5to9*A_DC5to9, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 238410.972 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6621938 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 7636.975 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6482940 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID) </td>
   <td style="text-align:right;"> 7639.439 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6335919 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 7630.828 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6400415 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC10to29 </td>
   <td style="text-align:left;"> (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 7633.379 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6373622 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DCover30 </td>
   <td style="text-align:left;"> (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 7636.136 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6348337 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 7633.149 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6410024 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC10to29 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 7636.305 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6384805 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 7639.058 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6365667 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DC10to29 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 7626.204 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6466919 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DCover30 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 7635.361 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6421834 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 7631.432 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6405776 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 7632.449 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6469102 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 7638.129 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6418691 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 7637.664 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6407455 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 7630.743 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6481358 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, DCover30, A_DC1to4, A_DC5to9, A_DC10to29, A_DCover30, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7591.890 </td>
   <td style="text-align:right;"> 0.898 </td>
   <td style="text-align:right;"> 0.6359964 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, A_DC1to4, DC1to4*A_DC1to4 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7609.721 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6327438 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, A_DC5to9, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7628.886 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6374809 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC10to29, A_DC10to29, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7636.496 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6271505 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DCover30, A_DCover30, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7642.765 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6281944 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7604.629 </td>
   <td style="text-align:right;"> 0.002 </td>
   <td style="text-align:right;"> 0.6370884 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, A_DC1to4, A_DC10to29, DC1to4*A_DC1to4, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7611.237 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6325166 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DCover30, A_DC1to4, A_DCover30, DC1to4*A_DC1to4, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7614.454 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6328786 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DC10to29, A_DC5to9, A_DC10to29, DC5to9*A_DC5to9, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7632.040 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6375811 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DCover30, A_DC5to9, A_DCover30, DC5to9*A_DC5to9, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7628.214 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6360592 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC10to29, DCover30, A_DC10to29, A_DCover30, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7628.214 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6360592 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, A_DC1to4, A_DC5to9, A_DC10to29, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7604.723 </td>
   <td style="text-align:right;"> 0.001 </td>
   <td style="text-align:right;"> 0.6352424 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover30, A_DC1to4, A_DC5to9, A_DCover30, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7608.045 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6367731 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, DCover30, A_DC1to4, A_DC10to29, A_DCover30, DC1to4*A_DC1to4, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7596.351 </td>
   <td style="text-align:right;"> 0.097 </td>
   <td style="text-align:right;"> 0.6255130 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Early Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DC10to29, DCover30, A_DC5to9, A_DC10to29, A_DCover30, DC5to9*A_DC5to9, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 7632.701 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6368432 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 17185.672 </td>
   <td style="text-align:right;"> 0.986 </td>
   <td style="text-align:right;"> 0.6814224 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID) </td>
   <td style="text-align:right;"> 17297.988 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6540371 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 17323.504 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6511166 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC10to29 </td>
   <td style="text-align:left;"> (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 17355.164 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6398369 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DCover30 </td>
   <td style="text-align:left;"> (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 17271.976 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6609956 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 17260.085 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6607748 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC10to29 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 17241.448 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6673880 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 17231.947 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6697752 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DC10to29 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 17272.381 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6623489 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DCover30 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 17248.742 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6666333 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 17237.964 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6729749 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DC5to9 | DC10to29) </td>
   <td style="text-align:right;"> 17216.907 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6713172 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover30 | DC10to29) </td>
   <td style="text-align:right;"> 17219.979 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6708745 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC10to29 | UniqueID), (DCover30 | DC10to29) </td>
   <td style="text-align:right;"> 17194.227 </td>
   <td style="text-align:right;"> 0.014 </td>
   <td style="text-align:right;"> 0.6806345 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DC10to29 | UniqueID), (DCover30 | DC10to29) </td>
   <td style="text-align:right;"> 17218.278 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6776196 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, DCover30, A_DC1to4, A_DC5to9, A_DC10to29, A_DCover30, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17203.163 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6574830 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, A_DC1to4, DC1to4*A_DC1to4 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17350.784 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6372065 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, A_DC5to9, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17348.865 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6403273 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC10to29, A_DC10to29, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17350.114 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6299816 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DCover30, A_DCover30, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17398.672 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6287403 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17328.626 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6447556 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, A_DC1to4, A_DC10to29, DC1to4*A_DC1to4, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17269.871 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6446436 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DCover30, A_DC1to4, A_DCover30, DC1to4*A_DC1to4, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17291.299 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6474565 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DC10to29, A_DC5to9, A_DC10to29, DC5to9*A_DC5to9, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17278.130 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6463570 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DCover30, A_DC5to9, A_DCover30, DC5to9*A_DC5to9, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17298.022 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6478255 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC10to29, DCover30, A_DC10to29, A_DCover30, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17331.924 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6337486 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, A_DC1to4, A_DC5to9, A_DC10to29, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17249.881 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6507047 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover30, A_DC1to4, A_DC5to9, A_DCover30, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17265.440 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6531821 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, DCover30, A_DC1to4, A_DC10to29, A_DCover30, DC1to4*A_DC1to4, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17230.057 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6515447 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Late Winter </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DC10to29, DCover30, A_DC5to9, A_DC10to29, A_DCover30, DC5to9*A_DC5to9, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 17244.602 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6515156 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 31672.859 </td>
   <td style="text-align:right;"> 1.000 </td>
   <td style="text-align:right;"> 0.6944693 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID) </td>
   <td style="text-align:right;"> 31865.447 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6761732 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 31894.939 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6745193 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC10to29 </td>
   <td style="text-align:left;"> (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 31857.886 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6755082 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DCover30 </td>
   <td style="text-align:left;"> (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 31879.775 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6764217 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID) </td>
   <td style="text-align:right;"> 31793.248 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6822002 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC10to29 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 31758.623 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6841722 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 31768.294 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6853126 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DC10to29 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 31768.778 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6858148 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DCover30 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 31812.960 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6833647 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 31802.026 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6858890 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DC10to29 | UniqueID) </td>
   <td style="text-align:right;"> 31704.881 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6891427 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 31741.362 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6889162 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC1to4, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC1to4 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 31714.320 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6912401 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Individual and Year (UniqueID) Random Effect </td>
   <td style="text-align:left;"> DC5to9, DC10to29, DCover30 </td>
   <td style="text-align:left;"> (DC5to9 | UniqueID), (DC10to29 | UniqueID), (DCover30 | UniqueID) </td>
   <td style="text-align:right;"> 31733.453 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6911387 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, DCover30, A_DC1to4, A_DC5to9, A_DC10to29, A_DCover30, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31965.100 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6672302 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, A_DC1to4, DC1to4*A_DC1to4 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 32002.198 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6616168 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, A_DC5to9, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 32003.991 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6615746 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC10to29, A_DC10to29, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31979.307 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6660735 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31998.285 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6616353 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, A_DC1to4, A_DC10to29, DC1to4*A_DC1to4, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31975.001 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6618046 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, A_DC1to4, A_DC10to29, DC1to4*A_DC1to4, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31975.001 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6665377 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DCover30, A_DC1to4, A_DCover30, DC1to4*A_DC1to4, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31993.683 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6627158 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DC10to29, A_DC5to9, A_DC10to29, DC5to9*A_DC5to9, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31974.658 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6663791 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DCover30, A_DC5to9, A_DCover30, DC5to9*A_DC5to9, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31993.368 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6618896 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC10to29, DCover30, A_DC10to29, A_DCover30, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31971.339 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6662015 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DC10to29, A_DC1to4, A_DC5to9, A_DC10to29, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DC10to29*A_DC10to29 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31969.444 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6668405 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC5to9, DCover30, A_DC1to4, A_DC5to9, A_DCover30, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31989.862 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6634097 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC1to4, DC10to29, DCover30, A_DC1to4, A_DC10to29, A_DCover30, DC1to4*A_DC1to4, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31966.746 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6668891 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> DU9 </td>
   <td style="text-align:left;"> Summer </td>
   <td style="text-align:left;"> GLMM with Functional Response </td>
   <td style="text-align:left;"> DC5to9, DC10to29, DCover30, A_DC5to9, A_DC10to29, A_DCover30, DC5to9*A_DC5to9, DC10to29*A_DC10to29, DCover30*A_DCover30 </td>
   <td style="text-align:left;"> (1 | UniqueID) </td>
   <td style="text-align:right;"> 31969.888 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 0.6666760 </td>
  </tr>
</tbody>
</table>

## Conclusions
Based on the correlation of annual distance to cutblock measures across years, there was a need to group distance to cutblock covariates into fewer categories to avoid correlation of covariates in the RSF model. At a minimum (but varying among season and DU) it appeared that distance to cutblock measures were correlated 2-5 years apart. In addition, patterns in caribou selection of cutblocks (but again, varying slightly among season and DU) indicated that caribou may avoid or have weak responses to cutblocks when they are relatively new (less than five years old), but select for cutblocks five to 30 years old and avoid cutblocks over 10 to 30 years old. Therefore, I reclassifed distance to cutblock into four classes: one to four years old, five to nine years old, ten to 29 years old and 30 and over. 

The effect of distance to cutblock on caribou habitat selection was relatively weak in DU6 (compared to other DU's) across all seasons, and the models were relatively simple (i.e., some of the distance to cutblock age class covariates were highly correlated, which required further grouping, and there was no functional response) suggesting that distance to cutblock may not be an important habitat feature. However, forestry activity is relatively low in boreal British Columbia, and therefore likely has limited influence on caribou distribution there.  

In DU7, the effect of distance to cutblock on caribou habitat selection was relatively weak, but stronger in summer than other seasons. In general the models were relatively simple, suggesting that distance to cutblock may not be important except in summer and when cutblocks are relatively new. 

In DU8, the effect of distance to cutblock on caribou habitat selection was relatively strong and generally consistent across seasons. However, the models did not include functional responses, suggesing a consistent response to cutblocks by caribou across areas regardless of the amount of cutblocks in those areas.  

In DU9, the effect of distance to cutblock on caribou habitat selection was similar to DU8 (relatively strong and generally consistent across seasons). However, the early winter model included functional reponse covariates, indicating caribou selction of cutblocks varied across areas with different amounts of cutblocks at that time of the year. However, this was not the case in late winter or summer. 

This analysis helped identify how to temporally group distance to cutblock covariates measured annually over a 50 year period for use in fitting a RSF model. This temproal grouping by cutblock age was done based on statistical principles of minimizing correlation between covariates and identifying parsimonious but reasonably predictive RSF models. However, results here are also consistent with our ecological understanding of how cutblocks age and how caribou might respond to them differently as they age. Specifically, new cutblocks (i.e., one to four year old) provide different habitat features for caribou and their 'competitors' (i.e., other ungulate species) than moderately aged (i.e., five to nine years old and 10 to 29 eyars old) and older (i.e., over 29 years old) cutblocks. For example, caribou may be responding to vegetation development on cutblock sites, as young cutblocks may be sparsely vegetated, moderately aged cutblocks may provide early seral vegetation, particularly shrubs, forbs and herbs, and older cutblocks may provide more treed vegetation. However, the exact mechanism for how caribou are reponding to these different age classes of cutblocks is not clear. For example, caribou may avoid new and moderately aged cutblcoks because of lack of lichen (Fisher and Wilkinson 2005). Alternatively, they may select moderately aged cutblocks because they provide preffered non-lichen summer food sources, such as some shrub species (Denryter et al. 2017). Caribou may also select for cutblock edges that provide access to lichen via litterfall and windthrow (Serrouya et al. 2007). However, in general caribou population parameters such as adult female survival (Wittmer et al. 2007) and calf recruitment (Environment Canada 2008) have been negatively correlated with cutblocks. Therefore, cariobu may not select cutblocks if they are associated with or they are unable to survive there because of higher predation risk. Moose density and distribtuion is generally postively correlated with cutblocks (Fisher and Wilkinson 2005; Anderson et al. 2018), which may result in higher wolf density (Messier 1994; Fuller et al. 2003; Kuzyk and Hatter 2014) and wolves might also select cutblocks to maximize their probabiltiy of encountering prey (Houle et al. 2010).     

The distance to cutblock covariates from the top models for each season and DU will be compared to and combined with other RSF models that include other habitat covariates. Comparisons will be made using the same statsical principles and undertanding of ecological mechanisms described here. This will help identify a robust and useful RSF model of caribou habitat selection across seasons and DUs in BC.

## Literature Cited
Anderson, M., McLellan, B. N., & Serrouya, R. (2018). Moose response to high‐elevation forestry: Implications for apparent competition with endangered caribou. The Journal of Wildlife Management, 82(2), 299-309.

DeCesare, N. J., Hebblewhite, M., Robinson, H. S., & Musiani, M. (2010). Endangered, apparently: the role of apparent competition in endangered species conservation. Animal conservation, 13(4), 353-362.

DeCesare, N. J., Hebblewhite, M., Schmiegelow, F., Hervieux, D., McDermid, G. J., Neufeld, L., ... & Wheatley, M. (2012). Transcending scale dependence in identifying habitat with resource selection functions. Ecological Applications, 22(4), 1068-1083.

Denryter, K. A., Cook, R. C., Cook, J. G., & Parker, K. L. (2017). Straight from the caribou’s (Rangifer tarandus) mouth: detailed observations of tame caribou reveal new insights into summer–autumn diets. Canadian Journal of Zoology, 95(2), 81-94.
Available from: http://www.nrcresearchpress.com/doi/pdf/10.1139/cjz-2016-0114

Environment Canada. 2008. Scientific Review for the Identification of Critical Habitat for Woodland Caribou (Rangifer tarandus caribou), Boreal Population, in Canada. August 2008. Ottawa: Environment Canada. 75 pp. plus 179 pp Appendices.

Fuller, T. K., Mech, L. D., & Cochrane, J. F. (2010). Wolf population dynamics. In: Mech, L. D., & Boitani, L. (Eds.). Wolves: behavior, ecology, and conservation. University of Chicago Press.

Houle, M., Fortin, D., Dussault, C., Courtois, R., & Ouellet, J. P. (2010). Cumulative effects of forestry on habitat use by gray wolf (Canis lupus) in the boreal forest. Landscape ecology, 25(3), 419-433.

Kuzyk, G. W., & Hatter, I. W. (2014). Using ungulate biomass to estimate abundance of wolves in British Columbia. Wildlife Society Bulletin, 38(4), 878-883.

Messier, F. (1994). Ungulate population models with predation: a case study with the North American moose. Ecology, 75(2), 478-488.

Montgomery, D. C., and E. A. Peck. 1992. Introduction to linear regression analysis. Wiley, New York, New York, USA

Serrouya, R., Lewis, D., McLellan, B. and Pavan, G. (2007). The selection of movement paths by mountain caribou , during winter within managed: landscapes: 4-year results of snow trailing. Final Technical Report, FSP Project #Y071312. Available from: https://www.researchgate.net/profile/Bruce_Mclellan/publication/255635833_The_selection_of_movement_paths_by_mountain_caribou_during_winter_within_managed_landscapes_4-year_results_of_snow_trailing/links/552d343e0cf29b22c9c4c3b4/The-selection-of-movement-paths-by-mountain-caribou-during-winter-within-managed-landscapes-4-year-results-of-snow-trailing.pdf

Wittmer, H. U., Sinclair, A. R., & McLellan, B. N. (2005). The role of predation in the decline and extirpation of woodland caribou. Oecologia, 144(2), 257-267.

Wittmer, H. U., McLellan, B. N., Serrouya, R., & Apps, C. D. (2007). Changes in landscape composition influence the decline of a threatened woodland caribou population. Journal of animal ecology, 76(3), 568-579.

