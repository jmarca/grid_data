fun({Doc}) ->
        T = couch_util:get_value(<<"ts">>, Doc),
        case T of
            undefined ->  ok;
            _ -> 
                D = couch_util:get_value(<<"data">>, Doc),
                case D of
                    undefined ->
                        Emit(1,1);
                    _ -> 
                        ok
                end
        end
end.
