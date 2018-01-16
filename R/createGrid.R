### createGrid.R --- 
#----------------------------------------------------------------------
## author: Brice Ozenne
## created: aug 31 2017 (16:40) 
## Version: 
## last-updated: jan 16 2018 (09:38) 
##           By: Brice Ozenne
##     Update #: 63
#----------------------------------------------------------------------
## 
### Commentary: 
## 
### Change Log:
#----------------------------------------------------------------------
## 
### Code:


## * Documentaiton - createGrid
#' @title Create a Mesh for the Integration
#' @description Create a mesh for the integration
#' @name createGrid
#' 
#' @param n the number of points for the mesh in the x direction.
#' @param xmin the minimal x value.
#' @param xmax the maximal x value.
#' @param d.y the number of dimensions for the triangle.
#' @param d.z the number of dimensions.
#' @param zmax the maximal z value (in absolute value).
#' @param fine should the mesh be displayed
#' @param double should the grid be just outside the region of interest? Otherwise it will be just inside.
#'
#' @details This create a mesh for integrating over a triangular surface using rectangles.
#' The domain is define by constrains on three types of variables:
#' \itemize{
#' \item the x variable: [unidimensional] that varies freely between [-xmax,-xmin] U [xmin,xmax].
#' \item the y variables: [dimension d.y] constrained to be lower in absolute value than the x variable.
#' In 2D this corresponds to 2 triangles, and in higher dimension to cones/hypercones.
#' \item the z variables: [dimension d.z] constrained to vary between [-zmax,zmax].
#' }
#' The intersection of these three conditions define the domain.
#'
#' The mesh is obtained slicing the triangles using rectangles.
#' 
#' @examples
#'
#' ## no z 
#' gridInt_2d <- createGrid(5, d.y = 1, xmin = 0, xmax = 4, 
#'                          d.z = 0, fine = FALSE, double = FALSE)
#' gridExt_2d <- createGrid(5, d.y = 1, xmin = 0, xmax = 4, 
#'                          d.z = 0, fine = FALSE, double = TRUE)
#' 
#' gridInt_4d <- createGrid(5, d.y = 3, xmin = 0, xmax = 4, 
#'                          d.z = 0, fine = FALSE, double = FALSE)
#' gridExt_4d <- createGrid(5, d.y = 3, xmin = 0, xmax = 4, 
#'                          d.z = 0, fine = FALSE, double = TRUE)
#' 
#' gridInt_2d <- createGrid(5, d.y = 1, xmin = 0, xmax = 4, 
#'                          d.z = 0, fine = TRUE, double = FALSE)
#' 
#' ## no z
#' gridIntZ1_2d <- createGrid(5, d.y = 1, xmin = 0, xmax = 4, 
#'                            d.z = 1, zmax = 2, fine = FALSE, double = FALSE)
#' gridExtZ1_2d <- createGrid(5, d.y = 1, xmin = 0, xmax = 4, 
#'                            d.z = 1, zmax = 2, fine = FALSE, double = TRUE)
#'  
#' gridIntZ2_4d <- createGrid(5, d.y = 3, xmin = 0, xmax = 4, 
#'                            d.z = 2, zmax = 2, fine = FALSE, double = FALSE)
#' gridExtZ2_4d <- createGrid(5, d.y = 3, xmin = 0, xmax = 4, 
#'                            d.z = 2, zmax = 2, fine = FALSE, double = TRUE)
#'


