require 'test_helper'

class FirstDataTest < Test::Unit::TestCase
  def setup
    Base.mode = :test

    @gateway = FirstDataGateway.new(
                 :login => 'login',
                 :password => 'password'
               )

    @credit_card = credit_card('4111111111111111')
    @amount = 100.25
    
    @options = { :order_id => 1, :billing_address => address }
  
  end
  
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    assert response = @gateway.purchase(@amount, @credit_card, @options)
  def test_successful_purchase
    assert_instance_of Response, response
    assert_success response    
    assert_equal 'ET4653', response.authorization
    assert response.test?
  end

=begin 
  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_equal('DECLINE', response.message)
    assert response.test?
  end
=end

  private

  # Place raw failed response from gateway here

  def successful_authorization_response
    '<?xml version="1.0" encoding="UTF-8"?>
<TransactionResult>
  <ExactID>ExactID</ExactID>
  <Password></Password>
  <Transaction_Type>32</Transaction_Type>
  <DollarAmount>15.75</DollarAmount>
  <SurchargeAmount></SurchargeAmount>
  <Card_Number>############1111</Card_Number>
  <Transaction_Tag>902006933</Transaction_Tag>
  <Track1></Track1>
  <Track2></Track2>
  <PAN></PAN>
  <Authorization_Num>ET4653</Authorization_Num>
  <Expiry_Date>1012</Expiry_Date>
  <CardHoldersName>Donald Duck</CardHoldersName>
  <VerificationStr1></VerificationStr1>
  <VerificationStr2></VerificationStr2>
  <CVD_Presence_Ind>0</CVD_Presence_Ind>
  <ZipCode></ZipCode>
  <Tax1Amount></Tax1Amount>
  <Tax1Number></Tax1Number>
  <Tax2Amount></Tax2Amount>
  <Tax2Number></Tax2Number>
  <Secure_AuthRequired></Secure_AuthRequired>
  <Secure_AuthResult></Secure_AuthResult>
  <Ecommerce_Flag>0</Ecommerce_Flag>
  <XID></XID>
  <CAVV></CAVV>
  <CAVV_Algorithm></CAVV_Algorithm>
  <Reference_No></Reference_No>
  <Customer_Ref></Customer_Ref>
  <Reference_3></Reference_3>
  <Language></Language>
  <Client_IP>10.1.1.20</Client_IP>
  <Client_Email></Client_Email>
  <LogonMessage></LogonMessage>
  <Error_Number>0</Error_Number>
  <Error_Description> </Error_Description>
  <Transaction_Error>false</Transaction_Error>
  <Transaction_Approved>true</Transaction_Approved>
  <EXact_Resp_Code>00</EXact_Resp_Code>
  <EXact_Message>Transaction Normal</EXact_Message>
  <Bank_Resp_Code>000</Bank_Resp_Code>
  <Bank_Message>APPROVED</Bank_Message>
  <Bank_Resp_Code_2></Bank_Resp_Code_2>
  <SequenceNo>025850</SequenceNo>
  <AVS></AVS>
  <CVV2></CVV2>
  <Retrieval_Ref_No>08183837</Retrieval_Ref_No>
  <CAVV_Response></CAVV_Response>
  <MerchantName>API Testing</MerchantName>
  <MerchantAddress>127 - 6768 Front St</MerchantAddress>
  <MerchantCity>Vancouver</MerchantCity>
  <MerchantProvince>British Columbia</MerchantProvince>
  <MerchantCountry>Canada</MerchantCountry>
  <MerchantPostal>V6B 2H7</MerchantPostal>
  <MerchantURL>www.firstdata.com</MerchantURL>
  <CTR>=========== TRANSACTION RECORD ==========
API Testing
127 - 6768 Front St
Vancouver, BC V6B 2H7
Canada
www.firstdata.com

TYPE: Pre-Auth Completion

ACCT: Visa  $ 15.75 CAD

CARD NUMBER : ############1111
DATE/TIME   : 18 Aug 10 11:38:36
REFERENCE # : 002 025850 M
AUTHOR. #   : ET4653
TRANS. REF. : 

    Approved - Thank You 000


Please retain this copy for your records.

Cardholder will pay above amount to card
issuer pursuant to cardholder agreement.
=========================================</CTR>
</TransactionResult>'
  end
  
  def successful_capture_response
    '<TransactionResult>
    <ExactID>ExactID</ExactID>
    <Password></Password>
    <Transaction_Type>32</Transaction_Type>
    <DollarAmount>15.75</DollarAmount>
    <SurchargeAmount></SurchargeAmount>
    <Card_Number>############1111</Card_Number>
     <Authorization_Num>ET4653</Authorization_Num>
    <Expiry_Date>1012</Expiry_Date>
    <CardHoldersName>Donald Duck</CardHoldersName>
    <Error_Number>0</Error_Number>
    <Error_Description> </Error_Description>
    <Transaction_Error>false</Transaction_Error>
    <Transaction_Approved>true</Transaction_Approved>
    <EXact_Resp_Code>00</EXact_Resp_Code>
    <EXact_Message>Transaction Normal</EXact_Message>
    <Bank_Resp_Code>000</Bank_Resp_Code>
    <Bank_Message>APPROVED</Bank_Message>
    <Bank_Resp_Code_2></Bank_Resp_Code_2>
    <SequenceNo>025850</SequenceNo>
    </TransactionResult>'
  end
  
  def successful_purchase_response
    successful_authorization_response
  end
  
  def failed_purchase_response
    '<r_csp></r_csp><r_time>Sun Jan 6 21:50:51 2008</r_time><r_ref></r_ref><r_error>SGS-002300: Invalid credit card type.</r_error><r_ordernum>2aec6babe076111deb2c94c21181d9fe</r_ordernum><r_message></r_message><r_code></r_code><r_tdate></r_tdate><r_score></r_score><r_authresponse></r_authresponse><r_approved>DECLINED</r_approved><r_avs></r_avs>'
  end
  
  def successful_void_response
    "CAPTURED:000000:NA:Y:Dec 11 2003:278659:NLS:NLS:NLS:53147623:200312111628:NA:NA:NA:NA:NA"
  end
  
  def failed_void_response
    "NOT CAPTURED:PARENT TRANSACTION NOT FOUND:NA:NA:Dec 11 2003:278644:NLS:NLS:NLS:53147562:200311251526:NA:NA:NA:NA:NA"
  end
  
  def error_response
    '!ERROR! 704-MISSING BASIC DATA TYPE:card, exp, zip, addr, member, amount'
  end

  
end
