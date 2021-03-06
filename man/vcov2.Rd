% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/vcov2.R
\name{vcov2}
\alias{vcov2}
\alias{vcov2.lm}
\alias{vcov2.gls}
\alias{vcov2.lme}
\alias{vcov2.lvmfit}
\alias{vcov2.lm2}
\alias{vcov2.gls2}
\alias{vcov2.lme2}
\alias{vcov2.lvmfit2}
\title{Extract the Variance Covariance Matrix of the Model Parameters}
\usage{
vcov2(object, ...)

\method{vcov2}{lm}(object, param = NULL, data = NULL,
  bias.correct = TRUE, ...)

\method{vcov2}{gls}(object, param = NULL, data = NULL,
  bias.correct = TRUE, ...)

\method{vcov2}{lme}(object, param = NULL, data = NULL,
  bias.correct = TRUE, ...)

\method{vcov2}{lvmfit}(object, param = NULL, data = NULL,
  bias.correct = TRUE, ...)

\method{vcov2}{lm2}(object, param = NULL, data = NULL, ...)

\method{vcov2}{gls2}(object, param = NULL, data = NULL, ...)

\method{vcov2}{lme2}(object, param = NULL, data = NULL, ...)

\method{vcov2}{lvmfit2}(object, param = NULL, data = NULL, ...)
}
\arguments{
\item{object}{a linear model or a latent variable model}

\item{...}{arguments to be passed to \code{sCorrect}.}

\item{param}{[optional] the fitted parameters.}

\item{data}{[optional] the data set.}

\item{bias.correct}{[logical] should the standard errors of the coefficients be corrected for small sample bias? Only relevant if the \code{sCorrect} function has not yet be applied to the object.}
}
\value{
A matrix.
}
\description{
Extract the variance covariance matrix of the model parameters from a Gaussian linear model.
}
\details{
If argument \code{p} or \code{data} is not null, then the small sample size correction is recomputed to correct the influence function.
}
\examples{
n <- 5e1
p <- 3
X.name <- paste0("X",1:p)
link.lvm <- paste0("Y~",X.name)
formula.lvm <- as.formula(paste0("Y~",paste0(X.name,collapse="+")))

m <- lvm(formula.lvm)
distribution(m,~Id) <- sequence.lvm(0)
set.seed(10)
d <- lava::sim(m,n)

## linear model
e.lm <- lm(formula.lvm,data=d)
vcov.tempo <- vcov2(e.lm, bias.correct = TRUE)
vcov.tempo[rownames(vcov(e.lm)),colnames(vcov(e.lm))]/vcov(e.lm)

## latent variable model
e.lvm <- estimate(lvm(formula.lvm),data=d)
vcov.tempo <- vcov2(e.lvm, bias.correct = FALSE)
vcov.tempo/vcov(e.lvm)

}
\seealso{
\code{\link{sCorrect}} to obtain \code{lm2}, \code{gls2}, \code{lme2}, or \code{lvmfit2} objects.
}
\concept{small sample inference}
