(** * specs.v : Collection of all related specs *)
Require Import VST.floyd.library.
Require Import DB.common.

(* functional definitions *)
Require Import DB.functional.keyslice.
Require Import DB.functional.bordernode.
Require Import DB.functional.trie.

(* spatial definitions *)
Require Import DB.representation.bordernode.
Require Import DB.representation.key.
Require Import DB.representation.string.
Require Import DB.representation.btree.
Require Import DB.representation.trie.

Require Export DB.prog.

Import List.
Import common.

(* Specification for auxilary functions *)

Definition surely_malloc_spec: ident * funspec :=
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
    SEP (malloc_token Ews t p * data_at_ Ews t p).

Definition UTIL_GetNextKeySlice_spec: ident * funspec :=
  DECLARE _UTIL_GetNextKeySlice
  WITH sh: share, str: val, key: string
  PRE [ _str OF tptr tschar, _len OF tuint ]
  PROP (readable_share sh)
  LOCAL (temp _str str;
         temp _len (Vint (Int.repr (Zlength key))))
  SEP (cstring_len sh key str)
  POST [ (if Archi.ptr64 then tulong else tuint) ]
  PROP ()
  LOCAL (temp ret_temp (Vint (Int.repr (get_keyslice key)))) (* machine dependent spec *)
  SEP (cstring_len sh key str).

Definition UTIL_StrEqual_spec: ident * funspec :=
  DECLARE _UTIL_StrEqual
  WITH sh1: share, s1: val, str1: string,
       sh2: share, s2: val, str2: string
  PRE [ _a OF tptr tschar, _lenA OF tuint, _b OF tptr tschar, _lenB OF tuint ]
  PROP (readable_share sh1;
        readable_share sh2)
  LOCAL (temp _a s1;
         temp _lenA (Vint (Int.repr (Zlength str1)));
         temp _b s2;
         temp _lenB (Vint (Int.repr (Zlength str2))))
  SEP (cstring_len sh1 str1 s1;
       cstring_len sh2 str2 s2)
  POST [ tint ]
  PROP ()
  LOCAL (temp ret_temp (Vint (if eq_dec str1 str2 then Int.one else Int.zero)))
  SEP (cstring_len sh1 str1 s1;
       cstring_len sh2 str2 s2).

Definition BN_NewBorderNode_spec: ident * funspec :=
  DECLARE _BN_NewBorderNode
  WITH tt: unit
  PRE [ ]
  PROP ()
  LOCAL ()
  SEP ()
  POST [ tptr tbordernode ] EX p:val,
  PROP ()
  LOCAL (temp ret_temp p)
  SEP (bordernode_rep Ews BorderNode.empty p * malloc_token Ews tbordernode p).

Definition BN_FreeBorderNode_spec: ident * funspec :=
  DECLARE _BN_FreeBorderNode
  WITH bordernode: BorderNode.table, p: val
  PRE [ _bordernode OF tptr tbordernode]
  PROP ()
  LOCAL (temp _bordernode p)
  SEP (bordernode_rep Ews bordernode p; malloc_token Ews tbordernode p)
  POST [ tvoid ]
  PROP ()
  LOCAL ()
  SEP ().

Definition BN_SetPrefixValue_spec: ident * funspec :=
  DECLARE _BN_SetPrefixValue
  WITH sh: share, key: Z, bordernode: BorderNode.table, p: val, value: val
  PRE [ _bn OF tptr tbordernode, _i OF tint, _val OF tptr tvoid ]
  PROP (0 < key <= keyslice_length;
        writable_share sh)
  LOCAL (temp _i (Vint (Int.repr key));
         temp _bn p;
         temp _val value)
  SEP (bordernode_rep sh bordernode p)
  POST [ tvoid ]
  PROP ()
  LOCAL ()
  SEP (bordernode_rep sh (BorderNode.put_prefix key value bordernode) p).

