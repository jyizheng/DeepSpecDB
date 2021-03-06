(** * btrees_spec.v : Specifications of relation_mem.c functions *)

Require Import VST.floyd.proofauto.
Require Import VST.floyd.library.
Require Import relation_mem.
Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.

Require Import VST.msl.wand_frame.
Require Import VST.msl.iter_sepcon.
Require Import VST.floyd.reassoc_seq.
Require Import VST.floyd.field_at_wand.
Require Import FunInd.
Require Import btrees.
Require Import btrees_sep.
Require Import index.

(**
    FUNCTION SPECIFICATIONS
 **)
Definition empty_node (b:bool) (F:bool) (L:bool) (p:val):node val := (btnode val) None (nil val) b F L p.
Definition empty_relation (pr:val) (pn:val): relation val := ((empty_node true true true pn),pr).
Definition empty_cursor := []:cursor val.
Definition first_cursor (root:node val) := moveToFirst root empty_cursor 0.

Definition surely_malloc_spec :=
  DECLARE _surely_malloc
   WITH t:type
   PRE [ _n OF tuint ]
     PROP (0 <= sizeof t <= Int.max_unsigned;
           complete_legal_cosu_type t = true;
           natural_aligned natural_alignment t = true)
     LOCAL (temp _n (Vint (Int.repr (sizeof t))))
     SEP ()
   POST [ tptr tvoid ] EX p:_,
     PROP ()
     LOCAL (temp ret_temp p)
     SEP (malloc_token Tsh t p * data_at_ Tsh t p).

Definition createNewNode_spec : ident * funspec :=
  DECLARE _createNewNode
  WITH isLeaf:bool, First:bool, Last:bool
  PRE [ _isLeaf OF tint, _First OF tint, _Last OF tint ]
    PROP ()
    LOCAL (temp _isLeaf (Val.of_bool isLeaf);
         temp _First (Val.of_bool First);
         temp _Last (Val.of_bool Last))
    SEP ()
  POST [ tptr tbtnode ]
    EX p:val, PROP ()
    LOCAL (temp ret_temp p)
    SEP (btnode_rep (empty_node isLeaf First Last p)).

Definition RL_NewRelation_spec : ident * funspec :=
  DECLARE _RL_NewRelation
  WITH u:unit
  PRE [ ]
    PROP ()
    LOCAL ()
    SEP ()
  POST [ tptr trelation ]
    EX pr:val, EX pn:val, PROP ()
    LOCAL(temp ret_temp pr)
    SEP (relation_rep (empty_relation pr pn) O).

