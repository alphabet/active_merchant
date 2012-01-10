module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class FirstDataGateway < Gateway
      
    # Initialization Options
    # :payment_page_id      the login is the Global Gateway e4 Gateway ID, configured in the merchant config screens
    # :transaction_key      The private key for the payment page id, also configured in the merchant config screens
      
      URL = 'https://api.globalgatewaye4.firstdata.com/transaction/v9'
      FIRST_DATA_WDSL = 'https://api.globalgatewaye4.firstdata.com/transaction/v9/wsdl'

      TRANSACTIONS = {
        :purchase => '00',
        :authorize => '01',
        :preauth_complete => '02',
        :forced_post => '03',
        :refund => '04',
        :pre_auth_only => '05',
        :void => '13',
        :tagged_preauth_complete => '32',
        :taggged_void => '33',
        :tagged_refund => '34',
        :secure_storage => '60',
        :information_retrieval => 'CR'
      }

      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['US']
      self.money_format = :cents
      self.default_currency = 'USD' #https://firstdata.zendesk.com/entries/450214-supported-currencies
      
      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :american_express, :discover, :jcb]
      
      # The homepage URL of the gateway
      self.homepage_url = 'http://www.firstdata.com/'
      
      # The name of the gateway
      self.display_name = 'First Data Global Gateway'
      
      # server communication errors
      BAD_REQUEST, UNAUTHORIZED, PAYMENT_REQUIRED, FORBIDDEN, NOT_FOUND  = 400, 401, 402, 403, 404 
      METHOD_NOT_ALLOWED, NOT_ACCEPTABLE, PROXY_AUTH_REQUIRED, REQUEST_TIMEOUT = 405, 406, 407, 408
      CONFLICT, GONE, LENGTH_REQUIRED, PRECONDITION_FAILED, REQUEST_TOO_LARGE = 409, 410, 411, 412, 413
      REQUEST_URI_TOO_LONG, UNSUPPORTED_MEDIA_TYPE, REQUEST_RANGE_NOT_SUITABLE = 414, 415, 416
      EXPECTATION_FAIL, INTERNAL_SERVER_ERR = 417, 500
      
      # transaction errors
      APPROVED = '00'
      CVV_ERR, INVALID_CC_NUM, INVALID_EXPIRY = '08', '22', '25'
      INVALID_AMOUNT, INVALID_CARD_HOLDER, INVALID_AUTH_NUM, INVALID_VERIF_STR = '26', '27', '28', '31'
      INVALID_TRANS_CODE, INVALID_REF_NUM, INVALID_AVS_STR, INVALID_DUP = '32', '57', '58', '63'
      INVALID_REFUND, RESTRICTED_CARD_NUMBER = '64', '68'
      
      # problem with the Global Gateway e4 host or an error in the merchant configuration
      INVALID_TRANS_DESC, INVALID_GATEWAY_ID, INVALID_TRANS_NUM, INACTIVE_CONNECTION = 10,14,15,16
      UNMATCHED_TRANSACTION, INVALID_REVERSAL_RESPONSE, UNABLE_TO_SEND_SOCKET_TRN = 17, 18, 19
      UNABLE_TO_WRITE_TRANS_FILE, UNABLE_TO_VOID, UNABLE_TO_CONNECT, UNABLE_TO_SEND_LOGIN = 20, 24, 40, 41
      UNABLE_TO_SEND_TRANS, INVALID_LOGIN, TERMINAL_NOT_ACTIVATED, GATEWAY_MISMATCH = 42, 43, 52, 53
      
      # ... there are more, see https://firstdata.zendesk.com/entries/451980-ecommerce-response-codes-etg-codes 
      
      def initialize(options = {})
        # the login is the Global Gateway e4 Gateway ID and password configured in the gateway config screens
        # online at https://globalgatewaye4.firstdata.com/terminal
        # <ExactID>A00140-01</ExactID>  <Password>Hc_tlsaH</Password>
        requires!(options, :login, :password)
        @options = options
        super       
        raise ArgumentError, "You need to pass in your login (Gateway ID) and Password or set these values globally using ActiveMerchant::Billing::FirstDataGateway.login = my_gateway_id " if @options[:login].blank?
      end  
      
      def add_invoice(xml, options)
        # todo: level 3 line items 
      end
      
      def add_money(money,xml)
        unless money.nil?
          xml.tag!('DollarAmount', money)
          xml.tag!('Currency', (options[:currency] || currency(money)))
        end
        xml.target!
      end
      
      
      def add_authorization_and_tag(money, xml, options)
        xml.tag!('Authorization_Num', options[:authorization])
        xml.tag!('Transaction_Tag', options[:transaction_tag])
        xml.target!
      end
      
      def add_customer_data(xml, options)
        if options.has_key? :email
          xml.tag!('client_email', options[:email])
        end

        if options.has_key? :customer
          xml.tag!('cust_id', options[:customer])
        end

        if options.has_key? :ip
          xml.tag!('customer_ip', options[:ip])
        end
        xml.target!
      end

      def add_address(xml, options)
        if options[:shipping_address].class == Hash
          xml.tag!('level3_ship_to_address') do |l3|
          l3.tag!('company', options[:shipping_address][:address1].to_s)
          l3.tag!('city', options[:shipping_address][:city].to_s)
          l3.tag!('state', options[:shipping_address][:state].blank?  ? 'n/a' : options[:shipping_address][:state])
          l3.tag!('zip', options[:shipping_address][:zip].to_s)
          l3.tag!('country', options[:shipping_address][:country].to_s)
          l3.tag!('customer_number', options[:shipping_address][:customer])
          l3.tag!('phone', options[:shipping_address][:phone].to_s)
          l3.tag!('email', options[:shipping_address][:email]) if options.has_key? :email
          end
        end
        
        if options[:billing_address].class == Hash
          xml.tag!('VerificationStr1', add_verification_str(options))
          xml.tag!('ZipCode', options[:billing_address][:zip])
        end
          xml.target!
      end
      
      def add_verification_str(options)
        if options[:billing_address].class == Hash
          @retval = options[:billing_address][:address1] 
          #@retval += "\n" + options[:billing_address][:address2] unless options[:billing_address][:address2].blank?
          #@retval += "\n" + options[:billing_address][:city] + ' ' + options[:billing_address][:state] + ', ' + options[:billing_address][:zip]
          @retval += ' ' + options[:billing_address][:zip]
        end
        @retval
      end
      
      # Perform an authorization and reserve funds on the customer's credit card, but do not
      # charge the card.
      def authorize(money, creditcard, options = {})
        xml = add_authentication_headers
        add_creditcard(xml, creditcard)
        add_address(xml, options)        
        add_customer_data(xml, options)
        add_money(money, xml)
        response = commit(:authorize, xml, options)
        response
      end
      
      def add_creditcard(xml, creditcard)       
          xml.tag!('Card_Number', creditcard.number)
          xml.tag! 'CVD_Presence_Ind', creditcard.verification_value? ? 1 : 0
          xml.tag! 'Verification_Str2', creditcard.verification_value
          xml.tag! 'Expiry_Date', expdate(creditcard)
          xml.tag! 'CardHoldersName', creditcard.name
          xml.target!        
      end
      
      def add_transarmor_token(xml, options, creditcard)
          if options.include?('transarmor_token') || options.include?('transarmortoken') # required fields for transarmor
            xml.tag! 'TransarmorToken', options[:transarmor_token] || options[:transarmortoken]
            xml.tag! 'CardType', creditcard.type
          end
      end
      
      def purchase(money, creditcard, options = {})
        xml = add_authentication_headers
        add_creditcard(xml, creditcard)        
        add_address(xml, options)   
        add_customer_data(xml, options)
        add_money(money, xml)
        response = commit(:purchase, xml, options)
        response
      end                       
    
      def capture(money, creditcard, options = {})
        xml = add_authentication_headers
        add_authorization_and_tag(money, xml, options)
        add_transarmor_token(xml, options, creditcard)
        add_money(money,xml)
        response = commit(:tagged_preauth_complete, xml, options)
        response
      end
    
      private                       
      
      def commit(action, xml, options = {})
        gateway_response = ssl_post(URL, build_request(xml, action, options), "Content-Type" => "text/xml") 
        response = parse(gateway_response)
        # this is a bit hacky in the to_i to_s comparison, and the avs codes may need to be mapped first_data to active_merchant
        Response.new(success?(response), response[:exact_message], response, 
            response.merge(:test => test?,
            :authorization => response[:authorization_num],
            :avs_result => { 
              :code => (response[:avs].to_i.to_s == response[:avs].to_s ? response[:avs].to_s : '')
              },
            :cvv_result => (response[:cvv].to_i.to_s == response[:cvv].to_s ? response[:cvv].to_s : '')
            )
          )
      end

      def test?
        true
      end
      
      def success?(r)
        r[:transaction_approved] == true
      end            
      
      def parse(_xml)
        reply = {}
        xml = REXML::Document.new(_xml)
        xml.root.elements.each do |node|
          reply[node.name.downcase.sub(/^r_/, '').to_sym] = typecast(node.text)
        end unless xml.root.nil?
        reply
      end     


      # Make a ruby type out of the response string
      def typecast(field)
        case field
        when "true"   then true
        when "false"  then false
        when ""       then nil
        when "null"   then nil
        else field
        end        
      end
      
      def camelize_and_underscore(camel_cased_word)
        word = camel_cased_word.to_s.dup
        word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
        word.gsub!(/::/, '/')
        word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        word.tr!("-", "_")
        word
      end
      
       # Build the XML file
      def build_request(xml, action, options = {})
        unless TRANSACTIONS.include?(action)
          raise StandardError, "Invalid First Data Action: #{action}"
        end
          xml.tag!('Transaction_Type', TRANSACTIONS[action])
          xml = wrap_xml(xml)
      end
      
      def wrap_xml(xml)
        _xml = Builder::XmlMarkup.new(:indent => 2)
        _xml.instruct!(:xml, :version => '1.0', :encoding => 'utf-8', :xmlns => FIRST_DATA_WDSL)
        _xml.Transaction{|t|t << xml.target!}
        _xml.target!
      end
      
      def add_authentication_headers
        xml = Builder::XmlMarkup.new(:indent => 2)
        xml.tag!('ExactID', @options[:login])
        xml.tag!('Password', @options[:password])
        xml
      end

      private
      
      def expdate(creditcard)
        year  = sprintf("%.4i", creditcard.year)
        month = sprintf("%.2i", creditcard.month)

        "#{month}#{year[-2..-1]}"
      end

 
 
    end
  end
end

