Require Import List.
Require Import Arith.
Require Import Omega.

Require Import bil.bil.


Fixpoint lift_above n (e : exp) : exp :=
match e with
| exp_var var5 => exp_var var5
| exp_letvar lid => exp_letvar (if lt_dec lid n then lid else (S lid))
| exp_int word5 => exp_int word5
| exp_mem e w v sz => exp_mem (lift_above n e) w v sz
| exp_load e1 e2 endian5 nat5 => exp_load (lift_above n e1) (lift_above n e2) endian5 nat5
| exp_store e1 e2 endian5 nat5 e3 =>
  exp_store (lift_above n e1) (lift_above n e2) endian5 nat5 (lift_above n e3)
| exp_binop e1 bop5 e2 => exp_binop (lift_above n e1) bop5 (lift_above n e2)
| exp_unop uop5 e => exp_unop uop5 (lift_above n e)
| exp_cast cast5 nat5 e => exp_cast cast5 nat5 (lift_above n e)
| exp_let e t eb => exp_let (lift_above n e) t (lift_above (S n) eb)
| exp_unk string5 type5 => exp_unk string5 type5
| exp_ite e1 e2 e3 => exp_ite (lift_above n e1) (lift_above n e2) (lift_above n e3)
| exp_ext hi lo e => exp_ext hi lo (lift_above n e)
| exp_concat e1 e2 => exp_concat (lift_above n e1) (lift_above n e2)
end.


Notation "^ e" := (lift_above 0 e) (at level 69, right associativity) : bil_exp_scope.

Fixpoint lift_above_m m n (e : exp) {struct e} : exp :=
match e with
| exp_var var5 => exp_var var5
| exp_letvar lid => exp_letvar (if lt_dec lid n then lid else (m + lid))
| exp_int word5 => exp_int word5
| exp_mem e w v sz => exp_mem (lift_above_m m n e) w v sz
| exp_load e1 e2 endian5 nat5 => exp_load (lift_above_m m n e1) (lift_above_m m n e2) endian5 nat5
| exp_store e1 e2 endian5 nat5 e3 =>
  exp_store (lift_above_m m n e1) (lift_above_m m n e2) endian5 nat5 (lift_above_m m n e3)
| exp_binop e1 bop5 e2 => exp_binop (lift_above_m m n e1) bop5 (lift_above_m m n e2)
| exp_unop uop5 e => exp_unop uop5 (lift_above_m m n e)
| exp_cast cast5 nat5 e => exp_cast cast5 nat5 (lift_above_m m n e)
| exp_let e t eb => exp_let (lift_above_m m n e) t (lift_above_m m (S n) eb)
| exp_unk string5 type5 => exp_unk string5 type5
| exp_ite e1 e2 e3 => exp_ite (lift_above_m m n e1) (lift_above_m m n e2) (lift_above_m m n e3)
| exp_ext hi lo e => exp_ext hi lo (lift_above_m m n e)
| exp_concat e1 e2 => exp_concat (lift_above_m m n e1) (lift_above_m m n e2)
end.

Lemma lift_above_above_m : forall m n e,
    lift_above_m m n (lift_above n e) = lift_above_m (S m) n e.
Proof.
  intros m n e; revert n; induction e; intro n; simpl; auto;
    try (repeat multimatch goal with
             [ H : forall n, _ = _ |- ?g] => try rewrite H; clear H
           end; reflexivity).
  - destruct (lt_dec lid5 n).
    destruct (lt_dec lid5 n).
    reflexivity.
    contradiction.
    destruct (lt_dec (S lid5) n).
    elim n0.
    omega.
    rewrite <- Nat.add_comm.
    simpl.
    rewrite <- Nat.add_comm.
    reflexivity.
Qed.

Lemma lift_above_0 : forall n e, lift_above_m 0 n e = e.
Proof.
  intros; revert n; induction e; intro n; simpl; auto;
    try (repeat multimatch goal with
             [ H : forall n, _ = _ |- ?g] => try rewrite H; clear H
           end; reflexivity).
  - destruct (lt_dec lid5 n);reflexivity.
Qed.

Notation "g ; lg |-- e ::: t" := (type_exp g lg e t) (at level 99) : type_scope.

Lemma in_delta_types : forall id type v d,
    type_delta d ->
    In (var_var id type, v) d ->
     nil; nil |-- v ::: type.
Proof.
  intros id type v d td v_in.
  induction td.
  - contradiction.
  - destruct v_in.
    + inversion H1.
      rewrite <- H5.
      rewrite <- H4.
      assumption.
    + apply IHtd; assumption.
Qed.



Definition var_id : var -> id :=
(fun v : var => match v with
                | var_var id0 _ => id0
                end).

