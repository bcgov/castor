
################################################################################
#
# Simplified script for example analysis for "A Simple Way to
# Incorporate Uncertainty and Risk into Forest Harvest Scheduling".
#
# Andrew Robinson  22 September 2015
#
################################################################################

## Set run parameters

set.seed(1)

n.coupes <- 1000

nsim <- 10000

################################################################################

## Call libraries

library(ggplot2)
library(gridExtra)
library(splines)
library(gamlss)
library(lpSolveAPI)
library(parallel)

################################################################################

## Generate fake albeit realistic data

coupes <-
    data.frame(HARVYEAR = sample(
                   2003:2013,
                   size = n.coupes,
                   replace = TRUE),
               ForestQualityClass = sample(
                   c("MAT_hq","MAT_lq","MIX_hq","MIX_lq"),
                   size = n.coupes,
                   replace = TRUE),
               grossArea = rweibull(n = n.coupes,
                   shape = 1.74,
                   scale = 70))

parameters <-
    data.frame(ForestQualityClass = c("MAT_hq","MAT_lq","MIX_hq","MIX_lq"),
               x.shapes = c(1.70, 1.45, 1.7, 0.90),
               x.scales = c(6800, 2400, 6000, 2600),
               recovery = c(0.5, 0.3, 0.5, 0.3),
               y.scales = c(1, 1.5, 2, 1.2))

coupes <- merge(coupes, parameters, all.x = TRUE)

coupes$grossHQSLest <- rweibull(n = nrow(coupes),
                                shape = coupes$x.shapes,
                                scale = coupes$x.scales)

coupes$SalesHQSL.s <-
    with(coupes, 200 * y.scales)
coupes$SalesHQSL.a <-
    with(coupes, grossHQSLest * recovery / SalesHQSL.s)

coupes$SalesHQSL <- rgamma(n = nrow(coupes),
                           shape = coupes$SalesHQSL.a,
                           scale = coupes$SalesHQSL.s)

pdf(file = "Figure 1 ex.pdf", height = 4, width = 4)
qplot(x = grossHQSLest / 1000,
      y = SalesHQSL / 1000,
      geom = c("point","smooth"),
      se = FALSE,
      xlab = expression(paste("Assessed HQ Sawlog ('000 ", m^3, ")")),
      ylab = expression(paste("Actual HQ Sawlog ('000 ", m^3, ")")),
      method = "lm",
      alpha = I(0.4),
      data = coupes) +
  geom_abline(aes(slope = 1, intercept = 0), linetype = 4, colour = "darkgrey") +
  geom_smooth(se = FALSE, linetype = 2)
dev.off()

str(coupes)

table(coupes$HARVYEAR)
table(coupes$ForestQualityClass)

coupes$fit <- TRUE
coupes$fit[coupes$HARVYEAR > 2007] <- FALSE

################################################################################
################################################################################
################################################################################

## Generate helper functions

summary.lpExtPtr <- function(x, target, ...) {
  cut.me <- get.variables(x)
  num.coupes.cut <- sum(cut.me)
  area.cut <- sum(cut.me * target$grossArea)
  volume.cut <- sum(cut.me * target$SalesHQSL)
  volume.cut.hat <- sum(cut.me * target$mu.hat)
  out <- list(cut.me = cut.me,
              num.coupes.cut = num.coupes.cut,
              area.cut = area.cut,
              volume.cut = volume.cut,
              volume.cut.hat = volume.cut.hat)
  class(out) <- "summary.lpExtPtr"
  return(out)
}

simulate.summary.lpExtPtr <-
  function(object, nsim = 1, seed = NULL, ...) {
    sim.volume <-
      lapply(1:nsim,
             function(x)
             with(to.cut[object$cut.me == 1, ],
                  sum(rGA(sum(object$cut.me),
                          mu = mu.hat,
                          sigma = sigma.hat))))
    return(unlist(sim.volume))
  }

################################################################################
################################################################################
################################################################################

## Fit and compare some models

test.0 <- gamlss(SalesHQSL ~ log(grossHQSLest),
                 sigma.formula = ~ 1,
                 sigma.link = "log",
                 family = GA(),
                 data = coupes)

