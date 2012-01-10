require 'test_helper'

class RemoteFirstDataTest < Test::Unit::TestCase
  

  def setup
    @gateway = FirstDataGateway.new(fixtures(:first_data))    
    @amount = 100.25
    @credit_card = credit_card('4000100011112224')
    @declined_card = credit_card('4000300011112220')
    
    @options = { 
      :order_id => '1',
      :billing_address => us_address,
      :description => 'Test Order'
    }
  end
  
  def test_successful_purchase
    setup
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal response.params['dollaramount'].to_f, @amount.to_f
    assert_equal 'Transaction Normal', response.message
  end

  def test_unsuccessful_purchase
    setup
    assert response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    assert_equal 'REPLACE WITH FAILED PURCHASE MESSAGE', response.message
  end

  def test_authorize_and_capture
    setup
    assert auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth
    assert auth.authorization
    assert capture = @gateway.capture(@amount, @credit_card, @options.merge(
      :authorization=>auth.authorization, 
      :transaction_tag=>auth.params['transaction_tag']
      )
    )
    assert_success capture
  end

  def test_failed_capture
    setup
    assert response = @gateway.capture(0.0-@amount, @credit_card, @options)    
    assert_failure response
    assert_equal 'REPLACE WITH GATEWAY FAILURE MESSAGE', response.message
  end

  def test_invalid_login
    setup
    gateway = FirstDataGateway.new(
                :login => 'asdf',
                :password => 'asdf'
              )
    assert response = gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_contains 'You need to pass in your login (Gateway ID) and Password', response.message
  end

  def us_address(options = {})
    { 
      :name     => 'John Smith',
      :address1 => '111 Broadway',
      :address2 => 'Apt 11',
      :company  => 'Widgets Inc',
      :city     => 'New York',
      :state    => 'NY',
      :zip      => '10006',
      :country  => 'USA',
      :phone    => '(555)555-5555',
      :fax      => '(555)555-6666'
    }.update(options)
  end

end
