## Statistical Analysis

# Loading the data
library(lmtest)
GDD <- read.csv("GDD2006-2100_fin.csv")

# Creating a vector with the year numbers (2006 omitted)
year_vec = c(2007:2100)

# Creating a container for the R2 values (and possibly other measures later on)
tests <- data.frame(lat = GDD$lat, lon = GDD$lon, r2 = 0, SW = 0, BP = 0, b1 = 0, 
                    sig = 0, del = 0, p = 0, log.p = 0, log.p.adj = 0)

tests.adj <- data.frame(lat=GDD$lat, lon=GDD$lon, SW.adj=0, BP.adj=0)

# Creating containers for the modeled GDD, SF, probs
columns <- c("lat", "lon", c(2007:2100))
GDD.fitted <- data.frame(matrix(ncol=96, nrow=2289))
SF <- data.frame(matrix(ncol=96, nrow=2289))
probs <- data.frame(matrix(ncol=96, nrow=2289))
colnames(GDD.fitted) <- columns
colnames(SF) <- columns
colnames(probs) <- columns

# Adding the geographical data
GDD.fitted$lat = GDD$lat
GDD.fitted$lon = GDD$lon
SF$lat = GDD$lat
SF$lon = GDD$lon
probs$lat = GDD$lat
probs$lon = GDD$lon

# Creating the models, storing the r2
for (i in 1:2289) {
  point <- unlist(as.vector(GDD[i, c(4:97)]), use.names=FALSE)
  point.lm <- lm(point~year_vec)
  
  # Getting the Coefficient of Determination
  rsq <- summary(point.lm)$r.squared
  tests$r2[i] <- rsq
  
  # Getting Shapiro-Wilk Normality Test p-value
  res <- point.lm$residuals
  SW.p <- shapiro.test(res)$p.value
  tests$SW[i] <- SW.p
  
  # Getting Breusch-Pagan Test for Heteroscedasticity p-value
  BP.p <- bptest(point.lm)$p.value
  tests$BP[i] <- BP.p
  
  # Getting the predicted change per year (slope of the model)
  tests$b1[i] = summary(point.lm)$coefficients[2]
  
  # Getting the residual Standard Error
  sig = summary(point.lm)$sigma
  tests$sig[i] = sig
  
  # Getting the Safe Forcing Delta
  del <- qnorm(0.10, mean=0, sd=sig)
  tests$del[i] <- del
  
  # Getting and saving the fitted values
  fitted <- point.lm$fitted.values
  GDD.fitted[i, 3:96] <- fitted
  
  # Getting and saving the SF values
  sf.val <- fitted + del
  SF[i, 3:96] <- sf.val
  
  # Getting the probabilities of going over 1194 GDD
  probs[i, 3:96] = pnorm(1194, mean=fitted, sd=sig, lower.tail=FALSE)
  
  #Getting the p-value for the model
  f <- summary(point.lm)$fstatistic
  p.val <- pf(f[1], f[2], f[3], lower.tail=FALSE)
  attributes(p.val) <- NULL
  tests$p[i] <- p.val
  tests$log.p[i] <- log10(p.val)
  
}

############## DATA VIZ ####################
# Visualizing the distribution of R squared
par(mfrow = c(1,1))

cols.4 = rep(c("#f7fcf5", "#3fa75a", "#1f763b", "#00441b"), each=5)
cols.5 = c("#891f1f", rep("#3fa75a", each=19))

r2.breaks = seq(min(tests$r2), max(tests$r2), length.out=21)
hist(tests$r2, breaks=r2.breaks, main="Coefficient of Determination", 
     col=cols.4, xlab="R-squared")

hist(tests$SW, nclass=20, ylim=c(0,300), main="p-values for the Shapiro-Wilk Test", 
     col=cols.5, xlab="p-value")

hist(tests$BP, nclass=20, ylim=c(0,200), main="p-values for the Breusch-Pagan Test", 
     col=cols.5, xlab="p-value")

b1.breaks = seq(min(tests$b1), max(tests$b1), length.out=21)
hist(tests$b1, breaks=b1.breaks, main="Rate of Change", ylim=c(0,600), 
     col=cols.4, xlab="Yearly change in GDD accumulation")

sig.breaks = seq(min(tests$sig), max(tests$sig), length.out=21)
hist(tests$sig, breaks=sig.breaks, main="Inter-year variability", ylim=c(0,500), 
     col=cols.4, xlab="Residual Standard Error")

hist(tests$del)
hist(log10(tests$p))

# Adjusting the p-values
adj.p <- p.adjust(tests$p, method="fdr")
hist(log10(adj.p))

tests$log.p.ajd <- log10(adj.p)

hist(tests$SW)
sw.adj = p.adjust(tests$SW, method = "fdr")
hist(sw.adj)

hist(tests$BP)
bp.adj = p.adjust(tests$BP, method = "fdr")
hist(bp.adj)

tests.adj$SW.adj = sw.adj
tests.adj$BP.adj = bp.adj

min(sw.adj)


# Exporting the data# ExSWporting the data
write.csv(tests, "r2test.csv", row.names = F)
# write.csv(tests.adj, "adjtest.csv", row.names = F)
write.csv(GDD.fitted, "GDD_FIN_fitted.csv", row.names=F)
write.csv(SF, "Safe_Forcing_FIN.csv", row.names=F)
write.csv(probs, "probabilities.csv", row.names=F)

############## CHECKING INDIVIDUAL POINTS ##############
point <- unlist(as.vector(GDD[1763, c(4:97)]), use.names=FALSE)
point.lm <- lm(point~c(2007:2100))

smry <- summary(point.lm)
smry
smry$coefficients[2]
smry$sigma

# Getting The Coefficient of Determination
rsq <- smry$r.squared

# Getting Shapiro-Wilk Normality Test p-value
res <- point.lm$residuals
SW.p <- shapiro.test(res)$p.value

# Breusch-Pagan Test for Heteroscedasticity
BP.p <- bptest(point.lm)$p.value

# Getting the Safe Forcing index for 2025
sig <- smry$sigma
fitted <- point.lm$fitted.values
SF.delta <- qnorm(0.10, mean=0, sd=sig)
SF.test <- fitted + SF.delta

# Getting the probabilities of going over 1194 GDD
prob = pnorm(1194, mean=fitted, sd=sig, lower.tail=FALSE)
plot(x=seq(1, 94), y=prob)

# Extracting the p-value
f <- smry$fstatistic
p <- pf(f[1], f[2], f[3], lower.tail=FALSE)
attributes(p) <- NULL

# Useful plotting tools
par(mfrow=c(1,1))

fit <- data.frame(Year=2007:2100, GDD = point.lm$fitted.values)

plot(year_vec, point, main = "", ylab="Yearly GDD", xlab="Year")
lines(fit, col=2)


par(mfrow=c(1,2))
plot(year_vec, resid(point.lm), type="p", main = "", 
     ylab="Residuals from the Linear Model", xlab="Year")
lines(y=c(rep(0, each=94)), x = c(2007:2100), col=2)
qqnorm(point.lm$residuals, main="")
qqline(point.lm$residuals, col=2)

hist(res)

# Checking for Autocorrelation
point.ts <- ts(res, start=c(1), end=c(95), frequency=1)
par(mfrow=c(2,1))
acfres <- acf(point.ts)
pacfres <- pacf(point.ts)