Definition BN_GetPrefixValue_spec: ident * funspec :=
  DECLARE _BN_GetPrefixValue
  WITH sh: share, key: Z, bordernode: BorderNode.table, p: val
  PRE [ _bn OF tptr tbordernode, _i OF tint ]
  PROP (0 < key <= keyslice_length;
        readable_share sh)
  LOCAL (temp _i (Vint (Int.repr key));
         temp _bn p)
  SEP (bordernode_rep sh bordernode p)
  POST [ tptr tvoid ]
  PROP ()
  LOCAL (temp ret_temp (BorderNode.get_prefix key bordernode))
  SEP (bordernode_rep sh bordernode p).

Definition BN_SetSuffixValue_spec: ident * funspec :=
  DECLARE _BN_SetSuffixValue
  WITH sh_string: share, key: string, s: val,
       sh_bordernode: share, bordernode: BorderNode.table, p: val,
       value: val
  PRE [ _bn OF tptr tbordernode, _suffix OF tptr tschar, _len OF tuint, _val OF tptr tvoid ]
  PROP (readable_share sh_string;
        writable_share sh_bordernode)
  LOCAL (temp _bn p;
         temp _suffix s;
         temp _len (Vint (Int.repr (Zlength key)));
         temp _val value)
  SEP (cstring_len sh_string key s;
       bordernode_rep sh_bordernode bordernode p)
  POST [ tvoid ]
  PROP ()
  LOCAL ()
  SEP (cstring_len sh_string key s;
       bordernode_rep sh_bordernode (BorderNode.put_suffix (Some key) value bordernode) p).

Definition BN_GetSuffixValue_spec: ident * funspec :=
  DECLARE _BN_GetSuffixValue
  WITH sh_string: share, key: string, s: val,
       sh_bordernode: share, bordernode: BorderNode.table, p: val
  PRE [ _bn OF tptr tbordernode, _suf OF tptr tschar, _len OF tuint ]
  PROP (readable_share sh_string;
        readable_share sh_bordernode)
  LOCAL (temp _bn p;
         temp _suf s;
         temp _len (Vint (Int.repr (Zlength key))))
  SEP (cstring_len sh_string key s;
       bordernode_rep sh_bordernode bordernode p)
  POST [ tptr tvoid ]
  PROP ()
  LOCAL (temp ret_temp (BorderNode.get_suffix (Some key) bordernode))
  SEP (cstring_len sh_string key s;
       bordernode_rep sh_bordernode bordernode p).

Definition BN_TestSuffix_spec: ident * funspec :=
  DECLARE _BN_TestSuffix
  WITH sh_key: share, key: string, k: val,
       sh_node: share, bordernode: BorderNode.table, p: val
  PRE [ _bn OF tptr tbordernode, _key OF tptr tkey ]                                    
  PROP (readable_share sh_key;
        readable_share sh_node;
        Zlength key > keyslice_length)
  LOCAL (temp _bn p;
         temp _key k)
  SEP (key_rep sh_key key k;
       bordernode_rep sh_node bordernode p)
  POST [ tint ]
  PROP ()
  LOCAL (temp ret_temp (if BorderNode.test_suffix (Some (get_suffix key)) bordernode then Vint Int.one else Vint Int.zero))
  SEP (key_rep sh_key key k;
       bordernode_rep sh_node bordernode p).

Definition BN_CompareSuffix_spec: ident * funspec :=
  DECLARE _BN_CompareSuffix
  WITH sh_key: share, key: string, k: val,
       sh_node: share, bordernode: BorderNode.table, p: val
  PRE [ _bn OF tptr tbordernode, _key OF tptr tkey ]                                    
  PROP (readable_share sh_key;
        readable_share sh_node;
        Zlength key > keyslice_length)
  LOCAL (temp _bn p;
         temp _key k)
  SEP (key_rep sh_key key k;
       bordernode_rep sh_node bordernode p)
  POST [ tint ]
  PROP ()
  LOCAL (temp ret_temp (
                match snd (fst bordernode) with
                | None => Vint Int.zero
                | Some k' => if (functional.key.TrieKeyFacts.lt_dec k' (get_suffix key)) then
                              Vint Int.zero
                            else
                              Vint Int.one
                end
        ))
  SEP (key_rep sh_key key k;
       bordernode_rep sh_node bordernode p).

