\name{glmboost}
\alias{glmboost}
\alias{glmboost.formula}
\alias{glmboost.matrix}
\alias{glmboost.default}

\title{ Gradient Boosting with Component-wise Linear Models }
\description{
  Gradient boosting for optimizing arbitrary loss functions where component-wise
  linear models are utilized as base-learners.
}
\usage{
\method{glmboost}{formula}(formula, data = list(), weights = NULL,
          na.action = na.pass, contrasts.arg = NULL,
          center = TRUE, control = boost_control(), ...)
\method{glmboost}{matrix}(x, y, center = TRUE, control = boost_control(), ...)
\method{glmboost}{default}(x,  ...)
}
\arguments{
  \item{formula}{ a symbolic description of the model to be fit. }
  \item{data}{ a data frame containing the variables in the model. }
  \item{weights}{ an optional vector of weights to be used in the fitting
                  process. }
  \item{contrasts.arg}{a list, whose entries are contrasts suitable for input
          to the \code{contrasts} replacement function and whose names are
          the names of columns of \code{data} containing factors.
          See \code{\link{model.matrix.default}}.}
  \item{na.action}{a function which indicates what should happen when the data
          contain \code{NA}s.}
  \item{center}{logical indicating of the predictor variables are centered before fitting.}
  \item{control}{ a list of parameters controlling the algorithm.}
  \item{x}{ design matrix. Sparse matrices of class \code{Matrix} can be used as well.}
  \item{y}{ vector of responses. }
  \item{\dots}{ additional arguments passed to \code{\link{mboost_fit}},
    including \code{weights}, \code{offset}, \code{family} and
    \code{control}. For default values see \code{\link{mboost_fit}}.}
}
\details{

  A (generalized) linear model is fitted using a boosting algorithm based on component-wise
  univariate linear models. The fit, i.e., the regression coefficients, can be
  interpreted in the usual way. The methodology is described in
  Buehlmann and Yu (2003), Buehlmann (2006), and Buehlmann and Hothorn (2007).

}
\value{
  An object of class \code{glmboost} with \code{\link{print}}, \code{\link{coef}},
  \code{\link{AIC}} and \code{\link{predict}} methods being available.
  For inputs with longer variable names, you might want to change
  \code{par("mai")} before calling the \code{plot} method of \code{glmboost}
  objects visualizing the coefficients path.
}
\references{

  Peter Buehlmann and Bin Yu (2003),
  Boosting with the L2 loss: regression and classification.
  \emph{Journal of the American Statistical Association}, \bold{98},
  324--339.

  Peter Buehlmann (2006), Boosting for high-dimensional linear models.
  \emph{The Annals of Statistics}, \bold{34}(2), 559--583.

  Peter Buehlmann and Torsten Hothorn (2007),
  Boosting algorithms: regularization, prediction and model fitting.
  \emph{Statistical Science}, \bold{22}(4), 477--505.

  Torsten Hothorn, Peter Buehlmann, Thomas Kneib, Mattthias Schmid and
  Benjamin Hofner (2010), Model-based Boosting 2.0. \emph{Journal of
    Machine Learning Research}, \bold{11}, 2109--2113.

  Benjamin Hofner, Andreas Mayr, Nikolay Robinzonov and Matthias Schmid
  (2014). Model-based Boosting in R: A Hands-on Tutorial Using the R
  Package mboost. \emph{Computational Statistics}, \bold{29}, 3--35.\cr
  \url{http://dx.doi.org/10.1007/s00180-012-0382-5}

  Available as vignette via: \code{vignette(package = "mboost", "mboost_tutorial")}
}
\seealso{\code{\link{mboost}} for the generic boosting function and
  \code{\link{gamboost}} for boosted additive models and
  \code{\link{blackboost}} for boosted trees. See \code{\link{cvrisk}} for
  cross-validated stopping iteration. Furthermore see
  \code{\link{boost_control}}, \code{\link{Family}} and  \code{\link[mboost]{methods}}}
\examples{

    ### a simple two-dimensional example: cars data
    cars.gb <- glmboost(dist ~ speed, data = cars,
                        control = boost_control(mstop = 2000),
                        center = FALSE)
    cars.gb

    ### coefficients should coincide
    cf <- coef(cars.gb, off2int = TRUE)     ## add offset to intercept
    coef(cars.gb) + c(cars.gb$offset, 0)    ## add offset to intercept (by hand)
    signif(cf, 3)
    signif(coef(lm(dist ~ speed, data = cars)), 3)
    ## almost converged. With higher mstop the results get even better

    ### now we center the design matrix for
    ### much quicker "convergence"
    cars.gb_centered <- glmboost(dist ~ speed, data = cars,
                                 control = boost_control(mstop = 2000),
                                 center = TRUE)

    ## plot coefficient paths of glmboost
    par(mfrow=c(1,2), mai = par("mai") * c(1, 1, 1, 2.5))
    plot(cars.gb, main = "without centering")
    plot(cars.gb_centered, main = "with centering")

    ### alternative loss function: absolute loss
    cars.gbl <- glmboost(dist ~ speed, data = cars,
                         control = boost_control(mstop = 1000),
                         family = Laplace())
    cars.gbl
    coef(cars.gbl, off2int = TRUE)

    ### plot fit
    par(mfrow = c(1,1))
    plot(dist ~ speed, data = cars)
    lines(cars$speed, predict(cars.gb), col = "red")     ## quadratic loss
    lines(cars$speed, predict(cars.gbl), col = "green")  ## absolute loss

    ### Huber loss with adaptive choice of delta
    cars.gbh <- glmboost(dist ~ speed, data = cars,
                         control = boost_control(mstop = 1000),
                         family = Huber())

    lines(cars$speed, predict(cars.gbh), col = "blue")   ## Huber loss
    legend("topleft", col = c("red", "green", "blue"), lty = 1,
           legend = c("Gaussian", "Laplace", "Huber"), bty = "n")

    ### sparse high-dimensional example that makes use of the matrix
    ### interface of glmboost and uses the matrix representation from
    ### package Matrix
    library("Matrix")
    n <- 100
    p <- 10000
    ptrue <- 10
    X <- Matrix(0, nrow = n, ncol = p)
    X[sample(1:(n * p), floor(n * p / 20))] <- runif(floor(n * p / 20))
    beta <- numeric(p)
    beta[sample(1:p, ptrue)] <- 10
    y <- drop(X \%*\% beta + rnorm(n, sd = 0.1))
    mod <- glmboost(y = y, x = X, center = TRUE) ### mstop needs tuning
    coef(mod, which = which(beta > 0))

}
\keyword{models}
\keyword{regression}
