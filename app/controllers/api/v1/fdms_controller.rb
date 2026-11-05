require "uri"
require "net/http"

class Api::V1::FdmsController < ApplicationController

  def register_device
    csr = "
    -----BEGIN NEW CERTIFICATE REQUEST-----
    MIIDuDCCAqACAQAwajERMA8GA1UECAwIWmltYmFid2UxIzAhBgNVBAoMGlppbWJh
    YndlIFJldmVudWUgQXV0aG9yaXR5MQswCQYDVQQGEwJaVzEjMCEGA1UEAwwaWklN
    UkEtZGFwc29mdC0xLTAwMDAwMTUzMDcwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
    ggEKAoIBAQC6Fk29y0BVXM7lDhzFgOWmw85qKoJyjFKqyR/pCGZ6y3O36lFif0Go
    pesAYCcSu82d14yoNdEmBgr+t5JxscubayZkA2j97m8RuY+zLR41amcSDEzQKWAQ
    0oLraHjA7pxSJokx/Oj61m1BZOo8/2n/RCG5PgqbUzfQ2DsmjiJaFl2623zC8W9G
    6OzfhMACycPmIS3tEg2TyTJL4HRzwInplsFzBDPwi9itawssv/7+e6iPxm15rYYV
    iof90eMx9+24wjU3m+J7cMnrpHhZU3vhg+j2UeWQ+U+S6bybk8Cw9jTWxqXQOwzJ
    WANeJ8aid4Lc1l8QoBmUDAZrQFi9iq85AgMBAAGgggEHMBwGCisGAQQBgjcNAgMx
    DhYMMTAuMC4xOTA0NS4yMC4GCSqGSIb3DQEJDjEhMB8wHQYDVR0OBBYEFN4B7Z8X
    1+eNArsg5j4SEQ/KokJVME8GCSsGAQQBgjcVFDFCMEACAQUMD0RFU0tUT1AtOUxS
    MEM5TAwhREVTS1RPUC05TFIwQzlMXFRlbmRhaSBEIENoaWhvYnZ1DAdNTUMuRVhF
    MGYGCisGAQQBgjcNAgIxWDBWAgEAHk4ATQBpAGMAcgBvAHMAbwBmAHQAIABTAG8A
    ZgB0AHcAYQByAGUAIABLAGUAeQAgAFMAdABvAHIAYQBnAGUAIABQAHIAbwB2AGkA
    ZABlAHIDAQAwDQYJKoZIhvcNAQELBQADggEBAB5g2JFv7Wm/BnpEgp88gBIbIszx
    0DcslolD1pljo1D2oB9ZQMeMLs26lgwUWJPYKTIkTFcDqAqU56OA+b9OWd6sN+xZ
    ne1kaPkH32SndNT9JeINmQNslZ1EgO22tWZZ+4hNRzEgLRWhVoVpTNaCs+yusyXv
    CG/miD3GXqgtCLb3M2y84Re92O1iNscQ9SEhm3Ec+Dt4r+KgG+C85s54vjuU9b6X
    sy5g+vmP3oPpFTLUQikKXNQYgStZDpLVhUM/kmzZPNo7S1sB4526iFZwLqA4Qgyp
    X/fH7j9n8BLc+KzloGlLPY8nrbwBTMZbXerWS0wUcPSPFN3DtH9W8XmYNHI=
    -----END NEW CERTIFICATE REQUEST-----
    "

    url = URI("https://fdmsapitest.zimra.co.zw/Public/v1/15307/RegisterDevice")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["DeviceModelName"] = "Server"
    request["DeviceModelVersionNo"] = "v1"
    form_data = [['deviceID', '15307'],['activationKey', '00271588'],
    ['certificateRequest', '-----BEGIN NEW CERTIFICATE REQUEST-----
    \nMIIDuDCCAqACAQAwajERMA8GA1UECAwIWmltYmFid2UxIzAhBgNVBAoMGlppbWJh
    \nYndlIFJldmVudWUgQXV0aG9yaXR5MQswCQYDVQQGEwJaVzEjMCEGA1UEAwwaWklN
    \nUkEtZGFwc29mdC0xLTAwMDAwMTUzMDcwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
    \nggEKAoIBAQC6Fk29y0BVXM7lDhzFgOWmw85qKoJyjFKqyR/pCGZ6y3O36lFif0Go
    \npesAYCcSu82d14yoNdEmBgr+t5JxscubayZkA2j97m8RuY+zLR41amcSDEzQKWAQ
    \n0oLraHjA7pxSJokx/Oj61m1BZOo8/2n/RCG5PgqbUzfQ2DsmjiJaFl2623zC8W9G
    \n6OzfhMACycPmIS3tEg2TyTJL4HRzwInplsFzBDPwi9itawssv/7+e6iPxm15rYYV
    \niof90eMx9+24wjU3m+J7cMnrpHhZU3vhg+j2UeWQ+U+S6bybk8Cw9jTWxqXQOwzJ
    \nWANeJ8aid4Lc1l8QoBmUDAZrQFi9iq85AgMBAAGgggEHMBwGCisGAQQBgjcNAgMx
    \nDhYMMTAuMC4xOTA0NS4yMC4GCSqGSIb3DQEJDjEhMB8wHQYDVR0OBBYEFN4B7Z8X
    \n1+eNArsg5j4SEQ/KokJVME8GCSsGAQQBgjcVFDFCMEACAQUMD0RFU0tUT1AtOUxS
    \nMEM5TAwhREVTS1RPUC05TFIwQzlMXFRlbmRhaSBEIENoaWhvYnZ1DAdNTUMuRVhF
    \nMGYGCisGAQQBgjcNAgIxWDBWAgEAHk4ATQBpAGMAcgBvAHMAbwBmAHQAIABTAG8A
    \nZgB0AHcAYQByAGUAIABLAGUAeQAgAFMAdABvAHIAYQBnAGUAIABQAHIAbwB2AGkA
    \nZABlAHIDAQAwDQYJKoZIhvcNAQELBQADggEBAB5g2JFv7Wm/BnpEgp88gBIbIszx
    \n0DcslolD1pljo1D2oB9ZQMeMLs26lgwUWJPYKTIkTFcDqAqU56OA+b9OWd6sN+xZ
    \nne1kaPkH32SndNT9JeINmQNslZ1EgO22tWZZ+4hNRzEgLRWhVoVpTNaCs+yusyXv
    \nCG/miD3GXqgtCLb3M2y84Re92O1iNscQ9SEhm3Ec+Dt4r+KgG+C85s54vjuU9b6X
    \nsy5g+vmP3oPpFTLUQikKXNQYgStZDpLVhUM/kmzZPNo7S1sB4526iFZwLqA4Qgyp
    \nX/fH7j9n8BLc+KzloGlLPY8nrbwBTMZbXerWS0wUcPSPFN3DtH9W8XmYNHI=
    \n-----END NEW CERTIFICATE REQUEST-----']]
    request.set_form form_data, 'multipart/form-data'
    response = https.request(request)
    puts "this response #{response.read_body}"
  end
end
