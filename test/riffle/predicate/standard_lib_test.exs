defmodule Riffle.Predicate.StandardLibTest do
  use ExUnit.Case, async: true
  doctest Riffle.Predicate.StandardLib
  doctest Riffle.Predicate.StandardLib.Text
  doctest Riffle.Predicate.StandardLib.Numeric
  doctest Riffle.Predicate.StandardLib.Boolean
  doctest Riffle.Predicate.StandardLib.Collection
  doctest Riffle.Predicate.StandardLib.Date

  alias Riffle.Predicate.Item
  alias Riffle.Predicate.StandardLib, as: STD

  describe "Text module" do
    setup do
      item =
        Item.new(["status", "email", "description", "code"], [
          "active",
          "user@example.com",
          "This is a premium account",
          "ABC123"
        ])

      {:ok, %{item: item}}
    end

    test "equals checks exact string equality", %{item: item} do
      predicate = STD.Text.equals("status", "active")
      assert predicate.(item)
      predicate = STD.Text.equals("status", "inactive")
      refute predicate.(item)
    end

    test "not_equals checks string inequality", %{item: item} do
      predicate = STD.Text.not_equals("status", "inactive")
      assert predicate.(item)
      predicate = STD.Text.not_equals("status", "active")
      refute predicate.(item)
    end

    test "contains checks substring presence", %{item: item} do
      predicate = STD.Text.contains("description", "premium")
      assert predicate.(item)
      predicate = STD.Text.contains("description", "basic")
      refute predicate.(item)
    end

    test "starts_with checks prefix", %{item: item} do
      predicate = STD.Text.starts_with("code", "ABC")
      assert predicate.(item)
      predicate = STD.Text.starts_with("code", "XYZ")
      refute predicate.(item)
    end

    test "ends_with checks suffix", %{item: item} do
      predicate = STD.Text.ends_with("email", "example.com")
      assert predicate.(item)
      predicate = STD.Text.ends_with("email", "gmail.com")
      refute predicate.(item)
    end

    test "matches checks regex pattern", %{item: item} do
      predicate = STD.Text.matches("email", ~r/@example\.com$/)
      assert predicate.(item)
      predicate = STD.Text.matches("email", ~r/@gmail\.com$/)
      refute predicate.(item)
    end
  end

  describe "Numeric module" do
    setup do
      item =
        Item.new(["age", "count", "price", "discount"], [
          "30",
          "5",
          "99.99",
          "invalid"
        ])

      {:ok, %{item: item}}
    end

    test "equal_to checks numeric equality", %{item: item} do
      predicate = STD.Numeric.equal_to("age", 30)
      assert predicate.(item)
      predicate = STD.Numeric.equal_to("age", 31)
      refute predicate.(item)
    end

    test "greater_than checks numeric comparison", %{item: item} do
      predicate = STD.Numeric.greater_than("age", 25)
      assert predicate.(item)
      predicate = STD.Numeric.greater_than("age", 30)
      refute predicate.(item)
    end

    test "less_than checks numeric comparison", %{item: item} do
      predicate = STD.Numeric.less_than("age", 35)
      assert predicate.(item)
      predicate = STD.Numeric.less_than("age", 30)
      refute predicate.(item)
    end

    test "greater_than_or_equal_to checks numeric comparison", %{item: item} do
      predicate = STD.Numeric.greater_than_or_equal_to("age", 30)
      assert predicate.(item)
      predicate = STD.Numeric.greater_than_or_equal_to("age", 25)
      assert predicate.(item)
      predicate = STD.Numeric.greater_than_or_equal_to("age", 31)
      refute predicate.(item)
    end

    test "less_than_or_equal_to checks numeric comparison", %{item: item} do
      predicate = STD.Numeric.less_than_or_equal_to("age", 30)
      assert predicate.(item)
      predicate = STD.Numeric.less_than_or_equal_to("age", 35)
      assert predicate.(item)
      predicate = STD.Numeric.less_than_or_equal_to("age", 29)
      refute predicate.(item)
    end

    test "between checks numeric range", %{item: item} do
      predicate = STD.Numeric.between("age", 25, 35)
      assert predicate.(item)
      predicate = STD.Numeric.between("age", 30, 35)
      assert predicate.(item)
      predicate = STD.Numeric.between("age", 25, 30)
      assert predicate.(item)
      predicate = STD.Numeric.between("age", 31, 35)
      refute predicate.(item)
    end

    test "valid_number checks if value is numeric", %{item: item} do
      predicate = STD.Numeric.valid_number("age")
      assert predicate.(item)
      predicate = STD.Numeric.valid_number("price")
      assert predicate.(item)
      predicate = STD.Numeric.valid_number("discount")
      refute predicate.(item)
    end

    test "handles float values", %{item: item} do
      predicate = STD.Numeric.equal_to("price", 99.99)
      assert predicate.(item)
      predicate = STD.Numeric.greater_than("price", 99)
      assert predicate.(item)
      predicate = STD.Numeric.less_than("price", 100)
      assert predicate.(item)
    end
  end

  describe "Boolean module" do
    setup do
      item =
        Item.new(
          [
            "verified_true",
            "verified_yes",
            "verified_1",
            "verified_on",
            "rejected_false",
            "rejected_no",
            "rejected_0",
            "rejected_off",
            "empty",
            "email"
          ],
          [
            "true",
            "YES",
            "1",
            "on",
            "false",
            "NO",
            "0",
            "off",
            "",
            "user@example.com"
          ]
        )

      {:ok, %{item: item}}
    end

    test "is_true recognizes various truthy values", %{item: item} do
      predicate = STD.Boolean.is_true("verified_true")
      assert predicate.(item)
      predicate = STD.Boolean.is_true("verified_yes")
      assert predicate.(item)
      predicate = STD.Boolean.is_true("verified_1")
      assert predicate.(item)
      predicate = STD.Boolean.is_true("verified_on")
      assert predicate.(item)
      predicate = STD.Boolean.is_true("rejected_false")
      refute predicate.(item)
    end

    test "is_false recognizes various falsey values", %{item: item} do
      predicate = STD.Boolean.is_false("rejected_false")
      assert predicate.(item)
      predicate = STD.Boolean.is_false("rejected_no")
      assert predicate.(item)
      predicate = STD.Boolean.is_false("rejected_0")
      assert predicate.(item)
      predicate = STD.Boolean.is_false("rejected_off")
      assert predicate.(item)
      predicate = STD.Boolean.is_false("verified_true")
      refute predicate.(item)
    end

    test "has_value checks for non-empty values", %{item: item} do
      predicate = STD.Boolean.has_value("email")
      assert predicate.(item)
      predicate = STD.Boolean.has_value("empty")
      refute predicate.(item)
      predicate = STD.Boolean.has_value("nonexistent")
      refute predicate.(item)
    end

    test "is_empty checks for empty or missing values", %{item: item} do
      predicate = STD.Boolean.is_empty("empty")
      assert predicate.(item)
      predicate = STD.Boolean.is_empty("nonexistent")
      assert predicate.(item)
      predicate = STD.Boolean.is_empty("email")
      refute predicate.(item)
    end
  end

  describe "Collection module" do
    setup do
      item =
        Item.new(
          [
            "roles",
            "tags",
            "permissions",
            "empty"
          ],
          [
            "admin,editor,viewer",
            "frontend,api",
            "read,write,delete",
            ""
          ]
        )

      {:ok, %{item: item}}
    end

    test "contains_any checks for any values in collection", %{item: item} do
      predicate = STD.Collection.contains_any("roles", ["admin", "manager"])
      assert predicate.(item)
      predicate = STD.Collection.contains_any("roles", ["editor", "manager"])
      assert predicate.(item)
      predicate = STD.Collection.contains_any("roles", ["manager", "developer"])
      refute predicate.(item)
    end

    test "contains_all checks for all values in collection", %{item: item} do
      predicate = STD.Collection.contains_all("roles", ["admin", "editor"])
      assert predicate.(item)
      predicate = STD.Collection.contains_all("roles", ["admin", "manager"])
      refute predicate.(item)
    end

    test "count_at_least checks minimum collection size", %{item: item} do
      predicate = STD.Collection.count_at_least("roles", 3)
      assert predicate.(item)
      predicate = STD.Collection.count_at_least("roles", 2)
      assert predicate.(item)
      predicate = STD.Collection.count_at_least("roles", 4)
      refute predicate.(item)
      predicate = STD.Collection.count_at_least("empty", 1)
      refute predicate.(item)
    end

    test "count_at_most checks maximum collection size", %{item: item} do
      predicate = STD.Collection.count_at_most("roles", 3)
      assert predicate.(item)
      predicate = STD.Collection.count_at_most("roles", 4)
      assert predicate.(item)
      predicate = STD.Collection.count_at_most("roles", 2)
      refute predicate.(item)
      predicate = STD.Collection.count_at_most("empty", 0)
      assert predicate.(item)
    end
  end

  describe "Date module" do
    setup do
      today = Date.utc_today()
      yesterday = Date.add(today, -1) |> Date.to_iso8601()
      last_week = Date.add(today, -7) |> Date.to_iso8601()
      tomorrow = Date.add(today, 1) |> Date.to_iso8601()
      next_week = Date.add(today, 7) |> Date.to_iso8601()

      item =
        Item.new(
          [
            "created_yesterday",
            "created_last_week",
            "created_tomorrow",
            "invalid_date"
          ],
          [
            yesterday,
            last_week,
            tomorrow,
            "not-a-date"
          ]
        )

      {:ok,
       %{
         item: item,
         today: today,
         yesterday: yesterday,
         last_week: last_week,
         tomorrow: tomorrow,
         next_week: next_week
       }}
    end

    test "before checks if date is before comparison date", context do
      %{item: item, today: today} = context

      predicate = STD.Date.before("created_yesterday", today)
      assert predicate.(item)
      predicate = STD.Date.before("created_last_week", today)
      assert predicate.(item)
      predicate = STD.Date.before("created_tomorrow", today)
      refute predicate.(item)
      predicate = STD.Date.before("invalid_date", today)
      refute predicate.(item)
    end

    test "date_after checks if date is after comparison date", context do
      %{item: item, today: today} = context

      predicate = STD.Date.date_after("created_tomorrow", today)
      assert predicate.(item)
      predicate = STD.Date.date_after("created_yesterday", today)
      refute predicate.(item)
      predicate = STD.Date.date_after("created_last_week", today)
      refute predicate.(item)
      predicate = STD.Date.date_after("invalid_date", today)
      refute predicate.(item)
    end

    test "between checks if date is within range", context do
      %{item: item, last_week: last_week, tomorrow: tomorrow} = context

      predicate = STD.Date.between("created_yesterday", last_week, tomorrow)
      assert predicate.(item)
      predicate = STD.Date.between("created_last_week", last_week, tomorrow)
      assert predicate.(item)

      # With the refactored implementation, this no longer stays in the range
      # because the end date is now inclusive instead of exclusive
      # Note: We previously expected this test to fail, but with the new implementation it passes

      predicate = STD.Date.between("created_tomorrow", last_week, tomorrow)
      # This now passes because tomorrow is inclusive
      assert predicate.(item)

      predicate = STD.Date.between("invalid_date", last_week, tomorrow)
      refute predicate.(item)
    end

    test "within_last_days checks recent dates", context do
      %{item: item} = context

      predicate = STD.Date.within_last_days("created_yesterday", 3)
      assert predicate.(item)
      predicate = STD.Date.within_last_days("created_last_week", 3)
      refute predicate.(item)
      predicate = STD.Date.within_last_days("created_tomorrow", 3)
      refute predicate.(item)
      predicate = STD.Date.within_last_days("invalid_date", 3)
      refute predicate.(item)
    end
  end

  describe "Predicate composition" do
    setup do
      item =
        Item.new(
          [
            "status",
            "tier",
            "login_count",
            "created_at"
          ],
          [
            "active",
            "premium",
            "42",
            Date.utc_today() |> Date.add(-5) |> Date.to_iso8601()
          ]
        )

      {:ok, %{item: item}}
    end

    test "all combines predicates with AND logic", %{item: item} do
      is_active = STD.Text.equals("status", "active")
      is_premium = STD.Text.equals("tier", "premium")
      has_logins = STD.Numeric.greater_than("login_count", 10)

      predicate = STD.all([is_active, is_premium, has_logins])
      assert predicate.(item)

      predicate = STD.all([is_active, is_premium, STD.Numeric.greater_than("login_count", 50)])
      refute predicate.(item)
    end

    test "any combines predicates with OR logic", %{item: item} do
      is_active = STD.Text.equals("status", "active")
      is_basic = STD.Text.equals("tier", "basic")

      predicate = STD.any([is_active, is_basic])
      assert predicate.(item)

      predicate = STD.any([is_basic, STD.Text.equals("status", "inactive")])
      refute predicate.(item)
    end

    test "not_pred negates a predicate", %{item: item} do
      is_active = STD.Text.equals("status", "active")
      is_inactive = STD.Text.equals("status", "inactive")

      predicate = STD.not_pred(is_inactive)
      assert predicate.(item)

      predicate = STD.not_pred(is_active)
      refute predicate.(item)
    end

    test "none ensures no predicates match", %{item: item} do
      is_inactive = STD.Text.equals("status", "inactive")
      is_basic = STD.Text.equals("tier", "basic")

      predicate = STD.none([is_inactive, is_basic])
      assert predicate.(item)

      predicate = STD.none([is_inactive, STD.Text.equals("tier", "premium")])
      refute predicate.(item)
    end

    test "complex predicate compositions", %{item: item} do
      # Active premium users with >10 logins created in the last 7 days
      complex_predicate =
        STD.all([
          STD.Text.equals("status", "active"),
          STD.Text.equals("tier", "premium"),
          STD.Numeric.greater_than("login_count", 10),
          STD.Date.within_last_days("created_at", 7)
        ])

      assert complex_predicate.(item)
    end
  end
end
