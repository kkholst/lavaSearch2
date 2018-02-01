### compare2.R --- 
##----------------------------------------------------------------------
## Author: Brice Ozenne
## Created: jan 30 2018 (14:33) 
## Version: 
## Last-Updated: feb  1 2018 (13:42) 
##           By: Brice Ozenne
##     Update #: 202
##----------------------------------------------------------------------
## 
### Commentary: 
## 
### Change Log:
##----------------------------------------------------------------------
## 
### Code:

## * Documentation - compare2
#' @title Test Linear Hypotheses with small sample correction
#' @description Test Linear Hypotheses using a Wald or an F statistic.
#' Similar to \code{lava::compare} but with small sample correction.
#' @name compare2
#'
#' @param object an object that inherits from lm/gls/lme/lvmfit.
#' @param adjust.residuals [logical] small sample correction: should the leverage-adjusted residuals be used to compute the score? Otherwise the raw residuals will be used.
#' @param par [vector of characters] expression defining the linear hypotheses to be tested.
#' See the examples section. 
#' @param contrast [matrix] a contrast matrix defining the left hand side of the linear hypotheses to be tested.
#' @param null [vector] the right hand side of the linear hypotheses to be tested.
#' @param as.lava [logical] should the output be similar to the one return by \code{lava::compare}.
#' @param level [numeric 0-1] the confidence level of the confidence interval.
#' @param ...  [internal] Only used by the generic method.
#' One exception: for gls models \code{...} is passed to dVco2,
#' this can be useful when the argument cluster is required. 
#'
#' @details A set of linear hypothesis can be written:
#' \deqn{
#'   contrast \theta = null
#' }
#' The contrast matrix must contain as many columns as there are parameters in the model (mean and variance parameters).
#' Each hypothesis correspond to a row in the contrast matrix.
#' So the null vector should contain as many elements as there are row in the contrast matrix.
#' The method \code{createContrast} can help to initialize the contrast matrix.
#' \cr \cr
#' 
#' Instead of a contrast matrix, on can also use expressions encoded in a vector of characters via the argument \code{par}.
#' For example \code{"beta = 0"} or \code{c("-5*beta + alpha = 3","-alpha")} are valid expressions if alpha and beta belong to the set of model parameters.
#'
#' @seealso \code{\link{createContrast}} to create contrast matrices. \cr
#' \code{\link{dVcov2}} to pre-compute quantities for the small sample correction.
#' 
#' 
#' @examples
#' #### simulate data ####
#' set.seed(10)
#' mSim <- lvm(Y~0.1*X1+0.2*X2)
#' categorical(mSim, labels = c("a","b","c")) <- ~X1
#' transform(mSim, Id~Y) <- function(x){1:NROW(x)}
#' df.data <- lava::sim(mSim, 1e2)
#'
#' #### with lm ####
#' ## direct use of compare2
#' e.lm <- lm(Y~X1+X2, data = df.data)
#' anova(e.lm)
#' compare2(e.lm, par = c("X1b=0","X1c=0"))
#'
#' ## or first compute the derivative of the information matrix
#' dVcov2(e.lm) <- TRUE
#' 
#' ## and define the contrast matrix
#' C <- createContrast(e.lm, par = c("X1b=0","X1c=0"))
#'
#' ## run compare2
#' compare2(e.lm, contrast = C$contrast, null = C$null)
#' 
#' #### with gls ####
#' library(nlme)
#' e.gls <- gls(Y~X1+X2, data = df.data, method = "ML")
#'
#' ## first compute the derivative of the information matrix
#' dVcov2(e.gls, cluster = 1:NROW(df.data)) <- TRUE
#' 
#' compare2(e.gls, par = c("5*X1b+2*X2 = 0","(Intercept) = 0"))
#' 
#' #### with lvm ####
#' m <- lvm(Y~X1+X2)
#' e.lvm <- estimate(m, df.data)
#' 
#' compare2(e.lvm, par = c("-Y","Y~X1b+Y~X1c"))
#' @export
`compare2` <-
  function(object, ...) UseMethod("compare2")

