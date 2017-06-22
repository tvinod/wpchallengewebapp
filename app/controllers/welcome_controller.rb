require 'wp-test'

class WelcomeController < ApplicationController
  include WpTest
  def index
#  	render plain: params[:welcome].inspect
  end

  def create
  	render plain: params[:welcome].inspect
  end

  def welcome
  	render plain: params[:welcome].inspect
  end

  def query
    str = my_test()
    @result = str
    @result = get_relation(params[:p1name], params[:p1city], params[:p1statecode],
                 params[:p2name], params[:p2city], params[:p2statecode])
    render "welcome/index"
  end

  def get
  	render plain: params[:welcome].inspect
  end

end