Definition BN_ExportSuffixValue_spec: ident * funspec :=
  DECLARE _BN_ExportSuffixValue
  WITH sh_bordernode: share, bordernode: BorderNode.table, p: val,
       sh_keybox: share, k: val
  PRE [ _bn OF tptr tbordernode, _key OF tptr tkeybox ]
  PROP (writable_share sh_bordernode;
        writable_share sh_keybox)
  LOCAL (temp _bn p;
         temp _key k)
  SEP (bordernode_rep sh_bordernode bordernode p;
       data_at_ sh_keybox tkeybox k)
  POST [ tptr tvoid ]
  PROP ()
  LOCAL (temp ret_temp (snd (BorderNode.get_suffix_pair bordernode)))
  SEP (bordernode_rep sh_bordernode (BorderNode.put_suffix None nullval bordernode) p;
       keybox_rep sh_keybox (fst (BorderNode.get_suffix_pair bordernode)) k).

Definition BN_GetLink_spec: ident * funspec :=
  DECLARE _BN_GetLink
  WITH sh_bordernode: share, bordernode: BorderNode.table, p: val
  PRE [ _bn OF tptr tbordernode ]
  PROP (readable_share sh_bordernode)
  LOCAL (temp _bn p)
  SEP (bordernode_rep sh_bordernode bordernode p)
  POST [ tptr tvoid ]
  PROP ()
  LOCAL (temp ret_temp (BorderNode.get_suffix None bordernode))
  SEP (bordernode_rep sh_bordernode bordernode p).

Definition BN_SetLink_spec: ident * funspec :=
  DECLARE _BN_SetLink
  WITH sh_bordernode: share, bordernode: BorderNode.table, p: val, value: val
  PRE [ _bn OF tptr tbordernode, _val OF tptr tvoid ]
  PROP (writable_share sh_bordernode)
  LOCAL (temp _bn p;
         temp _val value)
  SEP (bordernode_rep sh_bordernode bordernode p)
  POST [ tvoid ]
  PROP ()
  LOCAL ()
  SEP (bordernode_rep sh_bordernode (BorderNode.put_suffix None value bordernode) p).

Definition BN_HasSuffix_spec: ident * funspec :=
  DECLARE _BN_HasSuffix
  WITH sh_bordernode: share, bordernode: BorderNode.table, p: val
  PRE [ _bn OF tptr tbordernode ]
  PROP (readable_share sh_bordernode)
  LOCAL (temp _bn p)
  SEP (bordernode_rep sh_bordernode bordernode p)
  POST [ tint ]
  PROP ()
  LOCAL (temp ret_temp (Vint ((if BorderNode.is_link bordernode then Int.zero else Int.one))))
  SEP (bordernode_rep sh_bordernode bordernode p).

Definition BN_SetValue_spec: ident * funspec :=
  DECLARE _BN_SetValue
  WITH sh_key: share, key: string, k: val,
       sh_node: share, bordernode: BorderNode.table, p: val,
       v: val
  PRE [ _bn OF tptr tbordernode, _key OF tptr tkey, _val OF tptr tvoid ]
  PROP (readable_share sh_key;
        writable_share sh_node)
  LOCAL (temp _bn p;
         temp _key k;
         temp _val v)
  SEP (bordernode_rep sh_node bordernode p;
         key_rep sh_key key k)
  POST [ tvoid ]
  PROP ()
  LOCAL ()
  SEP (bordernode_rep sh_node (BorderNode.put_value key v bordernode) p;
       key_rep sh_key key k).

Instance inh_link: Inhabitant (@Trie.link val) := Trie.inh_link.
Instance bnode_link: BorderNodeValue (@Trie.link val) := Trie.bnode_link.

Definition bordernode_next_cursor_spec: ident * funspec :=
  DECLARE _bordernode_next_cursor
  WITH bnode: BorderNode.table, pbnode: val,
       bnode_cursor: BorderNode.cursor
  PRE [ _bnode_cursor OF tuint, _bn OF tptr tbordernode ]
  PROP (BorderNode.cursor_correct bnode_cursor)
  LOCAL (temp _bnode_cursor (Vint (Int.repr (BorderNode.cursor_to_int bnode_cursor)));
         temp _bn pbnode)
  SEP (Trie.bnode_rep Trie.trie_rep (pbnode, bnode))
  POST [ tuint ]
  PROP ()
  LOCAL (temp ret_temp (Vint (Int.repr (BorderNode.cursor_to_int (BorderNode.next_cursor bnode_cursor bnode)))))
  SEP (Trie.bnode_rep Trie.trie_rep (pbnode, bnode)).

