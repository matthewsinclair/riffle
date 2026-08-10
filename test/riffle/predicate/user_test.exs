defmodule Riffle.Predicate.UserTest do
  use ExUnit.Case, async: true

  alias Riffle.Predicate.Dsl.Loader
  alias Riffle.Predicate.Loop
  alias Riffle.Predicate.Item

  @test_pred_path "test/fixtures/predicate/examples/predicates/user_test.pred"
  @test_csv_path "test/fixtures/users/users_small.csv"

  test "filter suspended users using predicate loaded from file" do
    # Step 1: Load the predicate file
    {:ok, definitions} = Loader.load_file(@test_pred_path)

    # Step 2: Create instances from the loaded definitions
    {:ok, instances} = Loader.create_instances(definitions)

    # Step 3: Get the loop (just using the first loop instead of the whole pipeline)
    suspended_loop = instances.loops.suspended_users_loop

    # Step 4: Read the CSV file
    {:ok, file} = File.open(@test_csv_path, [:read, :utf8])

    # Read header line
    header_line = IO.read(file, :line) |> String.trim()
    headers = String.split(header_line, ",")

    # Read and process data lines
    items =
      file
      |> IO.stream(:line)
      |> Enum.map(&String.trim/1)
      |> Enum.map(fn line ->
        values = String.split(line, ",")
        Item.new(headers, values)
      end)

    File.close(file)

    # Step 5: Process through the suspended users loop
    filtered_items = Loop.filter(suspended_loop, items) |> Enum.to_list()

    # Step 6: Verify results. users_small.csv is static: exactly 26 of its
    # 100 rows are suspended -- a literal pin, not a mirror of the predicate.
    assert length(filtered_items) == 26

    Enum.each(filtered_items, fn item ->
      assert item.fields["account_status"] == "suspended"
      assert Item.has_tag?(item, :user_suspended)
    end)
  end
end
