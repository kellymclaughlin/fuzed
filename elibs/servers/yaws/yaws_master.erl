-module(yaws_master).
-export([start/3]).
-include("yaws.hrl").


start(IP, Port, DocRoot) ->
  {GC, SC} = yaws_global_configs(IP, Port, DocRoot),
  application:set_env(yaws, embedded, true),
  application:start(yaws),
  yaws_api:setconf(GC, [[SC]]).


yaws_global_configs(IP, Port, DocRoot) -> 
  io:format("IP: ~w  Port ~w DocRoot ~s~n",[IP,Port,DocRoot]),
  Y = yaws_dir(),
  %GC = #gconf{yaws_dir = Y,
  GC = #gconf{
    ebin_dir = [filename:join([Y, "examples/ebin"])],
    include_dir = [filename:join([Y, "examples/include"])],
    trace = false,
    logdir = "./log",
    cache_refresh_secs = 30,
    flags =  ?GC_AUTH_LOG bor ?GC_COPY_ERRLOG bor ?GC_FAIL_ON_BIND_ERR bor ?GC_PICK_FIRST_VIRTHOST_ON_NOMATCH,
    %uid = element(2, yaws:getuid()),
    yaws = "Yaws " ++ yaws_generated:version(),
    id = genericID
  },
  SC = #sconf{port = Port,
              servername = "master_responder",
              listen = IP,
              docroot = DocRoot, 
              appmods = [{"api", master_responder},
                         {"status", status_responder}]},
  {GC,SC}.

yaws_dir() ->
    case  yaws_generated:is_local_install() of
        true ->
            P = filename:split(code:which(?MODULE)),
            P1 = del_tail(P),
            filename:join(P1);
        false ->
            code:lib_dir(yaws)
    end.

del_tail(Parts) ->
     del_tail(Parts,[]).
%% Initial ".." should be preserved
del_tail([".." |Tail], Acc) ->
    del_tail(Tail, [".."|Acc]);
del_tail(Parts, Acc) ->
    del_tail2(Parts, Acc).

%% Embedded ".." should be removed together with preceding dir
del_tail2([_H, ".." |Tail], Acc) ->
    del_tail2(Tail, Acc);
del_tail2([".." |Tail], [_P|Acc]) ->
    del_tail2(Tail, Acc);
del_tail2([_X, _Y], Acc) ->
    lists:reverse(Acc);
del_tail2([H|T], Acc) ->
    del_tail2(T, [H|Acc]).