Definition move_key_spec: ident * funspec :=
  DECLARE _move_key
  WITH key: string, s: val 
  PRE [ _str OF tptr tschar, _len OF tuint ]
  PROP ()
  LOCAL (temp _str s;
         temp _len (Vint (Int.repr (Zlength key))))
  SEP (cstring_len Ews key s;
       malloc_token Ews (tarray tschar (Zlength key)) s)
  POST [ tptr tkey ] EX k:val,
  PROP ()
  LOCAL (temp ret_temp k)
  SEP (key_rep Ews key k;
       malloc_token Ews tkey k).

Definition new_key_spec: ident * funspec :=
  DECLARE _new_key
  WITH key: string, s: val 
  PRE [ _str OF tptr tschar, _len OF tuint ]
  PROP ()
  LOCAL (temp _str s;
         temp _len (Vint (Int.repr (Zlength key))))
  SEP (cstring_len Ews key s)
  POST [ tptr tkey ] EX k:val,
  PROP ()
  LOCAL (temp ret_temp k)
  SEP (key_rep Ews key k;
       malloc_token Ews tkey k;
       cstring_len Ews key s).

Definition free_key_spec: ident * funspec :=
  DECLARE _free_key
  WITH key: string, k: val 
  PRE [ _key OF tptr tkey ]
  PROP ()
  LOCAL (temp _key k)
  SEP (key_rep Ews key k;
       malloc_token Ews tkey k)
  POST [ tvoid ]
  PROP ()
  LOCAL ()
  SEP ().

Definition new_cursor_spec: ident * funspec :=
  DECLARE _new_cursor
  WITH tt: unit
  PRE [ ]
  PROP ()
  LOCAL ()
  SEP ()
  POST [ tptr Trie.tcursor ] EX pc: val,
  PROP ()
  LOCAL (temp ret_temp pc)
  SEP (Trie.cursor_rep [] pc).

Definition push_cursor_spec: ident * funspec :=
  DECLARE _push_cursor
  WITH cs: (@Trie.table val * @BTree.cursor val * @BorderNode.table (@Trie.link val) * BorderNode.cursor),
       pnode: val, pnode_cursor: val, bnode_cursor: val,
       c: Trie.cursor, pc: val
  PRE [ _node OF tptr Trie.ttrie, _node_cursor OF tptr BTree.tcursor, _bnode_cursor OF tuint, _cursor OF tptr Trie.tcursor ]
  PROP ()
  LOCAL (temp _node_cursor pnode_cursor; temp _bnode_cursor bnode_cursor; temp _cursor pc)
  SEP (Trie.cursor_slice_rep cs (pnode, (pnode_cursor, bnode_cursor)); Trie.cursor_rep c pc)
  POST [ tvoid ]
  PROP ()
  LOCAL ()
  SEP (Trie.cursor_rep (c ++ [cs]) pc).

Definition pop_cursor_spec: ident * funspec :=
  DECLARE _pop_cursor
  WITH c: Trie.cursor, pc: val
  PRE [ _cursor OF tptr Trie.tcursor ]
  PROP ()
  LOCAL (temp _cursor pc)
  SEP (Trie.cursor_rep c pc)
  POST [ tvoid ]
  PROP ()
  LOCAL ()
  SEP (Trie.cursor_rep (removelast c) pc).

Definition make_cursor_spec: ident * funspec :=
  DECLARE _make_cursor
  WITH c: @Trie.cursor val, pc: val,
       k: string, pk: val,
       t: @Trie.table val, pt: val
  PRE [ _key OF tptr tkey, _index OF tptr Trie.ttrie, _cursor OF tptr Trie.tcursor ]
  PROP (Trie.table_correct t)
  LOCAL (temp _key pk; temp _index pt; temp _cursor pc)
  SEP (Trie.trie_rep t pt; key_rep Ews k pk; Trie.cursor_rep c pc)
  POST [ tvoid ]
  PROP ()
  LOCAL ()
  SEP (Trie.trie_rep t pt; key_rep Ews k pk; Trie.cursor_rep (c ++ (Trie.make_cursor k t)) pc).

