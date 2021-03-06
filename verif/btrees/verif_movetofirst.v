(** * verif_movetofirst.v : Correctness proof of moveToFirst *)

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
Require Import btrees_spec.
Require Import index.

Lemma body_moveToFirst: semax_body Vprog Gprog f_moveToFirst moveToFirst_spec.
Proof.
  start_function.
  destruct r as [root prel].
  pose (r:=(root,prel)). fold r.
  destruct n as [ptr0 le isLeaf First Last pn].
  pose (n:=btnode val ptr0 le isLeaf First Last pn). fold n.
  assert(CLENGTH: 0 <= Zlength c < 20).
  { unfold partial_cursor in H. destruct H. unfold correct_depth in H2.
    rewrite Zlength_correct. apply partial_rel_length in H. rep_omega. }
  assert(GETVAL: pn = getval n). { unfold n. simpl. auto. }
  assert(SUBNODE: subnode n root).
  { unfold partial_cursor in H. destruct H.
    simpl in H1. unfold partial_cursor_correct_rel in H.
    destruct c as [|[n' i ] c'].
    - simpl in H1. inversion H1. unfold n. apply sub_refl.
    - simpl in H1. rewrite H1 in H. simpl in H. destruct H.
      apply partial_cursor_subnode' in H. apply nth_subnode in H1.
      apply sub_trans with (n0:=n) in H. auto. unfold n. auto. }
  assert_PROP(isptr pn).
  { unfold relation_rep. unfold r. apply subnode_rep in SUBNODE. rewrite SUBNODE.
    rewrite GETVAL. Intros. entailer!. }
  assert(ISPTR: isptr pn) by auto. clear H3.
                                 
  forward_if (
      PROP(pn<>nullval)
      LOCAL(temp _cursor pc; temp _node pn; temp _level (Vint (Int.repr (Zlength c))))
      SEP(relation_rep r numrec; cursor_rep c r pc))%assert.
  - apply denote_tc_test_eq_split. assert (SUBREP: subnode n root) by auto.
    apply subnode_rep in SUBREP. rewrite SUBREP. rewrite GETVAL. entailer!.
    entailer!.    
  - forward.                    (* skip *)
    entailer!.
  - assert (SUBREP: subnode n root) by auto.
    apply subnode_rep in SUBREP. unfold relation_rep. unfold r.
    rewrite SUBREP.
    assert_PROP(isptr (getval n)). entailer!.
    rewrite <- GETVAL in H4. rewrite H3 in H4. simpl in H4. contradiction.
  - forward_if (
        (PROP (pn <> nullval; pc <> nullval)
         LOCAL (temp _cursor pc; temp _node pn; temp _level (Vint (Int.repr (Zlength c))))
         SEP (relation_rep r numrec; cursor_rep c r pc))).
    + forward. entailer!.
    + assert_PROP(False).
      entailer!. contradiction.
    + forward_if ((PROP (pn <> nullval; pc <> nullval; (Zlength c) >= 0)
     LOCAL (temp _cursor pc; temp _node pn; temp _level (Vint (Int.repr (Zlength c))))
     SEP (relation_rep r numrec; cursor_rep c r pc))).
      * forward. entailer!.
      * assert_PROP(False). entailer. omega.
      * unfold cursor_rep.
        Intros anc_end. Intros idx_end. unfold r.
        forward.                (* cursor->ancestors[level]=node *)
        forward.                (* cursor->level = level *) 
        assert (SUBREP:subnode n root) by auto.
        apply subnode_rep in SUBREP. unfold relation_rep. rewrite SUBREP. unfold n.
        rewrite unfold_btnode_rep at 1. Intros ent_end.
        forward.                (* t'2=node->isLeaf *)
        { entailer!. destruct isLeaf; simpl; auto. }  
        forward_if.
{
  - forward.                    (* cursor->ancestorsIdx[level]=0 *)
    + gather_SEP 2 3 4 5. replace_SEP 0 (btnode_rep (btnode val ptr0 le isLeaf First Last pn)).
      { rewrite unfold_btnode_rep. entailer!. Exists ent_end. entailer!. }
      gather_SEP 0 3. replace_SEP 0 (btnode_rep root).
      { rewrite unfold_btnode_rep with (n:=root). entailer!. apply wand_frame_elim'. cancel. }
      gather_SEP 0 1 2. replace_SEP 0 (relation_rep r numrec).
      { entailer!. }
      gather_SEP 1 2. replace_SEP 0 (cursor_rep (moveToFirst n c (length c)) r pc).
      { entailer!. unfold cursor_rep.
      Exists (sublist 1 (Zlength anc_end) anc_end). Exists (sublist 1 (Zlength idx_end) idx_end).
      unfold r. fold n.
      assert (Zlength ((n,ip 0)::c) -1 = Zlength c). { rewrite Zlength_cons. omega. } 
      rewrite H6. cancel. 
      autorewrite with sublist. simpl. rewrite <- app_assoc. rewrite <- app_assoc.
      rewrite upd_Znth0. rewrite upd_Znth0. cancel. }
      forward.                  (* return *)
      unfold r. entailer!.
} {
  forward.                      (* cursor->ancestorsidx[level]=-1 *)
  -                             (* recursive call *)
    destruct ptr0 as [ptr0n|] eqn:EQPTR0.
    + destruct ptr0n eqn:EPTR0n.
      { 
      Intros.
      forward.                    (* t'1=node->ptr0 *)
      gather_SEP 2 3 4 5. replace_SEP 0 (btnode_rep (btnode val ptr0 le isLeaf First Last pn)).
      { rewrite unfold_btnode_rep with (n:=btnode val ptr0 le isLeaf First Last pn).
        entailer!. Exists ent_end. entailer!. }
      gather_SEP 0 3. replace_SEP 0 (btnode_rep root).
      { rewrite EQPTR0. pose (btnoderep:=btnode_rep (btnode val (Some (btnode val o l b b0 b1 v)) le isLeaf First Last pn)). fold btnoderep.
      pose(btroot:=btnode_rep root). fold btroot.
      entailer!. apply wand_frame_elim. }
      gather_SEP 0 1 2. replace_SEP 0 (relation_rep r numrec).
      { entailer!. }
      forward_call(r,((n,im)::c),pc,ptr0n,numrec). (* moveToFirst *)
      * entailer!. repeat apply f_equal. rewrite Zlength_cons. omega.
      * unfold cursor_rep. unfold r.
        Exists (sublist 1 (Zlength anc_end) anc_end). Exists (sublist 1 (Zlength idx_end) idx_end).
        assert (Zlength ((n,im)::c) -1 = Zlength c). rewrite Zlength_cons. omega.
        rewrite H7. change_compspecs CompSpecs. cancel.
        autorewrite with sublist. simpl. rewrite <- app_assoc. rewrite <- app_assoc.
        rewrite upd_Znth0. rewrite upd_Znth0. autorewrite with norm. simpl. cancel.
      * split.
        { unfold partial_cursor in *.
          destruct H. split.
          - split. unfold partial_cursor_correct.
            destruct c as [|[n' i] c']. simpl in H1. simpl. fold n in H1. inversion H1. auto.
            split.
            + simpl in H. destruct (nth_node i n').
              destruct H. auto.
              inv H.
            + fold n in H1. simpl in H1. auto.
            + unfold n. simpl. auto.
          - auto. }
        { split.
          - unfold r. auto.
          - split.
            + simpl. rewrite EPTR0n. auto.
            + auto. }
      * forward.                (* return, 3.96m *)
        (* instantiate (Frame:=[]). *) entailer!.
        fold r. destruct b eqn:HB; simpl; fold n. { cancel. }
        assert((S (length c + 1)) = (length c + 1 + 1)%nat) by omega.
        rewrite H6. cancel. }
    +                           (* ptr0 has to be defined on an intern node *)
      unfold root_integrity in H0. unfold get_root in H0. simpl in H0.
      apply H0 in SUBNODE. unfold node_integrity in SUBNODE.
      unfold n in SUBNODE. rewrite H6 in SUBNODE. contradiction. }
Qed.