Lemma typ_gamma_remove_var : forall g x g', typ_gamma (g ++ x :: g') -> typ_gamma (g ++ g').
Proof.
  intros g x g'; revert g g' x.
  induction g as [| x g].
  - simpl.
    intros g' x txg'.
    inversion txg'; assumption.
  -  simpl.
     intros g' x0 txgxn.
     inversion txgxn as [G | G id t nin twf tgxn x_eq_x].
     apply IHg in tgxn.
     fold var_id in nin.
     apply tg_cons.
     fold var_id.
     rewrite map_app.
     rewrite map_app in nin.
     simpl in nin.
     intro nin'.
     apply in_app_or in nin'.
     apply nin.
     apply in_or_app.
     destruct nin'.
     left; assumption.
     right; right; assumption.
     assumption.
     assumption.
Qed.

(*
Ltac unique_suffices_type_exp_base :=
match goal with
    | [ H_tG : typ_gamma ?G, H_G_eq : ?G = ?x :: ?g |- _ ] =>
      destruct H_tG; inversion H_G_eq;
        match goal with
        | [ H_g_eq : ?G = g |- _ ] =>
          rewrite H_g_eq in H_tG;
            apply t_int;
            assumption
        end
    end.

Lemma unique_suffices_type_exp : forall (g g' : gamma) x e t,
    In x (g ++ g')->
    type_exp (g ++ x::g') e t ->
    type_exp (g ++ g') e t.
Proof.
  intros g g' x e t x_in_g xg_te.
  remember (g ++ x :: g') as gxg'.
  induction xg_te.
  - destruct H0; inversion Heqgxg'.
    elim (app_cons_not_nil g g' x); assumption.
    destruct (eq_var (var_var id5 t) x).
    + rewrite <- e in x_in_g.
      apply t_var.
      * apply x_in_g.
      * apply H0.
    + rewrite Heqxg in H.
      destruct H.
      * elim n; symmetry; apply H.
      * apply t_var; assumption.
  - unique_suffices_type_exp_base.
  - apply (t_load _ e1 e2 ed sz nat5); auto.
  - apply (t_store _ e1 e2 ed sz e3); auto.
  - apply t_aop; auto.
  - apply (t_lop _ e1 lop5 e2 sz); auto.
  - apply t_uop; auto.
  - apply (t_cast _ _ _ _ nat5); auto.
  - apply t_let; auto.
    


Lemma fv_impl_exp_v : forall x e, In x (fv_exp e) -> In x (vars_in_exp e).
  intros x e.
  induction e.
  all: try (simpl; tauto).
  all: try (simpl;  intro x_in;  apply in_app_or in x_in; apply in_or_app; firstorder).
  - apply in_app_or in H.
    firstorder.
  - right.
    simpl; right.
    apply IHe2.
    apply (in_list_minus (fv_exp e2) (var5 :: nil)) in H.
    assumption.
  - apply in_app_or in H.
    firstorder.
Qed.
*)

Lemma type_exp_typ_gamma : forall g lg e t, g; lg |-- e ::: t -> typ_gamma g.
Proof.
  intros g lg e t te.
  induction te; auto.
Qed.

Ltac find_typed t :=
  multimatch goal with
  | [ e : t |- _ ] => e
  end.

Ltac do_for_all_exps tac :=
  first [ let app_tac := (apply t_letvarS) in tac app_tac
        | let app_tac := (apply t_letvarO) in tac app_tac
        | let app_tac := (apply t_var) in tac app_tac
        | let app_tac := (apply t_int) in tac app_tac
        | let app_tac := (apply t_unknown) in tac app_tac
        | let app_tac := (apply t_mem) in tac app_tac
        | let app_tac := (eapply t_load) in tac app_tac
        | let app_tac := (eapply t_store) in tac app_tac
        | let bop5 := find_typed bop in
          destruct bop5;
          first [ let app_tac := (apply t_aop) in tac app_tac
                | let app_tac := (eapply t_lop) in tac app_tac]
        | let app_tac := (apply t_aop) in tac app_tac
        | let app_tac := (eapply t_lop) in tac app_tac
        | let app_tac := (apply t_uop) in tac app_tac
        | let app_tac := (eapply t_cast) in tac app_tac
        | let app_tac := (eapply t_let) in tac app_tac
        | let app_tac := (eapply t_ite) in tac app_tac
        | let app_tac := (eapply t_extract) in tac app_tac
        | let app_tac := (eapply t_concat) in tac app_tac  ].

Ltac apply_concat_rule :=
  let rewrite_for_concat sz1 sz2 :=
      rewrite Word.sz_minus_nshift with (sz := sz1) (nshift := sz2);
      [|omega] in
  match goal with
  | [|- _;_|-- exp_concat _ _ ::: type_imm (_ + _)] => idtac
  | [|- _;_|-- exp_concat ?e1 ?e2 ::: _] =>
    match e1 with context [?sz1 - ?sz2] =>
        rewrite_for_concat sz1 sz2
    end
    || match e2 with context [?sz1 - ?sz2] =>
        rewrite_for_concat sz1 sz2;
          rewrite plus_comm
    end
  end;
  eapply t_concat.

Ltac normalize_words :=
  (* dummy argument because Ltac can't keep track of bound variables *)
  let w := idtac in
  repeat change (existT Word.word) with (existT (fun x => Word.word x));
  repeat change (existT _ _ ?w) with (Sized_Word.sized w).

Ltac apply_type_rule :=
  let rec fn_head e :=
      match e with ?f _ => fn_head f
              | ?f => f
      end in
  lazymatch goal with
    [|- _;_|-- ?e ::: _] =>
    lazymatch fn_head e with
    | exp_var => apply t_var || fail "could not use t_var"
    | exp_letvar => apply t_letvarO || eapply t_letvarS
                    || fail "could not use t_letvarO or t_letvarS"
    | exp_int =>
      normalize_words;
      match goal with
      | [|- _;_ |-- exp_int (Sized_Word.sized (Word.natToWord _)) ::: _ ] => idtac
      | [|- _;_ |-- exp_int (Sized_Word.sized ?wd) ::: type_imm ?x ] =>
        rewrite <- Word.natToWord_wordToNat with (sz := x) (w := wd)
        || fail 1 "could not rewrite goal to use natToWord"
      | [|- _;_ |-- exp_int ?w ::: type_imm _] =>
        fail 1 "word" w "not of an applicable form"
      end;
      apply t_int || fail "could not use t_int"
    | exp_mem => eapply t_mem || fail "could not use t_mem"
    | exp_load => eapply t_load || fail "could not use t_load"
    | exp_store => eapply t_store || fail "could not use t_store"
    | exp_binop =>
      try match goal with [bop5 : bop |- _] => destruct bop5 end;
      apply t_aop || eapply t_lop || fail "could not use t_aop or t_lop"
    | exp_unop => apply t_uop || fail "could not use t_uop"
    | exp_cast => eapply t_cast || fail "could not use t_cast"
    | exp_let => apply t_let || fail "could not use t_let"
    | exp_unk => apply t_unknown || fail "could not use t_unknown"
    | exp_ite => apply t_ite || fail "could not use t_ite"
    | exp_ext => eapply t_extract || fail "could not use t_extract"
    | exp_concat => apply_concat_rule || fail "could not use t_concat"
    end
  end.

Lemma exp_weakening : forall g gw g' lg e t,
    (g ++ g');lg |-- e ::: t -> typ_gamma (g ++ gw ++ g') -> (g ++ gw ++ g');lg |-- e ::: t.
Proof.
  intros g gw g' lg e t et gt.
  remember (g ++ g') as G.
  generalize dependent g.
  induction et;
    intros g HeqG tGw;
    try constructor; auto.
  - rewrite HeqG in H.
    apply in_app_or in H.
    apply in_or_app.
    destruct H.
    + left; assumption.
    + right; apply in_or_app; right; assumption.
  -  eapply t_load; auto; auto.
  - eapply t_lop; auto.
  - eapply t_cast; auto.
  - eapply t_extract; auto.
Qed.

Local Open Scope bil_exp_scope.

Ltac destruct_var_eqs :=
  repeat match goal with
           [ H : ?a = ?b |- _ ] =>
           (is_var a + is_var b);destruct H
         end.

Ltac on_all_hyps tac :=
  repeat match goal with
         | [ H : _ |- _ ] => progress tac H
         end.

(*Lemma type_exp_lift : forall g lg lg' e t m,
    g; lg |-- lift_above_m m 0 e ::: t ->
       g; lg'++lg |-- lift_above_m ((length lg')+m) 0 e ::: t.
Proof.
  intros g lg lg' e; revert g lg lg'.
  induction e; intros g lg lg' tt m te;
    try solve [
          induction lg'; simpl;  simpl in te;
          [ assumption
          | inversion IHlg'; constructor; assumption]].
  induction lg'; simpl; simpl in te;
    [ assumption
    | inversion IHlg'].
    apply t_letvarS;
    apply t_letvarO;
    assumption.
    apply t_letvarS.
    simpl in IHlg'.
    rewrite H, H1.
    assumption.

    simpl.
    inversion te.
    apply t_mem; auto.
    destruct_var_eqs.




Lemma exp_let_weakening_var : forall g lg wlg lg' lid t,
    g;lg++lg'|-- exp_letvar lid ::: t ->
      g; lg ++ wlg ++ lg' |-- lift_above_m (length wlg) (length lg) (exp_letvar lid) ::: t.
Proof.
  intros g lg wlg lg' lid t tlid.
  simpl.
  destruct (lt_dec lid (length lg)).
  - remember (exp_letvar lid) as e.
    inversion l.
    induction tlid; inversion Heqe.
    destruct lg.
    simpl in l; omega.
    
    + apply t_letvarO; assumption.
    + rewrite <- app_comm_cons.
      apply t_letvarS.
      apply IHlg.



    destruct lg; simpl in l; try omega.*)

Lemma canonical_word : forall w : word,
    w = Sized_Word.sized (Word.natToWord (projT1 w) (Word.wordToNat (projT2 w))).
Proof.
  intro w; destruct w.
  simpl.
  rewrite Word.natToWord_wordToNat.
  auto.
Qed.

Lemma typ_lgamma_app : forall lg lg',
    typ_lgamma lg -> typ_lgamma lg' -> typ_lgamma (lg ++ lg').
Proof.
  induction lg;
  simpl; auto;
  intros lg' lgwf lg'wf;
  inversion lgwf;
  constructor; auto.
Qed.

Lemma app_typ_lgamma : forall lg lg',
    typ_lgamma (lg ++ lg') -> typ_lgamma lg /\ typ_lgamma lg'.
Proof.
  induction lg; simpl.
  split; [constructor | assumption].
  intros lg' appwf;
  inversion appwf;
  specialize (IHlg lg' H2);
  destruct IHlg;
  split;
    [constructor|]; auto.
Qed.

(* TODO: move to bil.ott? *)
Theorem exp_ind_rec_lid
  : forall P : exp -> Prop,
    (forall var5 : var, P (exp_var var5)) ->
    P (exp_letvar 0) ->
    (forall lid5 : lid, P (exp_letvar lid5) -> P (exp_letvar (S lid5))) ->
    (forall word5 : word, P (exp_int word5)) ->
    (forall e : exp, P e -> forall (w : word) (v' : exp) sz, P v' -> P ([m:e, w <- v'@sz])) ->
    (forall e1 : exp,
        P e1 ->
        forall e2 : exp,
          P e2 -> forall (endian5 : endian) (nat5 : nat), P (exp_load e1 e2 endian5 nat5)) ->
    (forall e1 : exp,
        P e1 ->
        forall e2 : exp,
          P e2 ->
          forall (endian5 : endian) (nat5 : nat) (e3 : exp),
            P e3 -> P (exp_store e1 e2 endian5 nat5 e3)) ->
    (forall e1 : exp, P e1 -> forall (bop5 : bop) (e2 : exp), P e2 -> P (exp_binop e1 bop5 e2)) ->
    (forall (uop5 : uop) (e1 : exp), P e1 -> P (exp_unop uop5 e1)) ->
    (forall (cast5 : cast) (nat5 : nat) (e : exp), P e -> P (exp_cast cast5 nat5 e)) ->
    (forall e1 : exp, P e1 -> forall (t : type) (e2 : exp), P e2 -> P (exp_let e1 t e2)) ->
    (forall (string5 : string) (type5 : type), P (exp_unk string5 type5)) ->
    (forall e1 : exp,
        P e1 -> forall e2 : exp, P e2 -> forall e3 : exp, P e3 -> P (exp_ite e1 e2 e3)) ->
    (forall (nat1 nat2 : nat) (e : exp), P e -> P (exp_ext nat1 nat2 e)) ->
    (forall e1 : exp, P e1 -> forall e2 : exp, P e2 -> P (exp_concat e1 e2)) ->
    forall e : exp, P e.
Proof.
  intros.
  induction e; auto.
  induction lid5; auto.
Qed.

Lemma type_exp_typ_lgamma : forall g lg e t, g; lg |-- e ::: t -> typ_lgamma lg.
Proof.
  intros g lg e t te; revert lg t te;
  induction e using exp_ind_rec_lid;
  intros lg tt te;
    inversion te;
    try solve [auto
              | constructor; auto
              | match goal with
                  [IH : forall lg t, ?g; lg |-- ?e ::: t -> typ_lgamma lg,
                     H : ?g;?lg |-- ?e ::: _ |- typ_lgamma ?lg] => eapply IH; eauto
                end].
  subst.
  constructor.
  assumption.
  match goal with
    [IH : forall lg t, ?g; lg |-- ?e ::: t -> typ_lgamma lg,
       H : ?g;?lg |-- ?e ::: _ |- typ_lgamma ?lg] => eapply IH; eauto
  end.
Qed.


Ltac solve_typ_lgamma :=
  repeat match goal with
           [ H : _;_ |-- _ ::: _ |- _] =>
           apply type_exp_typ_lgamma in H
         end;
  repeat match goal with
           [H : _ :: _ = ?v |- _] =>
           is_var v;
           destruct H
         end;
  repeat match goal with
          [H : typ_lgamma (_ :: _) |- _] =>
          inversion H;
            clear H
        end;
  repeat match goal with
           | [H : ?t :: _ = _ |- _] =>
             simpl in H
           | [H : _ = ?t :: _ |- _] =>
             simpl in H
         end;
  repeat match goal with
           [H : ?t :: _ = ?t' :: _ |- _] =>
           let tty := type of t in
           unify tty type;
           inversion H;
           clear H
         end;
  repeat match goal with
           | [ H : typ_lgamma (_ ++ _) |- _] =>
             apply app_typ_lgamma in H;
             destruct H
           | [ H : typ_lgamma ?G, Heq : ?G = _ ++ _ |- _] =>
             rewrite Heq in H
           | [ H : typ_lgamma ?G, Heq :  _ ++ _ = ?G |- _] =>
             rewrite Heq in H
         end;
  simpl;
  repeat match goal with
           [|- typ_lgamma (_ :: _)] =>
           constructor
         end;
  repeat match goal with
           [|- typ_lgamma (_ ++ _)] =>
           apply typ_lgamma_app; try assumption
         end;
  assumption.

Lemma exp_let_weakening_int : forall g lg lg' w t,
    typ_lgamma lg' ->
    g;lg|-- exp_int w ::: t -> g; lg ++ lg' |-- exp_int w ::: t.
Proof.
  induction lg.
  simpl.
  intros lg' w t lgwf tw.
  inversion tw.
  apply t_int; auto.
  intros lg' w t lgwf tw.
  inversion tw.
  apply t_int; auto.
  apply typ_lgamma_app; auto.
Qed.

Lemma exp_let_weakening1 : forall g lg lg' e t,
    typ_lgamma lg' ->
    g;lg|-- e ::: t -> g; lg ++ lg' |-- e ::: t.
Proof.
  intros g lg lg' e t.
  revert lg lg' t.
  induction e using exp_ind_rec_lid;
    intros lg lg' lg'wf tt te;
    inversion te;
    destruct_var_eqs;
    let app_tac t :=
        t;eauto; apply typ_lgamma_app; auto
    in
    try solve [do_for_all_exps app_tac].
  - apply t_let;
      [ apply IHe1;
        assumption
      | rewrite app_comm_cons;
        apply IHe2;
        assumption].
Qed.

Lemma exp_let_strengthening_letvar : forall g lg lg' lid t,
    lid < (length lg) ->
    g; lg ++ lg' |-- exp_letvar lid ::: t ->
       g;lg|-- exp_letvar lid ::: t.
Proof.
  intros.
  generalize dependent lid.
  induction lg; intros.
  simpl in H; omega.
  destruct lid.
  inversion H0.
  apply t_letvarO;
    first [ assumption
          | solve_typ_lgamma].
  apply t_letvarS.
  - apply type_exp_typ_lgamma in H0.
    simpl in H0.
    inversion H0.
    assumption.
  - apply IHlg.
    simpl in H.
    omega.
    simpl in H0.
    inversion H0.
    assumption.
Qed.

Lemma word_type_independent : forall g1 lg1 g2 lg2 w t,
    typ_gamma g2 ->
    typ_lgamma lg2 ->
    g1; lg1 |-- exp_int w ::: t ->
        g2; lg2 |-- exp_int w ::: t.
Proof.
  intros;
  match goal with
    [H : _;_|-- exp_int _ ::: _ |- _] =>
    inversion H
  end;
  apply t_int; auto.
Qed.

Ltac prove_length_condition :=
  match goal with
  | [ H : _ <= length ?lg |- _ <= length ?lg ] =>
    (apply Nat.max_lub_iff in H;
     destruct H);
    eauto
  | [ H : _ <= length ?lg |- _ <= length (?t :: ?lg) ] =>
    simpl;
    repeat
      (apply Nat.max_lub_iff in H;
       destruct H);
    omega
  end.

Ltac prove_word_types :=
  match goal with
  | [ H : _;_ |-- exp_int ?w ::: ?t |- _;_ |-- exp_int ?w ::: ?t ] =>
    inversion H;
      apply t_int;
      assumption
  end.

Lemma mem_val_addr_size : forall g lg e1 w e2 nat5 sz,
    g;lg |-- [m:e1, w <- e2@sz] ::: type_mem nat5 sz ->
      projT1 w = nat5.
Proof.
  intros.
  inversion H.
  simpl.
  reflexivity.
Qed.

Lemma mem_val_addr_size' : forall g lg e1 w e2 nat5 sz,
    g;lg |-- [m:e1, w <- e2@sz] ::: type_mem nat5 sz ->
        w = Sized_Word.sized (Word.natToWord nat5 (Word.wordToNat (projT2 w))).
Proof.
  intros.
  inversion H.
  simpl.
  f_equal.
  rewrite Word.natToWord_wordToNat.
  reflexivity.
Qed.

Lemma values_closed : forall g gl v t,
    is_val_of_exp v ->
    g; gl |-- v ::: t -> nil; nil |-- v ::: t.
Proof.
  intros g gl v;
    induction v;
    intros tt vval vt;
    simpl in vval;
    try contradiction;
    inversion vt.
  - apply t_int; auto.
    constructor.
    constructor.
  - apply t_mem;
      destruct vval;
      auto.
  - apply t_unknown; auto.
    constructor.
    constructor.
Qed.

(* TODO: move to bil.ott *)

(* all free variables of e are less than  max_lfv e *)
Fixpoint max_lfv (e_5:exp) : lid  :=
  match e_5 with
  | (exp_var var5) => 0
  | (exp_letvar lid5) => S lid5
  | (exp_int word5) => 0
  | (exp_mem e w v' sz) => max_lfv e
  | (exp_load e1 e2 endian5 nat5) => max (max_lfv e1) (max_lfv e2)
  | (exp_store e1 e2 endian5 nat5 e3) => max (max_lfv e1) (max (max_lfv e2) (max_lfv e3))
  | (exp_binop e1 bop5 e2) => max (max_lfv e1) (max_lfv e2)
  | (exp_unop uop5 e1) => max_lfv e1
  | (exp_cast cast5 nat5 e) => max_lfv e
  | (exp_let e1 t e2) => max (max_lfv e1) (Nat.pred (max_lfv e2))
  | (exp_unk string5 type5) => 0
  | (exp_ite e1 e2 e3) => max (max_lfv e1) (max (max_lfv e2) (max_lfv e3))
  | (exp_ext nat1 nat2 e) => max_lfv e
  | (exp_concat e1 e2) => max (max_lfv e1) (max_lfv e2)
end.

Lemma max_lfv_length_env : forall g gl e t,
    g;gl |-- e ::: t -> max_lfv e <= length gl.
Proof.
  intros g gl e; revert gl;
    induction e using exp_ind_rec_lid;
    intros gl tt et;
    inversion et;
    simpl;
    auto;
    try omega;
    eauto;
    repeat (apply Nat.max_lub; eauto).
  - simpl in IHe.
    simpl.
    apply le_n_S.
    eapply IHe.
    eauto.
  - apply Nat.le_pred_le_succ.
    specialize (IHe2 (t::gl) tt H6).
    simpl in IHe2.
    assumption.
Qed.

Lemma val_closed : forall g gl v t,
    g; gl |-- v ::: t ->
       is_val_of_exp v ->
       nil; nil |-- v ::: t.
Proof.
  intros g gl v;
    induction v using exp_ind_rec_lid;
    intros tt vt vv;
    inversion vt;
    auto;
    simpl in vv;
    try contradiction;
    let app_tac tac := tac; auto; constructor in
    try do_for_all_exps app_tac.
  apply t_mem; auto.
  destruct vv.
  auto.
Qed.

Lemma exp_let_strengthening : forall g lg lg' e t,
    max_lfv e <= length lg ->
    g; lg ++ lg' |-- e ::: t ->
       g;lg|-- e ::: t.
Proof.
  intros g lg lg' e.
  revert lg lg'.
  induction e using exp_ind_rec_lid; simpl;
    intros lg lg' tt lfv_lt te;
    inversion te;
    subst;
    let app_tac t :=
        simpl; t; eauto;
          match goal with
            [ IH : forall lg lg' t, _ -> _ -> ?g;lg |-- ?e ::: t
              |- ?g;?lg |-- ?e ::: ?t ] =>
            eapply IH;
              eauto;
              repeat prove_length_condition;
              eauto
          end in
    try solve [apply_type_rule; auto;
               solve_typ_lgamma
        |do_for_all_exps app_tac].
  - destruct lg;[simpl in lfv_lt;omega|].
    inversion H.
    subst;
    simpl; apply t_letvarO; auto.
    solve_typ_lgamma.
  - destruct_var_eqs.
    destruct lg;[simpl in lfv_lt;omega|].
    apply t_letvarS.
    + simpl in H;
        inversion H.
        rewrite <- H1.
        auto.
    + eapply IHe.
      simpl; simpl in lfv_lt.
      apply le_S_n.
      assumption.
      inversion H.
      rewrite H4 in H3.
      eauto.
  - apply t_mem; auto.
    eapply IHe1; eauto.
    eapply IHe2; eauto.
    eapply val_closed in H3.
    apply max_lfv_length_env in H3.
    simpl in H3.
    omega.
    eauto.
Qed.

Lemma exp_letvar_strengthening2 : forall g gl gl' lid t,
    lid >= length gl' ->
    g;gl'++gl |-- exp_letvar lid ::: t ->
      g;gl |-- exp_letvar (lid - length gl') ::: t.
Proof.
  intros g gl gl'; revert gl.
  induction gl'.
  intros.
  simpl in H0. simpl.
  rewrite Nat.sub_0_r.
  assumption.
  simpl.
  intros.
  inversion H0.
  destruct_var_eqs.
  inversion H.
  simpl.
  apply IHgl'.
  omega.
  assumption.
Qed.

Lemma exp_let_weakening_letvar2 : forall g lg lg' lid t,
    typ_lgamma lg' ->
    g; lg |-- exp_letvar lid ::: t -> g; lg' ++ lg |-- exp_letvar (length lg' + lid) ::: t.
Proof.
  intros.
  induction lg'.
  simpl; auto.
  simpl.
  apply t_letvarS.
  - inversion H.
    assumption.
  - apply IHlg'.
    solve_typ_lgamma.
Qed.

Lemma exp_let_weakening : forall g lg wlg lg' e t,
    typ_lgamma wlg ->
    g;lg++lg'|-- e ::: t ->
      g; lg ++ wlg ++ lg' |-- lift_above_m (length wlg) (length lg) e ::: t.
Proof.
Admitted.
(*
  intros g lg wlg lg' e; revert lg wlg lg'.
  induction e using exp_ind_rec_lid; intros; simpl;
    match goal with
      [H : _;_|-- _ ::: _ |- _] =>
      inversion H
    end;
    destruct_var_eqs_strict;
    let app_tac tac := tac; eauto; prove_word_types in
    try solve [apply_type_rule; auto;
               solve_typ_lgamma
              |do_for_all_exps app_tac].
  - destruct (lt_dec 0 (length lg)).
    + destruct lg.
      simpl in l; omega.
      inversion H0.
      destruct_var_eqs.
      simpl.
      apply t_letvarO; auto.
      solve_typ_lgamma.
    + rewrite Nat.add_comm.
      simpl.
      assert (length lg = 0).
      omega.
      destruct_var_eqs_strict.
      apply length_zero_iff_nil in H4.
      rewrite H4.
      simpl.
      rewrite H4 in H0; simpl in H0.
      induction wlg.
      * simpl.
        assumption.
      * simpl.
        apply t_letvarS.
        -- inversion H.
           assumption.
        -- apply IHwlg.
           solve_typ_lgamma.
  - destruct lg.
    simpl.
    specialize IHe with (lg := nil).
    simpl in IHe.
    rewrite Nat.add_succ_r.
    simpl in H1.
    destruct wlg.
    simpl.
    rewrite <- H1.
    apply t_letvarS.
    assumption.
    assumption.
    simpl.
    apply t_letvarS.
    inversion H; assumption.
    rewrite <- H1.
    destruct wlg.
    simpl.
    apply t_letvarS;
    assumption.
    simpl;
      apply t_letvarS;
      auto.
    inversion H.
    inversion H7; assumption.
    rewrite <- app_nil_l with (l := Gl).
    rewrite app_comm_cons.
    rewrite app_assoc.
    rewrite <- Nat.add_succ_l.
    rewrite <- Nat.add_1_l.
    assert (forall {A : Set} (a : A), length (a :: nil) = 1) by
        (intros A a; simpl; reflexivity).
    rewrite <- H2 with (a := t').
    rewrite Nat.add_comm with (m := length wlg) .
    rewrite <- app_length.
    apply IHe.
    inversion H.
    inversion H8.
    apply typ_lgamma_app.
    assumption.
    constructor; auto.
    constructor.
    assumption.
    simpl.
    destruct (lt_dec (S lid0) (S (length lg))).
    destruct (lt_dec lid0 (length lg)) in IHe.
    + simpl in IHe.


      apply exp_let_weakening1.
      destruct lg.
      simpl in l; omega.
      inversion H0.
      solve_typ_lgamma.
      solve_typ_lgamma.
      apply t_letvarS.
      rewrite H7 in H3.
      simpl in l.
      apply exp_let_strengthening in H3.
      assumption.
      intros.
      simpl.
      omega.
    + rewrite le_plus_minus with (n := length lg) (m := S lid0).
      rewrite plus_assoc.
      rewrite plus_comm with (n := length wlg).
      rewrite <- plus_assoc.
      apply exp_let_weakening_letvar2 with (lg' := lg).
      apply exp_let_weakening_letvar2 with (lg' := wlg).
      apply exp_letvar_strengthening2.
      omega.
      inversion H0.
      apply t_letvarS.
      assumption.
      omega.
  - eapply t_mem; eauto.
    match goal with
      [ IH : forall lg wlg lg' t, _ -> _;_ |-- _ e2 ::: _,
          H : _;_++_ |-- e2 ::: _ |- _] =>
      apply val_closed in H;
        [specialize (IH nil nil nil);
         apply exp_weakening with (g := nil) (gw := g) in H;
         [simpl in H;
          rewrite app_nil_r in H;
          specialize (IH _ H);
          simpl in IH;
          rewrite lift_above_0 in IH;
          remember (lg ++ wlg ++ lg') as gf;
          apply exp_let_weakening1 with (lg' := gf) in H;
          simpl in H;
          assumption|]|]
    end.
    simpl;
    rewrite app_nil_r;
    apply type_exp_typ_gamma in H10;
    assumption.
    assumption.
  -  apply t_let.
    auto.
    apply IHe2 with (lg := t :: lg).
    simpl; auto.
Qed.
*)

Ltac apply_all e t:=
  repeat match goal with
         | [ H : forall _ : t, _ |- _ ] =>
           specialize (H e)
         end.

Lemma var_type_wf : forall g id t,
    typ_gamma g ->
    (In (var_var id t) g) ->
    type_wf t.
Proof.
  induction g; simpl;
    intros id t tg ing;
    inversion tg.
  contradiction.
  destruct ing.
  match goal with
    [H1 : ?a = _ ?t,
          H2 : _ ?t' = ?a,
               H_wf : type_wf ?t'
     |- type_wf ?t] =>
    rewrite H1 in H2;
      inversion H2;
      subst;
      assumption
  end.
  match goal with
    [ IH : forall id t, _ -> _ -> type_wf t |- _] =>
    eapply IH; eauto
  end.
Qed.
Lemma type_exp_type_wf : forall g gl e t,
    g;gl|-- e ::: t -> type_wf t.
Proof.
  intros g gl e; revert gl;
    induction e using exp_ind_rec_lid;
    intros gl tt te;
    inversion te;
    subst;
    [eapply var_type_wf|..];
    eauto;
    try solve [constructor;
               eauto].
  constructor.
  omega.
  constructor.
  apply IHe1 in H3.
  apply IHe2 in H5.
  inversion H3.
  inversion H5.
  omega.
Qed.

Ltac solve_type_wf :=
  tryif match goal with [ |- type_wf _] => idtac end then idtac
  else fail "goal not a type wellformedness judgment";
  solve [match goal with
           [H : ?sz > 0 |- type_wf (type_imm ?sz)] =>
           constructor; assumption
         end
        | constructor; solve [auto | omega]
        | eapply type_exp_type_wf; eauto].

Ltac solve_typ_gamma :=
  tryif match goal with [ |- typ_gamma _ ] => idtac end then idtac
  else fail "goal not a context wellformedness judgment";
  match goal with
    [H : ?g;_ |-- _ ::: _ |- typ_gamma ?g] =>
    apply type_exp_typ_gamma in H; assumption
  end.


Lemma compute_faithful : forall g gl v t,
    is_val_of_exp v ->
    g;gl |-- v ::: t -> compute_type v = t.
Proof.
  intros g gl v t vv vt;
    apply val_closed in vt; [|assumption];
      revert vv vt;
      induction v;
      simpl;
      auto;
      try contradiction;
      intros vv vt;
      inversion vt;
      subst;
      constructor.
Qed.

Require Import bil.Sized_Word.

Lemma word_size_in_type : forall g gl sz1 w sz2,
    g;gl|-- exp_int (existT Word.word sz1 w) ::: type_imm sz2 -> sz1 = sz2.
Proof.
  intros g gl sz1 w sz2 te.
  inversion te.
  reflexivity.
Qed.

Ltac unify_sizes :=
  repeat multimatch goal with
         | [ H : _;_|-- exp_int (existT _ ?sz1 _) ::: type_imm ?sz2 |- _] =>
           tryif unify sz1 sz2 then fail else
             let Hsz := fresh "Hsz" in
             apply word_size_in_type in H as Hsz;
             destruct Hsz
         | [ H : _;_|-- exp_int (@sized ?sz _) ::: type_imm ?sz' |- _] =>
           let Hsz := fresh "Hsz" in
           assert (sz = sz') as Hsz by
               (inversion H; reflexivity);
           destruct Hsz
         | [ H : _;_ |-- exp_unk _ (type_imm ?sz) ::: type_imm ?sz'|- _] =>
           let Hsz := fresh "Hsz" in
           assert (sz = sz') as Hsz by
               (inversion H; reflexivity);
           destruct Hsz
         | [ H1 : compute_type ?v = ?t1,
             H2 : compute_type ?v = ?t2 |- _] =>
           tryif unify t1 t2 then clear H2 else
           rewrite <- H1 in H2;
           injection H2;
           repeat (let eq := fresh in
                   intro eq; destruct eq);
           clear H2
         | [ Hc : compute_type ?v = ?t1,
             Ht : _;_ |-- ?v ::: ?t2 |- _] =>
           tryif unify t1 t2 then fail else
           let Hc' := fresh Hc in
           assert (compute_type v = t2) as Hc' by
                 (apply compute_faithful in Ht; assumption);
           rewrite Hc in Hc';
           injection Hc';
           repeat (let eq := fresh in
                   intro eq; destruct eq);
           clear Hc'
         end.

Lemma in_type_delta : forall d i t v, type_delta d -> In (var_var i t,v) d -> nil;nil |-- v ::: t.
Proof.
  intros d i t v td id; induction td;
  simpl in id; inversion id;
  [match goal with [H: (_, _) = ( _, _) |-_ ] => inversion H end|];
  subst;
  auto.
Qed.
Lemma exp_weakening_nil : forall (g : list var) (lg : lgamma) (e : exp) (t : type),
       (nil; lg |-- e ::: t) -> typ_gamma g -> g; lg |-- e ::: t.
Proof.
  intros g lg e t te tg;
  rewrite <- app_nil_r with (l := g);
  rewrite <- app_nil_l with (l := g ++ nil);
  apply exp_weakening;
    simpl;
    [|rewrite app_nil_r];
    assumption.
Qed.

Ltac solve_binop_preservation :=
  match goal with
  | [|- _;_ |-- exp_int (sw_lift_binop _ _ _) ::: _] => unfold sw_lift_binop
  | [|- _;_ |-- exp_int (sw_lift_shiftop _ _ _) ::: _] => unfold sw_lift_shiftop
  end;
  repeat match goal with
         | [ w : word |- _] => destruct w
         end;
  unify_sizes;
  try rewrite Sized_Word.lift_binop_in_equal_sizes;
  simpl;
  apply_type_rule;
  first [match goal with
         | [ H : _;_|-- exp_int _ ::: type_imm ?x |- ?x > 0] =>
           inversion H; auto
         end
        | solve_typ_gamma
        | solve_typ_lgamma].

Ltac self_multiple :=
  exists 1;
   simpl;
   rewrite Nat.add_0_r;
   reflexivity.

Lemma mult_gtz : forall a b, a * b > 0 -> b > 0.
Proof.
  induction b; intros; omega.
Qed.

Ltac solve_size_constraint :=
  unify_sizes;
  subst;
  try omega;
  match goal with [H : _;_|--_::: ?t |- ?sz > 0] =>
                  match t with context [sz] =>
                               apply type_exp_type_wf in H;
                               inversion H;
                               assumption
                  end end.

Lemma exp_type_succ : forall g gl w w' sz,
    succ w (exp_int w') ->
    g;gl |-- exp_int w ::: type_imm sz ->
      g;gl |-- exp_int w' ::: type_imm sz.
Proof.
  intros g gl w w' sz wsw tw.
  inversion tw.
  subst.
  inversion wsw.
  unfold sw_lift_binop.
  subst.
  normalize_words.
  apply_type_rule; auto.
Qed.


Ltac destruct_existentials :=
  repeat match goal with
           [ H : exists e, _ |- _] => destruct H end.


Ltac existential_as_evar f :=
  match goal with [|- exists (x : ?t), _] =>
                  let x := fresh "_" in
                  evar (x : t);
                  let x' := eval unfold x in x in
                  exists (f x');
                  clear x
  end.

Ltac sub_n_multiple :=
  existential_as_evar (fun x => x - 1);
  rewrite Nat.mul_sub_distr_r; simpl;
  rewrite Nat.add_0_r;
  repeat f_equal.

Ltac solve_is_multiple :=
  destruct_existentials;
  unify_sizes;
  subst;
  solve [self_multiple | sub_n_multiple].

Ltac solve_type_rule_using tac :=
  apply_type_rule; eauto;
  solve [ solve_is_multiple
        | solve_size_constraint
        | constructor
        | solve_type_wf
        | solve_typ_gamma
        | solve_typ_lgamma
        | tac
        | solve_type_rule_using tac].

Ltac solve_type_rule := solve_type_rule_using idtac.

Ltac destruct_all typ :=
  repeat match goal with
         | [ e : typ |- _] => destruct e
         end.

Lemma exp_preservation : forall d e e' t,
    type_delta d ->
    (map fst d);nil |-- e ::: t ->
    exp_step d e e' ->
    (map fst d);nil |-- e' ::: t.
Proof.
  intros d e e' t td te es.
  generalize dependent t.
  induction es; intros t0 te; inversion te;
    subst;
    try solve [try (apply_type_rule;
                    eauto;
                    try match goal with
                          [H:?G;_|--_:::_ |- typ_gamma ?G] =>
                          apply type_exp_typ_gamma in H;
                          assumption
                        end);
               match goal with
                 [H : _;_|-- ?ec ::: _ |- _;_ |-- ?e ::: _] =>
                 match ec with context [e] =>
                               inversion H;
                               destruct_var_eqs;
                               assumption
                 end
               end
              | apply_type_rule; eauto;
                subst;
                first [ solve_type_wf
                      | solve_typ_gamma
                      | solve_typ_lgamma]
              | solve_binop_preservation
              | apply_type_rule;
                inversion te;
                subst;
                eapply t_lop;
                eauto].
  - apply exp_weakening_nil.
    eapply in_type_delta; eauto.
    assumption.
  - apply_type_rule.
    + solve_type_rule.
    + replace (sz + (sz' - sz) - sz) with (sz' - sz) by omega.
      let tac := (first [omega | eapply exp_type_succ; eauto]) in
      solve_type_rule_using tac.
  - apply_type_rule.
   + replace (sz' - sz + sz - sz) with (sz' - sz) by omega.
     let tac := (first [omega | eapply exp_type_succ; eauto]) in
      solve_type_rule_using tac.
   + solve_type_rule.
  - let tac := (eapply exp_type_succ; eauto) in
      solve_type_rule_using tac.
  - let tac := (eapply exp_type_succ; eauto) in
      solve_type_rule_using tac.
  - unify_sizes.
    solve_type_rule.
  - match goal with
      [ H : _;_ |-- exp_unk _ ?t ::: type_imm ?sz |- _] =>
      destruct t; try now inversion H
    end.
    unify_sizes.
    solve_type_rule.
  - unify_sizes.
    solve_type_rule.
  - (*TODO: requires Lemma subst_type_exp *)
    give_up.
  - unfold sw_lt.
    destruct_all word.
      unify_sizes.
      unfold sw_lift_cmpop.
      simpl.
      unfold sw_lift_cmpop_in.
      match goal with
        |- context[eq_nat_decide ?x ?x] =>
        let n := fresh "n" in
        destruct (eq_nat_decide x x) as [| n];
          [|elim n; apply eq_nat_refl]
      end.
      match goal with
        |- context[if ?c then _ else _] =>
        destruct c; solve_type_rule
      end.
  - unfold sw_slt.
    destruct_all word.
      unify_sizes.
      unfold sw_lift_cmpop.
      simpl.
      unfold sw_lift_cmpop_in.
      match goal with
        |- context[eq_nat_decide ?x ?x] =>
        let n := fresh "n" in
        destruct (eq_nat_decide x x) as [| n];
          [|elim n; apply eq_nat_refl]
      end.
      match goal with
        |- context[if ?c then _ else _] =>
        destruct c; solve_type_rule
      end.
  - unify_sizes.
    solve_type_rule.
  - unify_sizes.
    solve_type_rule.
  - unify_sizes.
    solve_type_rule.
  - unify_sizes.
    solve_type_rule.
  - destruct_all word.
    unify_sizes.
    solve_type_rule.
  - destruct_all word.
    unify_sizes.
    unfold ext.
    unfold ext'.
    replace (sz1 - sz2 + 1) with (S sz1 - sz2) by omega.
    solve_type_rule.
  - destruct_all word.
    unify_sizes.
    unfold ext.
    unfold ext'.
    assert (type_imm sz = type_imm (S (sz - 1) - 0)).
    give_up.
    rewrite H.
    solve_type_rule.
  - unify_sizes.
    (* TODO: the spec is wrong in this case. Specifically, when sz > sz' *)
    give_up.
  - destruct_all word.
    unify_sizes.
    unfold ext_signed.
    unfold ext'_signed.
    assert (type_imm sz = type_imm (S (sz - 1) - 0)).
    give_up.
    rewrite H.
    solve_type_rule.


Lemma type_exp_unique : forall g gl e t,
    g; gl |-- e ::: t -> forall t', g; gl |-- e ::: t' -> t = t'.
Proof.
  intros g gl e t te;
  induction te;
    intros t0 t0e;
    inversion t0e.
  all: try reflexivity.
  all: try match goal with
    | [ IH : forall t', ?g;?gl |-- ?e ::: t' -> ?GL = t',
          H : ?g; ?gl |-- ?e ::: ?GR |- ?GL = ?GR ] =>
      apply IH; assumption
    end.
  - repeat match goal with
           | [ IH : forall t', ?g;?gl |-- ?e ::: t' -> ?GL = t' ,
                 H : ?g;?gl |-- ?e ::: _ |- _ ] =>
             apply IH in H
           end.
    inversion H3.
    inversion H5.
    reflexivity.
Qed.

(*
Lemma subst_inversion : forall es x e,
    e <> exp_letvar x -> ~ In x (lfv_exp es) ->
    (forall y, [es./x]e = exp_var y -> e = exp_var y) /\
    (forall y, [es./x]e = exp_letvar y -> e = exp_letvar y /\ x <> y) /\
    (forall w, [es./x]e = exp_int w -> e = exp_int w) /\
    (forall e1 e2 ed sz, [es./x]e = exp_load ([es./x]e1) ([es./x]e2) ed sz ->
                         e = exp_load e1 e2 ed sz) /\
    (forall e1 e2 ed sz e3, [es./x]e = exp_store ([es./x]e1) ([es./x]e2) ed sz ([es./x]e3) ->
                            e = exp_store e1 e2 ed sz e3) /\
    (forall e1 op e2, [es./x]e = exp_binop ([es./x]e1) op ([es./x]e2) -> e = exp_binop e1 op e2) /\
    (forall op e1, [es./x]e = exp_unop op [es./x]e1 -> e = exp_unop op e1) /\
    (forall c sz e1, [es./x]e = exp_cast c sz [es./x]e1 -> e = exp_cast c sz e1) /\
    (forall e1 e2, [es./x]e = exp_let x [es./x]e1 e2 -> e = exp_let x e1 e2 ) /\
    (forall y e1 e2, [es./x]e = exp_let y [es./x]e1 [es./x]e2 -> x <> y -> e = exp_let y e1 e2 ) /\
    (forall str t, [es./x]e = exp_unk str t -> e = exp_unk str t) /\
    (forall e1 e2 e3, [es./x]e = exp_ite [es./x]e1 [es./x]e2 [es./x]e3 -> e = exp_ite e1 e2 e3) /\
    (forall sz1 sz2 e1, [es./x]e = exp_ext sz1 sz2 [es./x]e1 -> e = exp_ext sz1 sz2 e1) /\
    (forall e1 e2, [es./x]e = exp_concat [es./x]e1 [es./x]e2 -> e = exp_concat e1 e2).
Proof.
  intros es x e enl nisl.
  repeat constructor; induction e; simpl.
  all: try solve [try destruct (eq_letvar letvar5 x); intros; inversion H;
                  try first [reflexivity
                            | elim enl; f_equal; assumption]].
  simpl in H.
  destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction).
  assumption.
  simpl in H.
  destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction).
  intro.
  inversion H.
  elim n.
  rewrite H0.
  assumption.
Admitted.
*)
(*
  intros.
  inversion H.


  simpl.
  all: try solve [intros; inversion H | auto].
  destruct (eq_letvar letvar5 x).
  rewrite e in enl; contradiction.
  auto.
  inversion H.

  all: try (destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction)).
  simpl.
  try destruct (eq_letvar letvar5 x).
  rewrite e in enl; contradiction.
  auto.
  inversion H.
  simpl; try destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction).
  auto.
  auto.
  - rewrite <- H.
    simpl.
    destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction).
    reflexivity.
  - simpl in H.
    destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction).
    inversion H.
    rewrite <- H1; intro eq; symmetry in eq; contradiction.
  - 
    destruct (eq_letvar letvar5 x); try (rewrite e in enl; contradiction).



  constructor.
  intros y H.
  inversion H.
  constructor.
  assumption.
  inversion H.
  simpl;
    intros;
    destruct (eq_letvar letvar5 x);
    solve [rewrite e in enl; contradiction | auto].
  constructor.
  induction e; simpl; try solve [auto | intros y H; inversion H].
  intros;
    destruct (eq_letvar letvar5 x).
  rewrite e in enl; contradiction.
  inversion H.
  rewrite H1 in n.
  firstorder.
  constructor.
  induction e; simpl; try solve [auto | intros y H; inversion H].
  intros;
    destruct (eq_letvar letvar5 x).
  rewrite e in enl; contradiction.
  auto.
  constructor.
  - induction e; simpl; try solve [auto | intros; inversion H].
    + intros.
      destruct (eq_letvar letvar5 x).
      rewrite e in enl; contradiction.
      inversion H.
    + intros.
      inversion H.
      destruct (eq_exp e0 (exp_letvar x));
        destruct (eq_exp e1 (exp_letvar x));
        destruct (eq_exp e2 (exp_letvar x));
        destruct (eq_exp e3 (exp_letvar x)).
      * rewrite e, e4, e5, e6.
        reflexivity.
      * rewrite e5 in H2.
        simpl in H2.
        destruct (eq_letvar x x); try contradiction.
        

Lemma subst_eq_esubst : forall e x es, es = [es./x]e -> e = exp_letvar x \/ e = es.
Proof.
  intros e x.
  induction e; simpl; auto; intros es es_eq.
  - destruct (eq_letvar letvar5 x).
    + rewrite e.
      left; reflexivity.
    + right; symmetry; assumption.
  - inversion es_eq.


elim n.
        

        rewrite e in H1.
        rewrite e4 in H1.
        
        repeat match goal with
             |

  constructor.
  *)
(*
Lemma letsubst_inversion_var : forall es x e y,
    e <> exp_letvar x -> [es./x]e = exp_var y -> e = exp_var y.
Proof.
  intros es x e y enl.
  induction e.
  all: simpl; try solve [auto | intro H; inversion H].
  simpl;
    intros;
    destruct (eq_letvar letvar5 x);
    solve [rewrite e in enl; contradiction | auto].
Qed.
*)
(*
Ltac letsubst_unused_rec_case :=
  f_equal;
  let H := match goal with
             [ H : forall x es, ~In x _ -> [es./x]?e = ?e |- [_./_]?e = ?e] => H
           end in
  apply H;
  auto;
  let nin := match goal with
               [ nin : ~In _ _ |- _ ] => nin
             end in
  intro; elim nin;
  apply in_or_app;
  first [left; assumption
        | right; apply in_list_minus;
          solve [firstorder]
        | solve [firstorder]].

Lemma letsubst_unused : forall x es e,
    ~In x (lfv_exp e) -> [es./x]e = e.
Proof.
  intros x es e; revert x es.
  induction e;
    simpl;
    auto;
    intros x es nin;
    try solve[letsubst_unused_rec_case].
  - destruct (eq_letvar letvar5 x);
      [> elim nin; left; assumption
      | reflexivity].
  - destruct (eq_letvar letvar5 x);
    letsubst_unused_rec_case.
Qed.

Ltac letsubst_distributes_rec_case :=
  f_equal;
  match goal with
    [ IH : forall x y es1 es2,
        _ -> _ -> _ -> [es1./x]([es2./y]?e) = [es2./y]([es1./x]?e)
        |- [?es1 ./ ?x] ([?es2 ./ ?y] ?e) = [?es2 ./ ?y] ([?es1 ./ ?x] ?e) ] =>
    apply IH; assumption
  end.

Lemma letsubst_distributes : forall x y es1 es2 e,
    ~In y (lfv_exp es1) ->
    lfv_exp es2 = nil ->
    x <> y -> ([es1./x][es2./y]e) = [es2./y][es1./x]e.
  intros x y es1 es2 e; revert x y es1 es2.
  induction e;
        intros x y es1 es2 yni1 es2_closed xne;
        simpl;
        try solve [auto | letsubst_distributes_rec_case].
  - destruct (eq_letvar letvar5 y).
    + destruct (eq_letvar letvar5 x).
      * rewrite <- e in xne;
          rewrite <- e0 in xne;
          contradiction.
      * simpl.
        destruct (eq_letvar letvar5 y).
        apply letsubst_unused;
          rewrite es2_closed;
          auto.
        rewrite e in n0.
        contradiction.
    + destruct (eq_letvar letvar5 x).
      * simpl.
        destruct (eq_letvar letvar5 x);
          rewrite letsubst_unused;
          tauto.
      * simpl.
        destruct (eq_letvar letvar5 x);
          destruct (eq_letvar letvar5 y);
          tauto.
  - destruct (eq_letvar letvar5 x) as [lv5xe | nlv5xe];
    destruct (eq_letvar letvar5 y)as [lv5ye | nlv5ye].
     + rewrite <- lv5xe in xne.
       rewrite <- lv5ye in xne.
       contradiction.
     + rewrite lv5xe.
       letsubst_distributes_rec_case.
     + rewrite lv5ye.
       letsubst_distributes_rec_case.
     + letsubst_distributes_rec_case.
Qed.
*)
(*
Ltac subst_type_exp app_tac :=
  inversion et;
  match goal with
    [ H : ?t = ?t' |- _;_ |-- _ ::: ?t ] => destruct H
  end;
  app_tac; auto.

Lemma subst_type_exp : forall g e t es gl ts gl',
    g; gl ++ (ts :: gl') |-- e ::: t ->
       g; gl' |-- es ::: ts ->
          g; gl ++ gl' |-- [es./length gl] e ::: t.
Proof.
  intros g e t es gl ts gl'.
  generalize dependent t.
  induction e; simpl;
    intros tt et est.
  - apply exp_let_weakening.
    destruct (eq_letvar letvar5 (letvar_var id ts)).
    destruct letvar5.
    inversion et.
    assumption.
  - let app_tac := (apply t_mem) in
    subst_type_exp app_tac.
  - let app_tac := (apply t_load with (sz := sz) (nat5 := nat0)) in
    subst_type_exp app_tac.
  - let app_tac := (apply t_store with (sz := sz) (nat5 := nat0)) in
    subst_type_exp app_tac.
  - destruct bop5.
    + let app_tac := (apply t_aop) in
      subst_type_exp app_tac.
    + let app_tac := (apply t_lop with (sz := sz)) in
      subst_type_exp app_tac.
  - let app_tac := (apply t_uop) in
    subst_type_exp app_tac.
  - let app_tac := (apply t_cast with (nat5 := nat0)) in
    subst_type_exp app_tac.
  -
 *)
Ltac get_var_from_type_subst_goal :=
  match goal with
    [ |- _ |-- ?e ::: _] =>
    match e with context [[_./?x]_] => x
    end
  end.

Ltac get_hyp_with_goal_type :=
  match goal with
    [ te : ?g |-- _ ::: ?t |- ?g |-- _ ::: ?t ] => te
  end.

Ltac type_subst_dec_subst_in_IH x te :=
   (multimatch goal with
     [ IH : forall t es1, _ ->  _ -> forall es, _ -> ?g |-- [es./x]?ei ::: t |- ?g |-- ?e ::: _] =>
     lazymatch e with context [[es./x]ei] =>
                      idtac "resolving via" IH;
                      let eq_e := fresh "eq_ei" in
                      let neq_e := fresh "neq_ei" in
                      destruct (eq_exp ei (exp_letvar x)) as [eq_e | neq_e];
                      idtac;
                      try rewrite eq_e;
                      simpl;
                      try rewrite eq_e in IH;
                      simpl in IH;
                      try rewrite eq_e in te
     end
   end
   || fail "No inductive hypothesis found");
  simpl in te;
  destruct (eq_letvar x x); try contradiction;
  idtac "inverting typing rule hypothesis";
  inversion te.

Ltac destruct_equalities_on t :=
  repeat match goal with
         | [H : ?t1 = ?t2 |- _] =>
           let tty := type of t1 in
           unify tty t;
           idtac "destructing equality:" t1 "=" t2;
           destruct H
         end.

Ltac unify_typing_judgments :=
  repeat multimatch goal with
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2, _ : ?t1 = ?t2 |- _ ] => fail
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2, _ : ?t2 = ?t1 |- _ ] => fail
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2 |- _ ] =>
           let teq := fresh "teq" in
           pose proof type_exp_unique as teq;
           specialize teq with (g := g) (t := t1) (t' := t2);
           specialize (teq e TE1 TE2);
           idtac "unified" TE1 "and" TE2 "via uniqueness of types";
           clear TE2;
           destruct teq
         end.

Ltac type_subst_solve_IH :=
  solve [first [solve [eauto]
        | match goal with
          | [ IH : forall t es1, _ -> _ -> forall es, _ -> ?g |-- [es./?x]?e ::: t,
                TES1 : ?g |-- [?es1./?x]?e ::: ?t'
                |- ?g |-- [?es./?x]?e ::: ?t ] =>
            apply IH with (es1 := es1); assumption
          | [ IH : forall t es1, _ -> _ -> forall es, _ -> ?g |-- es ::: t,
                TES1 : ?g |-- [?es1./?x]?e ::: ?t'
                |- ?g |-- ?e ::: ?t ] =>
            apply IH with (es1 := es1); assumption
          end]].

Ltac type_subst_rec_case app_tac :=
  let x := get_var_from_type_subst_goal in
  idtac "substituted variable:" x;
  let te := get_hyp_with_goal_type in
  idtac "typing judgment for e:" te;
  type_subst_dec_subst_in_IH x te;
  app_tac;
  destruct_equalities_on type;
  unify_typing_judgments;
  type_subst_solve_IH.

Lemma type_subst : forall id g es1 es2 e ts t,
    g |-- es1 ::: ts ->
    g |-- es2 ::: ts ->
    g |-- ([es1 ./ letvar_var id ts ] e) ::: t ->
    g |-- ([es2 ./ letvar_var id ts ] e) ::: t.
Proof.
  intros id g es1 es2 e ts t tes1 tes2 te.
  remember (letvar_var id ts) as x.
(*
  destruct (eq_exp e (exp_letvar x)).
  - rewrite e0.
    simpl.
    destruct (eq_letvar x x); try contradiction.
    rewrite e0 in te.
    simpl in te.
    destruct (eq_letvar x x); try contradiction.
    pose proof type_exp_unique as teqts.
    specialize teqts with g es1 t ts.
    specialize (teqts te tes1).
    rewrite teqts.
    assumption. *)
  - generalize dependent es2.
    generalize dependent es1.
    generalize dependent t.
    induction e;
      simpl;
      intros t es1 tes1 te es2 tes2;
      try assumption.
    + destruct (eq_letvar letvar5 x).
      * match goal with
        | [ H : ?g |-- ?e ::: ?t,
                H' : ?g |-- ?e ::: ?t' |- _] =>
          apply type_exp_unique with (t := t') in H as teq;
            try assumption;
            try rewrite <- teq;
            assumption
        end.
        * assumption.
   + do_to_all_exps type_subst_rec_case.
   + do_to_all_exps type_subst_rec_case.
   + do_to_all_exps type_subst_rec_case.
   + do_to_all_exps type_subst_rec_case.
   + do_to_all_exps type_subst_rec_case.
   + do_to_all_exps type_subst_rec_case.
   + destruct (eq_letvar letvar5 x).
     *  let x := get_var_from_type_subst_goal in
        idtac "substituted variable:" x;
          let te := get_hyp_with_goal_type in
          idtac "typing judgment for e:" te;
            type_subst_dec_subst_in_IH x te.
        eapply t_let;
          destruct_equalities_on letvar;
          destruct_equalities_on type;
          unify_typing_judgments;
          type_subst_solve_IH.
        eapply t_let.
          destruct_equalities_on letvar;
          destruct_equalities_on type;
          unify_typing_judgments;
          type_subst_solve_IH.
          destruct_equalities_on type;
          unify_typing_judgments.
          rewrite e in H.
          rewrite Heqx in H.
          inversion H.
          destruct H6, H7.
          rewrite <- Heqx.
          apply IHe2 with (es1 := [es1 ./ x] e1).
          assumption.
          rewrite <- Heqx in H5.
          assumption.
          apply IHe1 with (es1 := es1); auto.
     * let x := get_var_from_type_subst_goal in
        idtac "substituted variable:" x;
          let te := get_hyp_with_goal_type in
          idtac "typing judgment for e:" te;
            type_subst_dec_subst_in_IH x te.
       -- eapply t_let.
          destruct_equalities_on letvar;
            destruct_equalities_on type;
            unify_typing_judgments;
            type_subst_solve_IH.
          destruct_equalities_on type.
          remember (letvar_var id5 t0) as y.
          rewrite letsubst_unused.
          rewrite letsubst_unused in H5.
          unify_typing_judgments.
          assumption.
          rewrite type_exp_no_lfv with (g := g) (t := ts).
          simpl; auto.
          auto.
          rewrite type_exp_no_lfv with (g := g) (t := ts).
          simpl; auto.
          auto.
       -- eapply t_let.
          destruct_equalities_on letvar;
            destruct_equalities_on type;
            unify_typing_judgments;
            type_subst_solve_IH.
          destruct_equalities_on type.
          
          apply IHe2.

          type_subst_solve_IH.
          rewrite type_exp_no_lfv with (g := g) (t := ts).
          simpl; auto.
          
          rewrite type_exp_no_lfv with (g := g) (t := ts).
          simpl; auto.
          auto.

(* TODO: not true given the non-capture-avoiding substitution!
Lemma letsubst_distribute2 : forall es1 x es2 y e,
              ~In x (lfv_exp e) -> [[es1./x]es2./y]e = [es1./x][es2./y]e.
Proof.
  intros es1 x es2 y e nin.
  induction e; simpl; auto;
    try solve [f_equal;
               simpl in nin;
               auto
              |f_equal;
               simpl in nin;
               match goal with [IH : _ -> ?G |- ?G] => apply IH end;
               intro; elim nin;
               repeat (apply in_or_app;
                       auto;
                       right)].
  - destruct (eq_letvar letvar5 y); simpl; auto.
    destruct (eq_letvar letvar5 x); simpl; auto.
    simpl in nin; tauto.
  - destruct (eq_letvar letvar5 y);
      destruct (eq_letvar letvar5 x).
    + f_equal;
        simpl in nin;
        match goal with [IH : _ -> ?G |- ?G] => apply IH end;
        intro; elim nin;
          repeat (apply in_or_app;
                  auto;
                  right).
    + f_equal.
      simpl in nin;
        match goal with [IH : _ -> ?G |- ?G] => apply IH end;
        intro; elim nin;
          repeat (apply in_or_app;
                  auto;
                  right).
      symmetry.
      apply letsubst_unused.
      intro in2.
      elim nin.
      simpl.
      apply in_or_app.
      right.
      apply in_list_minus.
      constructor; auto.
      intro inxv5.
      simpl in inxv5.
      destruct inxv5; tauto.
    + rewrite e.
      (* TODO: fails because substitution isn't capture avoiding! *)
      f_equal.
      simpl in nin;
        match goal with [IH : _ -> ?G |- ?G] => apply IH end;
        intro; elim nin;
          repeat (apply in_or_app;
                  auto;
                  right).
      rewrite IHe2.
*)

Ltac type_subst_IH x te :=
  (multimatch goal with
     [ IH : forall t es1, _ ->  _ -> forall es, _ -> ?g |-- [es./x]?ei ::: t |- ?g |-- ?e ::: _] =>
     lazymatch e with context [[es./x]ei] =>
                      idtac "resolving via" IH;
                      let eq_e := fresh "eq_ei" in
                      let neq_e := fresh "neq_ei" in
                      destruct (eq_exp ei (exp_letvar x)) as [eq_e | neq_e];
                      idtac;
                      try rewrite eq_e;
                      simpl;
                      try rewrite eq_e in IH;
                      simpl in IH;
                      try rewrite eq_e in te
     end
   end;
    simpl in te;
  destruct (eq_letvar x x); try contradiction;
  inversion te)
   || fail "No inductive hypothesis found".

Ltac type_subst_rec_case' app_tac :=
  let x := get_var_from_type_subst_goal in
  idtac "substituted variable:" x;
  let te := get_hyp_with_goal_type in
  idtac "typing judgment for e:" te;
  (multimatch goal with
     [ IH : forall t es1, _ ->  _ -> forall es, _ -> ?g |-- [es./x]?ei ::: t |- ?g |-- ?e ::: _] =>
     lazymatch e with context [[es./x]ei] =>
                      idtac "resolving via" IH;
                      let eq_e := fresh "eq_ei" in
                      let neq_e := fresh "neq_ei" in
                      destruct (eq_exp ei (exp_letvar x)) as [eq_e | neq_e];
                      idtac;
                      try rewrite eq_e;
                      simpl;
                      try rewrite eq_e in IH;
                      simpl in IH;
                      try rewrite eq_e in te
     end
   end
   || fail "No inductive hypothesis found");
  simpl in te;
  destruct (eq_letvar x x); try contradiction;
  idtac "inverting typing rule hypothesis";
  inversion te;
  app_tac;
  repeat match goal with
         | [H : ?t1 = ?t2 |- _] =>
           let tty := type of t1 in
           unify tty type;
           idtac "destructing type equality:" H;
           destruct H
         end;
  repeat multimatch goal with
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2, _ : ?t1 = ?t2 |- _ ] => fail
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2, _ : ?t2 = ?t1 |- _ ] => fail
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2 |- _ ] =>
           let teq := fresh "teq" in
           pose proof type_exp_unique as teq;
           specialize teq with (g := g) (t := t1) (t' := t2);
           specialize (teq e TE1 TE2);
           idtac "unified" TE1 "and" TE2 "via uniqueness of types";
           clear TE2;
           destruct teq
         end;
  first [assumption
        | match goal with
          | [ IH : forall t es1, _ -> _ -> forall es, _ -> ?g |-- [es./?x]?e ::: t,
                TES1 : ?g |-- [?es1./?x]?e ::: ?t'
                |- ?g |-- [?es./?x]?e ::: ?t ] =>
            apply IH with (es1 := es1); assumption
          | [ IH : forall t es1, _ -> _ -> forall es, _ -> ?g |-- es ::: t,
                TES1 : ?g |-- [?es1./?x]?e ::: ?t'
                |- ?g |-- ?e ::: ?t ] =>
            apply IH with (es1 := es1); assumption
          end]
  || fail "could not solve goal".


+let x := get_var_from_type_subst_goal in
  idtac "substituted variable:" x;
  let te := get_hyp_with_goal_type in
  idtac "typing judgment for e:" te;
    type_subst_IH x te.
  idtac "inverting typing rule hypothesis";
  inversion te.
Focus 2.



(*
 let app_tac := (apply t_mem) in
      type_subst_rec_case app_tac. *)
    +  let x := match goal with
             [ |- _ |-- ?e ::: _] =>
             match e with context [[_./?x]_] => x
             end end in
  idtac "substituted variable:" x;
  let te := match goal with
              [ te : ?g |-- _ ::: ?t |- ?g |-- _ ::: ?t ] => te
            end in
  idtac "typing judgment for e:" te;
  let resolve_letvar :=
      fun ei IHe te =>
        let eq_e := fresh "eq_ei" in
        let neq_e := fresh "neq_ei" in
        destruct (eq_exp ei (exp_letvar x)) as [eq_e | neq_e];
        idtac;
        try rewrite eq_e;
        simpl;
        (try rewrite eq_e in IHe);
        (simpl in IHe);
        (try rewrite eq_e in te) in
  (multimatch goal with
     [ IH : forall t es1, _ ->  _ -> forall es, _ -> ?g |-- [es./x]?ei ::: t |- ?g |-- ?e ::: _] =>
     lazymatch e with context [[es./x]ei] =>
                      idtac "resolving via" IH;
                      resolve_letvar ei IH te
     end
   end
   || fail "No inductive hypothesis found");
  simpl in te;
  destruct (eq_letvar x x); try contradiction;
  idtac "inverting typing rule hypothesis";
  inversion te.
        let nat5_var := fresh "nat5" in
           evar (nat5_var : nat);
           let sz_var := fresh "sz" in
           evar (sz_var : nat);
           idtac "t_load app"; apply t_load with (nat5 := nat5_var) (sz := sz_var).
        unfold sz0;
          
  repeat match goal with
         | [H : ?t1 = ?t2 |- _] =>
           let tty := type of t1 in
           unify tty type;
           idtac "destructing type equality:" H;
           destruct H
         end;
  repeat multimatch goal with
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2, _ : ?t1 = ?t2 |- _ ] => fail
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2, _ : ?t2 = ?t1 |- _ ] => fail
         | [ TE1 : ?g |-- ?e ::: ?t1, TE2 : ?g |-- ?e ::: ?t2 |- _ ] =>
           let teq := fresh "teq" in
           pose proof type_exp_unique as teq;
           specialize teq with (g := g) (t := t1) (t' := t2);
           specialize (teq e TE1 TE2);
           idtac "unified" TE1 "and" TE2 "via uniqueness of types";
           clear TE2;
           destruct teq
         end;
  first [eauto
        | match goal with
          | [ IH : forall t es1, _ -> _ -> forall es, _ -> ?g |-- [es./?x]?e ::: t,
                TES1 : ?g |-- [?es1./?x]?e ::: ?t'
                |- ?g |-- [?es./?x]?e ::: ?t ] =>
            apply IH with (es1 := es1); assumption
          | [ IH : forall t es1, _ -> _ -> forall es, _ -> ?g |-- es ::: t,
                TES1 : ?g |-- [?es1./?x]?e ::: ?t'
                |- ?g |-- ?e ::: ?t ] =>
            apply IH with (es1 := es1); assumption
          end]
  || fail "could not solve goal".



















 let app_tac := (
           let nat5 := fresh "nat5" in
           evar (nat5 : nat);
           let sz := fresh "sz" in
           evar (sz : nat);
           idtac "t_load app"; apply t_load with (nat5 := nat5) (sz := sz)) in
      type_subst_rec_case app_tac.

























let app_tac := (
           let nat5 := fresh "nat5" in
           evar (nat5 : nat);
           let sz := fresh "sz" in
           evar (nat5 : nat);
           idtac "t_load app"; apply t_load with (nat5 := nat5) (sz := sz)) in
      type_subst_rec_case app_tac.


 multimatch goal with
        [ sz : nat |- _ ] =>
        multimatch goal with
          [ nat5 : nat |- _ ] =>
          let app_tac := (apply t_load with (sz := sz) (nat5 := nat5)) in
          type_subst_rec_case app_tac
        end || fail "nat5 not found"
      end || fail "sz not found".

let app_tac_k := fun sz nat5 =>
                         (apply t_load with (sz := sz) (nat5 := nat5)
                         + fail 1 "could not apply load constructor with" sz nat5)in
      let app_tac_k' := fun sz =>
                         find_typed_k nat (app_tac_k sz) in
      let app_tac := ( find_typed_k nat app_tac_k')
      in type_subst_rec_case app_tac.
    + let app_tac := (apply t_load with (nat5 := nat0) (sz := sz)) in
      type_subst_rec_case app_tac.
    + let app_tac := (apply t_store with (nat5 := nat0) (sz := sz)) in
      type_subst_rec_case app_tac.
    + destruct bop5.
      * let app_tac := (apply t_aop with (aop5 := aop5)) in
        type_subst_rec_case app_tac.
      * let app_tac := (apply t_lop with (lop5 := lop5) (sz := sz)) in
        type_subst_rec_case app_tac.
    + let app_tac := (apply t_uop) in
      type_subst_rec_case app_tac.
    + let app_tac := (apply t_cast with (nat5 := nat0)) in
      type_subst_rec_case app_tac.
    + destruct (eq_letvar letvar5 x).
      *  destruct letvar5.
        inversion te.
        destruct H.
        destruct H1.
        destruct H4.
        destruct H0.
        destruct H2.
        apply t_let.
        apply IHe1 with (t := t0) (es1 := es1);
        rewrite <- e in IHe1;
        rewrite Heqx in e;
        inversion e;
        destruct H1;
          assumption.
        destruct x.
        inversion Heqx.
        destruct H0, H1.
        inversion e.
        destruct H0, H1.
        apply IHe2 with (es1 := [es1./letvar_var id0 t0]e1);
          try assumption.
        apply IHe1 with (es1 := es1);
          try assumption.
      * inversion te.
        destruct H2.
        apply t_let.
        apply IHe1 with (es1 := es1);
          try assumption.

Lemma subst_type_exp : forall g e t es id ts,
            g |-- e ::: t ->
            g |-- es ::: ts ->
            g |-- [es./letvar_var id ts] e :: t.

        apply IHe2 with (es1 := [es1./letvar_var id5 t0]e1).
    + let app_tac := (apply t_uop) in
      type_subst_rec_case app_tac.
    + let app_tac := (apply t_uop) in
      type_subst_rec_case app_tac.
    + let app_tac := (apply t_uop) in
      type_subst_rec_case app_tac.
    + 






let app_tac := (apply t_load with (nat5 := nat0)) in
      type_subst_rec_case app_tac.

    + let x := match goal with
                 [ |- _ |-- ?e ::: _] =>
                 match e with context [[_./?x]_] => x
                 end end in
      let resolve_letvar :=
          fun ei IHe te =>
            let eq_e := fresh "eq_ei" in
            let neq_e := fresh "neq_ei" in
            destruct (eq_exp ei (exp_letvar x)) as [eq_e | neq_e];
              try rewrite eq_e;
              simpl;
              (try rewrite eq_e in IHe);
              (simpl in IHe);
              (try rewrite eq_e in te) in
      multimatch goal with
        [ IH : forall t, _ -> forall es, _ -> ?g |-- [es./x]?ei ::: t |- ?g |-- ?e ::: _] =>
        lazymatch e with context [[es./x]ei] =>
                       resolve_letvar ei IH te
        end
      end;
      simpl in te;
          destruct (eq_letvar x x); try contradiction;
            inversion te;
            apply t_load with (nat5 := nat0);
            first [assumption |
                   match goal with
                   | [ IH : forall t, _ -> forall es, _ -> ?g |-- [es./?x]?e ::: t
                                                      |- ?g |-- [?es./?x]?e ::: ?t ] =>
                     apply IH; assumption
                   | [ IH : forall t, _ -> forall es, _ -> ?g |-- es ::: t
                                                      |- ?g |-- ?e ::: ?t ] =>
                     apply IH; assumption
                   end].


match goal with
[ IH : forall t, _ -> forall es, _ -> ?g |-- [es./x]?ei ::: t |- ?g |-- ?e ::: _] =>
match e with context [[es./x]ei] => resolve_letvar e1 IHe1 te
end
end


let resolve_letvar := fun e1 IHe1 te =>
destruct (eq_exp e1 (exp_letvar x)) as [eq_e1 | neq_e1];
        try rewrite eq_e1;
        simpl;
        try rewrite eq_e1 in IHe1;
        simpl in IHe1;
        try rewrite eq_e1 in te;

 apply t_load with (nat5 := nat0);
      apply t_store;




      inversion H5.
      specialize (teqts H5 H6).
      specialize teqts with g es1 (type_mem nat0 nat5) ts.
      specialize (teqts H5 tes1).
      rewrite teqts.
      assumption.

simpl in te. 
      destruct (eq_letvar letvar5 x).
      elim n. inversion e. reflexivity.
      simpl in te.
      
apply t_var with (t := type5). constructor with (t := type5).
    + apply subst_inversion in Heqe';
      try (rewrite Heqe'; simpl; constructor);
        try( rewrite type_exp_no_lfv with (g := G) (t := ts); simpl);
        auto.
    + 


apply subst_inversion with (es := es2) in Heqe';
      try (rewrite Heqe'; simpl; constructor);
        try( rewrite type_exp_no_lfv with (g := G) (t := ts); simpl);
        auto.











    generalize dependent es1.
    generalize dependent ts.
    generalize dependent x.
    induction te;
      simpl;
      intros x enl ts es1 tes1 e_subst1_eq es2 tes2;
      symmetry in e_subst1_eq.
    + apply letsubst_inversion_var in e_subst1_eq;
        try (rewrite e_subst1_eq; simpl; constructor);
        assumption.
    + apply subst_inversion in e_subst1_eq;
      try (rewrite e_subst1_eq; simpl; constructor);
        try( rewrite type_exp_no_lfv with (g := G) (t := ts); simpl);
        auto.
    + apply subst_inversion with (es := es2) in e_subst1_eq;
      try (rewrite e_subst1_eq; simpl; constructor);
        try( rewrite type_exp_no_lfv with (g := G) (t := ts); simpl);
        auto.

 apply subst_inversion in e_subst1_eq;
        try rewrite e_subst1_eq;
        first [ assumption
              | simpl; constructor].


  all: try solve [auto | assumption].
  - destruct (eq_letvar letvar5 x).
    pose proof type_exp_unique as teu.
    specialize teu with (g := g) (t := ts) (t' := t).
    specialize (teu es1 tes1 tses1) as teu1.
    rewrite <- teu1.
    assumption.
    assumption.
  - (* TODO: improve this tactic! *)
    let app_tac := (apply t_load with nat0) in
    type_subst_rec_case app_tac.
  - let app_tac := (apply t_store) in
    type_subst_rec_case app_tac.
  - let app_tac :=
        fun _ =>
          let sz := match goal with
                    | [ _ : type_exp _ _ (type_imm ?sz) |- _ ] => sz
                    end in
          first [ apply t_aop | apply t_lop with sz] in
    let t := match goal with
             | [ |- type_exp _ _ ?t ] => t
             end in
    type_subst_rec_case app_tac.
  - let app_tac := (apply t_uop) in
    type_subst_rec_case app_tac.
  - (* TODO: improve this tactic! *)
    let app_tac := (apply t_cast with nat0) in
    type_subst_rec_case app_tac.
  - destruct (eq_letvar letvar5 x);
      destruct letvar5;
      apply t_let;
      inversion tses1.
    + apply IHe1 with (es1 := es1) (ts := ts);  assumption.
    + apply IHe2 with (es2 := [es2./x]e1) (es1 := [es1./x]e1) (ts:=type5);
        try apply IHe1 with (es1:=es1) (es2:=es2) (ts := ts);
        assumption.
    + apply IHe1 with (es1 := es1) (ts := ts);  assumption.
    + rewrite letsubst_distributes with (es1 := [es2 ./ x] e1).
      inversion H6.
      

 apply IHe2 with (es2 := [es2./x]e1) (es1 := [es1./x]e1) (ts:=type5);
        try apply IHe1 with (es1:=es1) (es2:=es2) (ts := ts);
        assumption.

    rewrite e in tses1.
    apply t_let.
destruct letvar5.
    
    apply t_let.
    simpl in tses1.
    destruct t; inversion tses1.
      apply t_let.
    apply IHe1 with (ts := type5).
    
destruct (eq_letvar letvar5 x).
    + destruct letvar5.
      apply t_let.
      apply t_let with (e1 := [es2./x]e1) (t' := t).

    type_subst_rec_case app_tac.
  - 





Ltac type_subst_rec_case app_tac :=
  let t := match goal with
           | [ |- type_exp _ _ ?t ] => t
           end in
  try (destruct t; inversion tses1);
  first [app_tac | app_tac ()];
  try match goal with
      | [ H : forall ts t : type,
            _ -> _ ->
            type_exp ?G [_./?x]?e t ->
            type_exp ?G [_./?x]?e t |- _ ] =>
        apply H with (ts := ts)
      end; assumption.







destruct t; inversion tses1.
    apply t_load with (nat5 := nat0);
      match goal with
      | [ H : forall ts t : type, _ -> _ ->
                                  type_exp ?G [_./?x]?e t ->
                                  type_exp ?G [_./?x]?e t |- _ ] =>
        apply H with (ts := ts)
      end; try assumption.
  - destruct t; inversion tses1.
    apply t_store;
      try match goal with
          | [ H : forall ts t : type,
                _ -> _ ->
                type_exp ?G [_./?x]?e t ->
                type_exp ?G [_./?x]?e t |- _ ] =>
            apply H with (ts := ts)
          end; assumption.

    constructor.
    all: try assumption.
    apply IHe1 with (ts := ts).
    all: try assumption.
    apply IHe2 with (ts := ts).
    all: try assumption.
    apply IHe3 with (ts := ts).
    all: try assumption.

  remember  ([es1./x] e) as e'.
  induction tses1.
  - symmetry in Heqe'.
    apply subst_inversion_var in Heqe'.
    + rewrite Heqe';
        simpl;
        constructor;
        assumption.
    + intro eeql.
      

pose proof subst_inversion_var as s_inv_var.
    specialize (s_in_var 

  all: try solve [rewrite <- Heqe'; auto].
  

Ltac preservation_rec_case C :=
  match goal with
  | [ IH : ?A -> forall t : type, ?P t -> ?Q t,
        H : ?P ?t',
        td : ?A |- _ ] =>
    specialize (IH td) with t';
    apply C;
    try apply IH; assumption
  end.

Ltac preservation_base_case C :=
  match goal with
  | [ H : type_exp ?d _ _ |- type_exp ?d _ _] =>
    apply C;
    apply type_exp_typ_gamma in H;
    assumption
  end.


Lemma exp_preservation : forall d e e' t,
    type_delta d ->
    type_exp (map fst d) e t ->
    exp_step d e e' ->
    type_exp (map fst d) e' t.
Proof.
  intros d e e' t td te es.
  generalize dependent t.
  induction es; intros t0 te; inversion te.
  - pose proof in_delta_types as v_types.
    specialize v_types with id5 t0 v delta5.
    rewrite <- H1 in H0.
    rewrite H5 in H0.
    specialize (v_types td H0).
    rewrite <- H3.
    rewrite <- (app_nil_r G).
    rewrite <- (app_nil_l (G ++ nil)).
    apply (exp_weakening nil G nil).
    + simpl; auto.
    + simpl; rewrite app_nil_r; rewrite H3; assumption.
  - rewrite H4 in H; contradiction.
  - preservation_rec_case (t_load (map fst delta5) e1 e2' ed sz nat5).
  - preservation_rec_case (t_load (map fst delta5) e1' v2 ed sz nat5).
  - match goal with
    | [ H : type_exp ?d ?eh _ |- type_exp ?d ?e _ ] =>
      match eh with
      | context c [e] =>
        inversion H
      end
    end.
    assumption.
  - preservation_base_case t_unknown.
  - inversion H8.
    apply (t_load (map fst delta5) _ _ ed _ nat5);  assumption.
  - preservation_base_case t_unknown.
  - rewrite H4 in H11.
    inversion H11.
    rewrite H21 in H2.
    elim (n_Sn sz').
    omega.
  - rewrite H4 in H11.
    inversion H11.
    rewrite H21 in H2.
    elim (n_Sn sz').
    omega.
  - preservation_rec_case t_store.
  - preservation_rec_case t_store.
  - preservation_rec_case t_store.
  - rewrite H5 in H16.
    inversion H16.
    rewrite H27 in H3.
    elim (n_Sn sz').
    omega.
  - rewrite H5 in H16.
    inversion H16.
    rewrite H27 in H3.
    elim (n_Sn sz').
    omega.
  - apply t_let.
    match goal with
    | [ IH : ?A -> forall t : type, ?P t -> ?Q t,
          H : ?P ?t',
          td : ?A |- _ ] =>
      specialize (IH td) with t';
        try apply IH; assumption
    end.
    

  - strengthen_rec_case (t_aop g e1 aop5 e2).
  - strengthen_rec_case (t_lop g e1 lop5 e2 sz).
  - strengthen_rec_case (t_uop g uop5 e1).
  - strengthen_rec_case (t_cast g cast5 sz e nat5). apply t_load.

  Lemma wf_all_val : forall d x v, delta_wf d -> In (x,v) d -> is_val_of_exp v.
  Proof.
    intros d x v wf x_in.
    induction wf.
    - contradiction.
    - destruct x_in as [H_in | H_in].
      + inversion H_in.
        rewrite <- H3; assumption.
      + apply IHwf.
        assumption.
  Qed.