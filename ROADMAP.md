#ltypekit Roadmap for v7
- Constraints using => instead of {}
- Lists: `[string]`
- Hashmaps: `{number:string}`
- Scopes & RankNTypes
- Prime support (a')
- Type synonyms
- Data structures
- Typeclasses and instances
## New unions
`[string|table]` turns into `[string|table] a => a`
## Constraints
`x{string|table}` turns into `[string|table] x => x`
## Scopes (scoped type variables)
`string a => a -> (a => a -> string)`
A new scope is initiated at every parenthesis, if there is no constraint sign, then the scope will be inherited,
a new one will be created otherwise.
`(string a => a) -> (table a => a)` -> Rank 2
`string a => a -> (table a => a)`   -> ???
## Lists
`lines :: string -> [string]`
## Typeclasses and instances
(see plan/classes.moon)
Use `typeforall`.
