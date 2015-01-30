# -*- coding: utf-8 -*-
require "prawn"
require "prawn/table"
require "bigdecimal"

module OlypInvoicePdfGenerator
  class InvoicePdfGenerator
    ACCOUNT_NUMBER = "0539.08.57553"

    def initialize(invoice)
      @invoice = invoice
      @pdf = Prawn::Document.new(:margin => [0, 0], :page_size => "A4")
    end

    def render
      draw_contact_info("Olyp AS", "Gateveien 14
1414 Oslo
NORGE",
      "Tlf: 12312312
Kontonr: #{ACCOUNT_NUMBER}
Orgnr: 123123123
E-post: foo@foo.com")

      draw_invoice_info([
          ["Fakturanr", "10"],
          ["Fakturadato", "22.08.1986"],
          ["Forfallsdato", "05.09.1986"]
        ])

      draw_lines(@invoice["lines"])

      @pdf.fill_color "FDFA76"
      @pdf.fill_rectangle [0, 100], @pdf.bounds.width, 80
      @pdf.fill_color "FFFFFF"
      @pdf.fill_rectangle [0, 75], @pdf.bounds.width, 50

      draw_price_and_account_number(200, 65, "149", "00", ACCOUNT_NUMBER)

      @pdf.render
    end

    def draw_invoice_info(lines)
      @pdf.font_size 9
      left_col_max = lines.collect { |line| @pdf.width_of(line[0], :style => :bold) }.max
      right_col_max = lines.collect { |line| @pdf.width_of(line[1]) }.max
      col_spacing = 20

      invoice_info_box = @pdf.bounding_box([@pdf.bounds.width - left_col_max - right_col_max - col_spacing - 10, @pdf.bounds.height - 10], :width => left_col_max + col_spacing + right_col_max) do
        left_col_box = @pdf.bounding_box([0, 0], :width => left_col_max) do
          lines.each do |line|
            @pdf.text "#{line[0]}", :style => :bold, :align => :right
          end
        end

        @pdf.bounding_box([left_col_max + col_spacing, left_col_box.height], :width => right_col_max) do
          lines.each do |line|
            @pdf.text "#{line[1]}", :align => :left
          end
        end
      end

      # @pdf.move_down invoice_info_box.height
    end

    def draw_lines(lines)
      @pdf.bounding_box([120, @pdf.cursor - 10], :width => @pdf.bounds.width - 130) do
        @pdf.font_size 9
        @pdf.table(
          [["Antall", "Produktnr", "Beskrivelse", "Enhetspris", "MVA"]].concat(lines.collect do |line|
              [line["quantity"], line["product_code"], line["description"], "%.2f" % BigDecimal.new(line["unit_price"]), "#{line["tax"]}%"]
            end),
          :column_widths  => [50, 60, 220, 70, 40],
          :cell_style => {:border_width => 1, :border_color => "dddddd"}) do
          row(0).font_style = :bold
          row(0).background_color = "dddddd"
        end
      end
    end

    def draw_contact_info(header, address, contact_info)
      @pdf.fill_color "000000"

      @pdf.bounding_box([10, @pdf.bounds.height - 10], :width => @pdf.bounds.width - 20, :height => @pdf.bounds.height - 20) do
        @pdf.text header, :style => :bold, :size => 11
        @pdf.move_down 10
        @pdf.text address, :size => 10
        @pdf.move_down 10
        @pdf.text contact_info, :size => 9
      end
    end

    def draw_price_and_account_number(start_x, y, price_base, price_fraction, account_number)
      @pdf.fill_color "000000"
      @pdf.font_size 9

      x = start_x
      @pdf.bounding_box([x, y], :width => 70) do
        @pdf.text "Kroner", :style => :bold
        @pdf.move_down 10
        @pdf.text price_base
      end

      x += 70

      @pdf.bounding_box([x, y], :width => 50) do
        @pdf.text "Øre", :style => :bold
        @pdf.move_down 10
        @pdf.text price_fraction
      end

      x += 50

      @pdf.bounding_box([x, y], :width => 70) do
        @pdf.text "Til konto", :style => :bold
        @pdf.move_down 10
        @pdf.text account_number
      end
    end
  end
end
