(** * verif_splitnode.v : Correctness proof of splitnode *)

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
Require Import verif_findindex.
Require Import index.

Lemma upd_Znth_twice: forall (A:Type) l i (x:A) x',
          0 <= i < Zlength l -> 
          upd_Znth i (upd_Znth i l x) x' = upd_Znth i l x'.
Proof.
  intros.
  unfold upd_Znth. rewrite sublist0_app1. rewrite sublist_app2.
  rewrite semax_lemmas.cons_app with (x:=x).
  rewrite sublist_app2. rewrite Zlength_sublist. rewrite Zlength_cons. simpl.
  replace (i + 1 - (i - 0) - 1) with 0 by omega.
  rewrite sublist_same with (al:=(sublist (i + 1) (Zlength l) l)).
  rewrite sublist_same. auto.
  auto. rewrite Zlength_sublist. omega. omega. omega. auto.
  rewrite Zlength_sublist. rewrite Zlength_app. rewrite Zlength_sublist.
  rewrite Zlength_cons. rewrite Zlength_sublist. omega.
  omega. omega. omega. omega. omega. omega. omega. omega.
  rewrite Zlength_cons. rewrite Zlength_sublist. simpl. omega.
  omega. omega. rewrite Zlength_sublist. omega. omega. omega.
  rewrite Zlength_sublist. omega. omega. omega.
Qed.

Lemma nth_first_sublist: forall le i,
    le_to_list (nth_first_le le (Z.to_nat i)) = sublist 0 i (le_to_list le).
Proof.
Admitted.

Lemma key_repr_k: forall key1 key2,
    key_repr key1 = key_repr key2 ->
    k_ key1 = k_ key2.
Proof.
  intros. unfold key_repr in H.
Admitted.


