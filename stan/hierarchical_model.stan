data {
  int<lower=1> J;
  int<lower=0> n[J];
  int<lower=0> y[J];
}

parameters {
  real<lower=0> alpha;
  real<lower=0> beta;
  vector<lower=0,upper=1>[J] theta;  // group-level churn probabilities
}

model {
  // Hyperpriors
  alpha ~ exponential(1);
  beta  ~ exponential(1);
  
  // Group-level priors
  theta ~ beta(alpha, beta);

  // Likelihood for each group
  y ~ binomial(n, theta);
}

generated quantities {
  int y_rep[J];
  for (j in 1:J) {
    y_rep[j] = binomial_rng(n[j], theta[j]);
  }
}
