use Croma

defmodule Blick.Model.Material do
  use SolomonAcs.Dodai.Model.Datastore, data_fields: [
    title: Croma.String,
    url: SolomonLib.Url,
    author_name: Croma.String,
    author_email: Croma.TypeGen.nilable(SolomonLib.Email),
    type: Type,
    excluded: Croma.Boolean, # Indicates the material is collected but manually excluded for reasons
  ]

  defmodule Type do
    use Croma.SubtypeOfAtom, values: [
      :google_slide,
      :google_directory,
      :slideshare,
      :speakerdeck,
      :qiita,
      :pdf,
      :html,
    ]
  end
end