test.1 <- gamlss(SalesHQSL ~ log(grossHQSLest),
                 sigma.formula = ~ log(grossHQSLest),
                 sigma.link = "log",
                 family = GA(),
                 data = coupes)

LR.test(test.0, test.1)

summary(test.1)

test.2 <- gamlss(SalesHQSL ~ pb(log(grossHQSLest)),
                 sigma.formula = ~ 1,
                 sigma.link = "log",
                 family = GA(),
                 data = coupes)

LR.test(test.0, test.2)

test.3 <- gamlss(SalesHQSL ~ log(grossHQSLest) * ForestQualityClass,
                 sigma.formula = ~ 1,
                 sigma.link = "log",
                 family = GA(),
                 data = coupes)

summary(test.3)
LR.test(test.0, test.3)

test.5 <- gamlss(SalesHQSL ~ poly(log(grossHQSLest), 2) * ForestQualityClass,
                 sigma.formula = ~ ForestQualityClass,
                 sigma.link = "log",
                 family = GA(),
                 data = coupes)

summary(test.5)
LR.test(test.0, test.5)

## Modest difference.

trajectory.5 <-
  with(coupes,
       expand.grid(grossHQSLest =
                   seq(from = min(grossHQSLest),
                       to = max(grossHQSLest),
                       length.out = 100),
                   ForestQualityClass = levels(coupes$ForestQualityClass)))

new.dist.5 <- predictAll(test.5, newdata = trajectory.5)

trajectory.5$mu <- new.dist.5$mu
trajectory.5$sigma <- new.dist.5$sigma
trajectory.5$upper.2 <- with(new.dist.5, qGA(0.95, mu = mu, sigma = sigma))
trajectory.5$lower.2 <- with(new.dist.5, qGA(0.05, mu = mu, sigma = sigma))
trajectory.5$upper.1 <- with(new.dist.5, qGA(0.67, mu = mu, sigma = sigma))
trajectory.5$lower.1 <- with(new.dist.5, qGA(0.33, mu = mu, sigma = sigma))

# setEPS()
# postscript("model.eps", height=6, width=6)
pdf("Figure 2 ex.pdf", height=6, width=6)

p.5 <-
  ggplot(coupes,
         aes(x = grossHQSLest / 1000,
             y = SalesHQSL / 1000)) +
#  geom_point(aes(shape = fit)) +
  geom_point(alpha=0.4) +
#  scale_colour_discrete(name = "Source", labels = c("Test","Fit")) +
  facet_wrap(~ ForestQualityClass) +
  xlab(expression(paste("Assessed HQ Sawlog ('000 ", m^3, ")"))) +
  ylab(expression(paste("Actual HQ Sawlog ('000 ", m^3, ")"))) +
#  geom_smooth(aes(colour = fit),
#              method = "lm", formula = y ~ pb(x), se = FALSE) +
  geom_line(aes(y = mu / 1000, x = grossHQSLest / 1000),
            data = trajectory.5) +
  geom_line(aes(y = lower.2 / 1000, x = grossHQSLest / 1000),
            linetype = "dashed", data = trajectory.5) +
  geom_line(aes(y = upper.2 / 1000, x = grossHQSLest / 1000),
            linetype = "dashed", data = trajectory.5) +
  geom_line(aes(y = lower.1 / 1000, x = grossHQSLest / 1000),
            linetype = "dotted", data = trajectory.5) +
  geom_line(aes(y = upper.1 / 1000, x = grossHQSLest / 1000),
            linetype = "dotted", data = trajectory.5) +
  ylim(c(0,10))
plot(p.5)

dev.off()

################################################################################
################################################################################

# Settle on model 5.  Obtain predictions for withheld stands

to.cut <-
  droplevels(subset(coupes, !fit &
                    ForestQualityClass %in%
                    levels(coupes$ForestQualityClass)))

to.cut.hat.cut <- predictAll(test.5, newdata = to.cut)

to.cut$mu.hat <- to.cut.hat.cut$mu
to.cut$sigma.hat <- to.cut.hat.cut$sigma

par(mfrow=c(1,3))
plot(SalesHQSL ~ mu.hat, data = to.cut)
plot(SalesHQSL ~ grossHQSLest, data = to.cut)
plot(mu.hat ~ grossHQSLest, data = to.cut)

################################################################################
################################################################################

