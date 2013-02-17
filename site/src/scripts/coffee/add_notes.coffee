#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')
unorm = require('unorm')

notes = libxml.parseXml(fs.readFileSync('/Users/nkallen/Workspace/Perseus/texts/1999.04/1999.04.0083.xml', 'utf8'))
for textDir in fs.readdirSync(path = 'src/main/resources/iliad/books/')
  text = libxml.parseXml(fs.readFileSync(path + "#{textDir}/text.html", 'utf8'))

  out = "<ol class='notes'>\n"
  for book in text.find("//section[@class='book']")
    bookNumber = book.attr('data-number').value()
    if notesForBook = notes.get("//div1[@type='book' and @n='#{bookNumber}']")
      for line in book.find(".//div[@class='line']")
        lineNumber = line.get(".//span[@class='line-number']").text()
        if notesForLine = notesForBook.get("div2[@type='commline' and @n='#{lineNumber}']")
          out += "  <li data-book='#{bookNumber}' data-line='#{lineNumber}'>\n"
          out += "    <ol>\n"
          for child in notesForLine.childNodes()
            out += "      <li>\n"
            switch child.name()
              when "text"
                out += child.text()
              when "p"
                p = child
                for child in p.childNodes()
                  switch child.name()
                    when "lemma"
                      if child.attr("lang")?.value() == "greek"
                        text = greek.betacode2unicode(child.text())
                        out += "<span class='lemma' data-lemma='#{text}'>#{text}</span>"
                      else throw child.toString()
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
                          when "lg"
                            lg = child
                            for child in lg.childNodes()
                              switch child.name()
                                when "l"
                                  out += "<div class='line'>#{child.text()}</div>"
                                when "text"
                                  out += text
                                else throw child.toString()
                          when "emph"
                            out += "<em>#{child.text()}</em>"
                          else throw child.toString() + "1"
                    when "foreign"
                      if child.attr("lang")?.value() == "greek"
                        text = greek.betacode2unicode(child.text())
                        out += "<span class='foreign'>#{text}</span>"
                      else
                        out += "<span class='foreign'>#{child.text()}</span>"
                    when "cit"
                      cit = child
                      for child in cit.childNodes()
                        switch child.name()
                          when "quote"
                            if child.attr("lang")?.value() == "greek"
                              text = greek.betacode2unicode(child.text())
                              out += "<span class='quote'>#{text}</span>"
                            else
                              out += "<span class='quote'>#{child.text()}</span>"
                          when "text"
                            out += child.text()
                          when "bibl"
                            true # skip for now
                          else throw child.toString()
                    when "bibl"
                      true
                    when "milestone"
                      true
                    when "emph"
                      out += "<em>#{child.text()}</em>"
                    when "title"
                      out += "<span class='title'>#{child.text()}</span>"
                    else throw child.toString()
              when "l"
                out += "<span class='translation'>"
                switch child.name()
                  when "lemma"
                    if child.attr("lang")?.value() == "greek"
                      text = greek.betacode2unicode(child.text())
                      out += "<span class='lemma' data-lemma='#{text}'>#{text}</span>"
                    else
                      throw child.toString()
                  when "text"
                    out += child.text()
                  when "quote"
                    quote = child
                    for child in quote.childNodes()
                      switch child.name()
                        when "text"
                          text = greek.betacode2unicode(child.text())
                          out += text
                        when "l"
                          out += "<span class='translation'>#{child.text()}</span>"
                        else throw child.toString()
                  when "l"
                    out += "<span class='translation'>#{child.text()}</span>"
                  else throw child.name()
                out += "</span>"
              when "head"
                out += "<h6>#{child.text()}</h6>"
              else throw child.toString()
          out += "      </li>"
          out += "    </ol>"
          out += "  </li>\n"

    out += "</ol>"
    fs.writeFileSync(path + "#{textDir}/notes.html", out)