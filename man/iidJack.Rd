% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/iidJack.R
\name{iidJack}
\alias{iidJack}
\alias{iidJack.default}
\title{Jackknife iid Decomposition from Model Object}
\usage{
iidJack(object, ...)

\method{iidJack}{default}(object, data = NULL, grouping = NULL,
  cpus = 1, keep.warnings = TRUE, keep.error = TRUE, cl = NULL,
  trace = TRUE, ...)
}
\arguments{
\item{object}{a object containing the model.}

\item{...}{[internal] only used by the generic method.}

\item{data}{[data.frame] dataset used to perform the jackknife.}

\item{grouping}{[vector] variable defining cluster of observations that will be simultaneously removed by the jackknife.}

\item{cpus}{[integer >0] the number of processors to use.
If greater than 1, the fit of the model and the computation of the influence function for each jackknife sample is performed in parallel.}

\item{keep.warnings}{[logical] keep warning messages obtained when estimating the model with the jackknife samples.}

\item{keep.error}{[logical]keep error messages obtained when estimating the model with the jackknife samples.}

\item{cl}{[cluster] a parallel socket cluster generated by \code{parallel::makeCluster}
that has been registered using \code{registerDoParallel}.}

\item{trace}{[logical] should a progress bar be used to trace the execution of the function}
}
\value{
A matrix with in row the samples and in columns the parameters.
}
\description{
Extract iid decomposition (i.e. influence function) from model object.
}
\examples{
n <- 20

#### glm ####
set.seed(10)
m <- lvm(y~x+z)
distribution(m, ~y+z) <- binomial.lvm("logit")
d <- lava::sim(m,n)
g <- glm(y~x+z,data=d,family="binomial")
iid1 <- iidJack(g, cpus = 1)
iid2 <- lava::iid(g)
quantile(iid1-iid2)
vcov(g)
colSums(iid2^2)
colSums(iid1^2)

#### Cox model ####
library(survival)
data(Melanoma, package = "riskRegression")
m <- coxph(Surv(time,status==1)~ici+age, data = Melanoma, x = TRUE, y = TRUE)

\dontrun{
## require riskRegression > 1.4.3
if(utils::packageVersion("riskRegression") > "1.4.3"){
library(riskRegression)
iid1 <- iidJack(m)
iid2 <- iidCox(m)$IFbeta

apply(iid1,2,sd)

print(iid2)

apply(iid2,2,sd)
  }
}

#### LVM ####
set.seed(10)

mSim <- lvm(c(Y1,Y2,Y3,Y4,Y5) ~ 1*eta)
latent(mSim) <- ~eta
categorical(mSim, K=2) <- ~G
transform(mSim, Id ~ eta) <- function(x){1:NROW(x)}
dW <- lava::sim(mSim, n, latent = FALSE)
dL <- reshape2::melt(dW, id.vars = c("G","Id"),
                     variable.name = "time", value.name = "Y")
dL$time <- gsub("Y","",dL$time)

m1 <- lvm(c(Y1,Y2,Y3,Y4,Y5) ~ 1*eta)
latent(m1) <- ~eta
regression(m1) <- eta ~ G
e <- estimate(m1, data = dW)
\dontrun{
iid1 <- iidJack(e)
iid2 <- iid(e)
attr(iid2, "bread") <- NULL

apply(iid1,2,sd)
apply(iid2,2,sd)
quantile(iid2 - iid1)
}

library(nlme)
e2 <- lme(Y~G+time, random = ~1|Id, weights = varIdent(form =~ 1|Id), data = dL)
e2 <- lme(Y~G, random = ~1|Id, data = dL)
\dontrun{
iid3 <- iidJack(e2)
apply(iid3,2,sd)
}

}
\concept{iid decomposition}
