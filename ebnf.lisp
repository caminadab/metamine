(
	(identifier IDENTIFIER)
	(ebnf (* rule))
	(rule (|| identifier ':' exp (* '\n')))
	(atom (| identifier string brackets))
	(brackets (|| '(' exp ')'))
	(postfix (| '+' '*' '?'))
	(exp
		(||
			atom
			(? postfix)
			(*
				(|| (? '|') exp)
			)
		)
	)
)
