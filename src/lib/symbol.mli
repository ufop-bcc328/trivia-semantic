type symbol
val name : symbol -> string
val symbol : string -> symbol
val new_symbol : string -> symbol
val pp_symbol : Format.formatter -> symbol -> unit

type 'a table
val empty : 'a table
val enter : symbol -> 'a -> 'a table -> 'a table
val look : symbol -> 'a table -> 'a option
