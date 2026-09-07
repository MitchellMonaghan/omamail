import QtQuick
import QtTest
import "../../message/Html.js" as Html

Item {
  width: 800
  height: 400

  TextEdit {
    id: document
    textFormat: TextEdit.RichText
    readOnly: true
    wrapMode: TextEdit.Wrap
    font.family: "monospace"
    width: 280
    height: contentHeight
  }

  TestCase {
    name: "ReaderStatusRow"
    when: windowShown

    function test_original_css_image_centering() {
      // A 640x320 canvas displayed at 40px high, like a height-only hero image.
      var image = 'data:image/gif;base64,R0lGODlhgAJAAYAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
      var source = '<table width="260"><tr><td><table width="100%"><tr><td><div>'
        + '<table width="100%" cellspacing="0" cellpadding="0"><tbody><tr>'
        + '<td style="padding:0 24px;text-align:center"> <img style="display:inline-block" height="40" src="' + image + '"> </td>'
        + '</tr></tbody></table></div></td></tr></table></td></tr></table>'
      var ready = Html.sanitize(source, { preserveFormatting: true })
      document.width = 280
      document.text = Html.documentFor(ready.document, { preserveFormatting: true, maxImageWidth: 280 })
      wait(0)
      var plain = document.getText(0, document.length)
      var position = plain.indexOf('\ufffc')
      verify(position >= 0)
      var box = document.positionToRectangle(position)
      verify(box.x > 80 && box.x < 110, "Image should be centered in its cell, x=" + box.x)
    }

    function test_original_label_above_icon() {
      var image = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
      var source = '<table><tr><td style="text-align:center"> <div style="font-size:11px"> A </div> '
        + '<img width="28" height="28" src="' + image + '"> </td></tr></table>'
      var ready = Html.sanitize(source, { preserveFormatting: true })
      document.width = 280
      document.text = Html.documentFor(ready.document, { preserveFormatting: true, maxImageWidth: 280 })
      wait(0)
      var plain = document.getText(0, document.length)
      var label = document.positionToRectangle(plain.indexOf('A'))
      var icon = document.positionToRectangle(plain.indexOf('\ufffc'))
      verify(icon.y > label.y, "Icon should follow the label on its own line")
    }

    function test_original_keeps_layout_alignment() {
      var source = '<table width="260" cellpadding="10" bgcolor="#234567"><tr>'
        + '<td><p align="center">Centered</p></td></tr><tr><td>'
        + '<table><tr><td>Left</td><td>Right</td></tr></table>'
        + '</td></tr></table>'
      var ready = Html.sanitize(source, { preserveFormatting: true, withReader: true })
      document.width = 280
      document.font.pixelSize = 13
      document.text = Html.documentFor(ready.document, { preserveFormatting: true, maxImageWidth: 280 })
      wait(0)
      var plain = document.getText(0, document.length)
      var center = document.positionToRectangle(plain.indexOf("Centered"))
      var left = document.positionToRectangle(plain.indexOf("Left"))
      var right = document.positionToRectangle(plain.indexOf("Right"))
      verify(center.x > left.x + 20, "Sender's centered paragraph must stay centered")
      compare(left.y, right.y, "Layout cells must remain beside each other")
      verify(right.x > left.x)
      verify(document.contentWidth <= document.width)
    }

    function test_labels_stay_side_by_side_data() {
      return [
        { tag: "narrow", width: 280, size: 13 },
        { tag: "wide", width: 700, size: 13 },
        { tag: "narrow-zoom", width: 280, size: 20 },
        { tag: "wide-labels", width: 280, size: 20, suffix: "WWW" },
        { tag: "original-narrow", width: 280, size: 13, original: true },
        { tag: "original-wide", width: 700, size: 13, original: true },
        { tag: "original-zoom", width: 280, size: 20, original: true }
      ]
    }

    function test_labels_stay_side_by_side(data) {
      // A self-contained image prevents network traffic in the real Qt renderer.
      var image = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
      var source = "<table><tr>"
      for (var i = 0; i < 7; i++) {
        source += "<td><div>" + String.fromCharCode(65 + i) + (data.suffix || "") + "</div><img src=\""
          + image + "\" width=\"28\" height=\"28\"></td>"
      }
      source += "</tr></table>"
      var ready = Html.sanitize(source, { withReader: true, preserveFormatting: data.original === true })
      document.width = data.width
      document.font.pixelSize = data.size
      document.text = data.original
        ? Html.documentFor(ready.document, { maxImageWidth: 200, compact: true })
        : Html.readerDocumentFor(ready.reader.document, { fontSize: data.size })
      wait(1)
      var plain = document.getText(0, document.length)
      var first = document.positionToRectangle(plain.indexOf("A"))
      var previous = first
      for (var j = 1; j < 7; j++) {
        var position = plain.indexOf(String.fromCharCode(65 + j))
        verify(position >= 0)
        var rect = document.positionToRectangle(position)
        compare(rect.y, first.y, "Status labels must share one horizontal row")
        verify(rect.x > previous.x, "Each icon keeps its own column")
        verify(rect.x + rect.width <= document.width, "The row fits the narrow reader")
        previous = rect
      }
      verify(document.contentHeight < 120, "Seven statuses must not become fourteen paragraphs")
      verify(document.contentWidth <= document.width, "The whole row must fit, including its last label")
    }
  }
}
