defmodule Ueberauth.Strategy.Procore.OAuth do
  @moduledoc """
  An implementation of OAuth2 for procore.

  To add your `client_id` and `client_secret` include these values in your configuration.

      config :ueberauth, Ueberauth.Strategy.Procore.OAuth,
        client_id: System.get_env("PROCORE_CLIENT_ID"),
        client_secret: System.get_env("PROCORE_CLIENT_SECRET")
  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://app.procore.com",
    authorize_url: "https://app.procore.com/oauth/authorize",
    token_url: "https://app.procore.com/oauth/token"
  ]

  @doc """
  Construct a client for requests to Procore.

  Optionally include any OAuth2 options here to be merged with the defaults.

      Ueberauth.Strategy.Procore.OAuth.client(redirect_uri: "http://localhost:4000/auth/procore/callback")

  This will be setup automatically for you in `Ueberauth.Strategy.Procore`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    opts =
      Keyword.merge(@defaults, Application.get_env(:ueberauth, Ueberauth.Strategy.Procore.OAuth))
      |> Keyword.merge(opts)

    json_library = Ueberauth.json_library()

    OAuth2.Client.new(opts)
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    client(opts)
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_token!(params \\ [], options \\ %{}) do
    headers = Map.get(options, :headers, [])
    options = Map.get(options, :options, [])
    client_options = Keyword.get(options, :client_options, [])
    client = OAuth2.Client.get_token!(client(client_options), params, headers, options)
    client.token
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
