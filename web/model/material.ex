use Croma

defmodule Blick.Model.Material do
  import Croma.TypeGen, only: [nilable: 1]
  alias Antikythera.Url

  defmodule Type do
    use Croma.SubtypeOfAtom, values: [
      :google_slide,
      :google_doc,
      :google_file,
      :google_folder,
      :qiita,
      :html,
      :intra,
    ]
  end

  @data_fields [
    title: Croma.String,
    url: Url,
    thumbnail_url: nilable(Url),
    created_time: nilable(Antikythera.Time),
    author_email: nilable(Antikythera.Email),
    type: Type,
    public: {Croma.Boolean, default: false},   # Indicates the material is publicly viewable, in terms of authorization and contents; TODO use section
    excluded: {Croma.Boolean, default: false}, # Indicates the material is collected but manually excluded for reasons; TODO use section
    exclude_reason: nilable(Croma.String),
  ]
  use AntikytheraAcs.Dodai.Model.Datastore, id_pattern: ~r/\A[A-Z2-7]{26}\Z/, data_fields: @data_fields

  def data_fields(), do: @data_fields

  @doc """
  Generates Unique ID of Material.

  This should be calculated from "original" URL,
  in order to reduce unnecessary renormalization/lookup roundtrips.
  (This is important since Google Drive API has quota limits,
  whereas our Dodai API does not, so we should fully utilize Dodai.)

  By "original" here it means:
  - URLs that are extracted from spreadsheet or other lookup entry points
    and get normalized only once (without additional lookups)
  - URLs that are registered directly by users (TODO)

  If the "original" URL is normalized to a different URL,
  it should be found in `:url` field.

  ## What if different URLs are found/registered but normalized into a single URL?

  Deduplicatoin should be performed "on entry", which means,
  normalized URL values will be searched from among already registered materials,
  and removed if a matching material is found (TODO).
  """
  defun generate_id(original_url :: v[Url.t]) :: Id.t do
    :crypto.hash(:md5, original_url) |> Base.encode32(padding: false)
  end

  defun normalize_url_by_types(raw_url :: Url.t) :: {Type.t, Url.t} do
    "https://docs.google.com" <> _ = google_docs_url ->
      normalize_google_docs_url(google_docs_url)
    "https://drive.google.com" <> _ = google_drive_url ->
      normalize_google_drive_url(google_drive_url)
    "https://qiita.com" <> _ = qiita_url ->
      {:qiita, qiita_url}
    "http://qiita.com" <> http_qiita_path ->
      {:qiita, "https://qiita.com" <> http_qiita_path}
    "http://gitbucket.tok.access-company.com" <> _ = gitbucket_url ->
      {:intra, gitbucket_url}
    otherwise ->
      {:html, otherwise}
  end

  defp normalize_google_docs_url(google_docs_url) do
    cond do
      matches = Regex.named_captures(~r{/presentation/d/(?<slide_id>[^/ ]+)([/?]|\Z)}, google_docs_url) ->
        {:google_slide, "https://docs.google.com/presentation/d/#{matches["slide_id"]}"}
      matches = Regex.named_captures(~r{/document/d/(?<doc_id>[^/ ]+)([/?]|\Z)}, google_docs_url) ->
        {:google_doc, "https://docs.google.com/document/d/#{matches["doc_id"]}"}
      matches = Regex.named_captures(~r{/file/d/(?<file_id>[^/ ]+)([/?]|\Z)}, google_docs_url) ->
        {:google_file, "https://drive.google.com/file/d/#{matches["file_id"]}"}
      true ->
        {:html, google_docs_url}
    end
  end

  defp normalize_google_drive_url(google_drive_url) do
    cond do
      matches = Regex.named_captures(~r|/open\?id=(?<file_id>[^& ]+)|, google_drive_url) ->
        {:google_file, "https://drive.google.com/file/d/#{matches["file_id"]}"}
      matches = Regex.named_captures(~r{/file/d/(?<file_id>[^/ ]+)([/?]|\Z)}, google_drive_url) ->
        {:google_file, "https://drive.google.com/file/d/#{matches["file_id"]}"}
      matches = Regex.named_captures(~r|folders/(?<folder_id>[^/?& ]+)|, google_drive_url) ->
        {:google_folder, "https://drive.google.com/drive/folders/#{matches["folder_id"]}"}
      true ->
        {:html, google_drive_url}
    end
  end

  @doc """
  Extracts Google Drive File ID from a normalized Google file URL in a material.

  If the given material is not a Google Drive File, it crashes.
  """
  defun google_file_id!(material :: t | Data.t) :: String.t do
    %__MODULE__{data: %Data{} = data} -> google_file_id!(data)
    %Data{url: "https://docs.google.com/document/d/" <> file_id} -> file_id
    %Data{url: "https://docs.google.com/presentation/d/" <> file_id} -> file_id
    %Data{url: "https://drive.google.com/file/d/" <> file_id} -> file_id
  end
end
