defmodule Riffle.Service.Csv do
  @moduledoc """
  Reads a CSV file into the field maps the pattern layer ingests.

  The first row is the header and names the fields; every later row becomes one
  map keyed by those names. Values are carried as read -- strings -- because
  deciding what `"42"` means is the engine's job (`Riffle.Predicate.Coerce`) and
  guessing at it here would put a second, weaker answer next to the real one.

  ## The boundary

  This module is a user-input boundary in the sense `Riffle.Predicate.Dsl.Loader`
  established for `.pred` text: what arrives is a file a person chose, so a
  malformed one is an ordinary outcome to report rather than a defect to crash
  on. It is the one place in the service layer that rescues, and it names the
  exception it converts. A `rescue`-all here would be D9 rebuilt at a new
  boundary -- the fence in `test/riffle/service/no_rescue_fence_test.exs`
  forbids that shape while permitting this one.

  ## What it refuses

  A row whose width differs from the header is a tagged error, never a padded or
  truncated map. Silently zipping a short row would invent a field map that no
  line of the file contains, and the pattern layer would then run predicates
  against data the user never supplied.

      iex> path = Path.join(System.tmp_dir!(), "riffle_doc_#{System.unique_integer([:positive])}.csv")
      iex> File.write!(path, "a,b\\n1,2\\n")
      iex> {:ok, rows} = Riffle.Service.Csv.read(path)
      iex> File.rm!(path)
      iex> rows
      [%{"a" => "1", "b" => "2"}]
  """

  alias NimbleCSV.RFC4180

  @type row :: %{String.t() => String.t()}
  @type error ::
          {:input_not_found, Path.t()}
          | {:input_unreadable, Path.t(), File.posix()}
          | {:input_empty, Path.t()}
          | {:input_malformed, Path.t(), String.t()}

  @doc """
  Reads `path` into one field map per data row.

  Returns `{:error, {:input_empty, path}}` for a file with no data rows --
  including a file that is only a header. An empty result is a thing a caller
  must be told about, not a successful run over nothing.
  """
  @spec read(Path.t()) :: {:ok, [row()]} | {:error, error()}
  def read(path) do
    with {:ok, contents} <- read_file(path),
         {:ok, rows} <- parse(contents, path) do
      to_maps(rows, path)
    end
  end

  defp read_file(path) do
    case File.read(path) do
      {:ok, contents} -> {:ok, contents}
      {:error, :enoent} -> {:error, {:input_not_found, path}}
      {:error, reason} -> {:error, {:input_unreadable, path, reason}}
    end
  end

  # The one rescue in the service layer, and it names its type. NimbleCSV raises
  # on unterminated quotes and similar text-level damage; that is a report, not
  # a crash, because the text came from outside.
  defp parse(contents, path) do
    {:ok, RFC4180.parse_string(contents, skip_headers: false)}
  rescue
    error in NimbleCSV.ParseError ->
      {:error, {:input_malformed, path, Exception.message(error)}}
  end

  defp to_maps([], path), do: {:error, {:input_empty, path}}
  defp to_maps([_header], path), do: {:error, {:input_empty, path}}

  defp to_maps([header | rows], path) do
    rows
    |> Enum.with_index(2)
    |> Enum.reduce_while({:ok, []}, fn row, acc -> pair(row, header, path, acc) end)
    |> finish()
  end

  defp pair({fields, _line}, header, _path, {:ok, built}) when length(fields) == length(header) do
    {:cont, {:ok, [Map.new(Enum.zip(header, fields)) | built]}}
  end

  defp pair({fields, line}, header, path, _acc) do
    {:halt,
     {:error,
      {:input_malformed, path,
       "line #{line} has #{length(fields)} fields, header has #{length(header)}"}}}
  end

  defp finish({:ok, built}), do: {:ok, Enum.reverse(built)}
  defp finish({:error, _reason} = error), do: error
end
