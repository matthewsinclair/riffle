defmodule Riffle.Service.CsvTest do
  use ExUnit.Case, async: true

  doctest Riffle.Service.Csv

  alias Riffle.Service.Csv
  alias Riffle.ServiceFixtures

  describe "read/1" do
    test "success: the header names the fields and each later row becomes one map" do
      path = ServiceFixtures.write_csv!("login_count,account_type\n100,standard\n5,premium\n")

      assert Csv.read(path) ==
               {:ok,
                [
                  %{"login_count" => "100", "account_type" => "standard"},
                  %{"login_count" => "5", "account_type" => "premium"}
                ]}
    end

    test "invariant: values arrive as read, uncoerced" do
      # Deciding what "42" means is the engine's job (Riffle.Predicate.Coerce).
      # A reader that guessed would put a second, weaker answer beside the real
      # one, and the two would disagree the first time a field held "007".
      path = ServiceFixtures.write_csv!("n,flag,blank\n007,true,\n")

      assert Csv.read(path) == {:ok, [%{"n" => "007", "flag" => "true", "blank" => ""}]}
    end

    test "success: a quoted field may carry the separator" do
      path = ServiceFixtures.write_csv!("name,note\nAda,\"one, two\"\n")

      assert Csv.read(path) == {:ok, [%{"name" => "Ada", "note" => "one, two"}]}
    end

    test "success: a quoted field may carry an escaped quote" do
      path = ServiceFixtures.write_csv!(~s(name,note\nAda,"she said ""hi"""\n))

      assert Csv.read(path) == {:ok, [%{"name" => "Ada", "note" => ~s(she said "hi")}]}
    end

    test "success: rows separated by CRLF read the same as LF" do
      path = ServiceFixtures.write_csv!("a,b\r\n1,2\r\n")

      assert Csv.read(path) == {:ok, [%{"a" => "1", "b" => "2"}]}
    end

    test "failure: an absent file is a tagged error" do
      assert Csv.read("/nope/missing.csv") == {:error, {:input_not_found, "/nope/missing.csv"}}
    end

    test "failure: a path that is not a readable file is a tagged error" do
      assert {:error, {:input_unreadable, _path, :eisdir}} = Csv.read(System.tmp_dir!())
    end

    test "failure: an empty file has no header and is refused" do
      path = ServiceFixtures.write_csv!("")

      assert Csv.read(path) == {:error, {:input_empty, path}}
    end

    test "failure: a header with no data rows is refused rather than read as an empty run" do
      path = ServiceFixtures.write_csv!("a,b\n")

      assert Csv.read(path) == {:error, {:input_empty, path}}
    end

    test "failure: a short row is refused, never padded" do
      path = ServiceFixtures.write_csv!("a,b,c\n1,2\n")

      assert Csv.read(path) ==
               {:error, {:input_malformed, path, "line 2 has 2 fields, header has 3"}}
    end

    test "failure: a long row is refused, never truncated" do
      path = ServiceFixtures.write_csv!("a,b\n1,2,3\n")

      assert Csv.read(path) ==
               {:error, {:input_malformed, path, "line 2 has 3 fields, header has 2"}}
    end

    test "failure: the reported line number is the offending row's own" do
      path = ServiceFixtures.write_csv!("a,b\n1,2\n3,4\n5\n")

      assert Csv.read(path) ==
               {:error, {:input_malformed, path, "line 4 has 1 fields, header has 2"}}
    end

    test "failure: text-level damage becomes a tagged error, not a raise" do
      path = ServiceFixtures.write_csv!("a,b\n\"unterminated,2\n")

      assert {:error, {:input_malformed, ^path, message}} = Csv.read(path)
      assert message =~ "escape character"
    end
  end
end