### Now use LP to optimize. This script portion benefits from prior
### work at
### http://fishyoperations.com/r/linear-programming-in-r-an-lpsolveapi-example
### see also
### http://www.r-bloggers.com/linear-programming-in-r-an-lpsolveapi-example/

## Here's an example that cuts le 15 stands, total area le 1000 ha,
## one year, max volume.

## ops creates the annual constraints

ops <- data.frame(year = c('y1'),
                  area = c(1000),
                  equip = c(30))

lpmodel.harvest <- make.lp(2*NROW(ops) + NROW(to.cut), NROW(ops) * NROW(to.cut))

column <- 0
row <- 0

# build the model column by column

for(wg in ops$year){
  row <- row + 1
  for(coupe in seq(1, NROW(to.cut))){
    column <- column + 1
# this takes the arguments 'column','values' & 'indices' (as in where
# these values should be placed in the column)
    set.column(lpmodel.harvest,
               column,
               c(1, to.cut[coupe,'grossArea'], 1),
               indices = c(row, NROW(ops) + row, NROW(ops)*2 + coupe))
  }}

# set rhs weight constraints - first triplet
set.constr.value(lpmodel.harvest,                    # The lp model
                 rhs = ops$equip,                    # The values
                 constraints = seq(1, NROW(ops)))    # Where to put them

# set rhs volume constraints - second triplet
set.constr.value(lpmodel.harvest,
                 rhs = ops$area,
                 constraints = seq(NROW(ops)+1, NROW(ops)*2))

# set rhs availability constraints - last quadruplet

set.constr.value(lpmodel.harvest,
                 rhs = rep(1, NROW(to.cut)),
                 constraints = seq(NROW(ops)*2+1, NROW(ops)*2+NROW(to.cut)))

# set objective coefficients - here the simulated average

set.objfn(lpmodel.harvest, rep(to.cut$mu.hat, NROW(ops)))

# set objective direction

lp.control(lpmodel.harvest, sense = 'max')

# Ensure integers - works!

get.type(lpmodel.harvest)
set.type(lpmodel.harvest, 1:length(get.type(lpmodel.harvest)), "integer")

# solve the model; if this returns 0 then an optimal solution has been found

solve(lpmodel.harvest)

# this returns the proposed solution

get.objective(lpmodel.harvest)

# Coupe choices

(base <- summary(lpmodel.harvest, target = to.cut))

par(mfrow=c(1,3))
plot(SalesHQSL ~ mu.hat, data = to.cut,
     pch=c(1,19)[base$cut.me + 1])
plot(SalesHQSL ~ grossHQSLest, data = to.cut,
     pch=c(1,19)[base$cut.me + 1])
plot(mu.hat ~ grossHQSLest, data = to.cut,
     pch=c(1,19)[base$cut.me + 1])

#########################################################################################
#
# FTM I have a stand prescription.  I should generate a bunch of random volumes
# corresponding to these predictions.
#
#########################################################################################

base.sim.volume <-
  sapply(1:10000,
         function(x)
         with(to.cut[base$cut.me == 1,],
              sum(rGA(sum(base$cut.me), # if n = 1 then randoms are correlated!
                      mu = mu.hat,
                      sigma = sigma.hat)))) / 1000

## Graphical summary.

par(mfrow=c(1,2), mar=c(5,4,3,2), las=1)
plot(density(base.sim.volume), xlim = c(50,300), main="Distribution",
     xlab = expression(paste("Assessed Sawlog ('000 ", m^3, ")")))
abline(v = base$volume.cut/1000, lty = 2)
abline(v = base$volume.cut.hat/1000)
abline(v = quantile(base.sim.volume, p = c(0.05, 0.95)), col = "darkgrey")
#qqnorm(base.sim.volume); qqline(base.sim.volume)
plot(ecdf(base.sim.volume), xlim = c(0,500), main="CDF",
     xlab = expression(paste("Assessed Sawlog ('000 ", m^3, ")")))
abline(v = base$volume.cut/1000, lty = 2)
abline(v = base$volume.cut.hat/1000)
abline(v = quantile(base.sim.volume, p = c(0.05, 0.95)), col = "darkgrey")

## This provides us with, as hoped for, probabilistic information
## about the expected return.

## For example, what is the mean expected return?

mean(base.sim.volume)

