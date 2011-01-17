%%%-------------------------------------------------------------------
%%% @author  <Kuleshov Alexander>
%%% @copyright (C) 2011, 
%%% @doc
%%%
%%% @end
%%% Created : 10 Jan 2011 by  <kuleshovmail@gmail.com>
%%%-------------------------------------------------------------------
-module(popd_listener).

-behaviour(gen_server).

-export([start_link/0, stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([accept/1]).
-export([receive_loop/1]).

-record(state, {
	        % listen socket
                listener 
               }).

-define(SERVER, ?MODULE).

start_link()  ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

accept(Socket) ->
    case gen_tcp:accept(Socket) of
	{ok, Sock} ->
	     spawn(?MODULE, receive_loop, [Sock]),
	     accept(Socket);
	{error, Reason} ->
	    Reason
    end.

receive_loop(Socket) ->
    case gen_tcp:recv(Socket, 0) of
	 {ok, Data} ->
	    case Data of
		<<"q\r\n">> ->
	          gen_tcp:send(Socket, "quit \n"),
		  gen_tcp:close(Socket);
	        _ ->
		  receive_loop(Socket)
	     end;
	 {error, closed} ->
	    ok
    end.
    
    
stop() ->
    io:format("Pop3 server stop! \n "),
    gen_server:cast(?MODULE, stop).

% 
% Callback functions
%
init([]) ->
    Port = 110,
    Opts = [binary, {reuseaddr, true},
            {keepalive, false}, {backlog, 30}, {active, false}],
    
    case gen_tcp:listen(Port, Opts) of
	 {ok, ListenSocket} ->
              spawn(?MODULE, accept, [ListenSocket]),
	      {ok, #state{ listener = ListenSocket}};
         {error, Reason} ->
	     {stop, Reason}
    end.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(stop, State) ->
    {stop, normal, State}.

handle_info(_Info, State) ->
    {noreply, State}.
%

%
% terminate server
%
terminate(_Reason, State) ->
    gen_tcp:close(State#state.listener),
    ok.

%
% Hot code change
%
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
%
