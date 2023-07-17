#include <iostream>
#include <geos/geom/Geometry.h>
using namespace std;
using namespace geos::geom;
int main() {
  cout<<"GEOS "<<geosversion()<<" ported from JTS "<<jtsport()<<endl;
  return 0;
}
