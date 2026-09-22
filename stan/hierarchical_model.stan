data {
  int<lower=1> J;
  array[J] int<lower=0> n;
  array[J] int<lower=0> y;
}

parameters {
  real<lower=0> alpha;
  real<lower=0> beta;
  vector<lower=0, upper=1>[J] theta;
}

model {
  alpha ~ exponential(1);
  beta ~ exponential(1);
  theta ~ beta(alpha, beta);
  y ~ binomial(n, theta);
}

generated quantities {
  array[J] int y_rep;
  for (j in 1:J) {
    y_rep[j] = binomial_rng(n[j], theta[j]);
  }
}
