defmodule GalaxiesWeb.NumbersTest do
  use ExUnit.Case, async: true

  describe "format_countdown/1" do
    test "when seconds is less than 0 or nil" do
      assert GalaxiesWeb.Numbers.format_countdown(-1) == ""
      assert GalaxiesWeb.Numbers.format_countdown(nil) == ""
    end

    test "when seconds is between 0 and 60 (1m)" do
      assert GalaxiesWeb.Numbers.format_countdown(0) == "0s"
      assert GalaxiesWeb.Numbers.format_countdown(30) == "30s"
      assert GalaxiesWeb.Numbers.format_countdown(59) == "59s"
    end

    test "when seconds is between 60 (1m) and 3600 (1h)" do
      assert GalaxiesWeb.Numbers.format_countdown(60) == "1m 0s"
      assert GalaxiesWeb.Numbers.format_countdown(90) == "1m 30s"
      assert GalaxiesWeb.Numbers.format_countdown(3599) == "59m 59s"
    end

    test "when seconds is between 3600 (1h) and 86400 (1d)" do
      assert GalaxiesWeb.Numbers.format_countdown(3600) == "1h 0m 0s"
      assert GalaxiesWeb.Numbers.format_countdown(3660) == "1h 1m 0s"
      assert GalaxiesWeb.Numbers.format_countdown(86399) == "23h 59m 59s"
    end

    test "when seconds is greater than 86400 (1d)" do
      assert GalaxiesWeb.Numbers.format_countdown(86400) == "1d 0h 0m 0s"
      assert GalaxiesWeb.Numbers.format_countdown(86460) == "1d 0h 1m 0s"
      assert GalaxiesWeb.Numbers.format_countdown(172_799) == "1d 23h 59m 59s"
    end
  end
end
