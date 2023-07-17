#include "gdal.h"
#include "cpl_conv.h"
#include <stdio.h>

int main() {
  GDALAllRegister();
  printf("GDALAllRegister worked\\n");
  return 0;
}
