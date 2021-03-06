
### 
### Experimental version of gradient boosting with componentwise least
### smoothing splines
### 

basedef <- function(x, baselearner, dfbase) {

    for (xn in names(x)) {
        dpp <- attr(x[[xn]], "dpp")
        if (is.function(dpp)) next()
        if (is.numeric(x[[xn]]) && dfbase > 2) {
            args <- list(x = x[[xn]], df = dfbase, xname = xn)
            if (baselearner == "bols") args$df <- NULL
            x[[xn]] <- do.call(baselearner, args)
        } else {
            x[[xn]] <- bols(x[[xn]], xname = xn)
        }
    }
    x
}

### Fitting function
gamboost_fit <- function(object, baselearner = c("bss", "bbs", "bols", "bns"), 
                         dfbase = 4, family = GaussReg(),
                         control = boost_control(), weights = NULL) {

    baselearner <- match.arg(baselearner)
    if (control$center) 
        warning("inputs are not centered in ", sQuote("gamboost"))

    sigma <- 1
    
    ### data and baselearner
    x <- object$input
    class(x) <- "list"
    x <- basedef(x, baselearner = baselearner, dfbase = dfbase)

    y <- object$yfit
    check_y_family(object$y, family)
    if (is.null(weights)) {
        weights <- object$w
    } else {
        if (NROW(y) == length(weights))
            object$w <- weights
        else 
            stop(sQuote("weights"), " is not of length ", NROW(y))
    }

    ### hyper parameters
    mstop <- control$mstop
    risk <- control$risk
    constraint <- control$constraint
    nu <- control$nu
    trace <- control$trace
    tracestep <- options("width")$width / 2

    ### surrogate variables for handling missing values: add later
    nsurrogate <- 0
    nsurrogate <- min(nsurrogate, length(x))

    ### extract negative gradient and risk functions
    ngradient <- family@ngradient
    riskfct <- family@risk

    ### unweighted problem
    WONE <- (max(abs(weights - 1)) < .Machine$double.eps)
    if (!family@weights && !WONE)
        stop(sQuote("family"), " is not able to deal with weights")

    ### rescale weights (because of the AIC criterion)
    ### <FIXME> is this correct with zero weights??? </FIXME>
    weights <- rescale_weights(weights)
    oobweights <- as.numeric(weights == 0)

    ### the ensemble
    ens <- matrix(NA, nrow = mstop, ncol = nsurrogate + 1)
    if (nsurrogate > 0) {
        colnames(ens) <- c("xselect", 
            paste("xselect_surr", 1:nsurrogate, sep = "_"))
    } else {
        colnames(ens) <- "xselect"
    }
    ensss <- vector(mode = "list", length = mstop)

    ### vector of empirical risks for all boosting iterations
    ### (either in-bag or out-of-bag)
    sigmavec <- numeric(mstop)
    sigmavec[1:mstop] <- NA
    mrisk <- numeric(mstop)
    mrisk[1:mstop] <- NA   
    tsums <- numeric(length(x))
    ss <- vector(mode = "list", length = length(x))

    fit <- offset <- family@offset(y, weights)
    u <- ustart <- ngradient(1, y=y, f=fit, w=weights)
    
    #if (class(y)=="Surv") event <- y[,2]
    
    logl <- function(sigma, ff){
    vec <- family@loss(y, f=ff, sigma=sigma)
    sum(vec)
    }

    ### dpp
    fitfct <- vector(mode = "list", length = length(x))
    for (i in 1:length(x))
        fitfct[[i]] <- attr(x[[i]], "dpp")(weights)

    #browser()
    ### start boosting iteration
    for (m in 1:mstop) {
  
        ### fit least squares to residuals _componentwise_
        for (i in 1:length(x)) {
            tsums[i] <- -1
            ss[[i]] <- try(fitfct[[i]]$fit(y = u))
            if (inherits(ss[[i]], "try-error")) next
            tsums[i] <- mean(weights * (fitted(ss[[i]]) - u)^2, na.rm = TRUE)            
        }

        if (all(tsums < 0)) 
            stop("could not fit base learner in boosting iteration ", m)
        xselect <- order(tsums)[1:(nsurrogate + 1)]
        basess <- ss[xselect]
        class(basess) <- "baselist"

        ### update step
        fit <- fit + nu * basess[[1]]$fitted

        ### L2 boost with constraints (binary classification)
        if (constraint)
            fit <- sign(fit) * pmin(abs(fit), 1)
            
        ### scale parameter estimation for aft models
        
        if (family@sigmaTF == TRUE)
        sigma <- optimize(logl, interval=c(0,1000), ff=fit)$minimum
        sigmavec[m] <- sigma

        ### negative gradient vector, the new `residuals'
        u <- ngradient(sigma, y=y, f=fit, w=weights)

        ### evaluate risk, either for the learning sample (inbag)
        ### or the test sample (oobag)
        if (risk == "inbag") mrisk[m] <- riskfct(sigma, y=y, f=fit, w=weights)
        if (risk == "oobag") mrisk[m] <- riskfct(sigma, y=y, f=fit, w=oobweights)

        ### save the model, i.e., the selected coefficient and variance
        ens[m,] <- xselect
        ensss[[m]] <- basess

        ### print status information
        if (trace) 
            do_trace(m, risk = mrisk, step = tracestep, width = mstop)
    }

    updatefun <- function(object, control, weights) 
        gamboost_fit(object, dfbase = dfbase, family = family,
                     control = control, weights = weights)

    RET <- list(ensemble = ens,         ### selected variables 
                ensembless = ensss,	    ### list of smooth.spline fits
                fit = fit,              ### vector of fitted values
                sigma = sigmavec,       ### scale parameter estimate
                offset = offset,        ### offset
                ustart = ustart,        ### first negative gradients
                risk = mrisk,           ### empirical risks for m = 1, ..., mstop
                control = control,      ### control parameters   
                family = family,        ### family object
                response = y,           ### the response variable
                weights = weights,      ### weights used for fitting   
                update = updatefun,     ### a function for fitting with new weights
                dfbase = dfbase         ### degrees of freedom for smooth.spline
    )
    ### save learning sample
    if (control$savedata) RET$data <- object

    ### prediction function (linear predictor only)
    RET$predict <- function(newdata = NULL, mstop = mstop, ...) {

        if (!is.null(newdata)) {
            if (is.null(colnames(newdata)))
                stop("missing column names for ", sQuote("newdata"))
            if (is.matrix(newdata)) newdata <- as.data.frame(newdata)
        }

        lp <- offset
        for (m in 1:mstop)
            lp <- lp + nu * predict(ensss[[m]], newdata = newdata)
        if (constraint) lp <- sign(lp) * pmin(abs(lp), 1)    
        return(lp)
    }

    ### function for computing hat matrices of individual predictors
    RET$hat <- function(j) fitfct[[j]]$hatmatrix()

    class(RET) <- c("gamboost", "gb")
    return(RET)
}

