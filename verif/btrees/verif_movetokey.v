(** * verif_movetokey.v : Correctness proof of moveToKey *)

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
Require Import verif_findindex.

Lemma partial_correct_append: forall (c:cursor val) n i r child,
    partial_cursor_correct_rel c r ->
    next_node c (get_root r) = Some n ->
    nth_node i n = Some child ->
    partial_cursor_correct_rel ((n,i)::c) r.
Proof.
  intros. destruct c.
  simpl. simpl in H0. inv H0. rewrite H1. split; auto.
  simpl. rewrite H1. destruct p. split; auto.
  simpl in H0.
  split; auto.
  simpl in H. rewrite H0 in H. destruct H. auto.
Qed. 

Lemma body_moveToKey: semax_body Vprog Gprog f_moveToKey moveToKey_spec.
Proof.
  start_function.
  destruct r as [root prel].
  pose (r:=(root,prel)). fold r.
  destruct n as [ptr0 le isLeaf First Last pn].
  pose (n:=btnode val ptr0 le isLeaf First Last pn). fold n.
  unfold subcursor_rep. Intros anc_end. Intros idx_end. Intros length. unfold r.
  assert(CLENGTH: 0 <= Zlength c < 20).
  { unfold partial_cursor in H. destruct H. unfold correct_depth in H1.
    rewrite Zlength_correct. apply partial_rel_length in H. rep_omega. }
  assert(SUBNODE: subnode n root).
  { fold n in H2. unfold next_node in H2.
    destruct c as [|[n' i] c']. simpl in H2. inv H2. apply sub_refl.
    eapply sub_trans. apply nth_subnode in H2. eauto. unfold partial_cursor in H.
    destruct H. apply partial_cursor_subnode in H. simpl in H. auto. }
  assert (SUBREP: subnode n root) by auto. apply subnode_rep in SUBREP.
  assert (GETVAL: pn = getval n).
  { unfold n. simpl. auto. }
  assert_PROP(isptr pn).
  { unfold relation_rep. apply subnode_rep in SUBNODE. rewrite SUBNODE.
    rewrite GETVAL. Intros. entailer!. }
  assert(ISPTR: isptr pn) by auto. clear H4.
  
  forward.                      (* cursor->ancestors[level]=node *)
  forward.                      (* cursor->level = level *)
  gather_SEP 1 2.         (* the cursor, with a new node *)
  unfold relation_rep.
  rewrite SUBREP.
  rewrite unfold_btnode_rep at 1. unfold n. Intros. Intros ent_end.
  forward.                      (* t'3=node->isLeaf *)
  { entailer!. destruct isLeaf; simpl; auto. }
  forward_if.
  - forward_call (n,key).    (* t'1=findRecordIndex(node,key) *)
    + rewrite unfold_btnode_rep with (n:=n). unfold n. Exists ent_end. cancel.
      change_compspecs CompSpecs. cancel.
    + forward.                  (* cursor->ancestorsIdx[level]=t'1 *)
      gather_SEP 0 5. replace_SEP 0 (btnode_rep root).
      { fold n. entailer!. apply wand_frame_elim. }
      gather_SEP 0 3 4. replace_SEP 0 (relation_rep r numrec).
      { entailer!. apply derives_refl. }
      forward.                  (* return *)
      entailer!.
      unfold cursor_rep.
      Exists (sublist 1 (Zlength anc_end) anc_end). Exists (sublist 1 (Zlength idx_end) idx_end).
      cancel.
      pose (ii:=findRecordIndex' le key (ip 0)). fold ii.
      assert(moveToKey val (btnode val ptr0 le true First Last pn) key c = (n,ii)::c).
      { rewrite moveToKey_equation. simpl. fold n. fold ii. auto. }
      rename H4 into H13. rewrite H13. rewrite Zlength_cons.
      rewrite Zsuccminusone. autorewrite with sublist. rewrite upd_Znth0. rewrite upd_Znth0. simpl.
      rewrite <- app_assoc. rewrite <- app_assoc. simpl. cancel.
      apply derives_refl.
  - forward_call(n,key).     (* t'2=findChildIndex(node,key) *)
    + rewrite unfold_btnode_rep with (n:=n). unfold n. Exists ent_end.
      cancel. change_compspecs CompSpecs. cancel.
    + split3.
      * unfold n. simpl. rewrite H4. auto.
      * unfold root_integrity in H0. unfold get_root in H0. simpl in H0. apply H0 in SUBNODE. auto.
      * unfold root_wf in H3. unfold get_root in H3. simpl in H3. apply H3 in SUBNODE. auto.
    + forward.                  (* cursor->ancestors[level]=i *)
      pose (i:=findChildIndex n key). fold i.
      gather_SEP 1 2. replace_SEP 0 (cursor_rep ((n,i)::c) r pc).
      { entailer!. unfold cursor_rep. unfold r.
      Exists (sublist 1 (Zlength anc_end) anc_end). Exists (sublist 1 (Zlength idx_end) idx_end).
      entailer!. autorewrite with sublist. rewrite upd_Znth0. rewrite upd_Znth0. simpl.
      rewrite <- app_assoc. rewrite <- app_assoc. simpl. rewrite Zsuccminusone.
      cancel. apply derives_refl. }
{    forward_if (EX child:node val, PROP (nth_node i n = Some child)
     LOCAL (temp _i (Vint(Int.repr(rep_index i))); temp _t'3 (Val.of_bool isLeaf); temp _cursor pc; temp _child (getval child);
     temp _node pn; temp _key (key_repr key); temp _level (Vint (Int.repr (Zlength c))))
     SEP (cursor_rep ((n, i) :: c) r pc; btnode_rep n; malloc_token Tsh trelation prel;
     data_at Tsh trelation
       (getval root, (Vint (Int.repr (Z.of_nat (numrec))), Vint (Int.repr (Z.of_nat (get_depth r))))) prel;
     btnode_rep (btnode val ptr0 le isLeaf First Last pn) -* btnode_rep root))%assert.
     - rewrite unfold_btnode_rep with (n:=n). unfold n.
        destruct ptr0 eqn:HPTR0.
        + destruct n0 as [ptr00 le0 isLeaf0 F0 L0 x0]. Intros ent_end0.
        forward.                (* child=node->ptr0 *)
        Exists (btnode val ptr00 le0 isLeaf0 F0 L0 x0).
        entailer!.
          * destruct i eqn:HI.
            { auto. } exfalso. simpl in H5.
            unfold root_wf in H3. simpl in H3.
            apply H3 in SUBNODE. unfold node_wf in SUBNODE.
            assert (-1 <= idx_to_Z(findChildIndex n key) < Z.of_nat (numKeys n)) by apply FCI_inrange.
            fold i in H4. rewrite HI in H4. simpl in H4. simpl in SUBNODE.
            assert(Z.of_nat n0 < Z.of_nat Fanout) by omega.
            clear -H5 H15. apply (f_equal Int.unsigned) in H5. rewrite Fanout_eq in H15.
            simpl in H15. autorewrite with norm in H5. rewrite H5 in H15. compute in H15.
            inv H15.
          * fold n. cancel.
            rewrite unfold_btnode_rep with (n:=n). unfold n. Exists ent_end0. simpl. cancel.
        + unfold root_integrity in H0. unfold get_root in H0. simpl in H0.
          apply H0 in SUBNODE. unfold n in SUBNODE. rewrite H4 in SUBNODE. inv SUBNODE.
     - rewrite unfold_btnode_rep. unfold n. Intros ent_end0.
       fold n.
       destruct i as [|ii] eqn:HI.
       { simpl in H5. contradiction. } simpl.       
       assert(RANGE: (ii < numKeys_le le)%nat).
       { assert(-1 <= idx_to_Z (findChildIndex n key) < Z.of_nat (numKeys n)) by apply FCI_inrange.
         fold i in H6. rewrite HI in H6. simpl in H6. omega. }
       assert(NTHENTRY: (ii < numKeys_le le)%nat) by auto.
       apply nth_entry_le_in_range in NTHENTRY. destruct NTHENTRY as [e NTHENTRY].
       assert(ZNTH: nth_entry_le ii le = Some e) by auto.
       eapply Znth_to_list with (endle:=ent_end0) in ZNTH.
       destruct e as [k v x|k child].
       { unfold root_integrity in H0. apply H0 in SUBNODE. unfold n in SUBNODE.
         rewrite H4 in SUBNODE. simpl in SUBNODE.
         destruct ptr0. exfalso. eapply intern_no_keyval; eauto. contradiction. }
       forward.                 (* child=node->entries + i ->ptr.child *)
       { entailer!. split. omega.
         unfold root_wf in H3. apply H3 in SUBNODE. unfold node_wf in SUBNODE. simpl in SUBNODE.
         rep_omega. }
       {
         gather_SEP 1 2 3 4. replace_SEP 0 (btnode_rep n).
         { entailer!. rewrite unfold_btnode_rep with (n:=n). Exists ent_end0. cancel. }
         gather_SEP 0 4. replace_SEP 0 (btnode_rep root).
         { entailer!. apply wand_frame_elim. }
         assert(SUBCHILD: subnode child root).
         { eapply sub_trans with (n1:=n). unfold n.
           apply sub_child. apply nth_entry_child in NTHENTRY. eapply nth_subchild. eauto.
           auto. }
         apply subnode_rep in SUBCHILD. rewrite SUBCHILD. rewrite ZNTH. entailer!. }
       rewrite ZNTH. Exists child.
       entailer!.
       eapply nth_entry_child. eauto.
       fold n. cancel. rewrite unfold_btnode_rep with (n:=n).
       unfold n. Exists ent_end0. entailer!.       
     - Intros child.
       gather_SEP 1 4. replace_SEP 0 (btnode_rep root).
       { entailer!. apply wand_frame_elim. }
       gather_SEP 0 2 3. replace_SEP 0 (relation_rep r numrec).
       { entailer!. apply derives_refl. }
       forward_call(child,key,(n,i)::c,pc,r,numrec). (* recursive call *)
       + entailer!. rewrite Zlength_cons.
         repeat apply f_equal. rep_omega.
       + eapply derives_trans. eapply cursor_subcursor_rep. cancel.
       + split3.
         * unfold partial_cursor in H. destruct H. unfold partial_cursor. split; auto.
           unfold get_root in H2. simpl in H2. fold n in H2.
           eapply partial_correct_append; eauto.
         * auto.
         * split. auto. split; auto.
       + forward.            (* return: 3.6minutes *)
         cancel.
         assert((moveToKey val child key ((n, i) :: c)) =  (moveToKey val (btnode val ptr0 le false First Last pn) key c)).
         { rewrite moveToKey_equation with (c:=c).
           fold n. fold i. rewrite H5. auto. }
         rewrite H4. apply derives_refl. }
Qed.