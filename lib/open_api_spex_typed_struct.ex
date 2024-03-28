defmodule OpenApiSpexTypedStruct do
  @moduledoc """
  Automatically generate api specs for your typed structs. This library is a plugin for [OpenApiSpex](github.com/open-api-spex/open_api_spex) that allows you to define typed structs and have the schema automatically generated for you. You can then easily reference these schemas in your OpenApiSpex operations. This allows you to keep your api specs in sync with your typed structs without having to constantly update two different versions of what is effectively the same schema.

  - Give your struct a title and you're all set, the rest is generated for you.
  - You can optionally give `default` values to your fields and they will also be included in the schema.
  - Same for `example`s. Can be combined with default values.
  - Additionally, you can override the generated schema property for specific fields by providing a
    `property` option to the field. This is for when you want to reference another schema.

  ## Usage

  ```elixir
  defmodule MySpec do
    use TypedStruct

    typedstruct do
      plugin TypedSpec, title: "my spec"
      field :id, :string, default: "123", example: "456"
      field :qty, :integer
      field :other_schema, :object, property: MyOtherSchema
    end
  end
  ```

  Generates a schema that looks like:
  ```elixir
  %OpenApiSpex.Schema%{
    properties: %{
      id: %OpenApiSpex.Schema%{type: :string, default: "123", example: "456"},
      qty: %OpenApiSpex.Schema%{type: :integer},
      other_schema: OtherSchema
    },
    required: [:id, :qty],
    title: "my spec",
    type: :object
  }
  ```

  That can then be used with OpenApiSpex in your controller:
  ```elixir
  operation(:index,
    summary: "Get fancy new spec-ed things",
    responses: [
      ok: {"Successful", "application/json", MySpec},
    ]
  )
  ```

  """

  use TypedStruct.Plugin
  alias OpenApiSpex.Schema

  @impl true
  @spec init(keyword()) :: Macro.t()
  defmacro init(opts) do
    quote do
      Module.register_attribute(__MODULE__, :properties, accumulate: true)
      Module.register_attribute(__MODULE__, :required_properties, accumulate: true)

      def title, do: unquote(opts)[:title]
      def description, do: unquote(opts)[:description]
    end
  end

  @impl true
  @spec field(atom(), any(), keyword(), Macro.Env.t()) :: Macro.t()
  def field(name, type, opts, _env) do
    required = Keyword.get(opts, :required, true)
    property = opts[:property] || create_schema(type, opts)

    add_property(name, property, required)
  end

  @impl true
  @spec after_definition(opts :: keyword()) :: Macro.t()
  def after_definition(_opts) do
    quote do
      def schema do
        %Schema{
          title: title(),
          description: description(),
          type: :object,
          properties: Map.new(@properties),
          required: @required_properties
        }
      end
    end
  end

  defp add_property(name, property, required) do
    quote do
      if unquote(required) do
        Module.put_attribute(__MODULE__, :required_properties, unquote(name))
      end

      Module.put_attribute(__MODULE__, :properties, {unquote(name), unquote(property)})
    end
  end

  defp create_schema(type, opts) do
    nullable = Keyword.get(opts, :nullable, false)

    Macro.escape(%Schema{
      type: map_type(type),
      nullable: nullable,
      default: opts[:default],
      example: opts[:example]
    })
  end

  defp map_type({:__aliases__, _keyword, [:Money, :Ecto, :Amount, :Type]}), do: :number
  defp map_type({:__aliases__, _keyword, [:Ecto, :Atom]}), do: :string
  defp map_type(:decimal), do: :number
  defp map_type(:map), do: :object
  defp map_type(:date), do: :string
  defp map_type(:utc_datetime_usec), do: :string
  defp map_type(type), do: type
end