## * compare2.lm
#' @rdname compare2
#' @export
compare2.lm <- function(object, adjust.residuals = TRUE, ...){
    object$dVcov  <- dVcov2(object, adjust.residuals = adjust.residuals)
    return(.compare2(object, ...))
}

## * compare2.gls
#' @rdname compare2
#' @export
compare2.gls <- function(object, adjust.residuals = TRUE, ...){
    object$dVcov  <- dVcov2(object, adjust.residuals = adjust.residuals, ...)
    return(.compare2(object, ...))
}

## * compare2.lme
#' @rdname compare2
#' @export
compare2.lme <- compare2.lm

## * compare2.lvmfit
#' @rdname compare2
#' @export
compare2.lvmfit <- function(object, adjust.residuals = TRUE, ...){
    object$dVcov  <- dVcov2(object, adjust.residuals = adjust.residuals)
    return(.compare2(object, ...))
}

## * compare2.lm2
#' @rdname compare2
#' @export
compare2.lm2 <- function(object, ...){
    return(.compare2(object, ...))
}
## * compare2.gls2
#' @rdname compare2
#' @export
compare2.gls2 <- compare2.lm2
## * compare2.lme2
#' @rdname compare2
#' @export
compare2.lme2 <- compare2.lm2
## * compare2.lvmfit2
#' @rdname compare2
#' @export
compare2.lvmfit2 <- compare2.lm2

