require 'tax_calculator'

class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :set_stocks, only: [:edit, :new]
  before_action :set_actions, only: [:edit, :new]
  before_action :set_currencies, only: [:edit, :new]

  respond_to :html, :csv

  def index
    if params[:date].present? && params[:date][:year].present?
      @year = params[:date][:year].to_i
    else
      @year = Date.today.year
    end

    @events = current_user.events.events_for_year(@year).order(:executed_on, :action).includes(:stock, :currency).all
    @total_capital_gain = current_user.events.total_capital_gain(@year)
    @total_discount = current_user.events.total_discount(@year)
    @quantity_acquired = current_user.quantity_acquired
    @quantity_sold = current_user.quantity_sold

    @taxes_unmarried = TaxCalculator.taxes_on(@total_capital_gain, @year, false)
    @taxes_married = TaxCalculator.taxes_on(@total_capital_gain, @year, true)
    @taxes_on_discount = TaxCalculator.taxes_on_discount(@total_discount, @year)

    @start_year = start_year
    @end_year = end_year
    respond_with(@events)
  end

  def new
    @event = current_user.events.new
    respond_with(@event)
  end

  def edit
  end

  def create
    @event = current_user.events.new(event_params)

    if @event.save
      flash[:notice] = 'Event was successfully created.'
      redirect_to events_path
    else
      render :new
    end
  end

  def update
    @event.update(event_params)
    flash[:notice] = 'Event was successfully updated.'

    redirect_to events_path
  end

  def destroy
    @event.destroy
    flash[:notice] = 'Event was removed.'

    redirect_to events_path
  end

  private

  def start_year
    if current_user.events.first
      current_user.events.first.executed_on.year
    else
      Time.now.year - 2
    end
  end

  def end_year
    if current_user.events.last
      current_user.events.last.executed_on.year
    else
      Time.now.year
    end
  end

  def set_event
    @event = current_user.events.find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :action,
      :stock_id,
      :quantity,
      :price,
      :price_discounted,
      :include_discount,
      :commission,
      :currency_id,
      :executed_on
    )
  end

  def set_stocks
    @stocks = Stock.all
  end

  def set_actions
    @actions = Event.actions
  end

  def set_currencies
    @currencies = Currency.all
  end
end
