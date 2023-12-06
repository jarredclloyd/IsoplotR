# helper function for isochron() that flips X- and Y- axis and back
# if necessary to facilitate anchored regression and model-3 fits
flipper <- function(x,inverse=FALSE,hide=NULL,omit=NULL,model=1,
                    wtype=0,anchor=0,type='p',y0rat,t2DPfun,...){
    flip <- FALSE
    xyz <- data2york(x,inverse=inverse)
    if (model<3 & anchor[1]<1){
        fitinverse <- inverse
        d2calc <- clear(xyz,hide,omit)
        fit <- regression(d2calc,model=model)
    } else if (anchor[1]==1){
        wtype <- 1
        fitinverse <- FALSE
        yd <- data2york(x,inverse=fitinverse)
        d2calc <- clear(yd,hide,omit)
        anchor[2:3] <- iratio(y0rat)
        if (model>1) fit <- MLyork(d2calc,anchor=anchor,model=model)
        else fit <- anchoredYork(d2calc,y0=anchor[2],sy0=anchor[3])
    } else if (anchor[1]==2){
        wtype <- 2
        fitinverse <- TRUE
        yd <- data2york(x,inverse=fitinverse)
        flip <- (type=='p')
        if (flip) yd[,c('X','sX','Y','sY','rXY')] <- yd[,c('Y','sY','X','sX','rXY')]
        d2calc <- clear(yd,hide,omit)
        st <- ifelse(length(anchor)<3,0,anchor[3])
        DP <- do.call(t2DPfun,args=list(t=anchor[2],st=st,...))
        if (type=='d') y0 <- DP
        else y0 <- quotient(X=DP[1],sX=DP[2],Y=1,sY=0,sXY=0)
        if (model>1) fit <- MLyork(d2calc,anchor=c(1,y0),model=model)
        else fit <- anchoredYork(d2calc,y0=y0[1],sy0=y0[2])
    } else if (wtype==1){
        fitinverse <- FALSE
        yd <- data2york(x,inverse=fitinverse)
        d2calc <- clear(yd,hide,omit)
        fit <- MLyork(d2calc,model=model,wtype='a')
    } else if (wtype==2){
        fitinverse <- TRUE
        yd <- data2york(x,inverse=fitinverse)
        flip <- (type=='p')
        if (flip) yd[,c('X','sX','Y','sY','rXY')] <- yd[,c('Y','sY','X','sX','rXY')]
        d2calc <- clear(yd,hide,omit)
        fit <- MLyork(d2calc,model=model,wtype='a')
    } else {
        stop("Invalid anchor and/or wtype value.")
    }
    if (flip) flipped <- flipfit(fit)
    else flipped <- fit
    if (inverse == fitinverse) out <- flipped
    else out <- invertfit(flipped,type=type,wtype=wtype)
    out$xyz <- xyz
    out
}

flipfit <- function(fit){
    out <- fit
    a <- -fit$a[1]/fit$b[1]
    b <- 1/fit$b[1]
    J11 <- -1/fit$b[1]
    J12 <- -a/fit$b[1]
    J21 <- 0
    J22 <- -b/fit$b[1]
    E11 <- fit$a[2]^2
    E22 <- fit$b[2]^2
    E12 <- fit$cov.ab
    vcovab <- errorprop(J11,J12,J21,J22,E11,E22,E12)
    out$a <- c(a,sqrt(vcovab[1]))
    out$b <- c(b,sqrt(vcovab[2]))
    out$cov.ab <- unname(vcovab[3])
    out$disp <- abs(b*fit$disp/fit$a[1])
    out
}

invertfit <- function(fit,type="p",wtype=0){
    out <- fit
    if (type%in%c(1,"p")){
        a <- 1/fit$a[1]
        b <- -fit$b[1]/fit$a[1]
        J11 <- -a/fit$a[1]
        J12 <- 0
        J21 <- -b/fit$a[1]
        J22 <- -1/fit$a[1]
        E11 <- fit$a[2]^2
        E22 <- fit$b[2]^2
        E12 <- fit$cov.ab
        vcovab <- errorprop(J11,J12,J21,J22,E11,E22,E12)
        out$a <- c(a,sqrt(vcovab[1]))
        out$b <- c(b,sqrt(vcovab[2]))
        out$cov.ab <- vcovab[3]
        if (wtype==1) out$disp <- a*fit$disp/fit$a[1]
        else if (wtype==2) out$disp <- abs(b*fit$disp/fit$b[1])
    } else if (type%in%c(2,"d")){
        out$a <- fit$b
        out$b <- fit$a
    } else {
        stop("Invalid isochron type.")
    }
    names(out$a) <- c('a','s[a]')
    names(out$b) <- c('b','s[b]')
    out
}

anchoredYork <- function(x,y0=0,sy0=0){
    eps <- .Machine$double.eps
    X <- rbind(x,c(0,eps,y0,max(sy0,eps),0))
    out <- yorkhelper(X,np=1)
    if (y0==0) out$a[1] <- 0
    if (sy0==0) out$a[2] <- 0
    out$model <- 1
    out$n <- nrow(x)
    out
}