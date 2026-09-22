stopifnot(ppc_value(rep(5, 100), 5) == 1,
          ppc_value(c(1, 2, 3), 10) == 0,
          abs(ppc_value(c(1, 2, 3, 4), 1) - 0.5) < 1e-12)
cat("PPC calculation passed.\n")