## What is the probability of achieving the mean objective?

mean(base.sim.volume > base$volume.cut.hat / 1000)

## What is the 90% prediction interval?

quantile(base.sim.volume, p = c(0.05, 0.95))

## How can this be related back to headroom?  10%? 20%? 30%?

mean(base.sim.volume > base$volume.cut.hat * 0.9 / 1000) # 10% HR
mean(base.sim.volume > base$volume.cut.hat * 0.8 / 1000) # 20% HR
mean(base.sim.volume > base$volume.cut.hat * 0.7 / 1000) # 30% HR

## We could compare this with a clearly inadequate correction, such as
## a straight ratio, somehow.

## What is the proportion reduced relative to expectations?

(base$volume.cut.hat - base$volume.cut) / base$volume.cut.hat

################################################################################
################################################################################

# Now penalize optimization by uncertainty.  Start simply: use the 0.1
# quantile as the objective, and analyze as above.

set.objfn(lpmodel.harvest,
          rep(with(to.cut, qGA(0.1, mu = mu.hat, sigma = sigma.hat)),
              NROW(ops)))

solve(lpmodel.harvest)

get.objective(lpmodel.harvest)

# Coupe choices

(q10 <- summary(lpmodel.harvest, target = to.cut))

cor(base$cut.me, q10$cut.me)

q10.sim.volume <-
  sapply(1:10000,
         function(x)
         with(to.cut[q10$cut.me == 1,],
              sum(rGA(sum(q10$cut.me), # if n = 1 then randoms are correlated!
                      mu = mu.hat,
                      sigma = sigma.hat)))) / 1000

## Graphical summary.

par(mfrow=c(1,2), mar=c(5,4,3,2), las=1)
plot(density(q10.sim.volume), xlim = c(0,100), main="Distribution",
     xlab = expression(paste("Assessed Sawlog ('000 ", m^3, ")")))
lines(density(base.sim.volume), col = "darkgrey")
abline(v = q10$volume.cut/1000, lty = 2)
abline(v = q10$volume.cut.hat/1000)
abline(v = quantile(q10.sim.volume, p = c(0.05, 0.95)))
#qqnorm(base.sim.volume); qqline(base.sim.volume)
plot(ecdf(q10.sim.volume), xlim = c(0,100), main="CDF",
     xlab = expression(paste("Assessed Sawlog ('000 ", m^3, ")")))
lines(ecdf(base.sim.volume), col = "darkgrey")
abline(v = q10$volume.cut/1000, lty = 2)
abline(v = q10$volume.cut.hat/1000)
abline(v = quantile(q10.sim.volume, p = c(0.05, 0.95)))

## This provides us with, as hoped for, probabilistic information
## about the expected return.  For example, what is the probability of
## achieving the implied objective?

mean(q10.sim.volume > q10$volume.cut / 1000)

## How can this be related back to headroom?  10%? 20%? 30%?

mean(q10.sim.volume > q10$volume.cut * 0.9 / 1000) # 10% HR
mean(q10.sim.volume > q10$volume.cut * 0.8 / 1000) # 20% HR
mean(q10.sim.volume > q10$volume.cut * 0.7 / 1000) # 30% HR

quantile(q10.sim.volume, p = c(0.05, 0.95))

#### Compare with Base in Figure 3 (below)


################################################################################

## Try to minimize variance given constraints on volume

sum(to.cut$grossArea)

sum(to.cut$mu.hat)

to.cut$variance <- with(to.cut, mu.hat^2 * sigma.hat^2)

ops <- data.frame(year = c('y1'),
                  area = c(1000),
                  cut.out = c(17100))

# create an LP model

lpmodel.harvest <- make.lp(2*NROW(ops) + NROW(to.cut), NROW(ops) * NROW(to.cut))

# I used this to keep count within the loops, I admit that this could
# be done a lot neater

column <- 0
row <- 0

# build the model column per column

for(wg in ops$year){
  row <- row + 1
  for(coupe in seq(1, NROW(to.cut))){
    column <- column + 1
# this takes the arguments 'column','values' & 'indices' (as in where
# these values should be placed in the column)
    set.column(lpmodel.harvest,
               column,
               c(to.cut[coupe, 'mu.hat'], to.cut[coupe, 'grossArea'], 1),
               indices = c(row, NROW(ops) + row, NROW(ops)*2 + coupe))
  }}

