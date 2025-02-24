#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>

/* .Call calls */
extern "C" {
  /* Register entry points for exported C/C++ functions */
  static const R_CallMethodDef CallEntries[] = {
    {NULL, NULL, 0}
  };

  void R_init_toth(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
  }
} 