defmodule Riffle.Predicate.Item do
  @moduledoc """
  Represents an item being processed by the predicate framework.

  An item contains field data, tags applied by predicates, and additional
  metadata that may be attached during processing.

  ## Examples

      iex> alias Riffle.Predicate.Item
      iex> item = Item.new(["id", "name", "status"], ["1", "John", "active"])
      iex> item.fields["name"]
      "John"
      iex> item = Item.add_tag(item, :premium)
      iex> Item.has_tag?(item, :premium)
      true
  """

  @type t :: %__MODULE__{
          fieldnames: [String.t()],
          fields: %{String.t() => String.t()},
          tags: [atom()],
          metadata: map()
        }

  defstruct fieldnames: [], fields: %{}, tags: [], metadata: %{}

  @doc """
  Creates a new item from a list of field names and values.

  ## Parameters
    * `fieldnames` - List of field names from CSV header
    * `values` - List of field values

  ## Returns
    * A new Item struct

  ## Examples

      iex> alias Riffle.Predicate.Item
      iex> Item.new(["id", "name"], ["1", "John"])
      %Item{fieldnames: ["id", "name"], fields: %{"id" => "1", "name" => "John"}, tags: [], metadata: %{}}
  """
  @spec new([String.t()], [String.t()]) :: t()
  def new(fieldnames, values) when length(fieldnames) == length(values) do
    fields = Enum.zip(fieldnames, values) |> Map.new()
    %__MODULE__{fieldnames: fieldnames, fields: fields}
  end

  @doc """
  Creates a new item from a map of field values.

  ## Parameters
    * `fields` - Map of field names to values
    
  ## Returns
    * A new Item struct
    
  ## Examples

      iex> alias Riffle.Predicate.Item
      iex> Item.create(%{"id" => "1", "name" => "John"})
      %Item{fieldnames: ["id", "name"], fields: %{"id" => "1", "name" => "John"}, tags: [], metadata: %{}}
  """
  @spec create(map()) :: t()
  def create(fields) when is_map(fields) do
    fieldnames = Map.keys(fields)
    %__MODULE__{fieldnames: fieldnames, fields: fields}
  end

  @doc """
  Adds a tag to an item.

  ## Parameters
    * `item` - The item to add the tag to
    * `tag` - The tag to add (atom)

  ## Returns
    * Updated item with the new tag

  ## Examples

      iex> alias Riffle.Predicate.Item
      iex> item = %Item{tags: [:existing]}
      iex> Item.add_tag(item, :new_tag)
      %Item{tags: [:new_tag, :existing]}
  """
  @spec add_tag(t(), atom()) :: t()
  def add_tag(%__MODULE__{} = item, tag) when is_atom(tag) do
    %{item | tags: [tag | item.tags] |> Enum.uniq()}
  end

  @doc """
  Adds multiple tags to an item.

  ## Parameters
    * `item` - The item to add the tags to
    * `tags` - List of tags to add (atoms)

  ## Returns
    * Updated item with the new tags

  ## Examples

      iex> alias Riffle.Predicate.Item
      iex> item = %Item{tags: [:existing]}
      iex> Item.add_tags(item, [:tag1, :tag2])
      %Item{tags: [:tag1, :tag2, :existing]}
  """
  @spec add_tags(t(), [atom()]) :: t()
  def add_tags(%__MODULE__{} = item, tags) when is_list(tags) do
    %{item | tags: (tags ++ item.tags) |> Enum.uniq()}
  end

  @doc """
  Adds metadata to an item.

  ## Parameters
    * `item` - The item to add metadata to
    * `metadata` - Map of metadata to add

  ## Returns
    * Updated item with the new metadata

  ## Examples

      iex> alias Riffle.Predicate.Item
      iex> item = %Item{metadata: %{existing: "value"}}
      iex> Item.add_metadata(item, %{new: "data"})
      %Item{metadata: %{existing: "value", new: "data"}}
  """
  @spec add_metadata(t(), map()) :: t()
  def add_metadata(%__MODULE__{} = item, metadata) when is_map(metadata) do
    %{item | metadata: Map.merge(item.metadata, metadata)}
  end

  @doc """
  Checks if an item has a specific tag.

  ## Parameters
    * `item` - The item to check
    * `tag` - The tag to check for

  ## Returns
    * `true` if the item has the tag, `false` otherwise

  ## Examples

      iex> alias Riffle.Predicate.Item
      iex> item = %Item{tags: [:existing]}
      iex> Item.has_tag?(item, :existing)
      true
      iex> Item.has_tag?(item, :nonexistent)
      false
  """
  @spec has_tag?(t(), atom()) :: boolean()
  def has_tag?(%__MODULE__{} = item, tag) when is_atom(tag) do
    tag in item.tags
  end

  @doc """
  Retrieves a field value from an item.

  ## Parameters
    * `item` - The item to get the field from
    * `field` - The field name

  ## Returns
    * The field value, or nil if the field doesn't exist

  ## Examples

      iex> alias Riffle.Predicate.Item
      iex> item = %Item{fields: %{"name" => "John"}}
      iex> Item.get_field(item, "name")
      "John"
      iex> Item.get_field(item, "nonexistent")
      nil
  """
  @spec get_field(t(), String.t()) :: String.t() | nil
  def get_field(%__MODULE__{} = item, field) when is_binary(field) do
    Map.get(item.fields, field)
  end

  @doc """
  Gets metadata from an item by key.

  ## Parameters
    * `item` - The item to get metadata from
    * `key` - The metadata key

  ## Returns
    * The metadata value, or nil if the key doesn't exist

  ## Examples

      iex> alias Riffle.Predicate.Item
      iex> item = %Item{metadata: %{count: 42}}
      iex> Item.get_metadata(item, :count)
      42
      iex> Item.get_metadata(item, :nonexistent)
      nil
  """
  @spec get_metadata(t(), atom()) :: any() | nil
  def get_metadata(%__MODULE__{} = item, key) when is_atom(key) do
    Map.get(item.metadata, key)
  end
end