# set rhs equipment constraints - first triplet
set.constr.value(lpmodel.harvest,                    # The lp model
                 rhs = ops$cut.out,                  # The values
                 constraints = seq(1, NROW(ops)))    # Where to put them

# set rhs area constraints - second triplet
set.constr.value(lpmodel.harvest,
                 rhs = ops$area,
                 constraints = seq(NROW(ops)+1, NROW(ops)*2))

# set rhs availability constraints - last quadruplet

set.constr.value(lpmodel.harvest,
                 rhs = rep(1, NROW(to.cut)),
                 constraints = seq(NROW(ops)*2+1, NROW(ops)*2+NROW(to.cut)))

set.constr.type(lpmodel.harvest,
                c(rep(">=", NROW(ops)),
                  rep("<=", NROW(ops)),
                  rep("<=", NROW(to.cut))))

# set objective coefficients - here the simulated average

set.objfn(lpmodel.harvest, rep(to.cut$variance, NROW(ops)))

# set objective direction

lp.control(lpmodel.harvest, sense='min')

# Ensure integers - works!

set.type(lpmodel.harvest, 1:length(get.type(lpmodel.harvest)), "integer")

# I in order to be able to visually check the model, I find it useful
# to write the model to a text file

write.lp(lpmodel.harvest, 'harvest.lp', type = 'lp')

# solve the model, if this return 0 an optimal solution is found

solve(lpmodel.harvest)

# this returns the proposed solution

get.objective(lpmodel.harvest)

# Coupe choices

(port.1 <- summary(lpmodel.harvest, target = to.cut))

out.1 <- simulate(port.1, nsim = 1000)

plot(density(out.1))


#########################################################################################
#########################################################################################
#########################################################################################
#########################################################################################

## Write a portfolio function

portfolio <- function(min.vol, target = to.cut, area = 2000) {
  ops <- data.frame(year = c('y1'),
                    area = c(area),
                    cut.out = c(min.vol))
  lpmodel.harvest <- make.lp(2*NROW(ops) + NROW(to.cut), NROW(ops) * NROW(to.cut))
  column <- 0
  row <- 0
  for(wg in ops$year){
    row <- row + 1
    for(coupe in seq(1, NROW(to.cut))){
      column <- column + 1
      set.column(lpmodel.harvest,
                 column,
                 c(to.cut[coupe, 'mu.hat'], to.cut[coupe, 'grossArea'], 1),
                 indices = c(row, NROW(ops) + row, NROW(ops)*2 + coupe))
    }}
  set.constr.value(lpmodel.harvest,                    # The lp model
                   rhs = ops$cut.out,                  # The values
                   constraints = seq(1, NROW(ops)))    # Where to put them
  set.constr.value(lpmodel.harvest,
                   rhs = ops$area,
                   constraints = seq(NROW(ops)+1, NROW(ops)*2))
  set.constr.value(lpmodel.harvest,
                   rhs = rep(1, NROW(to.cut)),
                   constraints = seq(NROW(ops)*2+1, NROW(ops)*2+NROW(to.cut)))
  set.constr.type(lpmodel.harvest,
                  c(rep(">=", NROW(ops)),
                    rep("<=", NROW(ops)),
                    rep("<=", NROW(to.cut))))
  set.objfn(lpmodel.harvest, rep(to.cut$variance, NROW(ops)))
  lp.control(lpmodel.harvest, sense='min')
  set.type(lpmodel.harvest, 1:length(get.type(lpmodel.harvest)), "integer")
  solve(lpmodel.harvest)
  return(summary(lpmodel.harvest, target = target))
}



################################################################################

minima <- (15:25)*1000

returns <- mclapply(minima, portfolio, mc.cores = 4)

lapply(returns, function(x) sum(x$cut.me))

sim.returns <- mclapply(returns, simulate, nsim = nsim, mc.cores = 4)

simexp <- data.frame(volume.cut = do.call(c, sim.returns),
                     minima = rep(minima, each = nsim))

ggplot(simexp,
       aes(x = factor(minima), y = volume.cut))  +
  geom_violin() +
  xlab(expression(paste("Minimum prescribed cut (", m^3, ")"))) +
  ylab(expression(paste("Achieved cut (", m^3, ")"))) +
  geom_point(aes(x = factor(minima), y = minima))

