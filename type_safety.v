Require Import List.
Require Import Arith.
Require Import Omega.

Require Import bil.bil.

Local Open Scope bil_exp_scope.

Ltac smart_induction x :=
  intros until x;
  repeat match goal with
           y : _ |- _ =>
           tryif unify y x then fail else revert y end;
  induction x.

Lemma Nth_app : forall {A : Set} (l l' : list A) n a, Nth l n a -> Nth (l ++ l') n a.
Proof.
  intros A l l' n a nth;
    induction nth;
    simpl;
    constructor;
    assumption.
Qed.

Lemma app_Nth : forall {A : Set} (l l' : list A) n a,
    n < length l ->
    Nth (l ++ l') n a ->
    Nth l n a.
Proof.
  smart_induction l;
    intros l' n aa nlt nth.
  simpl in nlt; inversion nlt.
  simpl in nth; inversion nth.
  constructor.
  subst.
  constructor.
  eapply IHl.
  simpl in nlt; omega.
  eassumption.
Qed.

Lemma Nth_not_empty : forall {A : Set} (l : list A) n a, Nth l n a -> l <> nil.
Proof.
  smart_induction l.
  intros.
  inversion H.
  intros.
  intro Hne; inversion Hne.
Qed.
Lemma Nth_length : forall {A : Set} (l : list A) n a, Nth l n a -> n < length l.
Proof.
  smart_induction l;
    intros; inversion H; subst.
  simpl; omega.
  simpl.
  apply lt_n_S.
  eauto.
Qed.

Ltac solve_Nth :=
  solve [ apply Nth_app; assumption
        | eapply app_Nth; eassumption ].

Hint Extern 9 (Nth _ _ _) => solve_Nth.

Ltac destruct_decisions_with rules :=
  repeat (match goal with
         | |- context [lt_dec ?n1 ?n2] =>
           destruct (lt_dec n1 n2)
         | |- context [lt_eq_lt_dec ?n1 ?n2] =>
           destruct (lt_eq_lt_dec n1 n2)
         | dec : {_} + {_} |- _  => destruct dec
         end; simpl);
  try rewrite rules;
  try first [reflexivity | f_equal; omega].

Ltac destruct_decisions := destruct_decisions_with ().

Lemma lift_by_0 : forall n e, lift 0 n e = e.
Proof.
  intros; revert n; induction e; intro n; simpl; auto;
    try (repeat multimatch goal with
             [ H : forall n, _ = _ |- ?g] => try rewrite H; clear H
           end; reflexivity).
  - destruct_decisions.
Qed.

Lemma combine_lift : forall p i n k e, k <= i -> i <= k + n ->
    lift p i (lift n k e) = lift (p + n) k e.
Proof.
  intros p i n k e;
    revert p i n k;
    induction e;
    intros p i n k klei ilekn;
    simpl; auto;
  repeat match goal with
           [ IH : forall p i n k _ _, lift p i (lift n k ?e) = lift (p + n) k ?e |- _] =>
           rewrite IH; clear IH
         end;
  try first [omega | reflexivity].
  - destruct_decisions_with Nat.add_assoc.
Qed.

Lemma commute_lift : forall p i n k e, i <= k ->
    lift p i (lift n k e) = lift n (p + k) (lift p i e).
Proof.
  intros p i n k e;
    revert p i n k;
    induction e;
    intros p i n k ilek;
    simpl; auto;
  repeat match goal with
           [ IH : forall p i n k _, lift p i (lift n k ?e) = lift n (p + k) (lift p i ?e) |- _] =>
           rewrite IH; clear IH
         end;
  try first [omega | reflexivity].
  - destruct_decisions.
  - replace (p + S k) with (S (p + k)) by omega;
      reflexivity.
Qed.

Lemma lift_drop_subst : forall n k p e e', k <= p -> p <= n + k ->
    [e'./p](lift (S n) k e) = (lift n k e).
Proof.
  intros n k p e;
    revert n k p;
    induction e;
    intros n k p e' klep plenk;
    simpl; auto;
      repeat match goal with
               [ IH : forall n k p e' _ _, [e' ./ p] (lift (S n) k ?e) = lift n k ?e |- _] =>
               rewrite IH; clear IH
             end;
      try first [omega | reflexivity].
  destruct_decisions.
Qed.


Lemma commute_lift_subst : forall p n k es e, k <= p ->
    lift n k ([es./p]e) = [es./n+p](lift n k e).
Proof.
  smart_induction e;
    simpl; auto;
      intros p n k es klep;
      f_equal;
      auto.
  destruct_decisions; try omega;
  rewrite combine_lift; try omega;
  reflexivity.
  replace (S (n + p)) with (n + S p) by omega.
  match goal with
    H : context[lift _ _ ?e]
    |- context[lift _ _ ?e] =>
    apply H
  end.
  omega.
Qed.

Lemma distribute_lift_subst : forall p n e es es',
    [es'./p+n]([es./p]e) = [[es'./n]es./p]([es'./p+n+1]e).
Proof.
  smart_induction e;
    simpl; auto;
      intros p n es es';
      try now (f_equal; auto).
  destruct_decisions;
    try replace (p + n + 1) with (S (p + n)) by omega;
    try rewrite lift_drop_subst;
    try rewrite commute_lift_subst;
    first [reflexivity | omega].
  f_equal; auto.
  try replace (S (p + n)) with (S p + n) by omega;
  auto.
  match goal with H : context [[_./_] e2] |- _ => apply H end.
Qed.

Lemma distribute_subst : forall p n e es es',
    [es'./p + n]([es./p]e) = [[es'./n]es./p]([es'./p + n + 1]e).
Proof.
   smart_induction e;
    simpl; auto;
      intros p n es es';
      try now (f_equal; auto).
   destruct_decisions;
     try replace (p + n + 1) with (S (p + n)) by omega;
     try rewrite lift_drop_subst;
     try rewrite commute_lift_subst;
     solve [omega | reflexivity].
   f_equal; auto.
   try replace (S (p + n)) with (S p + n) by omega.
   match goal with H : context [[_./_] e2] |- _ => apply H end.
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
  first [let app_tac := (econstructor) in tac app_tac
        | let bop5 := find_typed bop in
          destruct bop5;
          first [ let app_tac := (apply t_aop) in tac app_tac
                | let app_tac := (eapply t_lop) in tac app_tac] ].

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
    | exp_letvar => constructor
                    || fail "could not use t_letvar"
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
    | exp_cast =>
      destruct_all cast;
      let cast := match e with context[exp_cast ?c] => c end in
      match cast with
      | cast_high =>
        eapply t_cast_narrow
      | cast_low =>
        eapply t_cast_narrow
      | cast_signed =>
        eapply t_cast_widen
      | cast_unsigned =>
        eapply t_cast_widen
      end || fail "could not apply cast rule; TODO: improve"
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
    try now (econstructor; eauto).
  - rewrite HeqG in H.
    apply in_app_or in H.
    constructor; auto.
    apply in_or_app.
    destruct H; auto; auto.
    + right; apply in_or_app; right; assumption.
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

Lemma app_typ_gamma : forall g g',
    typ_gamma (g ++ g') -> typ_gamma g /\ typ_gamma g'.
Proof.
  induction g; simpl.
  split; [constructor | assumption].
  intros g' appwf;
  inversion appwf.
  specialize (IHg g' H3);
  destruct IHg;
  split;
    [constructor|]; auto.
  rewrite map_app in H1.
  intro ing.
  elim H1.
  apply in_or_app.
  auto.
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
           | [H : typ_lgamma (_ :: _) |- _] =>
             inversion H;
             clear H
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


Hint Extern 9 (typ_lgamma _) => solve_typ_lgamma.

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
Qed.

Lemma exp_let_weakening1 : forall g lg lg' e t,
    typ_lgamma lg' ->
    g;lg|-- e ::: t -> g; lg ++ lg' |-- e ::: t.
Proof.
  intros g lg lg' e t.
  revert lg lg' t.
  induction e;
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
  inversion H0.
  constructor; auto.
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
  | (exp_mem v w v' sz) => (max (max_lfv v) (max_lfv v'))
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
    repeat (apply Nat.max_lub; eauto);
    try match goal with
          H : Nth _ _ _ |- _ =>
          apply Nth_length in H;
            omega
        end.
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
Qed.

Lemma exp_let_strengthening1 : forall g lg lg' e t,
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
    try solve [apply_type_rule; auto
        |do_for_all_exps app_tac].
Qed.

Ltac smart_induction_using x ind :=
  intros until x;
  repeat match goal with
           y : _ |- _ =>
           tryif unify y x then fail else revert y end;
  induction x using ind.

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

Lemma lvar_type_wf : forall lg t, typ_lgamma lg -> In t lg -> type_wf t.
Proof.
  induction lg;
    intros t tlg inlg;
    inversion inlg.
  inversion tlg;
    subst;
    assumption.
  apply IHlg; auto.
Qed.

Lemma Nth_In : forall {A : Set} l n (a : A), Nth l n a -> In a l.
Proof.
  smart_induction l;
    intros; inversion H.
  constructor; reflexivity.
  subst.
  simpl.
  right.
  eapply IHl.
  eassumption.
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

  apply Nth_In in H0.
  eapply lvar_type_wf; eauto.
  inversion H0.
  apply IHe with (gl := l).
  subst.
  inversion te.
  econstructor; eauto.
  constructor.
  omega.
  apply IHe1 in H3;
    apply IHe2 in H5.
  inversion H3;
    inversion H5;
    constructor; omega.
Qed.

Ltac solve_type_wf :=
  tryif match goal with [ |- type_wf _] => idtac end then idtac
  else fail "goal not a type wellformedness judgment";
  match goal with H : _;_|-- _ ::: _ |- _ => apply type_exp_typ_lgamma in H end;
  match goal with H : typ_lgamma (_ :: _) |- _ => inversion H end;
  auto;
  solve [match goal with
           [H : ?sz > 0 |- type_wf (type_imm ?sz)] =>
           constructor; assumption
         end
        | constructor; solve [auto | omega]
        | eapply type_exp_type_wf; eauto].

Hint Extern 9 (type_wf _) => solve_type_wf.

Ltac solve_typ_gamma :=
  tryif match goal with [ |- typ_gamma _ ] => idtac end then idtac
  else fail "goal not a context wellformedness judgment";
  match goal with
    [H : ?g;_ |-- _ ::: _ |- typ_gamma ?g] =>
    apply type_exp_typ_gamma in H; assumption
  end.

Hint Extern 9 (typ_gamma _) => solve_typ_gamma.

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
  apply_type_rule;
  try eassumption; eauto;
  solve [ solve_is_multiple
        | solve_size_constraint
        | constructor
        | solve_type_wf
        | tac
        | solve_type_rule_using tac].

Ltac solve_type_rule := solve_type_rule_using idtac.

Ltac destruct_all typ :=
  repeat match goal with
         | [ e : typ |- _] => destruct e
         end.


Lemma lift_val : forall n m v, is_val_of_exp v -> lift n m v = v.
Proof.
  intros n m v;
    induction v;
    simpl; intro vv;
      inversion vv;
      reflexivity.
Qed.

(*
Lemma exp_let_strengthening2 : forall g lg lg' e t,
    g; lg ++ lg' |-- ^(length lg) e ::: t ->
       g;lg'|-- e ::: t.
Proof.
  smart_induction e; simpl; intros.
  - destruct_all var;
      match goal with H : _;_ |-- _ ::: _ |- _ => inversion H end.
    constructor; auto.
  - induction lg;
      simpl; intros; auto.
    match goal with H : _;_ |-- _ ::: _ |- _ => inversion H end;
      subst.
      match goal with
        H : context[_;_|-- ?e ::: _] |- _;_|-- ?e ::: _ =>
        apply H
      end;
      simpl; auto.
  - inversion H.
    subst.
    destruct_all word.
    solve_type_rule.
  - inversion H.
    subst.
    constructor; auto;
    match goal with H : context [_;_|-- ?e ::: _] |- _;_|-- ?e ::: _ =>
                    eapply H;
                      rewrite lift_val; eauto
    end.
  - *)

Lemma app_Nth_ge : forall {A : Set} l l' n (a : A),
    n >= length l ->
    Nth (l ++ l') n a ->
    Nth l' (n - length l) a.
Proof.
  smart_induction l;
    simpl; intros.
  rewrite Nat.sub_0_r;
    assumption.
  destruct n; [omega|
               inversion H0;
               subst;
               simpl;
               apply IHl;
               [omega | assumption]].
Qed.

Lemma exp_letvar_strengthening2 : forall g gl gl' lid t,
    lid >= length gl' ->
    g;gl'++gl |-- exp_letvar lid ::: t ->
      g;gl |-- exp_letvar (lid - length gl') ::: t.
Proof.
  intros g gl gl' lid t lidge lidt.
  constructor; auto.
  inversion lidt.
  subst.
  apply app_Nth_ge; auto.
  Qed.

(*
Lemma exp_let_weakening2 : forall g lg lg' e t,
    typ_lgamma lg ->
    g;lg' |-- e ::: t ->
      g;lg++lg' |-- ^(length lg) e ::: t.
Proof.
  smart_induction e;
    intros g lg lg' tt tlg te;
    inversion te;
    subst;
    try constructor; auto.
  induction lg;
  simpl;[|constructor]; auto.
  induction lg;
  simpl;[|constructor]; auto.
  match goal with
    H : forall g lg lg' t _ _, g;lg++lg'|-- ^_ ?e ::: t
    |- ?g;?lg++?lg' |-- ?e ::: ?t =>
    specialize (H g lg lg' t);
      rewrite lift_val in H;
      auto
  end.
  match goal with
    H : forall g lg lg' t _ _, g;lg++lg'|-- ^_ ?e ::: t
    |- ?g;?lg++?lg' |-- ?e ::: ?t =>
    specialize (H g lg lg' t);
      rewrite lift_val in H;
      auto
  end.
  simpl;
    econstructor;
    eauto.
  simpl;
    econstructor;
    eauto.
  simpl;
    econstructor;
    eauto.
  simpl.
  destruct cast5.
  eapply t_cast_narrow; eauto.
  eapply t_cast_narrow; eauto.
  match goal with H : is_narrow_cast_of_cast cast_signed |- _ => inversion H end.
  match goal with H : is_narrow_cast_of_cast cast_unsigned |- _ => inversion H end.
  fold lift.
  eapply t_cast_widen; eauto.
  simpl.
    apply
    eauto.
  simpl;
    econstructor;
    eauto.
  *)

Lemma Nth_app_ge : forall {A : Set} l l' n (a : A),
    Nth l' n a -> Nth (l ++ l') (n + length l) a.
Proof.
  smart_induction l;
    simpl; intros.
  rewrite Nat.add_0_r.
  assumption.
  rewrite Nat.add_succ_r.
  constructor.
  auto.
Qed.

Lemma exp_let_weakening : forall g lg wlg lg' e t,
    typ_lgamma wlg ->
    g;lg++lg'|-- e ::: t ->
      g; lg ++ wlg ++ lg' |-- lift (length wlg) (length lg) e ::: t.
Proof.
  intros g lg wlg lg' e;
    revert lg wlg lg';
    induction e;
    intros lg wlg lg' tt twlg te;
    inversion te; try now (simpl; econstructor; eauto).
  subst.
  constructor.
  destruct_decisions.
  apply Nth_app.
  apply app_Nth in H0; auto.
  apply app_Nth_ge in H0.

  apply Nth_app_ge with (l := lg ++ wlg) in H0.
  rewrite app_length in H0.
  rewrite Nat.add_assoc in H0.
  rewrite Nat.sub_add in H0.
  rewrite Nat.add_comm.
  rewrite List.app_assoc.
  assumption.
  omega.
  omega.
  auto.
  auto.
  constructor; auto.
  match goal with H : context [_;_|-- lift _ _ ?e ::: _] |- _;_|-- ?e ::: ?t =>
                  specialize (H lg wlg lg' t);
                  rewrite lift_val in H;
                  auto
  end.
  match goal with H : context [_;_|-- lift _ _ ?e ::: _] |- _;_|-- ?e ::: ?t =>
                  specialize (H lg wlg lg' t);
                  rewrite lift_val in H;
                  auto
  end.
  simpl; constructor; auto.
  specialize (IHe2 (t:: lg) wlg lg' tt).
  simpl in IHe2.
  apply IHe2; auto.
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


(*
Lemma let_closed_lift : forall g gl e t n,
    g;gl |-- e ::: t -> lift n (length gl) e = e.
Proof.
  intros g gl e; revert gl;
    induction e using exp_ind_rec_lid;
    intros gl tt et;
    simpl;
    auto;
    inversion et;
    subst;
    f_equal;
    try match goal with
          [ H : forall gl t, _ -> lift_above (length gl) ?e = ?e
                             |- lift_above _ ?e = ?e] =>
          eapply H; eassumption
        end.
  - simpl.
    destruct (lt_dec (S lid5) (S (length Gl))).
    reflexivity.
    elim n.
    apply max_lfv_length_env in H3.
    simpl in H3.
    omega.
  - apply IHe2 with (gl := t::gl) (t := tt).
    assumption.
Qed.
*)
(*
Lemma exp_let_strengthening : forall g lg wlg lg' e t,
      g; lg ++ wlg ++ lg' |-- lift (length wlg) (length lg) e ::: t ->
         g;lg++lg'|-- e ::: t.
Proof.
  smart_induction e;
    simpl;
    intros g lg wlg lg' tt te;
    inversion te;
    subst;
    try constructor; auto.
  match goal with H : context[lt_dec ?m ?n] |- _ => destruct (lt_dec m n) end.
  destruct lg.
  inversion l.
  inversion H.
  subst; simpl; constructor; auto.
  symmetry in H0.
  apply plus_is_O in H0.
  destruct H0.
  subst.
  destruct lg.
  destruct wlg.
  simpl.
  simpl in H.
  inversion H.
  constructor; auto.
  simpl in H0; inversion H0.
  simpl in n; omega.

  match goal with H : context[lt_dec ?m ?n] |- _ => destruct (lt_dec m n) end.
  subst.
  apply exp_let_strengthening1 in te.
Admitted.
(*
  rewrite <- app_nil_r with (l := lg).
  rewrite <- app_assoc.
  erewrite <- lift_by_0 with (e := exp_letvar (S lid0)).
  apply exp_let_weakening.
  constructor.
  

  destruct lg.
  - inversion l.
  - inversion H.
    subst.
    simpl; constructor; auto.
    simpl in l.
    assert (lid0 < length lg) by omega.
    eapply exp_let_strengthening1.
    simpl.
    rewrite app_length.
    omega.
    
    Search (length (_++_)).
    inversion l.
    

  inversion H0.
  Search (_ + _ = 0).

  intros.
  eapply exp_let_strengthening2.
  give_up.
  
  eapply max_lfv_length_env.
  Search max_lfv.

*)

Lemma letsubst_type : forall g gl1 gl2 lid t e' t',
    g;gl2 |-- e' ::: t' ->
      g;gl1 ++ (t'::gl2) |-- lift 1 (length gl1) (exp_letvar lid) ::: t ->
        g;gl1++gl2 |-- ([e'./length gl1](exp_letvar lid)) ::: t.
Proof.
  intros g gl1 gl2 lid t e' t'.
  intros.
  simpl.
  destruct_decisions.
  replace 1 with (length (t'::nil)) in H0 by (simpl; auto).
  replace (t'::gl2) with ((t'::nil)++gl2) in H0 by (simpl;auto).
  eapply exp_let_strengthening in H0.

  replace (exp_letvar lid) with (lift 0 0 (exp_letvar lid)) by (rewrite lift_by_0; auto).
  replace (length gl1) with (0 + length gl1) by (simpl; auto).
  rewrite <- commute_lift_subst.
  




  simpl.
  destruct_decisions.
  intros e't lidt.
  rewrite <- e in lidt.
  simpl.
  replace t with t'.
  rewrite <- app_nil_l with (l := gl2) in e't.
  apply exp_let_weakening with (wlg := gl1) in e't.
  simpl in e't.
  assumption.
  auto.
  apply exp_letvar_strengthening2 in lidt.
  replace (length gl1 - length gl1) with 0 in lidt by omega.
  inversion lidt.
  reflexivity.
  omega.
  generalize dependent gl1.
  revert gl2.
  induction lid.
  intros gl2 gl1 l0' l0 e't lidt.
  destruct gl1; simpl in l0; try omega.
  simpl.
  inversion lidt.
  constructor; auto.
  intros gl2 gl1 l0' l0 e't lidt.
  destruct gl1; simpl in l0; try omega.
  inversion lidt.
  subst.
  constructor; auto.
  fold (@app type).
  apply IHlid; auto.
  omega.
  omega.
  intros.
  generalize dependent lid.
  revert gl2.
  induction gl1.
  intros.
  

  replace (exp_letvar (length gl1)) with (^ (length gl1) (exp_letvar 0)) in lidt.
  apply exp_let_strengthening in lidt.

  replace (S (length gl1)) with (length gl1 + 1) by omega.
  replace (a::gl1 ++ gl2) with ((a::nil) ++ gl1 ++ gl2) by (simpl ; auto).
  erewrite <- combine_lift.
  apply exp_let_weakening; auto.
  rewrite <- app_nil_l with (l := gl2) in e't.
  apply exp_let_weakening with (wlg := gl1) in e't.
  simpl in e't.
  
  replace (t' :: gl2) with ((t'::nil) ++ gl2) in lidt.
  smart_induction e;
    intros g gl1 gl2 lid tt e' tt';

*)


Lemma value_drop_lift : forall n m g gl v t,
    is_val_of_exp v ->
    g;gl |-- lift n m v ::: t ->
      g;gl |-- v ::: t.
Proof.
  induction v; simpl; tauto.
Qed.

Lemma value_types_any_context : forall g g' gl gl' v t,
    typ_gamma g' ->
    typ_lgamma gl' ->
    is_val_of_exp v ->
    g;gl |-- v ::: t ->
      g';gl' |-- v ::: t.
Proof.
  intros g g' gl gl' v t g't gl't vv vt.
  apply val_closed in vt;try assumption.
  match goal with
    |- ?g;_ |-- _ ::: _ =>
    rewrite <- app_nil_r with (l := g);
      rewrite <- app_nil_l with (l := g ++ nil)
  end.
  apply exp_weakening.
  match goal with
    |- _;?gl |-- _ ::: _ =>
    rewrite <- app_nil_r with (l := gl);
      rewrite <- app_nil_l with (l := gl ++ nil)
  end.
  eapply value_drop_lift; auto.
  apply exp_let_weakening; auto.
  simpl.
  rewrite app_nil_r.
  assumption.
Qed.


Lemma letsubst_type : forall g gl1 gl2 e t e' t',
    g;gl2 |-- e' ::: t' ->
      g;gl1 ++ (t'::gl2) |-- e ::: t ->
        g;gl1++gl2 |-- ([e'./length gl1]e) ::: t.
Proof.
  smart_induction e;
  intros g gl1 gl2 tt e' tt' e't et;
  inversion et;
  subst;
  try now (simpl; econstructor; eauto).
  simpl.
  destruct_decisions.
  destruct lid5.
  simpl in l; inversion l.
  simpl.
  rewrite Nat.sub_0_r.
  constructor; auto.
  replace lid5 with (lid5 - length gl1 + length gl1) by omega.
  apply Nth_app_ge.
  apply app_Nth_ge in H0.
  replace (S lid5 - length gl1) with (S (lid5 - length gl1)) in H0 by omega.
  inversion H0.
  subst.
  assumption.
  omega.
  replace (gl1 ++ gl2) with (nil ++ gl1 ++ gl2) by (simpl; reflexivity).
  apply exp_let_weakening; auto.
  simpl.
  subst.
  apply app_Nth_ge in H0; auto.
  rewrite Nat.sub_diag in H0.
  inversion H0.
  subst; assumption.
  simpl in et.
  destruct (lt_dec lid5 (length gl1 + 1)); try omega.
  apply exp_let_strengthening1 in et.
  rewrite <- app_nil_r with (l := gl1) in et.
  apply exp_let_weakening with (wlg := gl2) in et.
  simpl in et.
  destruct (lt_dec lid5 (length gl1)); try omega.
  rewrite app_nil_r in et.
  assumption.
  auto.
  auto.
  simpl; constructor; auto.
  eapply value_types_any_context; eauto.
  eapply value_types_any_context; eauto.
  simpl; constructor; eauto.
  rewrite app_comm_cons.
  eapply IHe2; eauto.
Qed.

Hint Immediate type_exp_type_wf.

Lemma ext_high_size : forall sz sz',
    sz > 0 ->
    sz' >= sz -> match sz' - sz with
                 | 0 => S (sz' - 1)
                 | S l => sz' - 1 - l
                 end  = sz.
Proof.
  intros sz sz' szgtz sz'gt.
  simpl.
  destruct (Nat.eq_dec sz' sz).
  subst.
  replace (sz - sz) with 0 by omega.
  omega.
  assert (sz' > sz) by omega.
  replace (sz' - sz) with (S (sz' - sz - 1)) by omega.
  omega.
Qed.


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
                eauto];
    unify_sizes;
    try solve_type_rule.
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
  - constructor; eauto.
    + destruct_existentials.
      subst.
      exists (x - 1).
      rewrite Nat.mul_sub_distr_r.
      simpl.
      rewrite Nat.add_0_r.
      reflexivity.
    + omega.
    + solve_type_rule.
    + eapply exp_type_succ; eauto.
    + solve_type_rule.
  - let tac := (first [omega | eapply exp_type_succ; eauto]) in
      solve_type_rule_using tac.
  - rewrite <- app_nil_l with (l := nil).
    eapply letsubst_type; eauto.
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
  - destruct_all word.
    unify_sizes.
    solve_type_rule.
  - destruct_all word.
    unify_sizes.
    unfold ext.
    unfold ext'.
    replace (sz1 - sz2 + 1) with (S sz1 - sz2) by omega.
    solve_type_rule.
  - destruct_all cast;
    try match goal with
      [ H : is_widen_cast_of_cast _ |- _] =>
      simpl in H; contradiction
    end;
    solve_type_rule.
  - destruct_all cast;
    try match goal with
      [ H : is_narrow_cast_of_cast _ |- _] =>
      simpl in H; contradiction
    end;
    solve_type_rule.
  - destruct_all word.
    unfold ext;
      unfold ext'.
    replace (type_imm sz) with (type_imm (S (sz - 1) - 0))
        by (f_equal; omega).
    solve_type_rule.
  - destruct_all word.
    unfold ext;
      unfold ext'.
    replace (type_imm sz) with (type_imm (S (sz - 1) - 0))
        by (f_equal; omega).
    solve_type_rule.
  - simpl in H2; contradiction.
  - unfold ext;
      unfold ext'.
    simpl.
    rewrite <- ext_high_size with (sz := sz) (sz' := sz') at 3.
    match goal with
      [|- _;_|-- exp_int (sized ?w') ::: _] =>
      rewrite <- Word.natToWord_wordToNat with (w := w')
    end.
    apply t_int.
    rewrite ext_high_size.
    assumption.
    assumption.
    inversion H8.
    subst.
    assumption.
    solve_typ_gamma.
    solve_typ_lgamma.
    assumption.
    inversion H8.
    subst.
    assumption.
  - unfold ext_signed.
    unfold ext'_signed.
    destruct_all word.
    simpl.
    unify_sizes.
    match goal with
      [|- _;_|-- exp_int (sized ?w') ::: _] =>
      rewrite <- Word.natToWord_wordToNat with (w := w')
    end.
    replace (type_imm sz) with (type_imm (S (sz - 1) - 0)) by (f_equal; omega).
    apply t_int.
    omega.
    solve_typ_gamma.
    solve_typ_lgamma.
  - destruct_all word.
    unify_sizes.
    unfold ext_signed.
    unfold ext'_signed.
    replace (type_imm sz) with (type_imm (S (sz - 1) - 0)) by (f_equal; omega).
    simpl.
    match goal with
      [|- _;_|-- exp_int (sized ?w') ::: _] =>
      rewrite <- Word.natToWord_wordToNat with (w := w')
    end.
    solve_type_rule.
  - destruct_all word.
    unify_sizes.
    unfold ext.
    unfold ext'.
    simpl.
    replace (type_imm sz) with (type_imm (S (sz - 1))) by (f_equal; omega).
    match goal with
      [|- _;_|-- exp_int (sized ?w') ::: _] =>
      rewrite <- Word.natToWord_wordToNat with (w := w')
    end.
    solve_type_rule.
  - destruct_all word.
    unify_sizes.
    unfold ext.
    unfold ext'.
    simpl.
    replace (type_imm sz) with (type_imm (S (sz - 1))) by (f_equal; omega).
    match goal with
      [|- _;_|-- exp_int (sized ?w') ::: _] =>
      rewrite <- Word.natToWord_wordToNat with (w := w')
    end.
    solve_type_rule.
Qed.

Lemma Nth_Nth_eq : forall {A : Set} l n (a a' : A),
    Nth l n a -> Nth l n a' -> a = a'.
Proof.
  smart_induction l;
    intros n aa aa' aanth aa'nth; inversion aanth;
      subst; inversion aa'nth; [reflexivity | eapply IHl; eassumption].
Qed.

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
  eapply Nth_Nth_eq; eassumption.
  repeat match goal with
         | [ IH : forall t', ?g;?gl |-- ?e ::: t' -> ?GL = t' ,
               H : ?g;?gl |-- ?e ::: _ |- _ ] =>
           apply IH in H
         end.
  inversion H3.
  inversion H5.
  subst.
  reflexivity.
Qed.


Lemma get_delta_val : forall {A B : Set} (l : list (A * B)) x,
    In x (map fst l) ->
    exists e, In (x,e) l.
Proof.
  intros A B l;
    induction l;
    intros x inx;
    inversion inx.
  exists (snd a).
  subst.
  rewrite <- surjective_pairing.
  simpl.
  auto.
  simpl.
  assert (exists e : B, In (x,e) l) by auto.
  destruct H0.
  eauto.
Qed.


Lemma in_type_delta_val : forall x v d, type_delta d -> In (x,v) d -> is_val_of_exp v.
Proof.
  smart_induction d;
    simpl;
    intros x v td xind;
    inversion xind;
    inversion td.
  subst.
  inversion H0.
  subst.
  assumption.
  eapply IHd; eauto.
Qed.


Lemma exp_progress : forall d e t,
    type_delta d ->
    map fst d;nil |-- e ::: t ->
      is_val_of_exp e \/
      exists e', exp_step d e e'.
Proof.
  smart_induction e;
    intros d tt td te;
    (* solve the value cases *)
    try solve [left; constructor; inversion te; assumption];
    right.
  - inversion te.
    subst.
    apply get_delta_val in H0.
    destruct H0 as [x xin].
    exists x.
    constructor.
    eapply in_type_delta_val; eauto.
    assumption.
  - inversion te.
    match goal with H : Nth nil _ _ |- _ => inversion H end.
  -  inversion te.
     subst.
     repeat match goal with
       H : _;_ |-- ?e ::: _,
         IH : context[_;_ |-- ?e ::: _ -> _]
       |- _ =>
       apply IH in H;
         destruct H;
         clear IH;
         auto
     end.
     + match goal with
         H : is_val_of_exp ?e |- _ =>
         destruct e;
           inversion H;
           clear H
       end;
       match goal with
         H : is_val_of_exp ?e |- _ =>
         destruct e;
           inversion H;
           clear H
       end;
       try now (inversion te;
           match goal with
             | H : _;_|-- [m: _, _ <- _ @ _] ::: type_imm _ |- _ =>
               inversion H
             | H : _;_|-- exp_int _ ::: type_mem _ _ |- _ =>
               inversion H
           end).
       * inversion te.
         subst.
         destruct (Sized_Word.eq_word w word5).
         inversion H11.
         subst.
         eexists.
         destruct (Nat.eq_dec nat5 sz1).
         subst.
         apply step_load_byte; auto.
         assert (nat5 > sz1) ...
         fail.
         Search (Sized_Word.eq_word).
         destruct (word_eq w word5).
         inversion H11.
         subst.
         destruct (word_eq (
       * eexists.
         apply step_load_un_mem; simpl; auto.
       * inversion te.
         subst.
         inversion H12.
         subst.
         give_up. (* TODO: other complicated case *)
       * eexists.
         apply step_load_un_mem; simpl; auto.
     + match goal with
         H : exists _, exp_step _ _ _ |- _ =>
         destruct H
       end;
         eexists;
         apply step_load_step_mem;
         eassumption.
     + match goal with
         H : exists _, exp_step _ _ _ |- _ =>
         destruct H
       end;
         eexists;
         (* TODO: order of eval for load is right to left; is this intended? *)
         apply step_load_step_addr;
         eassumption.
     + repeat match goal with
         H : exists _, exp_step _ _ _ |- _ =>
         destruct H
       end;
         eexists;
         (* TODO: order of eval for load is right to left; is this intended? *)
         apply step_load_step_addr;
         eassumption.
  -

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
