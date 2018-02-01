### createContrast.R --- 
##----------------------------------------------------------------------
## Author: Brice Ozenne
## Created: jan 31 2018 (12:05) 
## Version: 
## Last-Updated: feb  1 2018 (18:29) 
##           By: Brice Ozenne
##     Update #: 151
##----------------------------------------------------------------------
## 
### Commentary: 
## 
### Change Log:
##----------------------------------------------------------------------
## 
### Code:

## * Documentation - createContrast
#' @title Create Contrast matrix.
#' @description Returns an contrast matrix corresponding an object.
#' The contrast matrix will contains the hypotheses in rows and the model parameters in columns.
#' @name createContrast
#' 
#' @param object an \code{ls.lvmfit} object.
#' @param par [vector of characters] expression defining the linear hypotheses to be tested. See the examples section. 
#' @param var.test [character] a regular expression that is used to identify the coefficients to be tested using \code{grep}. Each coefficient will be tested in a separate hypothesis. When this argument is used, the argument \code{par} is disregarded.
#' @param name.param [internal] the names of all the model parameters.
#' @param add.rowname [internal] should a name be defined for each hypothesis.
#' @param ... Only used by the generic method.
#'
#' @details One can initialize an empty contrast matrix setting the argument par to \code{character(0)}.
#'
#' @return A list containing
#' \itemize{
#' \item{contrast} [matrix] a contrast matrix corresponding to the left hand side of the linear hypotheses.
#' \item{null} [vector] the right hand side of the linear hypotheses.
#' \item{Q} [integer] the rank of the contrast matrix.
#' \item{ls.contrast} [list, optional] the contrast matrix corresponding to each submodel.
#' Only present when the argument object is a list of models.
#' }
#' @examples
#' ## Simulate data
#' mSim <- lvm(X ~ Age + Treatment,
#'             Y ~ Gender + Treatment,
#'             c(Z1,Z2,Z3) ~ eta, eta ~ treatment,
#'             Age[40:5]~1)
#' latent(mSim) <- ~eta
#' categorical(mSim, labels = c("placebo","SSRI")) <- ~Treatment
#' categorical(mSim, labels = c("male","female")) <- ~Gender
#' n <- 1e2
#' set.seed(10)
#' df.data <- sim(mSim,n)
#'
#' ## Estimate separate models
#' lmX <- estimate(lvm(X ~ -1 + Age + Treatment), data = df.data)
#' lmY <- estimate(lvm(Y ~ -1 + Gender + Treatment), data = df.data)
#' lvmZ <- estimate(lvm(c(Z1,Z2,Z3) ~ -1 + 1*eta, eta ~ -1 + Treatment), 
#'                  data = df.data)
#'
#' ## Contrast matrix for a given model
#' createContrast(lmX, par = "X~Age")
#' createContrast(lmX, par = c("X~Age=0","X~Age+5*X~TreatmentSSRI=0"))
#' createContrast(lmX, par = character(0))
#'
#' ## Contrast matrix for the join model
#' ls.lvm <- list(X = lmX, Y = lmY, Z = lvmZ)
#' createContrast(ls.lvm, var.test = "Treatment")
#' createContrast(ls.lvm, par = character(0))
#'
#' @export
`createContrast` <-
    function(object, ...) UseMethod("createContrast")

