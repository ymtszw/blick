use Croma

defmodule Blick.External.Google.OpenidConnect do
  @moduledoc """
  Verifies id_token provided via [Google OpenID Connect][oidc].

  Subject id_token can be acquired alongside with access_token and refresh_token
  in well-known OAuth2.0 authorization code flow.

  [oidc]: https://developers.google.com/identity/protocols/OpenIDConnect
  """

  alias Croma.Result, as: R
  alias SolomonLib.Httpc

  @configuration_endpoint "https://accounts.google.com/.well-known/openid-configuration"
  @doc """
  Retrieves latest OpenID configuration (Discovery document).
  """
  defun configuration!() :: map do
    Httpc.get!(@configuration_endpoint).body |> Poison.decode!()
  end

  @publickey_endpoint "https://www.googleapis.com/oauth2/v3/certs"
  @doc """
  Retrieves publickey used for JWS signing.

  According to Google, this key is changed only infrequently (on the order of once per day), so you may cache it.
  """
  defun publickey(kid) :: R.t(map) do
    R.m do
      %Httpc.Response{body: body} <- Httpc.get(@publickey_endpoint)
      %{"keys" => keys} <- Poison.decode(body)
      case Enum.find(keys, fn key -> key["kid"] == kid end) do
        nil -> {:error, {:publickey_not_found, kid}}
        key -> {:ok, key}
      end
    end
  end

  @sample """
  eyJhbGciOiJSUzI1NiIsImtpZCI6Ijk3OGNhNDExOGJmMTg4M2IzMTZiYmNhNmNlOTA0NGQ5OTc3ZjIw
  MjcifQ.
  eyJhenAiOiIxOTkzODM4MzIwNjUta2dqbzJmc2hsMTd0aGNpODNwN2IydGJocGlhdWEydjEuYXBwcy5n
  b29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiIxOTkzODM4MzIwNjUta2dqbzJmc2hsMTd0aGNpODNw
  N2IydGJocGlhdWEydjEuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDg4MzE1Mjcy
  MTM2NTM2MjEwNjUiLCJoZCI6ImFjY2Vzcy1jb21wYW55LmNvbSIsImVtYWlsIjoieXUubWF0c3V6YXdh
  QGFjY2Vzcy1jb21wYW55LmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJhdF9oYXNoIjoibkdHd0N6
  SktpeE10Y1ZVY2MzQ0d3dyIsImV4cCI6MTUxNjM1ODU2NywiaXNzIjoiaHR0cHM6Ly9hY2NvdW50cy5n
  b29nbGUuY29tIiwiaWF0IjoxNTE2MzU0OTY3LCJuYW1lIjoiWXUgTWF0c3V6YXdhIiwicGljdHVyZSI6
  Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS8tODV6dlZMUDZHWUUvQUFBQUFBQUFBQUkv
  QUFBQUFBQUFBQmsvWFRMdzZObmw5M1kvczk2LWMvcGhvdG8uanBnIiwiZ2l2ZW5fbmFtZSI6Ill1Iiwi
  ZmFtaWx5X25hbWUiOiJNYXRzdXphd2EiLCJsb2NhbGUiOiJqYSJ9.
  cuCTQxfK9CLkL_EsqOFbDLhyhdJSyllgmUiffL0ZZgVVZZjwbMQnI4kTsl15aBKMJlmP1q36e3JNPT_d
  qZPNZ0KGm27mCPssYXkc75AO5h4P-fEXelfYzW3WwQ_Akd3i6uB0Ws-wE1UZFAkVrrSzs62GTbeJMHtA
  OU6fv1Ig20kE9z6KQTO096zbQgXpEyubj0p4hDRLQIrON_V5g1dG0QJrp6Onj4Olu5_-Wk1y5FkVAejr
  88TN1LnW99H_Pb0OhN0PU9Pe0Q4yENxXuE-grxhuU34yJPAGSlBHiw5RYl7y_PL4WmPdbuuCOzhVp7xt
  IN4u8mWnG4eJZ-PKJhA5vA
  """ |> String.replace("\n", "") |> String.trim()

  def try_sample(), do: parse_and_verify_id_token(@sample)

  @doc """
  Parses and verifies subject id_token.

  Only supports algorithms used by Google OpenID Connect, which should be using secure (signed) JWS.
  """
  defun parse_and_verify_id_token(id_token :: v[String.t]) :: R.t(map) do
    case String.split(id_token, ".", trim: false) do
      [header, payload, ""] ->
        parse_and_verify_unsecure_jws(header, payload)
      [header, payload, signature] ->
        parse_and_verify_secure_jws(header, payload, signature)
      [header, encrypted_key, iv, ciphertext, authentication_tag] ->
        parse_and_verify_jwe(header, encrypted_key, iv, ciphertext, authentication_tag)
    end
  end

  defp parse_and_verify_unsecure_jws(header, payload) do
    decode_json_part(header)
    |> R.bind(fn
      %{"alg" => "none"} ->
        {:error, {:not_verified, [{:unsecure_jws, decode_json_part(payload)}]}}
      otherwise ->
        {:error, {:invalid_value, [{:invalid_header, otherwise}]}}
    end)
  end

  defp parse_and_verify_secure_jws(header, payload, signature) do
    R.m do
      decoded_payload <- decode_json_part(payload)
      decoded_header <- decode_json_part(header)
      :verified <- verify_secure_jws(decoded_header, header <> "." <> payload, signature)
      pure decoded_payload
    end
  end

  defp verify_secure_jws(%{"alg" => "RS256", "kid" => kid}, string_to_sign, signature) do
    publickey(kid)
    |> R.bind(fn
      %{"alg" => "RS256", "e" => e_value, "n" => n_value} ->
        rsa256_verify(string_to_sign, e_value, n_value, signature)
      wrong_algorithm_key ->
        {:error, {:wrong_algorithm_key, wrong_algorithm_key}}
    end)
  end
  defp verify_secure_jws(unsupported_algorithm, _string_to_sign, _signature) do
    {:error, {:unsupported_algorithm, unsupported_algorithm}}
  end

  defp rsa256_verify(string_to_sign, e_value, n_value, signature) do
    R.m do
      decoded_signature <- url_decode64(signature)
      decoded_e_value <- url_decode64(e_value)
      decoded_n_value <- url_decode64(n_value)
      if :crypto.verify(:rsa, :sha256, string_to_sign, decoded_signature, [decoded_e_value, decoded_n_value]) do
        {:ok, :verified}
      else
        {:error, :not_verified}
      end
    end
  end

  defp parse_and_verify_jwe(header, _encrypted_key, _iv, _ciphertext, _authentication_tag) do
    decode_json_part(header)
    |> R.bind(fn
      %{"enc" => enc} ->
        {:error, {:unsupported, [{:jwe, enc}]}}
      otherwise ->
        {:error, {:invalid_value, [{:invalid_header, otherwise}]}}
    end)
  end

  # Internals

  defp decode_json_part(base64url_string) do
    url_decode64(base64url_string)
    |> R.bind(&Poison.decode/1)
  end

  defp url_decode64(raw_string) do
    case Base.url_decode64(raw_string, padding: false) do
      {:ok, _} = ok -> ok
      :error -> {:error, {:invalid_value, [:base64_url_string]}}
    end
  end
end
