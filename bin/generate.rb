$LOAD_PATH << File.dirname(__FILE__) + "/../lib"

require "olyp_invoice_pdf_generator/invoice_pdf_generator"
require "net/http"
require "uri"
require "json"

uri = URI.parse(ARGV[0])
http = Net::HTTP.new(uri.host, uri.port)
response = http.request(Net::HTTP::Get.new(uri.request_uri))
if response.code == "200"
  puts "Success!!"
  JSON.parse(response.body)["invoices"].each do |invoice|
    puts "Generating PDF for invoice #{invoice["invoice_number"]}"
    generator = OlypInvoicePdfGenerator::InvoicePdfGenerator.new(invoice)
    File.open("out/invoice-#{invoice["invoice_number"]}.pdf", "w+") do |f|
      f.write(generator.render)
    end
  end
else
  puts "Faaaail (#{response.code})"
  exit 1
end
