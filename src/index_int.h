/** This file contains the ideal interface of index for int.

 *  This should be implemented by b+-trees, as the original
 *  [relation_mem.c]
 */

#ifndef _INDEX_INT_H
#define _INDEX_INT_H

#include "inttypes.h"

typedef keyslice_t IKey;
typedef void *IValue;
typedef void *ICursor;
typedef void *IIndex;

IIndex Iempty();

ICursor Imake_cursor(IKey key, IIndex index);

ICursor Imove_cursor(IKey key, ICursor cursor, IIndex index);

ICursor Ifirst_cursor(IIndex index);

ICursor Ilast_cursor(IIndex index);

ICursor Inext_cursor(ICursor cursor, IIndex index);

ICursor Iprev_cursor(ICursor cursor, IIndex index);

IKey Iget_key(ICursor cursor, IIndex index);

IValue Iget_value(ICursor cursor, IIndex index);

ICursor Iput(IKey key, IValue value, ICursor cursor, IIndex index);

#endif
