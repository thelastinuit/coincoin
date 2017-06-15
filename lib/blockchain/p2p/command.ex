defmodule Blockchain.P2P.Command do
  @moduledoc "TCP server command parsing and execution"

  alias Blockchain.{Chain, Op, Block}

  # simple ping
  @ping "ping"

  # to request latest block
  @query_latest "query_latest"

  # to request all the blockchain
  @query_all "query_all"

  # to receive a blockchain (all the chain or only latest block in an array)
  @response_blockchain "response_blockchain"

  def parse(data) do
    case Poison.decode(data, as: %{"chain" => [%Block{}]}) do
      {:ok, json} ->
        parse_cmd(json)
      {:error, {reason, _, _}} ->
        {:error, reason}
    end
  end

  def parse_cmd(json) do
    case json do
      %{"type" => @query_latest} ->
        {:ok, @query_latest}
      %{"type" => @query_all} ->
        {:ok, @query_all}
      %{"type" => @response_blockchain, "chain" => chain_payload} ->
        {:ok, {@response_blockchain, chain_payload}}
      %{"type" => @ping} ->
        {:ok, @ping}
      _ ->
        {:error, :unknown_type}
    end
  end

  def run(@ping) do
    {:ok, "pong"}
  end

  def run(@query_latest) do
    payload = Poison.encode!([Chain.latest_block()])
    {:ok, payload}
  end

  def run(@query_all) do
    payload = Poison.encode!(Chain.all_blocks())
    {:ok, payload}
  end

  def run({@response_blockchain, chain}) do
    action = Op.determine_action(chain)
    {:ok, Atom.to_string(action)}
  end
end
