class UI::Account::Chart < ApplicationComponent
  attr_reader :account

  def initialize(account:, period: nil, view: nil)
    @account = account
    @period = period
    @view = view
  end

  def period
    @period ||= Period.last_30_days
  end

  def holdings_value_money
    account.balance_money - account.cash_balance_money
  end

  def view_balance_money
    case view
    when "balance"
      account.balance_money
    when "holdings_balance"
      holdings_value_money
    when "cash_balance"
      account.cash_balance_money
    end
  end

  def title
    case account.accountable_type
    when "Investment", "Crypto"
      case view
      when "balance"
        "Total account value"
      when "holdings_balance"
        "Holdings value"
      when "cash_balance"
        "Cash value"
      end
    when "Property", "Vehicle"
      "Estimated #{account.accountable_type.humanize.downcase} value"
    when "CreditCard", "OtherLiability"
      "Debt balance"
    when "Loan"
      "Remaining principal balance"
    else
      "Balance"
    end
  end

  def converted_balances
    other_currencies = account.family.available_currencies - [account.currency]
    return [] if other_currencies.empty?

    other_currencies.filter_map do |cur|
      converted = account.balance_money.exchange_to(cur, date: Date.current, fallback_rate: nil)
      converted
    rescue
      nil
    end
  end

  def converted_balance_money
    converted_balances.first
  end

  def view
    @view ||= "balance"
  end

  def series
    account.balance_series(period: period, view: view)
  end

  def trend
    series.trend
  end
end