### generic method for gradient boosting with componentwise smoothing splines
### for fitting generalized additive models
gamboost <- function(x, ...) UseMethod("gamboost")

### formula interface
gamboost.formula <- function(formula, data = list(), weights = NULL, 
                             na.action = na.omit, ...) {

    ### construct design matrix etc.
    object <- boost_dpp(formula, data, weights, na.action)

    ### fit the ensemble
    object$input <- object$menv@get("input")
    RET <- gamboost_fit(object, ...)

    RET$call <- match.call()

    return(RET)
}

### matrix interface
gamboost.matrix <- function(x, y, weights = NULL, ...) {

    if (NROW(y) != NROW(x))
        stop("number of observations in", sQuote("x"), "and",
             sQuote("y"), "differ")
    if (is.null(colnames(x)))
        stop("missing column names for ", sQuote("x"))
    if (is.null(weights)) weights <- rep(1, NROW(x))
    if (length(weights) != NROW(x))
        stop("number of observations in", sQuote("x"), "and",
             sQuote("weights"), "differ")

    object <- gb_xyw(x, y, weights)
    object$input <- as.data.frame(x)
    RET <- gamboost_fit(object, ...)
    RET$call <- match.call()
    return(RET)
}

### methods: print
print.gamboost <- function(x, ...) {

    cat("\n")
    cat("\t Generalized Additive Models Fitted via Gradient Boosting\n")
    cat("\n")
    if (!is.null(x$call))
    cat("Call:\n", deparse(x$call), "\n\n", sep = "")
    show(x$family)
    cat("\n")
    cat("Number of boosting iterations: mstop =", mstop(x), "\n")
    cat("Step size: ", x$control$nu, "\n")
    cat("Offset: ", x$offset, "\n")
    dfbase <- ifelse(length(unique(x$dfbase)) == 1, unique(x$dfbase), 
                     x$dfbase)
    cat("Degree of freedom: ", dfbase, "\n")
    cat("\n")
    invisible(x)

}

plot.gamboost <- function(x, which = NULL, ask = TRUE && dev.interactive(), 
    type = "b", ylab = expression(f[partial]), add_rug = TRUE, ...) {

    lp <- mboost:::gamplot(x)
    input <- x$data$input
    ### <FIXME>: y ~ bbs(x) means that we only have access to x via
    ### the environment of its dpp function
    tmp <- lapply(input, function(x) 
        eval(expression(x), envir = environment(attr(x, "dpp"))))
    input <- as.data.frame(tmp)
    names(input) <- names(tmp)
    ### </FIXME>
    if (is.null(which)) which <- colnames(input)

    if (ask) {
        op <- par(ask = TRUE)
        on.exit(par(op))
    }

    out <- sapply(which, function(w) {
        xp <- input[[w]]
        yp <- lp[,w]
        ox <- order(xp)
        plot(xp[ox], yp[ox], xlab = w, type = type, 
             ylab = ylab, ylim = range(lp[,which]), ...)
        abline(h = 0, lty = 3)
        if (add_rug) rug(input[[w]])
    })
    rm(out)
}
