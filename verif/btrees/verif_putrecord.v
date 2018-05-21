(** * verif_putrecord.v : Correctness proof of putEntry and RL_PutRecord *)

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
Require Import verif_newnode.
Require Import verif_movetokey.
Require Import verif_currnode.
Require Import verif_entryindex.
Require Import verif_splitnode.

(* integrity of a new root *)
Lemma cons_integrity: forall r childe ke vnewnode,
    root_integrity r ->
    root_integrity childe ->
    root_integrity (btnode val (Some r) (cons val (keychild val ke childe) (nil val)) false true true vnewnode).
Proof.
  intros.
  unfold root_integrity. intros.
  inversion H1.                 (* induction? *)
  - simpl. apply ileo.
  - apply H. apply sub_refl.
  - inv H4. apply H0. apply sub_refl. inv H12.
  - subst. admit.
Admitted.

(* well_formedness of a new root *)
Lemma cons_wf: forall r childe ke vnewnode,
    root_wf r ->
    root_wf childe ->
    root_wf (btnode val (Some r) (cons val (keychild val ke childe) (nil val)) false true true vnewnode).
Proof.
  intros.
  unfold root_wf. intros.
  inversion H1.                 (* induction? *)
  - simpl. unfold node_wf. simpl. rewrite Fanout_eq. omega.
  - apply H. apply sub_refl.
  - inv H4. apply H0. apply sub_refl. inv H12.
  - subst. admit.
Admitted.

