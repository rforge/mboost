\name{Family}
\alias{Family}
\alias{AdaExp}
\alias{Binomial}
\alias{GaussClass}
\alias{GaussReg}
\alias{Huber}
\alias{Laplace}
\alias{Poisson}
\alias{CoxPH}
\alias{Weib}
\alias{LogNormal}
\alias{Loglog}
\title{ Gradient Boosting Families }
\description{
    \code{boost_family} objects provide a convenient way to specify loss functions
    and corresponding risk functions to be optimized by one of the boosting
    algorithms implemented in this package.
}
\usage{
Family(ngradient, loss = NULL, risk = NULL, 
       offset = function(y, w) 0, 
       fW = function(f) rep(1, length(f)), 
       check_y = function(y) TRUE,
       weights = TRUE, name = "user-specified",
       sigmaTF = FALSE)
AdaExp()
Binomial()
GaussClass()
GaussReg()
Huber(d = NULL)
Laplace()
Poisson()
CoxPH()
Weib()
Loglog()
LogNormal()
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{ngradient}{ a function with arguments \code{y}, \code{f} and \code{w} implementing the
                    \emph{negative} gradient of the \code{loss} function (which is to be minimized). }
  \item{loss}{ an optional loss function with arguments \code{y} and \code{f} to be minimized (!). }
  \item{risk}{ an optional risk function with arguments \code{y}, \code{f} and \code{w},
               the weighted mean of the loss function by default. }
  \item{offset}{ a function with argument \code{y} and \code{w} (weights) 
                 for computing a \emph{scalar} offset. }
  \item{fW}{ transformation of the fit for the diagonal weights matrix for an
             approximation of the boosting hat matrix for loss functions other than
             squared error.}
  \item{check_y}{ a function for checking the class / mode of a response variable.}
  \item{weights}{ a logical indicating if weights are allowed. }
  \item{name}{ a character giving the name of the loss function for pretty printing. }
  \item{d}{ delta parameter for Huber loss function. If omitted, it is chosen adaptively.}
  \item{sigmaTF}{ a logical indicating whether the family contains an additional scale parameter.}
}
\details{

  The boosting algorithms implemented in \code{\link{glmboost}}, \code{\link{gamboost}} or
  \code{\link{blackboost}} aim at minimizing the (weighted) empirical risk function 
  \code{risk(y, f, w)} with respect to \code{f}. By default, the risk function is the 
  weighted sum of the loss function \code{loss(y, f)} but can be chosen arbitrarily.
  The \code{ngradient(y, f)} function is the negative gradient of \code{loss(y, f)} with 
  respect to \code{f}.
  For binary classification problems we assume that the response \code{y} is coded by
  \eqn{-1} and \eqn{+1}.

  Pre-fabricated functions for the most commonly used loss functions are
  available as well.

  The \code{offset} function returns the population minimizers evaluated
  at the response, i.e., \eqn{1/2 \log(p / (1 - p))} for \code{Binomial()} or
  \code{AdaExp()} and \eqn{(\sum w_i)^{-1} \sum w_i y_i} for \code{GaussReg} and the median
  for \code{Huber} and \code{Laplace}.

}
\value{
  An object of class \code{boost_family}.
}
\examples{

    Laplace()

    Family(ngradient = function(y, f) y - f, 
           loss = function(y, f) (y - f)^2,
           name = "My Gauss Variant")

}
\keyword{models}
