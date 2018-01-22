use Croma

defmodule Blick.External.Google do
  alias Croma.Result, as: R
  alias SolomonLib.{Httpc, Url}
  alias SolomonLib.Http.{Method, Headers, Status}
  alias Blick.Model.AdminToken

  @type token_t         :: AdminToken.t | String.t
  @type multipart_req_t :: {Method.t, Url.t, Httpc.ReqBody.t, Headers.t, Keyword.t}
  @type multipart_res_t :: {Status.t, map | String.t}
  @type res_t           :: R.t(:no_content | map | [multipart_res_t], Httpc.Response.t)

  @default_timeout 20_000

  @doc """
  Makes authorized requests to Google API.
  """
  defun request(token :: token_t,
                method :: v[Method.t],
                url :: v[Url.t],
                body :: v[Httpc.ReqBody.t] \\ "",
                headers :: v[Headers.t] \\ %{},
                opts :: Keyword.t \\ []) :: res_t do
    at = access_token(token)
    authorized_headers = Map.merge(%{"authorization" => "Bearer #{at}"}, headers) # Allow overriding Authorization header by caller
    Httpc.request(method, url, body, authorized_headers, Keyword.put(opts, :recv_timeout, @default_timeout))
    |> R.bind(&handle_res/1)
  end

  def access_token(%AdminToken{data: data}), do: data.access_token.value
  def access_token(str) when is_binary(str), do: str

  defun handle_res(res :: Httpc.Response.t) :: res_t do
    %Httpc.Response{status: 204} ->
      {:ok, :no_content}
    %Httpc.Response{status: code, headers: %{"content-type" => "multipart" <> _ = mp}, body: res_body} when code in 200..299 ->
      R.bind(boundary(mp), &parse_multipart_response_body(&1, res_body))
    %Httpc.Response{status: code, body: res_body} when code in 200..299 ->
      {:ok, Poison.decode!(res_body)}
    res ->
      {:error, res}
  end

  defp boundary("multipart" <> _ = multipart_content_type) do
    case Regex.named_captures(~r/boundary=(?<boundary>[^;]+)(;|\Z)/, multipart_content_type) do
      %{"boundary" => b} -> {:ok, b}
      _otherwise -> {:error, :boundary_not_found}
    end
  end

  defunp parse_multipart_response_body(boundary :: v[String.t], res_body :: v[String.t]) :: {:ok, [multipart_res_t]} do
    parser = :hackney_multipart.parser(boundary)
    {:ok, collect_with_multipart_parser(parser.(res_body), [])}
  end

  @spec collect_with_multipart_parser(:hackney_multipart.part_result | :hackney_multipart.body_result, [multipart_res_t]) :: [multipart_res_t]
  defp collect_with_multipart_parser({:headers, _part_headers, body_cont}, acc) do
    collect_with_multipart_parser(body_cont.(), acc)
  end
  defp collect_with_multipart_parser({:body, body, body_cont}, acc) do
    collect_with_multipart_parser(body_cont.(), [parse_response_part_body(body) | acc])
  end
  defp collect_with_multipart_parser({:end_of_part, part_cont}, acc) do
    collect_with_multipart_parser(part_cont.(), acc)
  end
  defp collect_with_multipart_parser(:eof, acc) do
    Enum.reverse(acc)
  end

  defp parse_response_part_body(part_body) do
    res_parser = :hackney_http.parser([:response])
    collect_with_http_parser(:hackney_http.execute(res_parser, part_body), nil, {200, ""})
  end

  @spec collect_with_http_parser(:hackney_http.parser_result, nil | :json | :form | :plain, multipart_res_t) :: multipart_res_t
  defp collect_with_http_parser({:response, _version, status, _reason, cont}, nil, {_, res_body}) do
    collect_with_http_parser(:hackney_http.execute(cont), nil, {status, res_body})
  end
  defp collect_with_http_parser({:header, {header, value}, cont}, nil, res) do
    case String.downcase(header) do
      "content-type" ->
        collect_with_http_parser(:hackney_http.execute(cont), response_content_type(value), res)
      _otherwise ->
        collect_with_http_parser(:hackney_http.execute(cont), nil, res)
    end
  end
  defp collect_with_http_parser({:header, _header_value, cont}, non_nil_content_type, res) do
    collect_with_http_parser(:hackney_http.execute(cont), non_nil_content_type, res)
  end
  defp collect_with_http_parser({:headers_complete, cont}, content_type, res) do
    collect_with_http_parser(:hackney_http.execute(cont), content_type, res)
  end
  defp collect_with_http_parser({:ok, body, cont}, content_type, {status, acc_body}) do
    collect_with_http_parser(:hackney_http.execute(cont), content_type, {status, acc_body <> body})
  end
  defp collect_with_http_parser({:done, _}, content_type, {status, acc_body}) do
    {status, parse_res_body(content_type, acc_body)}
  end

  defp response_content_type("application/json" <> _), do: :json
  defp response_content_type("application/x-www-form-urlencoded" <> _), do: :form
  defp response_content_type(_otherwise), do: :plain

  defp parse_res_body(:json, body), do: Poison.decode!(body)
  defp parse_res_body(:form, body), do: URI.decode_query(body)
  defp parse_res_body(_text, body), do: body

  @batch_api_base_url "https://www.googleapis.com/batch"
  @boundary "END_OF_PART"

  @doc """
  Makes batch request.
  """
  defun batch(token :: token_t, requests :: [multipart_req_t]) :: res_t do
    _token, [] ->
      {:error, :empty_requests}
    token, requests ->
      request(token, :post, @batch_api_base_url, make_batch_request_body(token, requests), %{"content-type" => "multipart/mixed; boundary=#{@boundary}"})
  end

  defp make_batch_request_body(token, requests) do
    """
    --#{@boundary}
    #{requests |> Enum.map_join("--#{@boundary}\n", &make_request_part_body(token, &1))}
    --#{@boundary}--
    """
  end

  defp make_request_part_body(token, {method, url, req_body, headers, opts}) do
    headers_str =
      content_type_header(req_body)
      |> Map.put("authorization", "Bearer #{access_token(token)}")
      |> Map.merge(headers)
      |> Enum.map_join("\n", fn {key, value} -> "#{key}: #{value}" end)

    """
    content-type: application/http


    #{Method.to_string(method)} #{make_url(url, opts[:params])}
    #{headers_str}


    #{req_body_to_string(req_body)}
    """
  end

  defp make_url(url, nil), do: url
  defp make_url(url, params), do: url <> "?" <> URI.encode_query(params)

  defp content_type_header(""), do: %{}
  defp content_type_header({:json, _}), do: %{"content-type" => "application/json; charset=utf-8"}
  defp content_type_header({:form, _}), do: %{"content-type" => "application/x-form-www-urlencoded; charset=utf-8"}
  defp content_type_header(str) when is_binary(str) and byte_size(str) > 0, do: %{"content-type" => "text/plain; charset=utf-8"}

  defp req_body_to_string({:json, map}), do: Poison.encode!(map)
  defp req_body_to_string({:form, list}), do: URI.encode_query(list)
  defp req_body_to_string(str) when is_binary(str), do: str
end