Definition RL_NewCursor_spec : ident * funspec :=
  DECLARE _RL_NewCursor
  WITH r:relation val, numrec:nat
  PRE [ _relation OF tptr trelation ]
    PROP (snd r <> nullval; root_integrity (get_root r); correct_depth r)
    LOCAL (temp _relation (getvalr r))
    SEP (relation_rep r numrec)
  POST [ tptr tcursor ]
    EX p':val,
    PROP ()
    LOCAL(temp ret_temp p')
    SEP (relation_rep r numrec * cursor_rep (first_cursor (get_root r)) r p').

Definition entryIndex_spec : ident * funspec :=
  DECLARE _entryIndex
  WITH r:relation val, c:cursor val, pc:val, numrec:nat
  PRE[ _cursor OF tptr tcursor ]                                                  
    PROP(ne_partial_cursor c r \/ complete_cursor c r; correct_depth r)
    LOCAL(temp _cursor pc)
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST[ tint ]
    PROP()
    LOCAL(temp ret_temp (Vint(Int.repr(rep_index (entryIndex c)))))
    SEP(relation_rep r numrec; cursor_rep c r pc).

Definition currNode_spec : ident * funspec :=
  DECLARE _currNode
  WITH r:relation val, c:cursor val, pc:val, numrec:nat
  PRE[ _cursor OF tptr tcursor ]
    PROP(ne_partial_cursor c r \/ complete_cursor c r; correct_depth r) (* non-empty partial or complete *)
    LOCAL(temp _cursor pc)
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST[ tptr tbtnode ]
    PROP()
    LOCAL(temp ret_temp (getval(currNode c r)))
    SEP(relation_rep r numrec; cursor_rep c r pc).
                                                  
Definition isValid_spec : ident * funspec :=
  DECLARE _isValid
  WITH r:relation val, c:cursor val, pc:val, numrec:nat
  PRE[ _cursor OF tptr tcursor]
    PROP(complete_cursor c r; correct_depth r; root_wf (get_root r))
    LOCAL(temp _cursor pc)
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST [ tint ]
    PROP()
    LOCAL(temp ret_temp (Val.of_bool (isValid c r)))
    SEP(relation_rep r numrec; cursor_rep c r pc).

Definition RL_CursorIsValid_spec : ident * funspec :=
  DECLARE _RL_CursorIsValid
  WITH r:relation val, c:cursor val, pc:val, numrec:nat
  PRE[ _cursor OF tptr tcursor]
    PROP(complete_cursor c r; correct_depth r; root_wf (get_root r))
    LOCAL(temp _cursor pc)
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST [ tint ]
    PROP()
    LOCAL(temp ret_temp (Val.of_bool (isValid c r)))
    SEP(relation_rep r numrec; cursor_rep c r pc).

Definition isFirst_spec : ident * funspec :=
  DECLARE _isFirst
  WITH r:relation val, c:cursor val, pc:val, numrec:nat
  PRE[ _cursor OF tptr tcursor]
    PROP(complete_cursor c r; correct_depth r; root_wf (get_root r))
    LOCAL(temp _cursor pc)
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST [ tint ]
    PROP()
    LOCAL(temp ret_temp (Val.of_bool (isFirst c)))
    SEP(relation_rep r numrec; cursor_rep c r pc).

Definition moveToFirst_spec : ident * funspec :=
  DECLARE _moveToFirst
  WITH r:relation val, c:cursor val, pc:val, n:node val, numrec:nat
  PRE[ _node OF tptr tbtnode, _cursor OF tptr tcursor, _level OF tint ]
    PROP(partial_cursor c r; root_integrity (get_root r); next_node c (get_root r) = Some n; correct_depth r)
    LOCAL(temp _cursor pc; temp _node (getval n); temp _level (Vint(Int.repr(Zlength c))))
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST[ tvoid ]
    PROP()
    LOCAL()
    SEP(relation_rep r numrec; cursor_rep (moveToFirst n c (length c)) r pc).

Definition moveToLast_spec : ident * funspec :=
  DECLARE _moveToLast
  WITH r:relation val, c:cursor val, pc:val, n:node val, numrec:nat
  PRE[ _node OF tptr tbtnode, _cursor OF tptr tcursor, _level OF tint ]
    PROP(partial_cursor c r; root_integrity (get_root r); root_wf (get_root r); next_node c (get_root r) = Some n; correct_depth r)
    LOCAL(temp _cursor pc; temp _node (getval n); temp _level (Vint(Int.repr(Zlength c))))
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST[ tvoid ]
    PROP()
    LOCAL()
    SEP(relation_rep r numrec; cursor_rep (moveToLast val n c (length c)) r pc).

Definition findChildIndex_spec : ident * funspec :=
  DECLARE _findChildIndex
  WITH n:node val, key:key
  PRE[ _node OF tptr tbtnode, _key OF tuint ]
    PROP(InternNode n; node_integrity n; node_wf n)
    LOCAL(temp _node (getval n); temp _key (key_repr key))
    SEP(btnode_rep n)
  POST[ tint ]
    PROP()
    LOCAL(temp ret_temp (Vint(Int.repr(rep_index(findChildIndex n key)))))
    SEP(btnode_rep n).

Definition findRecordIndex_spec : ident * funspec :=
  DECLARE _findRecordIndex
  WITH n:node val, key:key
  PRE[ _node OF tptr tbtnode, _key OF tuint ]
    PROP(node_integrity n; node_wf n)
    LOCAL(temp _node (getval n); temp _key (key_repr key))
    SEP(btnode_rep n)
  POST[ tint ]
    PROP()
    LOCAL(temp ret_temp (Vint(Int.repr(rep_index(findRecordIndex n key)))))
    SEP(btnode_rep n).

Definition moveToKey_spec : ident * funspec :=
  DECLARE _moveToKey
  WITH n:node val, key:key, c:cursor val, pc:val, r:relation val, numrec:nat
  PRE [ _node OF tptr tbtnode, _key OF tuint, _cursor OF tptr tcursor, _level OF tint ]
    PROP(partial_cursor c r; root_integrity (get_root r); correct_depth r; next_node c (get_root r) = Some n; root_wf (get_root r))
    LOCAL(temp _cursor pc; temp _node (getval n); temp _key (key_repr key); temp _level (Vint(Int.repr(Zlength c))))
    SEP(relation_rep r numrec; subcursor_rep c r pc) (* _length in cursor can contain something else *)
  POST[ tvoid ]
    PROP()
    LOCAL()
    SEP(relation_rep r numrec; cursor_rep (moveToKey val n key c) r pc).

Definition isNodeParent_spec : ident * funspec :=
  DECLARE _isNodeParent
  WITH n:node val, key:key
  PRE[ _node OF tptr tbtnode, _key OF tuint ]
    PROP(node_integrity n; node_wf n)
    LOCAL( temp _node (getval n); temp _key (key_repr key))
    SEP(btnode_rep n)
  POST[ tint ]
    PROP()
    LOCAL(temp ret_temp (Val.of_bool (isNodeParent n key)))
    SEP(btnode_rep n).

Definition AscendToParent_spec : ident * funspec :=
  DECLARE _AscendToParent
  WITH c:cursor val, pc:val, key:key, r:relation val, numrec:nat
  PRE[ _cursor OF tptr tcursor, _key OF tuint ]
    PROP(ne_partial_cursor c r \/ complete_cursor c r; correct_depth r; root_integrity (get_root r); root_wf (get_root r))
    LOCAL(temp _cursor pc; temp _key (key_repr key))
    SEP(cursor_rep c r pc; relation_rep r numrec)
  POST [ tvoid ]
    PROP()
    LOCAL()
    SEP(cursor_rep (AscendToParent c key) r pc; relation_rep r numrec).

Definition goToKey_spec : ident * funspec :=
  DECLARE _goToKey
  WITH c:cursor val, pc:val, r:relation val, key:key, numrec:nat
  PRE[ _cursor OF tptr tcursor, _key OF tuint ]
    PROP(complete_cursor c r; correct_depth r; root_integrity (get_root r); root_wf (get_root r))   (* would also work for partial cursor, but always called for complete *)
    LOCAL(temp _cursor pc; temp  _key (key_repr key))
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST[ tvoid ]
    PROP()
    LOCAL()
    SEP(relation_rep r numrec; cursor_rep (goToKey c r key) r pc).

Definition lastpointer_spec : ident * funspec :=
  DECLARE _lastpointer
  WITH n:node val
  PRE[ _node OF tptr tbtnode ]
    PROP(node_wf n)
    LOCAL(temp _node (getval n))
    SEP(btnode_rep n)
  POST[ tint ]
    PROP()
    LOCAL(temp ret_temp (Vint(Int.repr(rep_index (lastpointer n)))))
    SEP(btnode_rep n).

Definition firstpointer_spec : ident * funspec :=
  DECLARE _firstpointer
  WITH n:node val
  PRE[ _node OF tptr tbtnode ]
    PROP(node_wf n)
    LOCAL(temp _node (getval n))
    SEP(btnode_rep n)
  POST[ tint ]
    PROP()
    LOCAL(temp ret_temp (Vint(Int.repr(rep_index (firstpointer n)))))
    SEP(btnode_rep n).

Definition moveToNext_spec : ident * funspec :=
  DECLARE _moveToNext
  WITH c:cursor val, pc:val, r:relation val, numrec:nat
  PRE[ _cursor OF tptr tcursor ]
    PROP(complete_cursor c r; correct_depth r; root_wf (get_root r); root_integrity (get_root r))
    LOCAL(temp _cursor pc)
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST[ tvoid ]
    PROP()
    LOCAL()
    SEP(relation_rep r numrec; cursor_rep (moveToNext c r) r pc).

Definition moveToPrev_spec : ident * funspec :=
  DECLARE _moveToPrev
  WITH c:cursor val, pc:val, r:relation val, numrec:nat
  PRE[ _cursor OF tptr tcursor ]
    PROP(complete_cursor c r \/ partial_cursor c r)
    LOCAL(temp _cursor pc)
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST[ tvoid ]
    PROP()
    LOCAL()
    SEP(relation_rep r numrec; cursor_rep (moveToPrev c r) r pc).

Definition RL_MoveToNext_spec : ident * funspec :=
  DECLARE _RL_MoveToNext
  WITH c:cursor val, pc:val, r:relation val, numrec:nat
  PRE[ _cursor OF tptr tcursor ]
    PROP(complete_cursor c r; correct_depth r; root_wf(get_root r); root_integrity (get_root r))
    LOCAL(temp _cursor pc)
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST[ tvoid ]
    PROP()
    LOCAL()
    SEP(relation_rep r numrec; cursor_rep (RL_MoveToNext c r) r pc).

Definition RL_MoveToPrevious_spec : ident * funspec :=
  DECLARE _RL_MoveToPrevious
  WITH c:cursor val, pc:val, r:relation val, numrec:nat
  PRE[ _cursor OF tptr tcursor ]
    PROP(complete_cursor c r)
    LOCAL(temp _cursor pc)
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST[ tvoid ]
    PROP()
    LOCAL()
    SEP(relation_rep r numrec; cursor_rep (RL_MoveToPrevious c r) r pc).

Definition splitnode_spec : ident * funspec :=
  DECLARE _splitnode
  WITH n:node val, e:entry val, pe: val
  PRE[ _node OF tptr tbtnode, _entry OF tptr tentry, _isLeaf OF tint ]
    PROP(node_integrity n; numKeys n = Fanout; LeafEntry e = LeafNode n) (* splitnode only called on full nodes *)
    LOCAL(temp _node (getval n); temp _entry pe; temp _isLeaf (Val.of_bool (isnodeleaf n)))
    SEP(btnode_rep n; entry_rep e; data_at Tsh tentry (entry_val_rep e) pe)
  POST[ tvoid ]
    EX newx:val,
    PROP()
    LOCAL()
    SEP(btnode_rep (splitnode_left n e); entry_rep (splitnode_right n e newx);
          data_at Tsh tentry (key_repr(splitnode_key n e),inl newx) pe).

Definition putEntry_spec : ident * funspec :=
  DECLARE _putEntry
  WITH c:cursor val, pc:val, r:relation val, e:entry val, pe:val, oldk:key
  PRE[ _cursor OF tptr tcursor, _newEntry OF tptr tentry, _key OF tuint ]
  PROP(complete_cursor c r \/ partial_cursor c r; ((S (get_depth r)) < MaxTreeDepth)%nat; root_integrity (get_root r); root_wf (get_root r); entry_depth e = cursor_depth c r; entry_integrity e; entry_wf e; (entry_numrec e > O)%nat)
    LOCAL(temp _cursor pc; temp _newEntry pe; temp _key (key_repr oldk))
    SEP(cursor_rep c r pc; relation_rep r (get_numrec r + entry_numrec e - 1); entry_rep e; data_at Tsh tentry (entry_val_rep e) pe)
  POST[ tvoid ]
    EX newx:list val,
    PROP()
    LOCAL()
    SEP(let (newc,newr) := putEntry val c r e oldk newx nullval in
        (cursor_rep newc newr pc * relation_rep newr (get_numrec newr) *
         data_at Tsh tentry (entry_val_rep e) pe)).

Definition RL_PutRecord_spec : ident * funspec :=
  DECLARE _RL_PutRecord
  WITH r:relation val, c:cursor val, pc:val, key:key, recordptr:val, record:V
  PRE[ _cursor OF tptr tcursor, _key OF tuint, _record OF tptr tvoid ] 
    PROP(complete_cursor c r; ((S (get_depth r)) < MaxTreeDepth)%nat; root_integrity (get_root r); root_wf (get_root r); Z.of_nat(get_numrec r) < Int.max_signed - 1)
    LOCAL(temp _cursor pc; temp _key (key_repr key); temp _record recordptr)
    SEP(relation_rep r (get_numrec r); cursor_rep c r pc; value_rep record recordptr)
  POST[ tvoid ]
    EX newx:list val,
    PROP()
    LOCAL()
    SEP(let (newc,newr) := RL_PutRecord c r key record recordptr newx nullval in
        (relation_rep newr (get_numrec newr) * cursor_rep newc newr pc)).

Definition RL_GetRecord_spec : ident * funspec :=
  DECLARE _RL_GetRecord
  WITH r:relation val, c:cursor val, pc:val, numrec:nat
  PRE[ _cursor OF tptr tcursor ]
    PROP(complete_cursor c r; correct_depth r; isValid c r = true; root_wf(get_root r); root_integrity(get_root r))
    LOCAL(temp _cursor pc)
    SEP(relation_rep r numrec; cursor_rep c r pc)
  POST[ tptr tvoid ]
    PROP()
    LOCAL(temp ret_temp (RL_GetRecord c r))
    SEP(relation_rep r numrec; cursor_rep (normalize c r) r pc).

(**
    GPROG
 **)

Definition Gprog : funspecs :=
  ltac:(with_library prog [
    surely_malloc_spec; createNewNode_spec; RL_NewRelation_spec; RL_NewCursor_spec;
    entryIndex_spec; currNode_spec; moveToFirst_spec; moveToLast_spec;
    isValid_spec; RL_CursorIsValid_spec; isFirst_spec;
    findChildIndex_spec; findRecordIndex_spec;
    moveToKey_spec; isNodeParent_spec; AscendToParent_spec; goToKey_spec;
    lastpointer_spec; firstpointer_spec; moveToNext_spec;
    RL_MoveToNext_spec; RL_MoveToPrevious_spec;
    splitnode_spec; putEntry_spec; RL_PutRecord_spec; RL_GetRecord_spec ]).

Ltac start_function_hint ::= idtac.

(* proof from VST/progs/verif_queue.v *)
Lemma body_surely_malloc: semax_body Vprog Gprog f_surely_malloc surely_malloc_spec.
Proof.
  start_function.
  forward_call (* p = malloc(n); *)
     t.
  Intros p.
  forward_if
  (PROP ( )
   LOCAL (temp _p p)
   SEP (malloc_token Tsh t p * data_at_ Tsh t p)).
*
  if_tac.
    subst p. entailer!.
    entailer!.
*
    forward_call tt.
    contradiction.
*
    if_tac.
    + forward. subst p. congruence.
    + Intros. forward. entailer!.
*
  forward. Exists p; entailer!.
Qed.
