(** * verif_newcursor.v: Correctness proof of newCursor *)

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
Require Import verif_movetofirst.

Lemma upd_repeat: forall X i (a:X) b m, 0 <= i -> (Z.to_nat i < m)%nat -> m=MaxTreeDepth ->  
    upd_Znth i (list_repeat (Z.to_nat i) a ++ list_repeat (m - Z.to_nat i) b) a =
    (list_repeat (Z.to_nat (i+1)) a) ++ list_repeat (m - Z.to_nat (i+1)) b.
Proof.
  intros. assert (Z.to_nat (i + 1) = ((Z.to_nat i) + S O)%nat).
  rewrite Z2Nat.inj_add; auto. omega.
  rewrite H2.
  assert(1 <= 20 - i).
  { rewrite H1 in H0. rewrite MTD_eq in H0.
    replace (20%nat) with (Z.to_nat 20) in H0 by auto.
    apply Z2Nat.inj_lt in H0. omega. auto. omega. }
  rewrite <- list_repeat_app.
  rewrite upd_Znth_app2. 
  rewrite Zlength_list_repeat by auto.
  simpl. assert (i-i=0). omega. rewrite H4.
  unfold upd_Znth. simpl.
  assert ((m - (Z.to_nat i))%nat = Z.to_nat (20-i)).
  {rewrite H1. rewrite MTD_eq. rewrite Z2Nat.inj_sub by auto. simpl. auto. }
  assert ((m - (Z.to_nat i + 1))%nat = Z.to_nat (20-i-1)).
  { rewrite H1. rewrite MTD_eq. rewrite Z2Nat.inj_sub by omega.
    rewrite Z2Nat.inj_sub by auto. replace (1%nat) with (Z.to_nat 1) at 2.
    replace (20%nat) with (Z.to_nat 20). omega. auto. auto. }
  rewrite H5. rewrite H6. 
  rewrite sublist_list_repeat.
  rewrite Zlength_list_repeat. rewrite <- app_assoc. auto.
  { rewrite H1 in H0. rewrite MTD_eq in H0. omega. }
  omega.
  rewrite Zlength_list_repeat. split; auto.
  omega.
  omega.
  rewrite Zlength_list_repeat. split. apply Z.le_refl.
  assert(0 <= Zlength (list_repeat (m - Z.to_nat i) b)) by apply Zlength_nonneg. omega.
  auto.
Qed.

Lemma body_NewCursor: semax_body Vprog Gprog f_RL_NewCursor RL_NewCursor_spec.
Proof.
  start_function.
  destruct r as [root prel].
  pose (r:=(root,prel)). fold r.
  forward_if (PROP() LOCAL(temp _relation prel) SEP(relation_rep r numrec))%assert.
  - forward. entailer!.
  - assert_PROP(False).
    entailer!. contradiction.
  - forward_call tcursor.
    + split. unfold sizeof. simpl. rep_omega. split; auto.
    + Intros vret.
      forward_if.
      * forward.
      * forward.                (* cursor->relation=relation *)
        forward.                (* cursor->level=0 *)
        unfold relation_rep. unfold r. Intros.
        forward.                  (* t'3=relation->root *)
        simpl.
{       forward_call(r,empty_cursor,vret,root,numrec). (* moveToFirst at level 0 *)
        - instantiate (Frame:=[]). unfold Frame. simpl.
          unfold relation_rep. unfold r. entailer!.
          change_compspecs CompSpecs. cancel.
          unfold cursor_rep.
          Exists (list_repeat 20 Vundef). Exists (list_repeat 20 Vundef). unfold empty_cursor. simpl.
          change_compspecs CompSpecs.
          cancel.
        - split; try split; try split.
          + unfold partial_cursor_correct_rel. simpl. auto.
          + unfold empty_cursor. simpl. auto.
          + auto.
        - unfold cursor_rep. Intros anc_end. Intros idx_end. unfold r.
          forward.              (* return *)
          Exists vret. entailer!. unfold cursor_rep.
          Exists anc_end. Exists idx_end. cancel. }
Qed.
