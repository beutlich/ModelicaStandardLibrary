#include "../../../.CI/Test/Common.c"
#define MODEL_IDENTIFIER ISSUE_4576
#include "g2constructor.h"
#include "ModelicaRandom.h"

static int init = 0;
#ifdef G2_DEFINE_CONSTRUCTOR_NEEDS_PRAGMA
#pragma G2_DEFINE_CONSTRUCTOR_PRAGMA_ARGS(G2_FUNCNAME(ModelicaRandom_initializeCS))
#endif
G2_DEFINE_CONSTRUCTOR(G2_FUNCNAME(ModelicaRandom_initializeCS))
static void G2_FUNCNAME(ModelicaRandom_initializeCS)(void) {
	init = 1;
}
#ifdef G2_DEFINE_DESTRUCTOR_NEEDS_PRAGMA
#pragma G2_DEFINE_DESTRUCTOR_PRAGMA_ARGS(G2_FUNCNAME(ModelicaRandom_deleteCS))
#endif
G2_DEFINE_DESTRUCTOR(G2_FUNCNAME(ModelicaRandom_deleteCS))
static void G2_FUNCNAME(ModelicaRandom_deleteCS)(void) {
	init = 0;
}

int main(int argc, char* argv[])
{
	int x[2];
	ModelicaFormatMessage("init=%d", init);
	ModelicaRandom_convertRealToIntegers(42.0, &x[0]);
	return 0;
}
