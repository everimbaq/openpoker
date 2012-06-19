-module(sim_deal_test).
-include("genesis.hrl").
-include("genesis_test.hrl").

-define(TWO_PLAYERS, [{?JACK, ?JACK_ID}, {?TOMMY, ?TOMMY_ID}]).

private_rank_test_() -> {setup, fun setup_with_private_rank/0, fun cleanup/1, fun () ->
        Players = ?TWO_PLAYERS,
        sim:join_and_start_game(Players),

        sim:check_blind_only_raise(Players, 1, 1, 2),
        sim:check_deal(),

        ?assertMatch(#notify_hand{rank = ?HC_PAIR, high1 = ?CF_FOUR}, sim_client:head(?JACK)),
        ?assertMatch(#notify_hand{rank = ?HC_PAIR, high1 = ?CF_THREE}, sim_client:head(?TOMMY))
    end}.

deal_test_() -> {setup, fun setup_with_deal/0, fun cleanup/1, fun () ->
        Players = ?TWO_PLAYERS,
        sim:join_and_start_game(Players),

        sim:check_blind_only_raise(Players, 1, 1, 2),
        sim:check_deal(),
        sim:check_shared(3, Players),

        Ctx = game:ctx(?GAME),
        Jack = seat:get(1, Ctx#texas.seats),
        Tommy = seat:get(2, Ctx#texas.seats),
        ?assertEqual(52 - 4 - 3, deck:size(Ctx#texas.deck)),
        ?assertEqual(3, length(Ctx#texas.board)),
        ?assertEqual(2, hand:size(Jack#seat.hand)),
        ?assertEqual(2, hand:size(Tommy#seat.hand)),
        ?assertMatch(stop, game:state(?GAME))
    end}.

share_rank_test_() -> {setup, fun setup_with_share_rank/0, fun cleanup/1, fun () ->
        Players = ?TWO_PLAYERS,
        sim:join_and_start_game(Players),
        sim:check_blind_only_raise(Players, 1, 1, 2),
        sim:check_deal(),
        sim:check_shared(1, Players),
        ?assertMatch(#notify_hand{rank = ?HC_PAIR, high1 = ?CF_FOUR}, sim_client:head(?JACK)),
        ?assertMatch(#notify_hand{rank = ?HC_THREE_KIND, high1 = ?CF_THREE}, sim_client:head(?TOMMY))
    end}.

share_rank2_test_() -> {setup, fun setup_with_share_rank2/0, fun cleanup/1, fun () ->
        Players = ?TWO_PLAYERS,
        sim:join_and_start_game(Players),
        sim:check_blind_only_raise(Players, 1, 1, 2),
        sim:check_deal(),
        sim:check_shared(3, Players),
        ?assertMatch(#notify_hand{rank = ?HC_FOUR_KIND, high1 = ?CF_FOUR}, sim_client:head(?JACK)),
        ?assertMatch(#notify_hand{rank = ?HC_FULL_HOUSE, high1 = ?CF_THREE, high2 = ?CF_FOUR}, sim_client:head(?TOMMY))
    end}.

%%%
%%% setup & cleanup
%%%

setup_with_share_rank2() ->
  MixinMods = [{blinds, []}, {rig, [hand:make_cards("3H 4H 3D 4D 3C 4C 4S ")]}, {deal_cards, [2, private]}, {deal_cards, [3, shared]}, {ranking, []}],
  setup(MixinMods).

setup_with_share_rank() ->
  MixinMods = [{blinds, []}, {rig, [hand:make_cards("3H 4H 3D 4D 3C")]}, {deal_cards, [2, private]}, {deal_cards, [1, shared]}, {ranking, []}],
  setup(MixinMods).

setup_with_deal() ->
  MixinMods = [{blinds, []}, {deal_cards, [2, private]}, 
    {deal_cards, [1, shared]}, {deal_cards, [1, shared]}, {deal_cards, [1, shared]}],
  setup(MixinMods).

setup_with_private_rank() ->
  RigCards = hand:make_cards("3H 4H 3D 4D"),
  MixinMods = [{blinds, []}, {rig, [RigCards]}, {deal_cards, [2, private]}, {ranking, []}],
  setup(MixinMods).

setup(MixinMods) ->
  schema_test:init(),
  sim_client:setup_players(?PLAYERS),
  Mods = [{wait_players, []}] ++ MixinMods ++ [{stop, []}],
  Limit = #limit{min = 100, max = 400, small = 10, big = 20},
  Conf = #tab_game_config{module = game, mods = Mods, limit = Limit, seat_count = 9, start_delay = 500, required = 2, timeout = 1000, max = 1},
  game:start(Conf).

cleanup(Games) ->
  lists:foreach(fun ({ok, Pid}) -> exch:stop(Pid) end, Games),
  lists:foreach(fun ({Key, _R}) -> sim_client:stop(Key) end, ?PLAYERS).
