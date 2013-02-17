#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')
unorm = require('unorm')

fs.readFile('/Users/nkallen/Workspace/pseudw/site/src/main/resources/iliad.html', 'utf8', (err, doc) ->
  throw err if err?

  fs.readFile('/Users/nkallen/Workspace/Perseus/texts/1999.04/1999.04.0083.xml', 'utf8', (err, notes) ->
    throw err if err?

    doc = libxml.parseXml(doc)
    notes = libxml.parseXml(notes)

    out = "<ol class='notes'>\n"
    for book in doc.find("//section[@class='book']")
      bookNumber = book.attr('data-number').value()
      notesForBook = notes.get("//div1[@type='book' and @n='#{bookNumber}']")
      for line in book.find(".//div[@class='line']")
        lineNumber = line.get(".//span[@class='line-number']").text()
        if notesForLine = notesForBook.get("div2[@type='commline' and @n='#{lineNumber}']")
          out += "  <li data-book='#{bookNumber}' data-line='#{lineNumber}'>\n"
          out += "    <ol>"
          for child in notesForLine.childNodes()
            switch child.name()
              when "text"
                out += child.text()
              when "p"
                p = child
                out += "<li>"
                for child in p.childNodes()
                  switch child.name()
                    when "lemma"
                      if child.attr("lang").value() == "greek"
                        text = greek.betacode2unicode(child.text())
                        out += "<span class='lemma' data-lemma='#{text}'>#{text}</span>"
                      else
                        throw child.toString()
                    when "text"
                      out += child.text()
                    when "ref"
                      out += "<span class='reference'>#{child.text()}</span>"
                    when "quote"
                      quote = child
                      for child in quote.childNodes()
                        switch child.name()
                          when "text"
                            text = greek.betacode2unicode(child.text())
                            out += text
                          when "l"
                            out += "<span class='translation'>#{child.text()}</span>"
                          else throw child.name()
                    when "foreign"
                      if child.attr("lang").value() == "greek"
                        text = greek.betacode2unicode(child.text())
                        out += "<span class='foreign'>#{text}</span>"
                      else
                        out += "<span class='foreign'>#{child.text()}</span>"
                    when "cit"
                      cit = child
                      for child in cit.childNodes()
                        switch child.name()
                          when "quote"
                            if child.attr("lang").value() == "greek"
                              text = greek.betacode2unicode(child.text())
                              out += "<span class='quote'>#{text}</span>"
                            else
                              out += "<span class='quote'>#{child.text()}</span>"
                          when "text"
                            out += child.text()
                          when "bibl"
                            true # skip for now
                          when "quote"
                            throw "asdf"
                          else throw child.name()
                    when "bibl"
                      true
                    when "milestone"
                      true
                    when "emph"
                      out += "<em>#{child.toString()}</em>"
                    when "title"
                      out += "<span class='title'>#{child.toString()}</span>"
                    else throw child.name()
                out += "</li>"
              when "l"
                out += "<div class='translation'>"
                out += "</div>"
              else throw childNode.name()
          out += "    </ol>"
          out += "  </li>\n"

    out += "</ol>"
    console.log(out)))