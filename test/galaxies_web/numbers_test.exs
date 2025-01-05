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

  describe "format_number/1" do
    test "when number is less than 1000" do
      assert GalaxiesWeb.Numbers.format_number(0) == "0"
      assert GalaxiesWeb.Numbers.format_number(999) == "999"
    end

    test "when number is greater than 1000" do
      assert GalaxiesWeb.Numbers.format_number(1_000) == "1.000"
      assert GalaxiesWeb.Numbers.format_number(1_000_000) == "1.000.000"
      assert GalaxiesWeb.Numbers.format_number(1_000_000_000) == "1.000.000.000"
    end
  end
end