## * .compare2
#' @rdname compare2
.compare2 <- function(object, par = NULL, contrast = NULL, null = NULL,
                      as.lava = TRUE, level = 0.95, ...){

    ## ** extract information
    dVcov.dtheta <- object$dVcov
    
    p <- attr(dVcov.dtheta, "param")
    vcov.param <- attr(dVcov.dtheta, "vcov.param")
    warn <- attr(vcov.param, "warning")
    attr(dVcov.dtheta, "vcov.param") <- NULL
    keep.param <- dimnames(dVcov.dtheta)[[3]]

    n.param <- length(p)
    name.param <- names(p)
        
    ### ** normalize linear hypotheses
    if(!is.null(par)){
        
        if(!is.null(contrast)){
            stop("Argument \'par\' and argument \'contrast\' should not simultaneously specified")
        }else if(!is.null(null)){
            stop("Argument \'par\' and argument \'null\' should not simultaneously specified")
        }else{
            res.C <- createContrast(par, name.param = name.param, add.rowname = TRUE)
            contrast <- res.C$contrast
            null <- res.C$null
        }
        
    }else{
        
        if(is.null(contrast)){
            stop("Argument \'contrast\' and argument \'par\' cannot be both NULL \n",
                 "Please specify the null hypotheses using one of the two arguments \n")
        }
        if(NCOL(contrast) != n.param){
            stop("Argument \'contrast\' should be a matrix with ",n.param," columns \n")
        }
        if(is.null(colnames(contrast)) || any(colnames(contrast) != name.param)){
            stop("Argument \'contrast\' has incorrect column names \n")
        }
        if(any(abs(svd(contrast)$d)<1e-10)){
            stop("Argument \'contrast\' is singular \n")
        }
        if(is.null(null)){
            null <- setNames(rep(0,NROW(contrast)),rownames(contrast))
        }else if(length(null)!=NROW(contrast)){
            stop("The length of argument \'null\' does not match the number of rows of argument \'contrast' \n")
        }
        if(is.null(rownames(contrast))){
            rownames(contrast) <- .contrast2name(contrast, null = null)
            null <- setNames(null, rownames(contrast))
        }
    }
    
    ### ** prepare export
    name.hypo <- rownames(contrast)
    n.hypo <- NROW(contrast)

    df.table <- as.data.frame(matrix(NA, nrow = n.hypo, ncol = 5,
                                     dimnames = list(name.hypo,
                                                     c("estimate","std","statistic","df","p-value"))
                                     ))

    ### ** Compute degrees of freedom
    calcDF <- function(M.C){ # M.C <- C
        C.vcov.C <- rowSums(M.C %*% vcov.param * M.C)
    
        C.dVcov.C <- sapply(keep.param, function(x){
            rowSums(M.C %*% dVcov.dtheta[,,x] * M.C)
        })
        numerator <- 2 *(C.vcov.C)^2
        denom <- rowSums(C.dVcov.C %*% vcov.param[keep.param,keep.param,drop=FALSE] * C.dVcov.C)
        df <- numerator/denom
        return(df)
    }

    ### *** Wald test
    ## statistic
    C.p <- (contrast %*% p) - null
    C.vcov.C <- contrast %*% vcov.param %*% t(contrast)
    sd.C.p <- sqrt(diag(C.vcov.C))
    stat.Wald <- C.p/sd.C.p
    
    ## df
    df.Wald  <- calcDF(contrast)
    
    ## store
    df.table$estimate <- as.numeric(C.p)
    df.table$std <- as.numeric(sd.C.p)
    df.table$statistic <- as.numeric(stat.Wald)
    df.table$df <- as.numeric(df.Wald)
    df.table$`p-value` <- as.numeric(2*(1-stats::pt(abs(df.table$statistic), df = df.table$df)))

    ### *** F test
    i.C.vcov.C <- solve(C.vcov.C)
    stat.F <- t(C.p) %*% i.C.vcov.C %*% (C.p) / n.hypo

    ## df
    svd.tempo <- eigen(i.C.vcov.C)
    D.svd <- diag(svd.tempo$values, nrow = n.hypo, ncol = n.hypo)
    P.svd <- svd.tempo$vectors
     
    C.anova <- sqrt(D.svd) %*% t(P.svd) %*% contrast
    ## Fstat - crossprod(C.anova %*% p)/n.hypo
    nu_m <- calcDF(C.anova) ## degree of freedom of the independent t statistics
    
    EQ <- sum(nu_m/(nu_m-2))
    df.F <- 2*EQ / (EQ - n.hypo)

    ## store
    df.table <- rbind(df.table, global = rep(NA,5))
    df.table["global", "statistic"] <- as.numeric(stat.F)
    df.table["global", "df"] <- df.F
    df.table["global", "p-value"] <- 1 - stats::pf(df.table["global", "statistic"],
                                                   df1 = n.hypo,
                                                   df2 = df.table["global", "df"])

    ## ** export
    if(as.lava == TRUE){
        level.inf <- (1-level)/2
        level.sup <- 1-level.inf

        level.inf.label <- paste0(100*level.inf,"%")
        level.sup.label <- paste0(100*level.sup,"%")

        df.estimate <- matrix(NA, nrow = n.hypo, ncol = 5,
                              dimnames = list(name.hypo,c("Estimate", "Std.Err", "df", level.inf.label, level.sup.label)))
        df.estimate[,"Estimate"] <- df.table[name.hypo,"estimate"]
        df.estimate[,"Std.Err"] <- df.table[name.hypo,"std"]
        df.estimate[,"df"] <- df.table[name.hypo,"df"]
        df.estimate[,level.inf.label] <- df.table[name.hypo,"estimate"] + stats::qt(level.inf, df = df.table[name.hypo,"df"]) * df.table[name.hypo,"std"]
        df.estimate[,level.sup.label] <- df.table[name.hypo,"estimate"] + stats::qt(level.sup, df = df.table[name.hypo,"df"]) * df.table[name.hypo,"std"]

        out <- list(statistic = setNames(df.table["global","statistic"],"F-statistic"),
                    parameter = setNames(round(df.table["global","df"],2), paste0("df1 = ",n.hypo,", df2")),
                    p.value = df.table["global","p-value"],
                    method = c("- Wald test -", "", "Null Hypothesis:", name.hypo),
                    estimate = df.estimate,
                    vcov = C.vcov.C,
                    coef = C.p[,1],
                    null = null,
                    cnames = name.hypo                    
                    )
        attr(out, "B") <- contrast
        class(out) <- "htest"
    }else{
        out <- df.table
        attr(out, "warning") <- warn
        attr(out, "contrast") <- contrast
    }
    return(out)
}


##----------------------------------------------------------------------
### compare2.R ends here