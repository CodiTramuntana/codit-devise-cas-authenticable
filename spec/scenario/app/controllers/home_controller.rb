# frozen_string_literal: true

class HomeController < ApplicationController
  before_filter :authenticate_user!

  def index
    head(:ok)
  end
end
