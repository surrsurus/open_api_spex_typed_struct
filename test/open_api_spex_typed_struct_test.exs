defmodule OpenApiSpexTypedStructTest do
  use ExUnit.Case, async: true
  doctest OpenApiSpexTypedStruct

  alias OpenApiSpex.Schema

  defp unsorted_match?(l1, l2) when is_list(l1) and is_list(l2) do
    Enum.all?(l1, fn item -> item in l2 end) && length(l1) == length(l2)
  end

  defp unsorted_match?(_l1, _l2), do: false

  defmodule OtherSchema do
    require OpenApiSpex
    alias OpenApiSpex.Schema

    OpenApiSpex.schema(%{
      title: "Partner Account",
      description: "Partner Account Schema",
      type: :object,
      properties: %{flag: %Schema{type: :boolean}},
      required: [:flag]
    })
  end

  defmodule SpecTest do
    use TypedStruct

    typedstruct do
      plugin(OpenApiSpexTypedStruct, title: "my spec", description: "my description")
      field :id, :string, default: "123", example: "456"
      field :qty, :integer
      field :other_schema, :object, property: OtherSchema
    end
  end

  defmodule SpecRequiredTest do
    use TypedStruct

    typedstruct do
      plugin(OpenApiSpexTypedStruct, title: "my spec", description: "my description")
      field :id, :string, default: "123", example: "456"
      field :qty, :integer, required: false
    end
  end

  defmodule SpecNullableTest do
    use TypedStruct

    typedstruct do
      plugin(OpenApiSpexTypedStruct, title: "my spec", description: "my description")
      field :id, :string, default: "123", example: "456"
      field :qty, :integer, nullable: true
    end
  end

  describe "TypedSpec plugin" do
    test "can generate a schema/0" do
      required = SpecTest.schema().required

      # Assert required first because we can't guarantee the order of the list
      assert unsorted_match?(required, [:id, :other_schema, :qty])

      assert SpecTest.schema() == %Schema{
               properties: %{
                 id: %Schema{default: "123", nullable: false, example: "456", type: :string},
                 other_schema: OtherSchema,
                 qty: %Schema{type: :integer, nullable: false}
               },
               required: required,
               title: "my spec",
              description: "my description",
               type: :object
             }
    end

    test "can generate a schema/0 that respects required property" do
      required = SpecRequiredTest.schema().required

      assert unsorted_match?(required, [:id])
    end

    test "can generate a schema/0 that respects nullable property" do
      assert %Schema{
               properties: %{
                 qty: %Schema{type: :integer, nullable: true}
               }
             } = SpecNullableTest.schema()
    end

    test "can give fields default values" do
      assert SpecTest.schema().properties.id.default == "123"
    end

    test "can give fields example values" do
      assert SpecTest.schema().properties.id.example == "456"
    end

    test "can override fields with arbitrary properties" do
      assert SpecTest.schema().properties.other_schema == OtherSchema
    end
  end
end
