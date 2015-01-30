# -*- coding: utf-8 -*-
require "prawn"
require "prawn/table"
require "bigdecimal"
require "date"

module OlypInvoicePdfGenerator
  class InvoicePdfGenerator
    ACCOUNT_NUMBER = "1503.49.10488"

    def initialize(invoice)
      @invoice = invoice
    end

    def render
      pdf = Prawn::Document.new(:margin => [0, 0], :page_size => "A4")

      contact_info_height = draw_contact_info(pdf, "Oslo Lydproduksjon AS", "Trondheimsveien 42A
0560 Oslo
NORGE",
      "Kontonr: #{ACCOUNT_NUMBER}
Orgnr: 912 443 760
E-post: post@olyp.no")

      invoice_info_height = draw_invoice_info(pdf, [
          ["Fakturanr", "#{@invoice["invoice_number"]}"],
          ["Fakturadato", format_date(@invoice["invoice_date"])],
          ["Forfallsdato", format_date(@invoice["due_date"])],
          ["Sendt til", @invoice["customer"]["name"]]
        ])

      pdf.move_down [contact_info_height, invoice_info_height].max

      draw_lines(pdf, @invoice["lines"])

      pdf.move_down 10

      pdf.bounding_box([10, pdf.cursor], :width => pdf.bounds.width - 20) do
        pdf.text "Sum eks. MVA: #{"%.2f" % @invoice["sum_without_tax"]}"
        pdf.text "Total MVA: #{"%.2f" % @invoice["total_tax"]}"
        pdf.move_down 5
        pdf.text "Sum inkl. MVA: #{"%.2f" % @invoice["sum_with_tax"]}"
      end

      pdf.fill_color "FDFA76"
      pdf.fill_rectangle [0, 100], pdf.bounds.width, 80
      pdf.fill_color "FFFFFF"
      pdf.fill_rectangle [0, 75], pdf.bounds.width, 50

      price = ("%.2f" % @invoice["sum_with_tax"]).partition(".")
      draw_price_and_account_number(pdf, 200, 65, price[0], price[2], ACCOUNT_NUMBER)

      pdf.render
    end

    def format_date(date)
      Date.parse(date).strftime("%d.%m.%Y")
    end

    def draw_invoice_info(pdf, lines)
      pdf.font_size 9
      left_col_max = lines.collect { |line| pdf.width_of(line[0], :style => :bold) }.max
      right_col_max = lines.collect { |line| pdf.width_of(line[1]) }.max
      col_spacing = 20

      invoice_info_box = pdf.bounding_box([pdf.bounds.width - left_col_max - right_col_max - col_spacing - 10, pdf.bounds.height - 10], :width => left_col_max + col_spacing + right_col_max) do
        left_col_box = pdf.bounding_box([0, 0], :width => left_col_max) do
          lines.each do |line|
            pdf.text "#{line[0]}", :style => :bold, :align => :right
          end
        end

        pdf.bounding_box([left_col_max + col_spacing, left_col_box.height], :width => right_col_max) do
          lines.each do |line|
            pdf.text "#{line[1]}", :align => :left
          end
        end
      end

      # @pdf.move_down invoice_info_box.height

      return invoice_info_box.height
    end

    def get_line_tax_text(line)
      "#{line["tax"]}%"
    end

    def get_line_price_text(line)
      "%.2f" % BigDecimal.new(line["unit_price"])
    end

    def get_line_sum_text(line)
      "%.2f" % BigDecimal.new(line["sum_without_tax"])
    end

    def draw_lines(pdf, lines)
      width = pdf.bounds.width - 20
      padding = 5

      pdf.bounding_box([10, pdf.cursor - 10], :width => width) do
        pdf.font_size 9

        table_lines = [["Antall", "Produktnr", "Beskrivelse", "Enhetspris", "MVA", "Sum"]].concat(lines.collect do |line|
            [line["quantity"], line["product_code"], line["description"], get_line_price_text(line), get_line_tax_text(line), get_line_sum_text(line)]
          end)

        description_col_idx = 2
        num_cols = table_lines[0].length

        computed_col_widths = (0..num_cols).collect {|i| table_lines.collect { |line| pdf.width_of(line[i] || "", :style => :bold)}.max + (padding * 2) }

        total_col_widths_except_description = computed_col_widths.clone
        total_col_widths_except_description.delete_at(description_col_idx)
        total_col_widths_except_description = total_col_widths_except_description.inject {|sum, x| sum + x}

        col_widths = computed_col_widths.clone
        col_widths[description_col_idx] = width - total_col_widths_except_description

        pdf.table(
          table_lines,
          :column_widths  => col_widths,
          :cell_style => {:border_width => 1, :border_color => "dddddd"}) do
          row(0).font_style = :bold
          row(0).background_color = "dddddd"
          rows(0..-1).style(:padding => padding)
        end
      end
    end

    def draw_contact_info(pdf, header, address, contact_info)
      pdf.fill_color "000000"

      header_style = {:style => :bold, :size => 11}
      address_style = {:size => 10}
      contact_info_style = {:size => 9}

      box_width = [
        pdf.width_of(header, header_style),
        pdf.width_of(address, address_style),
        pdf.width_of(contact_info, contact_info_style)
      ].max

      contact_info_box = pdf.bounding_box([10, pdf.bounds.height - 10], :width => box_width) do
        pdf.image File.dirname(__FILE__) + "/olyp_logo.png", :width => 200
        pdf.move_down 20
        pdf.text header, header_style
        pdf.move_down 10
        pdf.text address, address_style
        pdf.move_down 10
        pdf.text contact_info, contact_info_style
      end

      return contact_info_box.height
    end

    def draw_price_and_account_number(pdf, start_x, y, price_base, price_fraction, account_number)
      pdf.fill_color "000000"
      pdf.font_size 9

      x = start_x
      pdf.bounding_box([x, y], :width => 70) do
        pdf.text "Kroner", :style => :bold
        pdf.move_down 10
        pdf.text price_base
      end

      x += 70

      pdf.bounding_box([x, y], :width => 50) do
        pdf.text "Øre", :style => :bold
        pdf.move_down 10
        pdf.text price_fraction
      end

      x += 50

      pdf.bounding_box([x, y], :width => 70) do
        pdf.text "Til konto", :style => :bold
        pdf.move_down 10
        pdf.text account_number
      end
    end
  end
end