## * createGrid
#' @rdname createGrid
#' @export
createGrid <- function(n,
                       xmin, xmax, d.y, 
                       d.z, zmax,
                       fine, double){

    index <- x.max <- x.min <- y1.max <- y1.min <- NULL ## [:for CRAN check] data.table
    
    ## ** find step along the x axis
    if(xmin[1]==0){
        by <- xmax/n
    }else{
        seqTry <- seq(0,xmax, length.out = n)
        by <- xmin/sum(seqTry<xmin)
    }
    seqPointsX <- seq(xmin,xmax, by = by)
    n.seqX <- length(seqPointsX)-1

    ## ** name variables
    y.minNames <- paste0("y",1:d.y,".min")
    y.maxNames <- paste0("y",1:d.y,".max")
    all.Names <- c("x.min","x.max",y.minNames,y.maxNames,"weight","index")

    seqNames.min <- c("x.min",y.minNames)
    seqNames.max <- c("x.max",y.maxNames)
    
    ## ** main grid
    grid.main <- NULL
    for(iX in 1:n.seqX){ #  iX <- 1
        grid.main <- rbind(grid.main,
                           c(seqPointsX[iX], seqPointsX[iX+1],
                             rep(-seqPointsX[iX+double],d.y), rep(seqPointsX[iX+double],d.y),
                             1, iX)
                           )
    }    
    grid.main <- as.data.table(grid.main)
    setnames(grid.main, old = names(grid.main), new = all.Names )
    
    ## gg.main <- ggplot(grid.main, aes(xmin = x.min, ymin = y1.min, xmax = x.max, ymax = y1.max, fill = index))
    ## gg.main <- gg.main + geom_rect()
    ## gg.main <- gg.main + geom_abline(slope = 1,color = "red") + geom_abline(slope = -1,color = "red")
    ## gg.main
    
    ## ** fine grid
    grid.fine <- NULL    
    if(fine){

        ls.mp <- lapply(1:d.y, function(x){c(-1,1)})
        grid.mp <- expand.grid(ls.mp)
        n.mp <- NROW(grid.mp)
        ls.index <- list(1:d.y,
                         (d.y+1):(2*d.y))

        for(iX in 1:n.seqX){ # iX <- 1
            for(iMP in 1:n.mp){ # iMP <- 1

                index.neg <- which(grid.mp[iMP,]<0)
                ls.index2 <- ls.index
                for(i.neg in index.neg){
                    ls.index2[[1]][i.neg] <- ls.index[[2]][i.neg]
                    ls.index2[[2]][i.neg] <- ls.index[[1]][i.neg]    
                }
                M.seq <- cbind(rep(seqPointsX[iX],d.y)*grid.mp[iMP,],
                               rep(seqPointsX[iX+1],d.y)*grid.mp[iMP,])
                
                grid.fine <- rbind(grid.fine,
                                   c(seqPointsX[iX], seqPointsX[iX+1],
                                     as.numeric(M.seq[unlist(ls.index2)]),
                                     1/2, iX+1)
                                   )
            }
        }        
        grid.fine <- as.data.table(grid.fine)
        setnames(grid.fine, old = names(grid.fine), new = all.Names)
        grid.fine[,c(all.Names) := lapply(.SD,as.numeric)]
        ## gg.fine <- ggplot(grid.fine, aes(xmin = x.min, ymin = y1.min, xmax = x.max, ymax = y1.max, fill = index))
        ## gg.fine <- gg.fine + geom_rect()
        ## gg.fine <- gg.fine + geom_abline(slope = 1,color = "red") + geom_abline(slope = -1,color = "red")
        ## gg.fine
    }

    ## ** Merge grids and remove empty cells
    grid.all <- rbind(grid.main, grid.fine)    
    grid.all <- grid.all[grid.all[, .I[y1.min!=y1.max]]] # remove empty rectangles
    
    ## ** duplicate grid  (negative x  and positive x)
    grid.all <- grid.all[ ,"index" := index - min(index) + 1]

    grid.all2 <- copy(grid.all)    
    grid.all2[, "x.min" := -grid.all$x.max] 
    grid.all2[, "x.max" := -grid.all$x.min] # DO NOT use just x.min, we need grid.all$x.min due to the previous line
    grid.all2[, "index" := index + max(index)]

    grid <- rbind(grid.all,grid.all2)

    ## ** add z coordinate
    if(d.z>0){
        z.minNames <- paste0("z",1:d.z,".min")
        z.maxNames <- paste0("z",1:d.z,".max")
        
        grid[,c(z.minNames) := -abs(zmax)]
        grid[,c(z.maxNames) := abs(zmax)]
        seqNames.min <- c(seqNames.min, z.minNames)
        seqNames.max <- c(seqNames.max, z.maxNames)
    }

    return(list(grid = grid,
                seqNames.min = seqNames.min,
                seqNames.max = seqNames.max))
}
