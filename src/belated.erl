%%%-------------------------------------------------------------------
%%% File    : belated.erl
%%% Author  : wil <wil@toughie.3cglabs.com>
%%% Description : 
%%%
%%% Created : 26 Sep 2008 by wil <wil@toughie.3cglabs.com>
%%%-------------------------------------------------------------------
-module(belated).

-behaviour(gen_server).

%% API
-export([start/0, stop/0, send/3, list/0, send_message/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {}).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start() ->
    io:format("Starting Belated...~n"),
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

% Function: stop()
% Description: Ends the server
stop() ->
    gen_server:call(?MODULE, stop).

% Function: send(Message, Time)
% Description: Sends a message at a specific time
send(Datetime, To, Message) ->
    gen_server:call(?MODULE, {send, Datetime, To, Message}).

% Function: list()
% Description: list all future scheduled messages
list() ->
    gen_server:call(?MODULE, {list}).

%%====================================================================
%% gen_server callbacks
%%====================================================================

%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init([]) ->
    timer:start(),
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call({ send, Datetime, To, Message }, _From, State) ->
    Seconds_interval = seconds_from_now(Datetime),
    io:format("Scheduling message: ~s~n", [Message]),
    Reply = try timer:apply_after(timer:seconds(Seconds_interval),
                                  ?MODULE, 
                                  send_message, 
                                  [To, Message]) of
                _ -> { scheduled, Datetime, To }
            catch
                % FIXME dammit, it's not catching correctly
                error:badarg -> { not_scheduled, Datetime, To }
            end,
    {reply, Reply, State};

% handle the call for listing scheduled messages
%
% TODO not yet finished
handle_call({ list }, _From, State) ->
    Reply = listing,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------

% Calculates the number of seconds from now that the Future_datetime will arrive
%
% :Future_datetime: - {{2008, 9, 26}, {22, 32, 00}}
seconds_from_now(Future_datetime) ->
    Now_datetime_utc = calendar:universal_time(),
    [Future_datetime_utc] = calendar:local_time_to_universal_time_dst(Future_datetime),
    time_difference_in_seconds(Now_datetime_utc, Future_datetime_utc).

% Calculates the difference in seconds between two date and times
% Datetime1 < Datetime2
time_difference_in_seconds(Datetime1, Datetime2) ->
    calendar:datetime_to_gregorian_seconds(Datetime2) - 
        calendar:datetime_to_gregorian_seconds(Datetime1).

% Sends the actual message
send_message(To, Message) ->
    io:format("Send to ~s message: ~s~n", [To, Message]).