ggplot(simexp,
       aes(x = factor(minima), y = volume.cut))  +
  geom_boxplot() +
  xlab(expression(paste("Minimum prescribed cut (", m^3, ")"))) +
  ylab(expression(paste("Achieved cut (", m^3, ")")))

lapply(sim.returns, function (x) (var(x)) / mean(x))

cv <- function (x) (sd(x)) / mean(x)

sapply(sim.returns, cv)

sapply(sim.returns, sd)

sapply(sim.returns, mean)

sim.results <- data.frame(minima = minima,
                          mean = sapply(sim.returns, mean),
                          sd = sapply(sim.returns, sd),
                          cv = sapply(sim.returns, cv))

write.csv(sim.results, file = "simresults.csv", row.names = FALSE)

################################################################################

## What if we now try to achieve the same volume with min variance?

cf.base <- portfolio(mean(base.sim.volume)*1000)

cf.sim.volume <-
  sapply(1:10000,
         function(x)
         with(to.cut[cf.base$cut.me == 1,],
              sum(rGA(sum(cf.base$cut.me), # if n = 1 then randoms are correlated!
                      mu = mu.hat,
                      sigma = sigma.hat)))) / 1000

## Graphical summary.

par(mfrow=c(1,2), mar=c(5,4,3,2), las=1)
plot(density(base.sim.volume), xlim = c(20, 90), main="Distribution",
     xlab = expression(paste("Assessed Sawlog ('000 ", m^3, ")")))
lines(density(cf.sim.volume), col = "darkgrey")
abline(v = base$volume.cut/1000, lty = 2)
abline(v = base$volume.cut.hat/1000)
abline(v = quantile(base.sim.volume, p = c(0.05, 0.95)), lty = 3)
#qqnorm(base.sim.volume); qqline(base.sim.volume)
plot(ecdf(base.sim.volume), xlim = c(20, 90), main="CDF",
     xlab = expression(paste("Assessed Sawlog ('000 ", m^3, ")")))
lines(ecdf(q10.sim.volume), col = "grey")
lines(ecdf(cf.sim.volume), col = "darkgrey")
#abline(v = base$volume.cut/1000, lty = 2)
#abline(v = base$volume.cut.hat/1000)
#abline(v = quantile(base.sim.volume, p = c(0.05, 0.95)))



qq.base <- qqnorm(base.sim.volume, plot.it = FALSE)
qq.q10 <- qqnorm(q10.sim.volume, plot.it = FALSE)
qq.cf <- qqnorm(cf.sim.volume, plot.it = FALSE)

grain <- 1000

x.range <- (min(base.sim.volume) * 10):(max(base.sim.volume) * 10) / 10

flip <- function(object) return(list(x = object$y, y = object$x))

pdf(file = "Figure 3 ex.pdf", height = 3.5, width = 8)

par(mfrow=c(1,2), mar=c(5,4,1,2), las=1)
plot(density(base.sim.volume), main = "",
     xlab = expression(paste("Assessed HQ Sawlog ('000 ", m^3, ")")))
#lines(density(q10.sim.volume), col = "darkgrey")
abline(v = base$volume.cut/1000, lty = 2)
abline(v = base$volume.cut.hat/1000)
abline(v = quantile(base.sim.volume, p = c(0.05, 0.95)), lty = 3)

plot(with(flip(qq.base), predict(smooth.spline(x, y), x = x.range)),
     type = "l", axes = FALSE,
     ylim = c(-4, 4),
     xlab = expression(paste("Assessed HQ Sawlog ('000 ", m^3, ")")),
     ylab = expression(paste(F[x](X))))
box()
axis(1)
axis(2, at = c(-4:4), label = c("0", formatC(pnorm(-3:4))), cex.axis=0.8)
lines(with(flip(qq.q10), predict(smooth.spline(x, y), x = x.range)),
      type="l", lty = 2)
lines(with(flip(qq.cf), predict(smooth.spline(x, y), x = x.range)),
      type="l", lty = 3)
legend("bottomright", lty = 1:3, bty = "n", cex = 0.9,
       legend=c("Maximize Mean","Maximize Q10","Minimize Variance"))

dev.off()



