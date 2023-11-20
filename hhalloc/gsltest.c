#include <stdio.h>
#include <gsl/gsl_rng.h>


/* To set seed and ring type use this:
 * GSL_RNG_SEED=123 GSL_RNG_TYPE=mrg ./gsltest
 */
 

int
main (void)
{
  const gsl_rng_type * T;
  gsl_rng * r;

  int i, n = 10;

  gsl_rng_env_setup();

  T = gsl_rng_default;
  r = gsl_rng_alloc (T);

  for (i = 0; i < n; i++)
    {
      double u = gsl_rng_uniform (r);
      printf ("%.5f\n", u);
    }

  gsl_rng_free (r);

  return 0;
}