## * createContrast.character
#' @rdname createContrast
#' @export
createContrast.character <- function(object, name.param, add.rowname = TRUE,
                           ...){

    n.param <- length(name.param)
    
    n.hypo <- length(object)
    if(any(nchar(object)==0)){
        stop("Argument contains empty character string(s) instead of an expression involving the model parameters \n")
    }
    null <- rep(NA, n.hypo)
    contrast <- matrix(0, nrow = n.hypo, ncol = n.param,
                       dimnames = list(NULL,name.param))

    if(n.hypo>0){
        for(iH in 1:n.hypo){ # iH <- 1
            iTempo.eq <- strsplit(object[iH], split = "=", fixed = TRUE)[[1]]
            if(length(iTempo.eq)==1){ ## set null to 0 when second side of the equation is missing
                iTempo.eq <- c(iTempo.eq,"0")
            }
            null[iH] <- as.numeric(trim(iTempo.eq[2]))
            iRh.plus <- strsplit(iTempo.eq[[1]], split = "+", fixed = TRUE)[[1]]
            iRh <- trim(unlist(sapply(iRh.plus, strsplit, split = "-", fixed = TRUE)))
            iRh <- iRh[iRh!="",drop=FALSE]
                            
            ls.iRh <- lapply(strsplit(iRh, split = "*", fixed = TRUE), trim)
                    
            iN.tempo <- length(ls.iRh)
                    
            for(iCoef in 1:iN.tempo){ # iCoef <- 1

                if(length(ls.iRh[[iCoef]])==1){
                    iFactor <- 1
                    iName <- ls.iRh[[iCoef]][1]                
                }else{
                    iFactor <- as.numeric(ls.iRh[[iCoef]][1])
                    iName <- ls.iRh[[iCoef]][2]
                }
            
                if(iName %in% name.param == FALSE){
                    stop("unknown coefficient ",iName," in hypothesis ",iH,"\n")
                }

                test.sign <- length(grep("-",strsplit(names(iRh)[iCoef], split = iName)[[1]][1]))>0
                contrast[iH,iName] <- c(1,-1)[test.sign+1] * iFactor
            }
        }
    
        if(add.rowname){
            name.hypo <- .contrast2name(contrast, null = null)
            rownames(contrast) <- name.hypo
            null <- setNames(null, name.hypo)
        }
    }
    
    return(list(contrast = contrast,
                null = null,
                Q = n.hypo))
}

## * createContrast.lm
#' @rdname createContrast
#' @export
createContrast.lm <- function(object, par, ...){

    if(!identical(class(par),"character")){
        stop("Argument \'par\' must be a character \n")
    }
    name.coef <- names(coef(object))
    if(any("sigma2" %in% name.coef)){
        stop("createContrast does not work when one of the coefficients is named \"sigma2\" \n")
    }
    out <- createContrast(par, name.param = c(name.coef,"sigma2"), ...)
    return(out)
    
}

## * createContrast.gls
#' @rdname createContrast
#' @export
createContrast.gls <- function(object, par, ...){

    if(!identical(class(par),"character")){
        stop("Argument \'par\' must be a character \n")
    }
    out <- createContrast(par, name.param = names(.coef2(object)), ...)
    return(out)
    
}

## * createContrast.lme
#' @rdname createContrast
#' @export
createContrast.lme <- createContrast.lm

## * createContrast.lvmfit
#' @rdname createContrast
#' @export
createContrast.lvmfit <- function(object, par, ...){

    if(!identical(class(par),"character")){
        stop("Argument \'par\' must be a character \n")
    }
    out <- createContrast(par, name.param = names(coef(object)), ...)
    return(out)
    
}

## * createContrast.list
#' @rdname createContrast
#' @export
createContrast.list <- function(object, par = NULL, var.test = NULL,
                                ...){

    ## ** find the names of the coefficients
    name.model <- names(object)
    
    ls.coefnames <- lapply(name.model, function(iModel){ ## list by model
        iResC <- createContrast(object[[iModel]], par = character(0))
        return(colnames(iResC$contrast))
    })
    names(ls.coefnames) <- name.model

    ls.object.coefnames <- lapply(name.model, function(iModel){ ## list by model with model name
        paste0(iModel,": ", ls.coefnames[[iModel]])
    })    
    names(ls.object.coefnames) <- name.model
    
    object.coefname <- unname(unlist(ls.object.coefnames)) ## vector
    n.coef <- length(object.coefname)
    
    ## ** normalize arguments
    if(!is.null(var.test)){
        if(!is.null(par)){
            stop("Argument \'var.test\' cannot be specified when argument \'par\' is specified \n")
        }else{
            if(length(var.test)!=1){
                stop("Argument \'var.test\' must have length 1 \n")
            }
            par <- grep(var.test, object.coefname, value = TRUE)
        }
    }

    ## ** create full contrast matrix
    out <- createContrast(par, name.param = object.coefname)
    if(any(out$null!=0)){
        warning("glht ignores the \'rhs\' argument when dealing with a multiple models \n")
    }

    ## ** create contrast matrix relative to each model
    out$mlf <- lapply(name.model, function(iModel){ ## x <- name.model[1]        
        ## only keep columns corresponding to coefficients belonging the the current model
        iContrast <- out$contrast[,ls.object.coefnames[[iModel]],drop=FALSE]

        ## update name by removing the name of the model
        colnames(iContrast) <- ls.coefnames[[iModel]]

        ## remove lines in the contrast matrix containing only 0
        index.n0 <- which(rowSums(iContrast!=0)!=0)
        return(iContrast[index.n0,,drop=FALSE])
        ## return(iContrast)
    })
    names(out$mlf) <- name.model    
    class(out$mlf) <- "mlf"
    
    ## remove right hand side from the names (like in multicomp)
    if(length(par)>0){
        rownames(out$contrast) <- .contrast2name(out$contrast, null = NULL)
        out$mlf <- lapply(out$mlf, function(x){ ## x <- name.model[1]
            rownames(x) <- .contrast2name(x, null = NULL)
            return(x)
        })
        class(out$mlf) <- "mlf"
        names(out$null) <- rownames(out$contrast)
    }
   
    ## ** export
    return(out)    
}