Definition strict_first_cursor_spec: ident * funspec :=
  DECLARE _strict_first_cursor
  WITH c: @Trie.cursor val, pc: val,
       t: @Trie.table val, pt: val
  PRE [ _index OF tptr Trie.ttrie, _cursor OF tptr Trie.tcursor ]
  PROP (Trie.table_correct t)
  LOCAL (temp _index pt; temp _cursor pc)
  SEP (Trie.trie_rep t pt; Trie.cursor_rep c pc)
  POST [ tint ]
  PROP ()
  LOCAL (temp ret_temp (if Trie.strict_first_cursor t then Vint Int.one else Vint Int.zero))
  SEP (Trie.trie_rep t pt; Trie.cursor_rep (c ++
                                              match Trie.strict_first_cursor t with
                                              | Some c' => c'
                                              | None => []
                                              end) pc).

Definition Iempty_spec: ident * funspec :=
  DECLARE _Iempty
  WITH tt: unit
  PRE [ ]
  PROP ()
  LOCAL ()
  SEP ()
  POST [ tptr BTree.tindex ] EX t: @BTree.table val, EX pt: val,
  PROP (BTree.empty t)
  LOCAL (temp ret_temp pt)
  SEP (BTree.table_rep t pt).

Definition Iput_spec: ident * funspec :=
  DECLARE _Iput
  WITH k: Z, v: val,
       t: @BTree.table val, pt: val,
       c: @BTree.cursor val, pc: val
  PRE [ _key OF tuint, _value OF tptr tvoid, _cursor OF tptr BTree.tcursor, _index OF tptr BTree.tindex ]
  PROP (BTree.abs_rel c t)
  LOCAL (temp _key (Vint (Int.repr k)); temp _value v;
         temp _cursor pc; temp _index pt)
  SEP (BTree.table_rep t pt; BTree.cursor_rep c pc)
  POST [ tvoid ]
  EX new_t: @BTree.table val, EX new_c: @BTree.cursor val,
  PROP (BTree.put k v c t new_c new_t)
  LOCAL ()
  SEP (BTree.table_rep new_t pt; BTree.cursor_rep new_c pc).

Definition create_pair_spec: ident * funspec :=
  DECLARE _create_pair
  WITH k1: string, k2: string, pk1: val, pk2: val, v1: val, v2: val
  PRE [ _key1 OF tptr tschar, _len1 OF tuint, _key2 OF tptr tschar, _len2 OF tuint,
        _v1 OF tptr tvoid, _v2 OF tptr tvoid ]
  PROP (0 < Zlength k1; 0 < Zlength k2; isptr v1; isptr v2)
  LOCAL (temp _key1 pk1; temp _key2 pk2;
         temp _len1 (Vint (Int.repr (Zlength k1))); temp _len2 (Vint (Int.repr (Zlength k2)));
         temp _v1 v1; temp _v2 v2)
  SEP (cstring_len Ews k1 pk1; cstring_len Ews k2 pk2)
  POST [ tptr Trie.ttrie ]
  EX t: @Trie.table val, EX pt: val, EX c: @Trie.cursor val,
  PROP (Trie.create_pair k1 k2 v1 v2 c t)
  LOCAL (temp ret_temp pt)
  SEP (cstring_len Ews k1 pk1; cstring_len Ews k2 pk2; Trie.trie_rep t pt).

Definition put_spec: ident * funspec :=
  DECLARE _put
  WITH k: string, pk: val, v: val,
       t: @Trie.table val, pt: val,
       c: @Trie.cursor val
  PRE [ _key OF tptr tschar, _len OF tuint, _v OF tptr tvoid, _index OF tptr Trie.ttrie ]
  PROP (0 < Zlength k; isptr v; Trie.table_correct t)
  LOCAL (temp _key pk;
         temp _len (Vint (Int.repr (Zlength k)));
         temp _v v;
         temp _index pt)
  SEP (cstring_len Ews k pk; Trie.trie_rep t pt)
  POST [ tvoid ]
  EX new_t: @Trie.table val, EX new_c: @Trie.cursor val,
  PROP (Trie.put k v c t new_c new_t)
  LOCAL ()
  SEP (cstring_len Ews k pk; Trie.trie_rep new_t pt).

