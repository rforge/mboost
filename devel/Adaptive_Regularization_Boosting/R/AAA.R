
#.onAttach <- function(libname, pkgname) {
#
#    sup <- file.path(libname, pkgname, "startup.txt")
#    if (file.exists(sup) || !interactive()) return(TRUE)
#    if (!suppressWarnings(file.create(sup))) return(TRUE)
#    file.remove(sup)
#    version <- packageDescription(pkg = pkgname)$Version
#    txt <- c("\n",
#             paste("	Welcome to ", sQuote("mboost"),
#                   " version ", version, "!", sep = ""),
#             "\n",
#             "The user-interface changed in some places.",
#             paste("Most important, subsetting an", sQuote("mboost"),
#                   "object modifies this object now."),
#             "Please read the NEWS file, consult the documentation and have fun!",
#             "\n",
#             "Would you like to see this message on startup again?")
#    writeLines(txt)
#    choice <- menu(c("Please, no!", "Yes, please!"))
#    if (choice == 2) return(TRUE)
#    file.create(sup)
#    return(TRUE)
#}

.onLoad <- function(libname, pkgname) {
    if (options("expressions")[[1]] <= 5000)
        options(expressions = 10000)  ### increase maximum number of expressions
    options(mboost_useMatrix = TRUE, ### allow for Matrix package?
            mboost_indexmin = 10000, ### handle ties for n > 10000
            mboost_dftraceS = TRUE,  ### df = trace(S) or df = trace(2 S - StS)
            mboost_lambdaMax = 1e+15)### maximum value for lambda as used in df2lambda
}

.onUnload <- function(libpath) {
    if (options("expressions")[[1]] == 10000)
        options(expression = 5000)  ### decrease maximum number of expressions again
}