Lemma FRI_next: forall X (le:listentry X) key i,
    next_index(findRecordIndex' le key i) = findRecordIndex' le key (next_index i).
Proof.
  intros.
  generalize dependent i.
  induction le; intros.
  - simpl. auto.
  - simpl. destruct e.
    + destruct (k_ key <=? k_ k). auto. rewrite IHle. auto.
    + destruct (k_ key <=? k_ k). auto. rewrite IHle. auto.
Qed.

Lemma FRI_repr: forall X (le:listentry X) key1 key2 i,
    key_repr key1 = key_repr key2 ->
    findRecordIndex' le key1 i = findRecordIndex' le key2 i.
Proof.
  intros. generalize dependent i. induction le; intros.
  - simpl. auto.
  - simpl. destruct e.
    + rewrite IHle. rewrite key_repr_k with (key2:=key2) by auto. auto.
    + rewrite IHle. rewrite key_repr_k with (key2:=key2) by auto. auto.
Qed.

Lemma insert_fri: forall X (le:listentry X) e fri key,
    key = entry_key e ->
    ip fri = findRecordIndex' le key (ip O) ->
    insert_le le e = le_app (nth_first_le le fri) (cons X e (skipn_le le fri)).
Proof.
  intros. generalize dependent fri.
  induction le; intros.
  - simpl. destruct fri; simpl; auto.
  - destruct fri.
    + simpl. simpl in H0.
      destruct e0.
      * rewrite <- H. simpl.
        destruct (k_ key <=? k_ k). auto.
        assert(idx_to_Z (ip 1) <= idx_to_Z(findRecordIndex' le key (ip 1))) by apply FRI_increase.
        rewrite <- H0 in H1. simpl in H1. omega.
      * rewrite <- H. simpl.
        destruct (k_ key <=? k_ k). auto.
        assert(idx_to_Z (ip 1) <= idx_to_Z(findRecordIndex' le key (ip 1))) by apply FRI_increase.
        rewrite <- H0 in H1. simpl in H1. omega.
    + simpl. simpl in H0.
      destruct e0.
      * rewrite <- H. simpl.
        destruct (k_ key <=? k_ k). inv H0.
        rewrite <- IHle. auto. replace (ip 1) with (next_index (ip O)) in H0 by (simpl; auto).
        rewrite <- FRI_next in H0.
        destruct (findRecordIndex' le key (ip 0)).
        simpl in H0. inv H0. simpl in H0. inv H0. auto.
      * rewrite <- H. simpl.
        destruct (k_ key <=? k_ k). inv H0.
        rewrite <- IHle. auto. replace (ip 1) with (next_index (ip O)) in H0 by (simpl; auto).
        rewrite <- FRI_next in H0.
        destruct (findRecordIndex' le key (ip 0)).
        simpl in H0. inv H0. simpl in H0. inv H0. auto.
Qed.

Lemma suble_skip: forall X (le:listentry X) i f,
    f = numKeys_le le ->
    suble i f le = skipn_le le i.
Proof.
  intros. generalize dependent f. generalize dependent i.
  destruct le; intros.
  - simpl. destruct i. simpl in H. rewrite H. rewrite suble_nil. auto.
    simpl in H. rewrite H. rewrite suble_nil'. auto. omega.
  - destruct f. inv H. simpl in H. inversion H.
    simpl. destruct i.
    + unfold suble. simpl. rewrite nth_first_same. auto. auto.
    + unfold suble. simpl. rewrite nth_first_same. auto.
      rewrite numKeys_le_skipn. auto.
Qed.

Lemma nth_first_le_app1: forall X (l1:listentry X) l2 i,
    (i <= numKeys_le l1)%nat ->
    nth_first_le (le_app l1 l2) i = nth_first_le l1 i.
Proof.
  intros. generalize dependent i. induction l1; intros.
  - simpl. simpl in H. destruct i. simpl. auto. omega.
  - destruct i.
    + simpl. auto.
    + simpl. rewrite IHl1. auto.
      simpl in H. omega.
Qed.

Lemma le_split: forall X (le:listentry X) i,
    (i <= numKeys_le le)%nat ->
    le = le_app (nth_first_le le i) (skipn_le le i).
Proof.
  intros. generalize dependent i. induction le; intros.
  - destruct i; simpl; auto.
  - simpl. destruct i.
    + simpl. auto.
    + simpl. rewrite <- IHle with (i:=i). auto. simpl in H. omega.
Qed.

Lemma insert_rep: forall le (e:entry val),
    le_iter_sepcon le * entry_rep e = le_iter_sepcon (insert_le le e).
Proof.
  intros.
  induction le.
  - apply pred_ext.
    + simpl. entailer!.
    + simpl. entailer!.
  - apply pred_ext.
    + simpl. destruct (k_ (entry_key e) <=? k_ (entry_key e0)).
      * simpl. entailer!.
      * simpl. rewrite <- IHle. entailer!.
    + simpl. destruct (k_ (entry_key e) <=? k_ (entry_key e0)).
      * simpl. entailer!.
      * simpl. rewrite <- IHle. entailer!.
Qed.

Lemma le_iter_sepcon_app: forall le1 le2,
    le_iter_sepcon (le_app le1 le2) = le_iter_sepcon le1 * le_iter_sepcon le2.
Proof.
  intros. induction le1.
  - simpl. apply pred_ext; entailer!.
  - simpl. rewrite IHle1. apply pred_ext; entailer!.
Qed.

Lemma nth_first_insert: forall X (le:listentry X) e k m,
    k = entry_key e ->
    Z.of_nat m <= idx_to_Z (findRecordIndex' le k (ip O)) ->
    nth_first_le (insert_le le e) m = nth_first_le le m.
Proof.
  intros. generalize dependent m. induction le; intros.
  - simpl in H0. destruct m. simpl. auto. rewrite Z2Nat.inj_le in H0.
    rewrite Nat2Z.id in H0. simpl in H0. omega.
    omega. omega.
  - simpl. simpl in H0. rewrite <- H. destruct e0.
    + simpl. destruct (k_ k <=? k_ k0).
      * destruct m. simpl. auto. rewrite Z2Nat.inj_le in H0.
        rewrite Nat2Z.id in H0. simpl in H0. omega.
        omega. omega.
      * destruct m. simpl. auto. simpl.
        rewrite IHle. auto. replace (ip 1) with (next_index(ip O)) in H0.
        rewrite <- FRI_next in H0. rewrite next_idx_to_Z in H0.
        rewrite Nat2Z.inj_succ in H0. omega.
        simpl. auto.
    + simpl. destruct (k_ k <=? k_ k0).
      * destruct m. simpl. auto. rewrite Z2Nat.inj_le in H0.
        rewrite Nat2Z.id in H0. simpl in H0. omega.
        omega. omega.
      * destruct m. simpl. auto. simpl.
        rewrite IHle. auto. replace (ip 1) with (next_index(ip O)) in H0.
        rewrite <- FRI_next in H0. rewrite next_idx_to_Z in H0.
        rewrite Nat2Z.inj_succ in H0. omega.
        simpl. auto.
Qed.

Lemma body_splitnode: semax_body Vprog Gprog f_splitnode splitnode_spec.
Proof.
  start_function.
  rename H1 into LEAFENTRY.
  destruct n as [ptr0 le isLeaf First Last nval].
  pose(n:=btnode val ptr0 le isLeaf First Last nval).
  destruct(entry_val_rep e) as [keyrepr coprepr] eqn:HEVR.
  assert(exists k, keyrepr = key_repr k).
  { destruct e; exists k; simpl; simpl in HEVR; inv HEVR; auto. }
  destruct H1 as [k HK].
  forward.                      (* t'28=entry->key *)
  forward_call(n,k).            (* t'1=findrecordindex(node,t'28) *)
  { fold n. cancel. }
  { split; auto. unfold node_wf. fold n in H0. omega. }
  forward.                      (* tgtIdx=t'1 *)
  assert(INRANGE: 0 <= index.idx_to_Z (findRecordIndex n k) <= Z.of_nat (numKeys n)) by apply FRI_inrange.
  fold n in H0. rewrite H0 in INRANGE.
  rewrite unfold_btnode_rep. unfold n. Intros ent_end.
  forward.                      (* t'27=node->Last *)
  { destruct Last; entailer!. }
  forward_call(isLeaf, false, Last). (* t'2=createNewNode(isLeaf,0,t'27 *)
  Intros vnewnode.
  forward.                      (* newnode=t'2 *)
  gather_SEP 1 2 3 4.
  replace_SEP 0 (btnode_rep n).
  { entailer!. rewrite unfold_btnode_rep with (n:=n). unfold n. Exists ent_end. cancel.
    change_compspecs CompSpecs. cancel. } clear ent_end.
  forward_if(PROP (vnewnode<>nullval)
     LOCAL (temp _newNode vnewnode; temp _t'2 vnewnode; temp _t'27 (Val.of_bool Last);
     temp _tgtIdx (Vint (Int.repr (rep_index (findRecordIndex' le k (index.ip 0)))));
     temp _t'1 (Vint (Int.repr (rep_index (findRecordIndex' le k (index.ip 0))))); 
     temp _t'28 keyrepr; lvar _allEntries (tarray (Tstruct _Entry noattr) 16) v_allEntries;
     temp _node nval; temp _entry pe; temp _isLeaf (Val.of_bool isLeaf))
     SEP (btnode_rep n; btnode_rep (empty_node isLeaf false Last vnewnode);
     data_at_ Tsh (tarray (Tstruct _Entry noattr) 16) v_allEntries; entry_rep e;
     data_at Tsh tentry (keyrepr, coprepr) pe)).
  { apply denote_tc_test_eq_split. replace vnewnode with (getval (empty_node isLeaf false Last vnewnode)).
    entailer!. simpl. auto. entailer!. }
  { forward.                    (* skip *)
    entailer!. }
  { assert_PROP(False). entailer!. contradiction. }
  rewrite unfold_btnode_rep with (n:=n). unfold n. Intros ent_end.
  forward.                      (* node->Last = 0 *)
  forward.                      (* t'3=node->isLeaf *)

  forward_if.

  -                             (* Leaf Node *)
    assert(LEAF: isLeaf=true).
    { destruct isLeaf; auto. simpl in H2. inv H2. }
    destruct (findRecordIndex n k) as [|fri] eqn:HFRI.
    { simpl in INRANGE. omega. }
    replace (findRecordIndex' le k (index.ip 0)) with (index.ip fri). simpl.
    gather_SEP 0 1 2 3.
    pose (nleft := btnode val ptr0 le true First false nval).
    replace_SEP 0 (btnode_rep nleft).
    { entailer!. rewrite unfold_btnode_rep with (n:=nleft). unfold nleft.
      Exists ent_end. cancel. } clear ent_end. fold tentry.
    assert(ENTRY: exists ke ve xe, e = keyval val ke ve xe). (* the entry to be inserted at a leaf must be keyval *)
    { destruct e. eauto. simpl in LEAFENTRY.
      rewrite LEAF in LEAFENTRY. exfalso. rewrite LEAFENTRY. auto. }
    destruct ENTRY as [ke [ve [xe ENTRY]]].
    
    forward_for_simple_bound (Z.of_nat fri)
    (EX i:Z, EX allent_end:list (val*(val+val)),
     (PROP (length allent_end = (Fanout + 1 - Z.to_nat(i))%nat)
      LOCAL (temp _t'3 (Val.of_bool isLeaf); temp _newNode vnewnode; temp _t'2 vnewnode;
      temp _t'27 (Val.of_bool Last); temp _tgtIdx (Vint (Int.repr (Z.of_nat fri)));
      temp _t'1 (Vint (Int.repr (Z.of_nat fri))); temp _t'28 keyrepr;
      lvar _allEntries (tarray tentry 16) v_allEntries; temp _node nval; temp _entry pe;
      temp _isLeaf (Val.of_bool isLeaf))
      SEP (btnode_rep nleft; btnode_rep (empty_node isLeaf false Last vnewnode);
           data_at Tsh (tarray tentry 16) (le_to_list (nth_first_le le (Z.to_nat i))++ allent_end) v_allEntries; entry_rep e; data_at Tsh tentry (keyrepr, coprepr) pe)))%assert.
    { simpl in INRANGE. rewrite Fanout_eq in INRANGE.
      replace (Z.of_nat 15) with 15 in INRANGE. rep_omega. simpl. auto. }
    { entailer!.
      Exists (default_val (nested_field_type (tarray (Tstruct _Entry noattr) 16) [])).
      entailer!. unfold data_at_, field_at_. entailer!. }
    {                           (* loop body *)
      rewrite unfold_btnode_rep with (n:=nleft). unfold nleft.
      Intros ent_end.
      assert(HENTRY: exists e, nth_entry_le (Z.to_nat i) le = Some e).
      { apply nth_entry_le_in_range. simpl in INRANGE. rewrite Fanout_eq in INRANGE.
        unfold n in H0. simpl in H0. rewrite H0. rep_omega. }
      destruct HENTRY as [ei HENTRY].
      assert (HEI: exists ki vi xi, ei = keyval val ki vi xi).
      { eapply integrity_nth_leaf. eauto. rewrite LEAF. simpl. auto. eauto. }
      destruct HEI as [ki [vi [xi HEI]]]. subst ei.
      assert_PROP(isptr xi).
      { apply le_iter_sepcon_split in HENTRY. rewrite HENTRY. simpl entry_rep. entailer!. }
      rename H5 into XIPTR.
      assert(HZNTH: forall ent_end, Znth (d:=(Vundef,inl Vundef)) i (le_to_list le ++ ent_end) = entry_val_rep (keyval val ki vi xi)).
      { intros. rewrite <- Z2Nat.id with (n:=i). apply Znth_to_list. auto. omega. }
      assert(HIRANGE: (0 <= i < 15)).
      { clear -INRANGE H3. simpl in INRANGE. rewrite Fanout_eq in INRANGE.
        replace (Z.of_nat 15) with 15 in INRANGE by auto. omega. }  
      forward.                  (* t'26 = node->entries[i].key *) 
      { entailer!. rewrite HZNTH. simpl; auto. }
      rewrite HZNTH. simpl.
      Opaque Znth.
      forward.                 (* allEntries[i].key = t'26 *)
      forward.                 (* t'25=node->entries[i]->ptr.record *)
      { rewrite HZNTH. entailer!. }
      rewrite HZNTH. simpl.
      forward.                  (* allEntries[i]->ptr.record=t'25 *)
      entailer!.
      assert(XEMP: Zlength x > 0).
      { destruct x. clear - H4 HIRANGE. simpl in H4. rewrite Fanout_eq in H4.
        apply eq_sym in H4. apply NPeano.Nat.sub_0_le in H4. apply inj_le in H4.
        replace (Z.of_nat (15 + 1)) with 16 in H4. rewrite Z2Nat.id in H4. rep_omega.
        omega. simpl. auto.
        rewrite Zlength_cons. rep_omega. }
      Exists (sublist 1 (Zlength x) x). entailer!.
      { clear -H4 H3 XEMP.
        destruct x.
        - rewrite Zlength_nil in XEMP. omega.
        - rewrite sublist_1_cons. rewrite Zlength_cons. rewrite Zsuccminusone.
          rewrite sublist_same by omega. simpl in H4. rewrite Z2Nat.inj_add by omega.
          simpl.
          assert((Fanout + 1 - Z.to_nat i)%nat = S(Fanout + 1 - (Z.to_nat i + 1))) by omega.
          rewrite H in H4. inv H4. omega. }
      assert(INUM: (Z.to_nat i <= numKeys_le le)%nat).
      { unfold n  in H0. simpl in H0. rewrite H0. clear -INRANGE H3.
        simpl in INRANGE. rep_omega. }
      rewrite unfold_btnode_rep with (n:=nleft). unfold nleft. Exists ent_end. cancel.      
      rewrite upd_Znth_twice.
      rewrite app_Znth2. rewrite le_to_list_length. rewrite numKeys_nth_first. rewrite Z2Nat.id.
      replace (i-i) with 0 by omega.
      rewrite upd_Znth_app2.
      rewrite le_to_list_length. rewrite numKeys_nth_first. rewrite Z2Nat.id.
      replace (i-i) with 0 by omega.
      rewrite upd_Znth_same.
      unfold upd_Znth. rewrite sublist_nil. simpl.
      rewrite nth_first_sublist. rewrite nth_first_sublist.
      rewrite sublist_split with (lo:=0) (mid:=i) (hi:=i+1).
      erewrite sublist_len_1. rewrite <- app_nil_r with (l:=le_to_list le). rewrite HZNTH. simpl.
      rewrite app_nil_r. rewrite <- app_assoc. simpl. cancel.
      rewrite le_to_list_length. unfold n in H0. simpl in H0. rewrite H0. rewrite Fanout_eq.
      replace (Z.of_nat 15) with 15. omega. simpl. auto. omega.
      rewrite le_to_list_length. unfold n in H0. simpl in H0. rewrite H0. rewrite Fanout_eq.
      replace (Z.of_nat 15) with 15. omega. simpl. auto.
      rewrite Zlength_app. rewrite le_to_list_length. rewrite numKeys_nth_first.
      rewrite Z2Nat.id. omega. 
      omega. omega.
      omega. omega.
      rewrite le_to_list_length. rewrite numKeys_nth_first.
      rewrite Z2Nat.id. omega.
      omega. omega.
      omega. omega.
      rewrite le_to_list_length. rewrite numKeys_nth_first. rewrite Z2Nat.id. omega. omega.
      omega.
      rewrite Zlength_app. rewrite le_to_list_length. rewrite numKeys_nth_first. rewrite Z2Nat.id.
      omega. omega. omega. }
    Intros allent_end.
    forward.                    (* t'24=entry->key *)
    rewrite HK. unfold key_repr.

    assert(FRIRANGE: (0 <= fri < 16)%nat).
    { simpl in INRANGE. rewrite Fanout_eq in INRANGE. split. omega.
      replace (Z.of_nat 15) with 15 in INRANGE.
      apply Nat2Z.inj_lt. destruct INRANGE. eapply Z.le_lt_trans with (m:=15). rep_omega.
      simpl. omega. simpl. auto. }
    rewrite ENTRY in HEVR. simpl in HEVR. inv HEVR.

    Opaque Znth.
    forward.                    (* allEntries[tgtIdx]->key = t'24 *)
    forward.                    (* t'23=entry->ptr.record *)
    forward.                    (* allEntries[tgtIdx]->ptr.record = t'23 *)
    assert(0 <= Z.of_nat fri < Zlength (le_to_list (nth_first_le le (Z.to_nat (Z.of_nat fri))) ++ allent_end)).
    { split. omega. rewrite Zlength_app. rewrite le_to_list_length.
      rewrite numKeys_nth_first. rewrite Z2Nat.id. rewrite Zlength_correct.
      rewrite H3. rewrite Nat2Z.id.
      assert(Z.of_nat(Fanout + 1 - fri) > 0).
      { rewrite Fanout_eq. simpl in INRANGE. rewrite Nat2Z.inj_sub.
        simpl. omega. rewrite Fanout_eq in INRANGE. simpl in INRANGE. omega. }
      omega. omega.
      rewrite Nat2Z.id. unfold n in H0. simpl in H0. rewrite H0. rewrite Fanout_eq. omega. }
    rewrite upd_Znth_twice by auto. rewrite upd_Znth_same by auto.
    deadvars!.
    assert(FRILENGTH: Zlength (le_to_list (nth_first_le le (Z.to_nat (Z.of_nat fri)))) = Z.of_nat fri).
    { rewrite le_to_list_length. rewrite numKeys_nth_first. rewrite Nat2Z.id. auto.
      rewrite Nat2Z.id. unfold n in H0. simpl in H0. rewrite H0. simpl in INRANGE. omega. }
    unfold upd_Znth. rewrite sublist_app1 by (try rep_omega; rewrite FRILENGTH; rep_omega).
    rewrite sublist_same by (try rep_omega; rewrite FRILENGTH; rep_omega).
    rewrite sublist_app2 by (rewrite FRILENGTH; rep_omega).
    repeat rewrite FRILENGTH.
    replace (Z.of_nat fri + 1 - Z.of_nat fri) with 1 by rep_omega. rewrite Zlength_app.
    rewrite FRILENGTH.
    replace (Z.of_nat fri + Zlength allent_end - Z.of_nat fri) with (Zlength allent_end) by rep_omega.

    forward_for_simple_bound (Z.of_nat(Fanout)) ( EX i:Z, EX ent_end:list (val * (val+val)), PROP(Z.of_nat fri <= i <= Z.of_nat Fanout; length ent_end = (Fanout - Z.to_nat(i))%nat) LOCAL(temp _newNode vnewnode; temp _tgtIdx (Vint (Int.repr (Z.of_nat fri))); lvar _allEntries (tarray tentry 16) v_allEntries; temp _node nval; temp _entry pe) SEP(btnode_rep nleft; btnode_rep (empty_node true false Last vnewnode);data_at Tsh tentry (Vint (Int.repr (k_ k)), inr xe) pe; data_at Tsh (tarray tentry 16) (le_to_list (nth_first_le le (Z.to_nat (Z.of_nat fri))) ++ (Vint (Int.repr (k_ k)), inr (force_val (sem_cast_pointer xe))) :: le_to_list(suble (fri) (Z.to_nat i) le) ++ ent_end) v_allEntries; entry_rep(keyval val ke ve xe)))%assert.

    { simpl in INRANGE. rewrite Fanout_eq in INRANGE.
      replace (Z.of_nat 15) with 15 in INRANGE.
      rewrite Fanout_eq. simpl. rep_omega. simpl. auto. }
    abbreviate_semax.
    {                           (* second loop *)
      forward.                  (* i=tgtidx *)
      Exists (Z.of_nat(fri)). Exists ( sublist 1 (Zlength allent_end) allent_end).
      entailer!.
      simpl in INRANGE. split3; try rep_omega.
      { clear -H3 INRANGE. destruct allent_end.
        - simpl in H3. rewrite Nat2Z.id in H3.
          assert((fri <= Fanout)%nat). rep_omega.
          omega.
        - rewrite sublist_1_cons. rewrite Zlength_cons. rewrite Zsuccminusone.
          rewrite sublist_same; auto. simpl in H3. omega. }
      rewrite Nat2Z.id. rewrite suble_nil. cancel. }
    {                           (* loop body *)
      rewrite unfold_btnode_rep with (n:=nleft). unfold nleft.
      Intros ent_end.
      assert(HENTRY: exists e, nth_entry_le (Z.to_nat i) le = Some e).
      { apply nth_entry_le_in_range. simpl in H0. rewrite H0. rep_omega. }
      destruct HENTRY as [ei HENTRY].
      assert (HEI: exists ki vi xi, ei = keyval val ki vi xi).
      { eapply integrity_nth_leaf. eauto. simpl. auto. eauto. }
      destruct HEI as [ki [vi [xi HEI]]]. subst ei.
      assert_PROP(isptr xi).
      { apply le_iter_sepcon_split in HENTRY. rewrite HENTRY. simpl entry_rep. entailer!. }
      rename H9 into XIPTR.
      rename H7 into IRANGE.
      assert(HZNTH: forall ent_end, Znth (d:=(Vundef,inl Vundef)) i (le_to_list le ++ ent_end) = entry_val_rep (keyval val ki vi xi)).
      { intros. rewrite <- Z2Nat.id with (n:=i). apply Znth_to_list. auto. omega. }
      assert(HIRANGE: (0 <= i < 15)).
      { split. rep_omega. rewrite Fanout_eq in H6. simpl in H6. rep_omega. }
      forward.                  (* t'22=node->entries[i].key *)
      { entailer!. rewrite HZNTH. simpl; auto. }
      rewrite HZNTH. simpl.
      Opaque Znth.
      forward.                  (* allEntries[i+1].key=t'26 *)
      forward.                  (* t'21=node->entries[i].ptr.record *)
      { rewrite HZNTH. entailer!. }
      rewrite HZNTH. simpl.
      forward.                  (* allEntries[i+1]->ptr.record=t'21 *)
      entailer!.
      assert(XEMP: Zlength x > 0).
      { destruct x. clear -H8 HIRANGE. rewrite Fanout_eq in H8.
        apply eq_sym in H8. apply NPeano.Nat.sub_0_le in H8. apply inj_le in H8.
        simpl in H8. rewrite Z2Nat.id in H8. rep_omega. omega.
        rewrite Zlength_cons. rep_omega. }
      Exists (sublist 1 (Zlength x) x). entailer!.
      { clear -IRANGE H8 XEMP.
        destruct x.
        - rewrite Zlength_nil in XEMP. omega.
        - rewrite sublist_1_cons. rewrite Zlength_cons. rewrite Zsuccminusone.
          rewrite sublist_same by omega. simpl in H8. rewrite Z2Nat.inj_add by omega.
          simpl. omega. }
      assert(INUM: (Z.to_nat i <= numKeys_le le)%nat).
      { unfold n  in H0. simpl in H0. rewrite H0. clear -HIRANGE.
        rewrite Fanout_eq. destruct HIRANGE. apply Z2Nat.inj_lt in H0.
        simpl in H0. omega. auto. omega. }
      rewrite unfold_btnode_rep with (n:=nleft). unfold nleft. Exists ent_end. cancel.
      rewrite Nat2Z.id.
      rewrite upd_Znth_twice.
      (* rewrite upd_Znth_app2. *)
      rewrite upd_Znth_same.
      assert((upd_Znth (i + 1) (le_to_list (nth_first_le le fri) ++ (Vint (Int.repr (k_ k)), inr xe) :: le_to_list (suble (fri) ((Z.to_nat i)) le) ++ x) (key_repr ki, inr xi)) = (le_to_list (nth_first_le le fri) ++ (Vint (Int.repr (k_ k)), inr xe) :: le_to_list (suble (fri) ((Z.to_nat (i + 1))) le) ++ sublist 1 (Zlength x) x)).
      { rewrite upd_Znth_app2. rewrite le_to_list_length. rewrite numKeys_nth_first.
        rewrite semax_lemmas.cons_app. rewrite upd_Znth_app2. simpl. rewrite Zlength_cons. simpl.
        rewrite upd_Znth_app2. rewrite le_to_list_length.
        assert(i + 1 - Z.of_nat fri - 1 - Z.of_nat (numKeys_le (suble (fri) ((Z.to_nat i)) le)) = 0).
        { rewrite numKeys_suble. simpl.
          rewrite Nat2Z.inj_sub. rewrite Z2Nat.id. omega. omega.
          rep_omega.
          split. assert(fri <= Z.to_nat i)%nat.
          rep_omega. omega.
          simpl in H0. rewrite H0. clear -H6 HIRANGE. destruct H6.
          rewrite Z2Nat.inj_lt in H0. rewrite Nat2Z.id in H0. omega.
          omega. rep_omega. }
        rewrite H19.
        rewrite upd_Znth0.
        assert(le_to_list (suble (fri) ((Z.to_nat i)) le) ++ [(key_repr ki, (inr xi):(val+val))] = le_to_list (suble (fri) ((Z.to_nat (i + 1))) le)).
        { rewrite Z2Nat.inj_add. simpl. rewrite NPeano.Nat.add_1_r.
          rewrite suble_increase with (e:=keyval val ki vi xi).
          rewrite le_to_list_app. simpl. auto.
          split. destruct IRANGE. clear -H20 HIRANGE. rewrite Nat2Z.inj_le. rewrite Z2Nat.id. auto.
          omega.
          simpl in H0. rewrite H0. rep_omega.
          auto. omega. omega. }
        rewrite <- H20. rewrite <- app_assoc. simpl. auto.
        
        assert(Z.to_nat i < Z.to_nat (Z.of_nat Fanout))%nat. 
        rewrite Nat2Z.id. rep_omega.
        rewrite le_to_list_length. rewrite numKeys_suble. rep_omega.
        simpl in H0. rewrite H0. rep_omega.
        rewrite Zlength_cons. simpl.
        rewrite Zlength_app.
        rewrite le_to_list_length. rewrite numKeys_suble.
        rewrite Zlength_correct. rewrite H8.
        split. omega. rep_omega.
        simpl in H0. rewrite H0. rep_omega.
        simpl in H0. rewrite H0. rep_omega.
        rewrite Zlength_cons. rewrite Zlength_app. rewrite le_to_list_length. rewrite le_to_list_length.
        rewrite numKeys_nth_first. rewrite numKeys_suble. split. omega.
        rep_omega.
        simpl in H0. rewrite H0. rep_omega.
        simpl in H0. rewrite H0. rep_omega.
      }
      rewrite H19. cancel.
      rewrite Zlength_app. rewrite Zlength_cons. rewrite le_to_list_length.
      rewrite numKeys_nth_first. rewrite Zlength_app. rewrite le_to_list_length.
      rewrite numKeys_suble. split. omega. rep_omega.
      simpl in H0. rewrite H0. rep_omega.
      simpl in H0. rewrite H0. rep_omega.
      rewrite Zlength_app. rewrite Zlength_cons. rewrite Zlength_app.
      rewrite le_to_list_length. rewrite le_to_list_length.
      rewrite numKeys_nth_first. rewrite numKeys_suble. split. omega. rep_omega.
      simpl in H0. rewrite H0. rep_omega.
      simpl in H0. rewrite H0. rep_omega.
    } 
        
    Intros ent_end.
    deadvars!.
    pose (e:=keyval val ke ve xe).
    rewrite unfold_btnode_rep with (n:=nleft).
    unfold nleft. Intros ent_end0.
    forward.                    (* node->numKeys=8 *)
    gather_SEP 3 7.
    replace_SEP 0 (le_iter_sepcon (insert_le le e)).
    { entailer!. rewrite <- insert_rep. entailer!. }
    rewrite le_split with (le0:=insert_le le e) (i:=Middle) by
        (simpl in H0; rewrite numKeys_le_insert; rewrite H0; rewrite Middle_eq; rewrite Fanout_eq; omega).
    rewrite le_iter_sepcon_app.
    
    forward_if (PROP ( )
    LOCAL (temp _newNode vnewnode; temp _tgtIdx (Vint (Int.repr (Z.of_nat fri)));
           lvar _allEntries (tarray tentry 16) v_allEntries; temp _node nval; temp _entry pe)
    SEP (btnode_rep (splitnode_left n e); btnode_rep (empty_node true false Last vnewnode);
         data_at Tsh tentry (Vint (Int.repr (k_ k)), inr xe) pe;
         data_at Tsh (tarray tentry 16) (le_to_list (nth_first_le le (Z.to_nat (Z.of_nat fri))) ++ (Vint (Int.repr (k_ k)), inr (force_val (sem_cast_pointer xe))) :: le_to_list (suble (fri) ((Z.to_nat (Z.of_nat Fanout))) le) ++ ent_end) v_allEntries; le_iter_sepcon (skipn_le (insert_le le e) Middle))).
    {                           (* fri < 8 *)
      admit. }
    {                           (* fri >= 8 *)
      forward.                  (* skip *)
      entailer!.
      assert((Middle <=? fri)%nat = true).
      { clear -H8. rewrite Middle_eq. apply leb_correct.
        assert(8 <= Z.of_nat fri) by omega. apply Z2Nat.inj_le in H. simpl in H.
        rewrite Nat2Z.id in H. auto. omega. omega. }
      rewrite unfold_btnode_rep with (n:=btnode val ptr0 (nth_first_le (insert_le le e) Middle) true First false nval).
      assert(SPLITLE: le_to_list le = le_to_list (nth_first_le le Middle) ++ le_to_list (skipn_le le Middle)).
      { rewrite le_split with (i:=Middle) at 1. rewrite le_to_list_app. auto.
        simpl in H0. rewrite H0. rewrite Middle_eq, Fanout_eq. omega. }
      rewrite SPLITLE.
      rewrite <- app_assoc.
      Exists (le_to_list (skipn_le le Middle) ++ ent_end0).
      simpl. rewrite numKeys_nth_first.
      rewrite nth_first_insert with (k:=ke). cancel.
      unfold e. simpl. auto. simpl in HFRI.
      rewrite FRI_repr with (key2:=k). rewrite HFRI. simpl. rewrite Middle_eq. simpl. omega.
      auto. simpl in H0. rewrite numKeys_le_insert. rewrite H0. rewrite Middle_eq.
      rewrite Fanout_eq. omega.
    }
    
    forward_for_simple_bound (Z.of_nat(Fanout) + 1)
    (EX i:Z, (PROP ( )
     LOCAL (temp _newNode vnewnode; temp _tgtIdx (Vint (Int.repr (Z.of_nat fri)));
            lvar _allEntries (tarray tentry 16) v_allEntries; temp _node nval; temp _entry pe)
     SEP (btnode_rep (splitnode_left n e);
          btnode_rep (btnode val None (suble Middle (Z.to_nat i) (insert_le le e)) true false Last vnewnode);
          data_at Tsh tentry (Vint (Int.repr (k_ k)), inr xe) pe;
          data_at Tsh (tarray tentry 16) (le_to_list (nth_first_le le (Z.to_nat (Z.of_nat fri))) ++ (Vint (Int.repr (k_ k)), inr (force_val (sem_cast_pointer xe))) :: le_to_list (suble (fri) ((Z.to_nat (Z.of_nat Fanout))) le) ++ ent_end) v_allEntries)))%assert.
    { rewrite Fanout_eq. simpl. rep_omega. }
    { rewrite Fanout_eq. simpl. rep_omega. }
    { entailer!. rewrite Middle_eq. rewrite suble_nil. unfold empty_node. cancel. admit. }
    {                           (* loop body *)
      admit. }
    rewrite unfold_btnode_rep with (n:=(btnode val None (suble Middle (Z.to_nat (Z.of_nat Fanout + 1)) (insert_le le e)) true false Last vnewnode)).
    Intros ent_end1. simpl.
    forward.                    (* newnode->numKeys=15+1-8 *)
    Intros. gather_SEP 1 2 3 4.
    replace_SEP 0 (btnode_rep (splitnode_leafnode le e vnewnode Last)).
    { entailer!. rewrite unfold_btnode_rep. simpl. Exists ent_end1.
      
      assert(HSUB: suble Middle (Z.to_nat (Z.of_nat Fanout + 1)) (insert_le le e) = skipn_le (insert_le le e) Middle).
      { apply suble_skip. rewrite numKeys_le_insert. unfold n in H0. simpl in H0. rewrite H0.
        rewrite Fanout_eq. simpl. auto. }
      rewrite HSUB. cancel.
      rewrite numKeys_le_skipn. rewrite numKeys_le_insert. unfold n in H0. simpl in H0. rewrite H0.
      rewrite Fanout_eq. rewrite Middle_eq. simpl. cancel. }
    replace_SEP 1 (btnode_rep (splitnode_left n e)).
    { entailer!. }

    assert(HINSERT: (le_to_list (nth_first_le le (Z.to_nat (Z.of_nat fri))) ++ (Vint (Int.repr (k_ k)), inr (force_val (sem_cast_pointer xe))) :: le_to_list (suble (fri) ((Z.to_nat (Z.of_nat Fanout))) le) ++ ent_end) = le_to_list (insert_le le e) ++ ent_end).
    { rewrite insert_fri with (fri:=fri) (key0:=ke).
      rewrite le_to_list_app.
      simpl. rewrite Nat2Z.id. rewrite H5. rewrite Nat2Z.id.
      rewrite suble_skip. unfold key_repr.
      assert(isptr xe). admit.
      apply force_val_sem_cast_neutral_isptr in H8.
      replace (force_val (sem_cast_pointer xe)) with xe.
      rewrite <- app_assoc. auto.
      admit.
      unfold n in H0. simpl in H0. auto.      
      unfold e. simpl. auto. unfold findRecordIndex in HFRI. unfold n in HFRI.
      rewrite FRI_repr with (key2:=k) by auto. rewrite HFRI. auto.
    } 
    rewrite HINSERT.

    assert(NTHENTRY: exists emid, nth_entry_le Middle (insert_le le e) = Some emid).
    { apply nth_entry_le_in_range. unfold n in H0. simpl in H0. rewrite numKeys_le_insert.
      rewrite H0. rewrite Middle_eq.
      rewrite Fanout_eq. omega. }
    destruct NTHENTRY as [emid NTHENTRY].
    assert(HZNTH: nth_entry_le Middle (insert_le le e) = Some emid) by auto.
    eapply Znth_to_list with (endle:=ent_end) in HZNTH.
    rewrite Middle_eq in HZNTH. simpl in HZNTH.
    
    forward.                    (* t'16=allEntries[8]->key *)
    { entailer!. rewrite HZNTH.
      destruct emid; simpl; auto. }
    rewrite HZNTH.
    forward.                    (* entry->key=t'16 *)
    forward.                    (* entry->ptr.child=newnode *)
    forward.                    (* return *)
    Exists vnewnode. fold e. rewrite NTHENTRY. entailer!.
    simpl. unfold splitnode_leafnode. cancel.
    destruct emid; simpl; cancel.
  -                             (* intern node *)
    admit.
Admitted.