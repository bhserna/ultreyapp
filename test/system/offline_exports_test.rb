require "application_system_test_case"
require "zip"
require "tmpdir"

class OfflineExportsTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "read the extracted program and documents with HTTP requests blocked" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_prior_activities.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    Document.create!(spreadsheet_act_key: "act-002", file: fixture_file_upload("agenda.txt", "text/plain"))

    Dir.mktmpdir("ultreyapp-offline-") do |directory|
      archive = File.join(directory, "program.zip")
      copy.offline_export.write_to(archive)
      Zip::File.open(archive) do |zip|
        zip.each do |entry|
          entry.extract(destination_directory: directory, create_parent_directories: true)
        end
      end

      browser = page.driver.browser
      browser.execute_cdp("Network.enable")
      browser.execute_cdp("Network.setBlockedURLs", urls: [ "http://*", "https://*" ])
      visit "file://#{directory}/index.html"
      assert_selector "h1", text: "Programa sin conexión"
      assert_text "Copia sin conexión"
      within ".site-nav aside[aria-label='Información de la copia']" do
        assert_selector "p", count: 1
        assert_no_text "Programa de la copia"
        assert_operator find("p").native.rect.height, :<, 30
      end
      assert_equal "border-box", page.evaluate_script("getComputedStyle(document.body).boxSizing")

      click_link "Sábado 14"
      within "nav[aria-label='Tipo de actividad']" do
        click_link "Actividades previas"
      end
      assert_selector "tr.schedule__prior-activity", text: "Recepción de Diócesis"
      click_link "Domingo 15"
      assert_selector "nav[aria-label='Tipo de actividad'] a[aria-current='page']", text: "Actividades previas"
      assert_no_selector "tr.schedule__preparation"
      within "nav[aria-label='Tipo de actividad']" do
        click_link "Preparaciones"
      end
      assert_selector "tr.schedule__preparation", text: "Preparar instrumentos"
      assert_no_selector "tr", text: "Inicio / Video"
      within "nav[aria-label='Tipo de actividad']" do
        click_link "Actos"
      end
      assert_selector "tr", text: "Inicio / Video"
      assert_no_selector "tr.schedule__preparation"
      click_link "Sábado 14"
      assert_text "No hay actividades de este tipo para este día."
      within "nav[aria-label='Tipo de actividad']" do
        click_link "Todo"
      end
      assert_selector "thead th", count: 4
      assert_no_selector "thead th", text: "Tipo"
      assert_operator find(".table-container").native.rect.y, :>, find(".toolbar").native.rect.y + find(".toolbar").native.rect.height
      within "tr.schedule__prior-activity", text: "Recepción de Diócesis" do
        assert_equal "rgb(255, 244, 220)", page.evaluate_script("getComputedStyle(document.querySelector('.schedule__prior-activity')).backgroundColor")
        click_link "Ver detalle"
      end
      assert_selector "h1", text: "Recepción de Diócesis"
      click_link "← Volver al programa"
      click_link "Domingo 15"
      within :schedule_preparation, text: "Preparar instrumentos" do
        assert_text "Preparación"
        assert_equal "rgb(225, 239, 250)", page.evaluate_script("getComputedStyle(document.querySelector('.schedule__preparation')).backgroundColor")
        click_link "Ver detalle"
      end
      assert_selector "h1", text: "Preparar instrumentos"
      click_link "Acto 2 · Grupo Folklórico"
      assert_selector "h1", text: "Grupo Folklórico"
      click_link "← Volver al programa"
      within "tr", text: "Inicio / Video" do
        assert_selector ".schedule__document-count[aria-label='1 documento'] svg"
        assert_selector "a.schedule__resources-link", text: "Ver detalle"
        click_link "Ver detalle"
      end
      assert_selector "h1", text: "Inicio / Video"
      within "section[aria-label='Documentos']" do
        assert_selector ".documents__list .documents__item", count: 1
        assert_selector ".documents__format[data-format=txt]", text: "TXT"
        assert_selector ".documents__file span", text: ApplicationController.helpers.number_to_human_size(file_fixture("agenda.txt").size)
        assert_link "agenda.txt", class: "link"
        assert_no_button "Eliminar"
        assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector('.documents__list')).listStyleType")
        assert_equal "rgb(56, 84, 115)", page.evaluate_script("getComputedStyle(document.querySelector('.documents__file a')).color")
      end
      click_link "agenda.txt"
      assert_text file_fixture("agenda.txt").read.strip
    ensure
      browser&.execute_cdp("Network.setBlockedURLs", urls: [])
    end
  end
end