Lemma body_putEntry: semax_body Vprog Gprog f_putEntry putEntry_spec.
Proof.
  start_function.
  unfold cursor_rep. Intros anc_end. Intros idx_end.
  destruct r as [root prel]. pose (r:=(root,prel)).
  forward.                      (* t'44=cursor->level *)
  forward_if.                   (* if t'44=-1 *)
  (* split root case *)
  - assert(c=[]).
    { apply (f_equal Int.signed) in H6. apply partial_complete_length' in H.
      assert(Zlength c - 1 < 20) by omega.
      autorewrite with norm in H6. destruct c. auto. rewrite Zlength_cons in H6.
      rewrite Zsuccminusone in H6. rep_omega. unfold correct_depth. omega. } subst c.
    destruct H. { exfalso. inv H. inv H7. }
    assert(HE: exists ke childe, e = keychild val ke childe).
    { simpl in H3. destruct e. simpl in H3. inv H3. exists k. exists n. auto. }
    destruct HE as [ke [childe HE]].
    assert_PROP(isptr (getval childe)).
    { rewrite HE. simpl entry_rep. entailer!. } rename H7 into ISPTRC.      
      
    forward_call(false,true,true). (* t'1=createnewnode(false,true,true) *)
    Intros vnewnode.
    assert_PROP(isptr vnewnode).
    entailer!. rename H7 into ISPTRV.
    gather_SEP 1 2. replace_SEP 0 (cursor_rep [] r pc).
    { entailer!. unfold cursor_rep. Exists anc_end. Exists idx_end. unfold r. cancel.
      change_compspecs CompSpecs. cancel. } clear anc_end. clear idx_end.
    forward_if(PROP (vnewnode <> nullval) LOCAL (temp _currNode__1 vnewnode; temp _t'44 (Vint (Int.repr (-1))); temp _cursor pc; temp _newEntry pe; temp _key (key_repr oldk)) SEP (cursor_rep [] r pc; btnode_rep (empty_node false true true vnewnode); relation_rep (root, prel) (get_numrec(root,prel) + entry_numrec e - 1); entry_rep e; data_at Tsh tentry (entry_val_rep e) pe)).
    + apply denote_tc_test_eq_split.
      replace (vnewnode) with (getval (empty_node false true true vnewnode)). entailer!.
      simpl. auto.
      entailer!.
    + forward.                  (* skip *)
      entailer!.
    + assert_PROP(False). unfold empty_node. entailer!. contradiction.
    + unfold cursor_rep. Intros anc_end. Intros idx_end. unfold r.
      forward.                  (* t'52=cursor->relation *)
      unfold relation_rep. Intros.
      assert_PROP(isptr (getval root)). { entailer!. } rename H8 into ISPTRR.
      forward.                  (* t'53=t'52->root *)
      unfold empty_node.
      rewrite unfold_btnode_rep. Intros ent_end. simpl.
      assert_PROP(Zlength ent_end = Z.of_nat Fanout).
      { entailer!. simplify_value_fits in H14.
        destruct H14, H20, H21, H22, H23.
        (* Set Printing Implicit.  *) clear -H24.
        assert(value_fits (tarray tentry 15) ent_end). auto.
        simplify_value_fits in H. destruct H.
        simpl in H. Check (reptype tentry). admit. }
        (* assert(reptype tentry = val * (val + val)). *)
        (* change_compspecs btrees.CompSpecs. auto. *)
        (* simplify_value_fits in H24. destruct H24. *)
        

        (* apply value_fits_JMeq with (t:=(Tstruct _Entry noattr)) in H24. *)

        (* (@reptype btrees.CompSpecs (Tstruct _Entry noattr)) *)
        (* simplify_value_fits in H24. destruct H24. *)
        (* apply value_fits_JMeq with (t:=) in H24. simplify_value_fits in H24. destruct H24.  *)
        (* rewrite Fanout_eq. rewrite H24. simpl. auto. } *)
      rename H8 into HENTEND.
      forward.                  (* currnode1->ptr0=t'53 *)
      forward.                  (* currnode1->numKeys=1 *)
      subst e. simpl.
      forward.                  (* t'53=newEntry->key *)
      Opaque Znth.
      forward.                  (* currNode_1->entries[O] -> key = t'53 *)
      forward.                  (* t'52 = newEntry->ptr.child *)
      forward.                  (* currnode_1->entries[0].ptr.child = t'52 *)
      forward.                  (* t'51 = cursor->relation. *)
      forward.                  (* t'51->root=currnode_1 *)
      forward.                  (* t'48=cursor->relation *)
      forward.                  (* t'49=cursor->relation *)
      forward.                  (* t'50=t'49->depth *)
      forward.                  (* t'48->depth=t'50+1 *)
      forward.                  (* t'45=cursor->relation *)
      forward.                  (* t'46=cursor->relation *)
      forward.                  (* t'47=t'46->numRecords *)
      forward.                  (* t'45->numRecords=t'47+1 *)
      forward.                  (* cursor->ancestors[0]=currnode_1 *)
      deadvars!.
      pose (newroot:= btnode val
                             (Some root)
                             (cons val (keychild val ke childe) (nil val))
                             false
                             true
                             true
                             vnewnode).
      forward_call(newroot,oldk,([]:cursor val),pc,(newroot,prel), (get_numrec (root,prel) + node_numrec childe - 1 + 1)%nat). (* movetoKey(currnode_1,key,cursor,0 *)
      unfold relation_rep. unfold newroot. simpl. fold newroot.
      * rewrite upd_Znth_same. rewrite upd_Znth_twice.
        apply force_val_sem_cast_neutral_isptr in ISPTRV.
        assert(force_val(sem_cast_pointer vnewnode) = vnewnode).
        { inversion ISPTRV. rewrite H9. auto. }
        assert(Vint (Int.add (Int.repr (Z.of_nat (get_numrec (root, prel) + node_numrec childe - 1))) (Int.repr 1)) = Vint (Int.repr (Z.of_nat (get_numrec (root, prel) + node_numrec childe - 1 + 1)))).        
        { rewrite add_repr. apply f_equal. apply f_equal.
          rewrite Nat2Z.inj_add. simpl. auto. }
        assert(Vint (Int.add (Int.repr (Z.of_nat (get_depth (root, prel)))) (Int.repr 1)) = Vint (Int.repr (Z.pos (Pos.of_succ_nat (index.max_nat (node_depth childe) (node_depth root)))))).
        { rewrite add_repr. repeat apply f_equal. rewrite Zpos_P_of_succ_nat.
          unfold get_depth. simpl. simpl in H3. inversion H3. rewrite index.max_refl. omega. }
        rewrite H8. rewrite H9. rewrite H10.
        cancel.
        unfold subcursor_rep.
        Exists (upd_Znth 0 anc_end vnewnode).
        Exists idx_end. Exists (-1).
        simpl. cancel. rewrite unfold_btnode_rep with (n:=newroot). unfold newroot.
        Exists (sublist 1 (Zlength ent_end) ent_end).
        simpl.
        assert(force_val(sem_cast_pointer(getval root)) = getval root).
        { apply force_val_sem_cast_neutral_isptr in ISPTRR. inversion ISPTRR. rewrite H12. auto. }
        assert(force_val(sem_cast_pointer(getval childe)) = getval childe).
        { apply force_val_sem_cast_neutral_isptr in ISPTRC. inversion ISPTRC. rewrite H13. auto. }
        rewrite H11. rewrite H12. rewrite upd_Znth0. cancel. change_compspecs CompSpecs. cancel.
        rewrite HENTEND. rewrite Fanout_eq. simpl. omega.
        rewrite HENTEND. rewrite Fanout_eq. simpl. omega.
      * split. auto. split. apply cons_integrity. auto. simpl in H4. auto.
        split. unfold correct_depth.
        assert(get_depth (newroot,prel)= node_depth newroot). unfold get_depth. simpl. auto. rewrite H8.
        assert(get_depth (root,prel) = node_depth root). unfold get_depth. simpl. auto.
        rewrite H9 in H0.
        simpl. simpl in H3. apply eq_add_S in H3. rewrite H3. rewrite index.max_refl. auto.
        simpl. split. auto. apply cons_wf. auto. simpl in H2. auto.
      * forward.                (* return *)
        Exists ([vnewnode]:list val). entailer!.
        destruct (putEntry val [] (root,prel) (keychild val ke childe) oldk [] nullval) as [newc newr] eqn:HNEW.
        unfold relation_rep.
        rewrite putEntry_equation. simpl. fold newroot.
        assert((Vint (Int.repr (Z.of_nat (get_numrec (root, prel) + node_numrec childe - 1 + 1)))) = 
               Vint (Int.repr (Z.of_nat (get_numrec (newroot, prel))))).
        { repeat apply f_equal. unfold newroot. unfold get_numrec. simpl.
          admit.                (* at least one record *)
        } rewrite H14. cancel. 
  - forward.                    (* skip *)
    destruct c as [|[currnode entryidx] c'] eqn:HC.
    { simpl in H0. exfalso. apply H6. rewrite Int.neg_repr. auto. }
    forward_call(r,c,pc,(get_numrec (root, prel) + entry_numrec e - 1)%nat).       (* t'26=currnode(cursor) *)
    { unfold r. unfold cursor_rep. Exists anc_end. Exists idx_end. cancel. change_compspecs CompSpecs.
      cancel. rewrite HC. simpl. cancel. change_compspecs CompSpecs. cancel. }
    { rewrite HC. unfold r. split.
      destruct H. right. auto. left. unfold ne_partial_cursor.
      destruct H. split; auto. split; auto. simpl. omega.
      unfold correct_depth. omega. }
    rewrite HC. simpl.
    assert(SUBNODE: subnode currnode root).
    { destruct H. destruct H. apply complete_cursor_subnode in H. simpl in H. auto.
      destruct H. apply partial_cursor_subnode in H. simpl in H. auto. }
    assert(SUBREP: subnode currnode root) by auto.
    apply subnode_rep in SUBREP.
    destruct currnode as [ptr0 le isLeaf First Last x].
    pose(currnode := btnode val ptr0 le isLeaf First Last x). simpl.
    rewrite SUBREP. fold currnode.
    rewrite unfold_btnode_rep with (n:=currnode) at 1. unfold currnode. Intros ent_end.
    forward.                    (* t'27=t'26->isLeaf *)
    { destruct isLeaf; entailer!. }
    admit.
Admitted.

Lemma gotokey_complete: forall c r key,
    complete_cursor c r ->
    complete_cursor (goToKey c r key) r.
Proof.
Admitted.

Lemma putentry_complete: forall c r e oldk newx d newc newr,
    complete_cursor c r ->
    putEntry val c r e oldk newx d = (newc, newr) ->
    complete_cursor newc newr.
Proof.
Admitted.

Lemma putentry_depth: forall c r e oldk newx d newc newr,
    complete_cursor c r ->
    correct_depth r ->
    putEntry val c r e oldk newx d = (newc, newr) ->
    correct_depth newr.
Proof.
Admitted.

Lemma putentry_wf: forall c r e oldk newx d newc newr,
    complete_cursor c r ->
    root_wf (get_root r) ->
    putEntry val c r e oldk newx d = (newc, newr) ->
    root_wf (get_root newr).
Proof.
Admitted.

Lemma putentry_integrity: forall c r e oldk newx d newc newr,
    complete_cursor c r ->
    root_integrity (get_root r) ->
    putEntry val c r e oldk newx d = (newc, newr) ->
    root_integrity (get_root newr).
Proof.
Admitted.

Lemma putentry_numrec: forall c r e oldk newx d newc newr,
    complete_cursor c r ->
    Z.of_nat(get_numrec r) < Int.max_signed - 1 ->
    putEntry val c r e oldk newx d = (newc, newr) ->
    Z.of_nat(get_numrec newr) < Int.max_signed.
Proof.
Admitted.

Lemma body_RL_PutRecord: semax_body Vprog Gprog f_RL_PutRecord RL_PutRecord_spec.
Proof.
  start_function.
  forward_if(PROP (pc <> nullval)
     LOCAL (lvar _newEntry (Tstruct _Entry noattr) v_newEntry; temp _cursor pc;
     temp _key (key_repr key); temp _record (value_repr record))
     SEP (data_at_ Tsh (Tstruct _Entry noattr) v_newEntry; relation_rep r (get_numrec r); cursor_rep c r pc)).
  - forward.                    (* skip *)
    entailer!.
  - assert_PROP(False). entailer!. contradiction.
  - fold tentry.
    forward.                    (* newentry.ptr.record=record *)
    forward.                    (* newentry.key=key *)
    forward_call(c,pc,r,key,get_numrec r).   (* gotokey(cursor,key) *)
    admit.
    forward_call((goToKey c r key),pc,r,(keyval val key record (field_address tentry [UnionField _record; StructField _ptr] v_newEntry)), v_newEntry, key). (* putEntry(cursor,newEntry,key *)
    + unfold entry_rep, value_rep, value_repr.
      unfold_data_at 1%nat.
      erewrite field_at_Tunion with (t:=tentry) (gfs:=[StructField _ptr]) (v1:=(inr(Vint(Int.repr(v_ record))))) (p:=v_newEntry).
      2:reflexivity. 2:apply JMeq_refl.
      simpl. unfold withspacer. rewrite if_true by omega.
      replace((get_numrec r + 1 - 1)%nat) with (get_numrec r) by omega. cancel.
      rewrite field_at_data_at with (gfs:=[UnionField _record; StructField _ptr]).
      simpl. cancel. unfold_data_at 1%nat. cancel.
      simpl. admit.
    + split3; auto. left. apply gotokey_complete. auto.
      split3; auto. simpl. unfold cursor_depth.
      admit.
    + Intros newx.
      destruct(putEntry val (goToKey c r key) r) as [newc newr] eqn:HPUTENTRY.
Admitted.
(*       forward_call(newc,pc,newr,get_numrec newr). (* RL_MoveToNext(cursor) *) *)
(*       * cancel. *)
(*       * apply gotokey_complete with (key:=key) in H. *)
(*         split3. *)
(*         eapply putentry_complete. eauto. eauto. *)
(*         eapply putentry_depth. eauto. eauto. eauto. *)
(*         split3. *)
(*         eapply putentry_wf. eauto. auto. eauto. *)
(*         eapply putentry_integrity. eauto. auto. eauto. *)
(*         eapply putentry_numrec. eauto. auto. eauto. *)
(*       * forward.                (* return *) *)
(*         Exists newx. *)
(*         Exists((field_address tentry [UnionField _record; StructField _ptr] v_newEntry)). *)
(*         entailer!. unfold RL_PutRecord. *)
(*         rewrite HPUTENTRY. *)
(*         cancel. fold tentry. unfold value_rep. *)
(*         eapply derives_trans. *)
(*         2:eapply data_at_data_at_ with (v:=(key_repr key, inr (value_repr record))). *)
(*         unfold_data_at 2%nat. *)
(*         erewrite field_at_Tunion with (t:=tentry) (gfs:=[StructField _ptr]) (v1:=(inr(Vint(Int.repr(v_ record))))) (p:=v_newEntry). *)
(*         2: reflexivity. 2: apply JMeq_refl. *)
(*         simpl. unfold withspacer. rewrite if_true by omega. cancel. *)
(*         rewrite field_at_data_at. simpl. cancel. *)
(* Qed. *)