Definition Imake_cursor_spec: ident * funspec :=
  DECLARE _Imake_cursor
  WITH k: Z,
       t: @BTree.table val, pt: val
  PRE [ _key OF tuint, _index OF tptr BTree.tindex ]
  PROP (0 <= k <= Int.max_unsigned; BTree.table_correct t)
  LOCAL (temp _key (Vint (Int.repr k)); temp _index pt)
  SEP (BTree.table_rep t pt)
  POST [ tptr BTree.tcursor ] EX pc: val,
  PROP ()
  LOCAL (temp ret_temp pc)
  SEP (BTree.table_rep t pt; BTree.cursor_rep (BTree.make_cursor k t) pc).

Definition Ifirst_cursor_spec: ident * funspec :=
  DECLARE _Ifirst_cursor
  WITH t: @BTree.table val, pt: val
  PRE [ _index OF tptr BTree.tindex ]
  PROP (BTree.table_correct t)
  LOCAL (temp _index pt)
  SEP (BTree.table_rep t pt)
  POST [ tptr BTree.tcursor ] EX pc: val,
  PROP ()
  LOCAL (temp ret_temp pc)
  SEP (BTree.table_rep t pt; BTree.cursor_rep (BTree.first_cursor t) pc).

Definition Ifree_cursor_spec: ident * funspec :=
  DECLARE _Ifree_cursor
  WITH c: @BTree.cursor val, pc: val
  PRE [ _cursor OF tptr BTree.tcursor ]
  PROP ()
  LOCAL (temp _cursor pc)
  SEP (BTree.cursor_rep c pc)
  POST [ tvoid ]
  PROP ()
  LOCAL ()
  SEP ().

Definition Iget_key_spec: ident * funspec :=
  DECLARE _Iget_key
  WITH c: @BTree.cursor val, pc: val,
       t: @BTree.table val, pt: val,
       pk: val, ret_sh: share
  PRE [ _cursor OF tptr BTree.tcursor, _index OF tptr BTree.tindex, _key OF tptr tuint ]
  PROP (BTree.abs_rel c t; writable_share ret_sh)
  LOCAL (temp _cursor pc; temp _index pt; temp _key pk)
  SEP (BTree.table_rep t pt; BTree.cursor_rep c pc; data_at_ ret_sh tuint pk)
  POST [ tint ]
  PROP ()
  LOCAL (temp ret_temp (if BTree.get_key c t then (Vint Int.one) else (Vint Int.zero)))
  SEP (BTree.table_rep t pt; BTree.cursor_rep c pc;
       data_at ret_sh tuint match BTree.get_key c t with
                         | Some k => (Vint (Int.repr k))
                         | None => Vundef
                         end pk).

Definition Iget_value_spec: ident * funspec :=
  DECLARE _Iget_value
  WITH c: @BTree.cursor val, pc: val,
       t: @BTree.table val, pt: val,
       pv: val, ret_sh: share
  PRE [ _cursor OF tptr BTree.tcursor, _index OF tptr BTree.tindex, _value OF tptr (tptr tvoid) ]
  PROP (BTree.abs_rel c t; writable_share ret_sh)
  LOCAL (temp _cursor pc; temp _index pt; temp _value pv)
  SEP (BTree.table_rep t pt; BTree.cursor_rep c pc; data_at_ ret_sh (tptr tvoid) pv)
  POST [ tint ]
  PROP ()
  LOCAL (temp ret_temp (if BTree.get_value c t then (Vint Int.one) else (Vint Int.zero)))
  SEP (BTree.table_rep t pt; BTree.cursor_rep c pc;
       data_at ret_sh (tptr tvoid) match BTree.get_value c t with
                                | Some v => v
                                | None => Vundef
                                end pv).
