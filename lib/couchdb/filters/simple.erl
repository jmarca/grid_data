"fun({Doc}, {Req}) ->      min_i = 128,     max_i = 135,    min_j = 153,    max_j = 161,    i = proplists:get_value((<<"i_cell">>, Doc),     j = proplists:get_value((<<"j_cell">>, Doc),    if        i >= min_i, i < max_i, j>= min_j, j<max_j -> true;         _ -> false     end  end."


fun({Doc}, {Req}) ->     
        Icell = couch_util:get_value(<<"i_cell">>, Doc),
        Jcell = couch_util:get_value(<<"j_cell">>, Doc),    
        if        
            Icell >= 128, Icell < 135, Jcell>= 153, Jcell<161 
            -> true;         
            _ -> false     
        end  
end.

fun({Doc}, {Req}) ->
        DocType = couch_util:get_value(<<"type">>, Doc),
        case DocType of
                undefined -> false;
                <<"mytype">> -> true;
                _ -> false
        end
end.

fun({Doc}, {Req}) ->
        ICell = couch_util:get_value(<<"i_cell">>, Doc),
        case ICell of
                undefined -> false;
                <<"128">> -> true;
                _ -> false
        end
end.