## * createContrast.mmm
#' @rdname createContrast
#' @export
createContrast.mmm <- createContrast.list

## * .contrast2name
#' @title Create Rownames for a Contrast Matrix
#' @description Create rownames for a contrast matrix using the coefficients and the names of the parameters. The rownames will be [value * name] == null, e.g. [beta + 4*alpha] = 0.
#' @name contrast2name
#'
#' @param contrast [matrix] a contrast matrix defining the left hand side of the linear hypotheses to be tested.
#' @param null [vector, optional] the right hand side of the linear hypotheses to be tested.
#'
#' @details When argument NULL is null then the rownames will not be put into brackets and the right hand side will not be added to the name.
#' 
.contrast2name <- function(contrast, null = NULL){

    contrast.names <- colnames(contrast)
    
    df.index <- as.data.frame(which(contrast != 0, arr.ind = TRUE))
    df.index$col <- contrast.names[df.index$col]
    index.order <- order(df.index$row,match(df.index$col,contrast.names))
    df.index <- df.index[index.order,]
    df.index$nrow <- unlist(tapply(df.index$row, df.index$row, function(x){1:length(x)}))

    ## find coef value to each  coefficient
    df.index$coef <- contrast[which(contrast!=0)][index.order]
    df.index$coefname <- as.character(df.index$coef)

    ## add positive sign
    df.index[df.index$coef>0,"coefname"] <- paste0("+",df.index$coefname[df.index$coef>0])
    
    ## add multiplicative symbol
    index.Npm1 <- which(df.index$coefname %in% c("","+1","-1") == FALSE)
    df.index[index.Npm1, "coefname"] <- paste0(df.index[index.Npm1, "coefname"],"*")

    ## simplify
    df.index[df.index$coefname == "+1" & df.index$nrow == 1, "coefname"] <- ""
    df.index[df.index$coefname == "+1", "coefname"] <- "+"            
    df.index[df.index$coefname == "-1", "coefname"] <- "-"
    df.index[df.index$nrow == 1, "coefname"] <- gsub("+","",df.index[df.index$nrow == 1, "coefname"], fixed = TRUE)

    ## add space between coefficients
    df.index$coefname <- gsub("+"," + ",df.index$coefname, fixed = TRUE)
    df.index$coefname <- gsub("-"," - ",df.index$coefname, fixed = TRUE)
    df.index[df.index$coefname == " - " & df.index$nrow == 1, "coefname"] <- "- "

    ## paste together value and coefficient names
    df.index$rowname <- paste0(df.index$coefname,df.index$col)
    ## paste together names from the same hypothesis
    out <- unlist(tapply(df.index$rowname,df.index$row,paste,collapse=""))

    ## add right hand side
    if(!is.null(null)){
        out <- paste0("[",out,"] = ",null)
        
    }

    return(as.character(out))
}


##----------------------------------------------------------------------
### createContrast.R ends here